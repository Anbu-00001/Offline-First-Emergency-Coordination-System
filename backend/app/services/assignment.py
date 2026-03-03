# SPDX-License-Identifier: GPL-3.0-or-later
"""
Responder assignment service — Haversine-based nearest-available selection.

Scoring formula:
    score = haversine_km(incident, responder) + WORKLOAD_WEIGHT * current_workload

The responder with the lowest score is chosen. Assignment is performed
inside a DB transaction with SELECT … FOR UPDATE to prevent race conditions.
"""
from __future__ import annotations

import logging
import math
from typing import Optional

from sqlalchemy.orm import Session

from app.models.incident import Incident, IncidentStatus
from app.models.responder import Responder

logger = logging.getLogger(__name__)

# Weight applied to each unit of current_workload in the scoring formula
WORKLOAD_WEIGHT: float = 5.0  # km-equivalent per extra assignment

# Earth radius in kilometres (mean)
_EARTH_RADIUS_KM: float = 6_371.0


def _haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Compute the great-circle distance in km between two WGS 84 points
    using the Haversine formula.
    """
    lat1, lon1, lat2, lon2 = (math.radians(v) for v in (lat1, lon1, lat2, lon2))
    dlat = lat2 - lat1
    dlon = lon2 - lon1
    a = math.sin(dlat / 2) ** 2 + math.cos(lat1) * math.cos(lat2) * math.sin(dlon / 2) ** 2
    return 2 * _EARTH_RADIUS_KM * math.asin(math.sqrt(a))


def assign_nearest_responder(
    db: Session,
    incident: Incident,
) -> Optional[Responder]:
    """
    Find the nearest available responder and atomically assign them.

    Returns the assigned ``Responder`` or ``None`` if nobody is available.
    """
    if incident.latitude is None or incident.longitude is None:
        logger.warning("Incident %s has no coordinates — skipping assignment", incident.id)
        return None

    # Fetch candidates with known location — lock rows to avoid races
    candidates = (
        db.query(Responder)
        .filter(
            Responder.available.is_(True),
            Responder.last_known_latitude.isnot(None),
            Responder.last_known_longitude.isnot(None),
        )
        .with_for_update(skip_locked=True)
        .all()
    )

    if not candidates:
        logger.info("No available responders for incident %s", incident.id)
        return None

    # Score each candidate
    best: Optional[Responder] = None
    best_score = float("inf")
    for resp in candidates:
        dist = _haversine(
            incident.latitude,
            incident.longitude,
            resp.last_known_latitude,  # type: ignore[arg-type]
            resp.last_known_longitude,  # type: ignore[arg-type]
        )
        score = dist + WORKLOAD_WEIGHT * resp.current_workload
        logger.debug(
            "Responder %s  dist=%.2f km  workload=%d  score=%.2f",
            resp.id, dist, resp.current_workload, score,
        )
        if score < best_score:
            best_score = score
            best = resp

    if best is None:
        return None

    # Atomically assign
    incident.assigned_responder_id = best.id
    incident.status = IncidentStatus.ASSIGNED
    best.current_workload += 1
    # Optionally mark unavailable if desired (commented out to allow multiple)
    # best.available = False

    db.add(incident)
    db.add(best)
    db.commit()
    db.refresh(incident)
    db.refresh(best)

    logger.info(
        "Assigned responder %s to incident %s (score=%.2f)",
        best.id, incident.id, best_score,
    )
    return best


def release_responder(db: Session, responder_id: str) -> Optional[Responder]:
    """
    Decrement a responder's workload when an incident is resolved.

    Sets ``available = True`` if workload drops to zero.
    Returns the updated ``Responder`` or ``None`` if not found.
    """
    resp = (
        db.query(Responder)
        .filter(Responder.id == responder_id)
        .with_for_update()
        .first()
    )
    if resp is None:
        logger.warning("Responder %s not found for release", responder_id)
        return None

    resp.current_workload = max(0, resp.current_workload - 1)
    if resp.current_workload == 0:
        resp.available = True

    db.add(resp)
    db.commit()
    db.refresh(resp)
    logger.info(
        "Released responder %s — workload now %d", resp.id, resp.current_workload
    )
    return resp
