# SPDX-License-Identifier: GPL-3.0-or-later
"""
Ephemeral pairing token endpoints (Day 6).

``POST /pairing/request`` creates a short-lived, single-use token that
a remote device can use (via ``?pair_token=``) to connect to the
``/ws/peer`` WebSocket without a full JWT.

Tokens are **never** published in mDNS TXT records or any discoverable
channel — they must be exchanged out-of-band (verbal PIN, QR, etc.).
"""
from __future__ import annotations

import logging
import random
import time
import uuid
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models.pairing import PairingToken

logger = logging.getLogger(__name__)

router = APIRouter()

# ---------------------------------------------------------------------------
# Simple in-memory rate limiter (per IP)
# ---------------------------------------------------------------------------

_rate_store: dict[str, list[float]] = defaultdict(list)
RATE_LIMIT_WINDOW: float = 60.0  # seconds
RATE_LIMIT_MAX: int = 10  # max requests per window


def _check_rate_limit(client_ip: str) -> None:
    """Raise 429 if the client has exceeded the pairing request rate limit."""
    now = time.time()
    timestamps = _rate_store[client_ip]
    # Prune old entries
    _rate_store[client_ip] = [t for t in timestamps if now - t < RATE_LIMIT_WINDOW]
    if len(_rate_store[client_ip]) >= RATE_LIMIT_MAX:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Rate limit exceeded for pairing requests",
        )
    _rate_store[client_ip].append(now)


# ---------------------------------------------------------------------------
# Request / response schemas
# ---------------------------------------------------------------------------

class PairingRequest(BaseModel):
    """Body for ``POST /pairing/request``."""

    pin_length: int = Field(
        4,
        ge=4,
        le=8,
        description="Number of digits for the optional human PIN",
    )
    ttl_minutes: int = Field(
        5,
        ge=1,
        le=60,
        description="Token time-to-live in minutes",
    )


class PairingResponse(BaseModel):
    """Response from ``POST /pairing/request``."""

    token: str
    pin: Optional[str] = None
    expires_at: datetime


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.post(
    "/request",
    response_model=PairingResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create an ephemeral pairing token",
)
def create_pairing_token(
    body: PairingRequest,
    request: Request,
    db: Session = Depends(get_db),
) -> PairingResponse:
    """
    Generate a one-time pairing token with a short TTL.

    The token and optional PIN should be communicated to the remote
    device out-of-band (verbally, QR, etc.).  The remote device then
    opens ``/ws/peer?pair_token=<token>`` to establish a paired session.
    """
    client_ip = request.client.host if request.client else "unknown"
    _check_rate_limit(client_ip)

    token_str = str(uuid.uuid4())
    pin = "".join(str(random.randint(0, 9)) for _ in range(body.pin_length))
    expires_at = datetime.now(timezone.utc) + timedelta(minutes=body.ttl_minutes)

    record = PairingToken(
        token=token_str,
        pin=pin,
        expires_at=expires_at,
    )
    db.add(record)
    db.commit()
    db.refresh(record)

    logger.info(
        "Pairing token created: token=%s pin=%s expires=%s (IP=%s)",
        token_str,
        pin,
        expires_at.isoformat(),
        client_ip,
    )

    return PairingResponse(
        token=token_str,
        pin=pin,
        expires_at=expires_at,
    )


@router.get(
    "/verify",
    summary="Debug: check whether a pairing token is still valid",
)
def verify_pairing_token(
    token: str = Query(..., description="Pairing token UUID"),
    db: Session = Depends(get_db),
) -> dict:
    """
    Admin/debug endpoint to inspect a pairing token's status.

    Should only be exposed in development/testing environments.
    """
    record = db.query(PairingToken).filter(PairingToken.token == token).first()
    if record is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Token not found",
        )

    now = datetime.now(timezone.utc)
    expires = record.expires_at
    if expires.tzinfo is None:
        expires = expires.replace(tzinfo=timezone.utc)

    return {
        "token": record.token,
        "used": record.used,
        "expired": now >= expires,
        "expires_at": expires.isoformat(),
        "created_at": record.created_at.isoformat() if record.created_at else None,
    }
