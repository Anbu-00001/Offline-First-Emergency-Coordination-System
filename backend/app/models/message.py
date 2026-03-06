# SPDX-License-Identifier: GPL-3.0-or-later
"""
Message model for peer-to-peer messaging (Day 6).

Stores every message exchanged through the WebSocket relay.  The
``message_id`` (client-generated UUID) provides idempotency — duplicate
inserts are rejected by the unique constraint.  A composite index on
``(recipient_id, delivered)`` accelerates queued-delivery look-ups.
"""
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    ForeignKey,
    Index,
    Integer,
    String,
    Text,
)
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.types import JSON

from app.core.database import Base


class Message(Base):
    """Persisted peer message for store-and-forward delivery."""

    __tablename__ = "messages"

    id = Column(Integer, primary_key=True, autoincrement=True)

    # Client-generated UUID — unique across all nodes (idempotency key)
    message_id = Column(
        String(36),
        unique=True,
        nullable=False,
        index=True,
        comment="Client-generated UUID4 for idempotent delivery",
    )

    # Sender / recipient (nullable for anonymous pairing sessions)
    sender_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
    )
    recipient_id = Column(
        Integer,
        ForeignKey("users.id", ondelete="SET NULL"),
        nullable=True,
        comment="NULL means broadcast / no specific recipient",
    )

    content = Column(Text, nullable=False)

    # Lamport logical clock for lightweight ordering
    lamport = Column(Integer, nullable=False, default=0)

    # Timestamps
    sent_at = Column(
        DateTime(timezone=True),
        nullable=False,
        comment="Client-reported send time (ISO 8601 UTC)",
    )
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        default=lambda: datetime.now(timezone.utc),
        comment="Server-side insertion time",
    )

    # Delivery tracking
    delivered = Column(Boolean, nullable=False, default=False)
    delivered_at = Column(DateTime(timezone=True), nullable=True)

    # Optional small JSON map for extensibility
    metadata_ = Column("metadata", JSON, nullable=True)

    # Direction enum stored as plain string ('inbound' | 'outbound')
    direction = Column(
        String(16),
        nullable=True,
        default="inbound",
        comment="inbound = received by server, outbound = sent to recipient",
    )

    # Composite index for efficient queued-delivery queries
    __table_args__ = (
        Index("ix_messages_recipient_delivered", "recipient_id", "delivered"),
    )

    def __repr__(self) -> str:  # pragma: no cover
        return (
            f"<Message id={self.id} message_id={self.message_id!r} "
            f"sender={self.sender_id} → recipient={self.recipient_id} "
            f"delivered={self.delivered}>"
        )
