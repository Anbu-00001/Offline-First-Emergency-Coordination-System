# SPDX-License-Identifier: GPL-3.0-or-later
"""
Pydantic schemas for peer messaging (Day 6).

Provides validation for inbound WebSocket messages, outbound responses,
and the batch-sync endpoint.
"""
from __future__ import annotations

from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# Inbound message from a client (WebSocket or sync batch)
# ---------------------------------------------------------------------------

class MessageIn(BaseModel):
    """Schema for a message sent by a client."""

    message_id: str = Field(
        ...,
        min_length=36,
        max_length=36,
        description="Client-generated UUID4 (idempotency key)",
    )
    recipient_id: Optional[int] = Field(
        None,
        description="Target user ID; NULL for broadcast",
    )
    content: str = Field(
        ...,
        min_length=1,
        max_length=4096,
        description="Message body text",
    )
    lamport: int = Field(
        0,
        ge=0,
        description="Client Lamport counter value",
    )
    sent_at: datetime = Field(
        ...,
        description="Client-reported send timestamp (ISO 8601 UTC)",
    )
    metadata: Optional[Dict[str, Any]] = Field(
        None,
        description="Optional JSON metadata map",
    )


# ---------------------------------------------------------------------------
# Outbound message representation
# ---------------------------------------------------------------------------

class MessageOut(BaseModel):
    """Schema returned by the server for a stored message."""

    id: int
    message_id: str
    sender_id: Optional[int] = None
    recipient_id: Optional[int] = None
    content: str
    lamport: int
    sent_at: datetime
    delivered: bool
    delivered_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ---------------------------------------------------------------------------
# Batch sync schemas
# ---------------------------------------------------------------------------

class MessageBatch(BaseModel):
    """Wrapper for ``POST /sync/messages`` offline batch upload."""

    messages: List[MessageIn]


class SyncMessagesResultItem(BaseModel):
    """Per-message result from a batch sync."""

    message_id: str
    action: str  # "created" | "duplicate" | "error"
    detail: Optional[str] = None


class SyncMessagesResult(BaseModel):
    """Aggregate response for batch message sync."""

    synced: List[SyncMessagesResultItem]
    total: int
