# SPDX-License-Identifier: GPL-3.0-or-later
"""
Offline-sync endpoint for batched incident uploads.

POST /sync/incidents — accept an array of incident objects, upsert
using ``client_id + identifier`` deduplication, and resolve conflicts
by comparing ``updated_at`` timestamps (client wins if newer).
"""
from __future__ import annotations

import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.incident import CAPCategory, CAPMsgType, Incident, IncidentStatus
from app.schemas.incident import IncidentBatch, SyncResult, SyncResultItem
from app.services.notification_queue import enqueue

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post(
    "/incidents",
    response_model=SyncResult,
    status_code=status.HTTP_200_OK,
    summary="Batch-sync incidents from offline clients",
)
async def sync_incidents(
    batch: IncidentBatch,
    db: Session = Depends(get_db),
) -> SyncResult:
    """
    Accept an array of incident objects from an offline client.

    For each item:
    - If ``remote_id`` matches an existing incident **and** the client's
      ``updated_at`` is newer, merge the client payload (client wins).
    - If no match, create a new record.
    - If the server record is already newer, skip (server wins).

    Returns a list of sync result items with actions taken.
    """
    results: list[SyncResultItem] = []
    now = datetime.now(timezone.utc)

    for item in batch.incidents:
        # --- Try to find existing record -----------------------------------
        existing: Incident | None = None

        if item.remote_id:
            existing = db.query(Incident).filter(Incident.id == item.remote_id).first()

        if existing is None and item.client_id:
            # Fallback: match by client_id + identifier (idempotent)
            existing = (
                db.query(Incident)
                .filter(
                    Incident.client_id == item.client_id,
                    Incident.identifier == item.identifier,
                )
                .first()
            )

        # Map category
        try:
            cat = CAPCategory(item.category)
        except ValueError:
            cat = CAPCategory.OTHER

        if existing is not None:
            # Conflict resolution — client wins if updated_at is newer
            client_ts = item.updated_at or now
            server_ts = existing.updated_at or now
            if client_ts >= server_ts:
                existing.headline = item.headline or existing.headline
                existing.description = item.description or existing.description
                existing.latitude = item.latitude if item.latitude is not None else existing.latitude
                existing.longitude = item.longitude if item.longitude is not None else existing.longitude
                existing.priority = item.priority
                existing.type = item.type or existing.type
                existing.category = cat
                existing.updated_at = now
                db.add(existing)
                results.append(SyncResultItem(
                    client_id=item.client_id,
                    server_id=str(existing.id),
                    action="merged",
                ))
            else:
                results.append(SyncResultItem(
                    client_id=item.client_id,
                    server_id=str(existing.id),
                    action="skipped",
                ))
        else:
            # Create new incident
            new_incident = Incident(
                id=uuid.uuid4(),
                identifier=item.identifier,
                sender=item.sender,
                sent_at=item.created_at or now,
                status=IncidentStatus.PENDING,
                msg_type=CAPMsgType.ALERT,
                category=cat,
                type=item.type,
                headline=item.headline,
                description=item.description,
                latitude=item.latitude,
                longitude=item.longitude,
                priority=item.priority,
                client_id=item.client_id or str(uuid.uuid4()),
                created_at=item.created_at or now,
                updated_at=item.updated_at or now,
            )
            db.add(new_incident)
            db.flush()  # get the ID
            results.append(SyncResultItem(
                client_id=item.client_id,
                server_id=str(new_incident.id),
                action="created",
            ))
            # Enqueue event for new synced incident
            await enqueue("incident_created", {
                "id": str(new_incident.id),
                "identifier": new_incident.identifier,
                "source": "offline_sync",
            })

    db.commit()

    return SyncResult(synced=results, total=len(results))
