# SPDX-License-Identifier: GPL-3.0-or-later
"""
Incident CRUD endpoints.

POST /incidents  — create (auth optional)
GET  /incidents  — list with filters (role-aware)
PATCH /incidents/{id}  — status / assignment updates
"""
from __future__ import annotations

import logging
import time
import uuid
from collections import defaultdict
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.incident import CAPCategory, CAPMsgType, Incident, IncidentStatus
from app.models.user import User
from app.schemas.incident import IncidentCreate, IncidentOut, IncidentUpdate
from app.services.assignment import assign_nearest_responder
from app.services.notification_queue import enqueue

logger = logging.getLogger(__name__)

router = APIRouter()

# ---------------------------------------------------------------------------
# Simple in-memory rate limiter (IP-based, dev-only)
# ---------------------------------------------------------------------------
_rate_store: dict[str, list[float]] = defaultdict(list)
_RATE_LIMIT = 30  # max requests
_RATE_WINDOW = 60  # seconds


def _check_rate_limit(client_ip: str) -> None:
    """Raise 429 if client exceeds the simple rate limit."""
    now = time.time()
    window_start = now - _RATE_WINDOW
    # Purge old entries
    _rate_store[client_ip] = [t for t in _rate_store[client_ip] if t > window_start]
    if len(_rate_store[client_ip]) >= _RATE_LIMIT:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Rate limit exceeded. Try again later.",
        )
    _rate_store[client_ip].append(now)


# ---------------------------------------------------------------------------
# Dependency: optional auth (allow anonymous)
# ---------------------------------------------------------------------------
def _get_optional_user(
    db: Session = Depends(get_db),
) -> Optional[User]:
    """Return None — anonymous creation is allowed."""
    return None


# ---------------------------------------------------------------------------
# POST /incidents
# ---------------------------------------------------------------------------
@router.post(
    "",
    response_model=IncidentOut,
    status_code=status.HTTP_201_CREATED,
    summary="Create a new incident",
)
async def create_incident(
    payload: IncidentCreate,
    db: Session = Depends(get_db),
) -> IncidentOut:
    """
    Create a new incident record.

    Authentication is optional — anonymous reports are accepted.
    On success the incident is persisted with status ``pending``,
    the assignment service is invoked, and an ``incident_created``
    event is enqueued for WebSocket broadcast.
    """
    # Map category string to enum (case-insensitive)
    try:
        cat = CAPCategory(payload.category)
    except ValueError:
        cat = CAPCategory.OTHER

    now = datetime.now(timezone.utc)

    incident = Incident(
        id=uuid.uuid4(),
        identifier=payload.identifier,
        sender=payload.sender,
        sent_at=now,
        status=IncidentStatus.PENDING,
        msg_type=CAPMsgType.ALERT,
        category=cat,
        type=payload.type,
        headline=payload.headline,
        description=payload.description,
        latitude=payload.latitude,
        longitude=payload.longitude,
        priority=payload.priority,
        created_at=now,
        updated_at=now,
    )
    db.add(incident)
    db.commit()
    db.refresh(incident)

    # Attempt automatic assignment
    responder = assign_nearest_responder(db, incident)

    # Publish event
    event_name = "incident_created"
    event_payload = {
        "id": str(incident.id),
        "identifier": incident.identifier,
        "status": incident.status.value if incident.status else "Pending",
        "latitude": incident.latitude,
        "longitude": incident.longitude,
        "assigned_responder_id": str(incident.assigned_responder_id) if incident.assigned_responder_id else None,
    }
    await enqueue(event_name, event_payload)

    if responder:
        await enqueue("incident_assigned", {
            "incident_id": str(incident.id),
            "responder_id": str(responder.id),
        })

    return IncidentOut.model_validate(incident)


# ---------------------------------------------------------------------------
# GET /incidents
# ---------------------------------------------------------------------------
@router.get(
    "",
    response_model=list[IncidentOut],
    summary="List incidents with filters",
)
def list_incidents(
    status_filter: Optional[str] = Query(None, alias="status", description="Filter by status"),
    min_lat: Optional[float] = Query(None, description="Bounding-box min latitude"),
    min_lon: Optional[float] = Query(None, description="Bounding-box min longitude"),
    max_lat: Optional[float] = Query(None, description="Bounding-box max latitude"),
    max_lon: Optional[float] = Query(None, description="Bounding-box max longitude"),
    since: Optional[datetime] = Query(None, description="Only incidents created after this UTC timestamp"),
    limit: int = Query(50, ge=1, le=500),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
) -> list[IncidentOut]:
    """
    Retrieve incidents with optional filters.

    Filters:
    - **status**: one of Pending, Assigned, InProgress, Resolved, Cancelled
    - **bbox**: bounding box via minLat/minLon/maxLat/maxLon
    - **since**: only incidents created after this ISO 8601 timestamp
    """
    q = db.query(Incident)

    if status_filter:
        try:
            enum_val = IncidentStatus(status_filter)
            q = q.filter(Incident.status == enum_val)
        except ValueError:
            pass  # ignore invalid status — return unfiltered

    if all(v is not None for v in (min_lat, min_lon, max_lat, max_lon)):
        q = q.filter(
            Incident.latitude >= min_lat,
            Incident.latitude <= max_lat,
            Incident.longitude >= min_lon,
            Incident.longitude <= max_lon,
        )

    if since is not None:
        q = q.filter(Incident.created_at >= since)

    q = q.order_by(Incident.created_at.desc())
    incidents = q.offset(offset).limit(limit).all()
    return [IncidentOut.model_validate(i) for i in incidents]


# ---------------------------------------------------------------------------
# PATCH /incidents/{id}
# ---------------------------------------------------------------------------
@router.patch(
    "/{incident_id}",
    response_model=IncidentOut,
    summary="Update incident status or assignment",
)
async def update_incident(
    incident_id: str,
    payload: IncidentUpdate,
    db: Session = Depends(get_db),
) -> IncidentOut:
    """
    Partially update an incident.

    Supported fields: ``status``, ``assigned_responder_id``,
    ``priority``, ``headline``, ``description``.
    """
    incident = db.query(Incident).filter(Incident.id == incident_id).first()
    if incident is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Incident {incident_id} not found",
        )

    if payload.status is not None:
        try:
            incident.status = IncidentStatus(payload.status)
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail=f"Invalid status: {payload.status}",
            )

    if payload.assigned_responder_id is not None:
        incident.assigned_responder_id = payload.assigned_responder_id
        if incident.status == IncidentStatus.PENDING:
            incident.status = IncidentStatus.ASSIGNED

    if payload.priority is not None:
        incident.priority = payload.priority
    if payload.headline is not None:
        incident.headline = payload.headline
    if payload.description is not None:
        incident.description = payload.description

    incident.updated_at = datetime.now(timezone.utc)
    db.add(incident)
    db.commit()
    db.refresh(incident)

    # Publish update event
    await enqueue("incident_updated", {
        "id": str(incident.id),
        "status": incident.status.value if incident.status else None,
        "assigned_responder_id": str(incident.assigned_responder_id) if incident.assigned_responder_id else None,
    })

    return IncidentOut.model_validate(incident)
