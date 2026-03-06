# SPDX-License-Identifier: GPL-3.0-or-later
"""
PairingToken model for ephemeral ad-hoc device pairing (Day 6).

A pairing token grants temporary WebSocket access to ``/ws/peer``
without requiring a full JWT.  Tokens are single-use and expire after
a configurable TTL (default 5 minutes).
"""
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Integer,
    String,
)

from app.core.database import Base


class PairingToken(Base):
    """Short-lived, single-use token for anonymous WS pairing."""

    __tablename__ = "pairing_tokens"

    id = Column(Integer, primary_key=True, autoincrement=True)

    # UUID4 token string — given to the remote device
    token = Column(
        String(36),
        unique=True,
        nullable=False,
        index=True,
        comment="UUID4 pairing token (query-param for /ws/peer)",
    )

    # Optional human-friendly PIN (e.g. 4–6 digits)
    pin = Column(
        String(8),
        nullable=True,
        comment="Optional numeric PIN for verbal exchange",
    )

    # Who requested the pairing (NULL if anonymous)
    created_by = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )

    expires_at = Column(
        DateTime(timezone=True),
        nullable=False,
        comment="Absolute expiry timestamp (UTC)",
    )

    used = Column(
        Boolean,
        nullable=False,
        default=False,
        comment="Single-use flag — set True after first WS connect",
    )

    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
    )

    def is_valid(self) -> bool:
        """Return True if the token is unused and not yet expired."""
        return (
            not self.used
            and datetime.now(timezone.utc) < self.expires_at.replace(
                tzinfo=timezone.utc
            )
            if self.expires_at.tzinfo is None
            else not self.used
            and datetime.now(timezone.utc) < self.expires_at
        )

    def __repr__(self) -> str:  # pragma: no cover
        return (
            f"<PairingToken id={self.id} token={self.token!r} "
            f"used={self.used} expires_at={self.expires_at}>"
        )
