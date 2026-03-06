# SPDX-License-Identifier: GPL-3.0-or-later
"""
Batch message sync endpoint (Day 6).

``POST /sync/messages`` accepts an array of messages from an offline
client and persists them idempotently using ``message_id`` as the
deduplication key.
"""
from __future__ import annotations

import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.events import event_bus
from app.models.message import Message
from app.schemas.message import (
    MessageBatch,
    SyncMessagesResult,
    SyncMessagesResultItem,
)
from app.services.peer_manager import peer_manager

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post(
    "/messages",
    response_model=SyncMessagesResult,
    status_code=status.HTTP_200_OK,
    summary="Batch-sync messages from offline clients",
)
async def sync_messages(
    batch: MessageBatch,
    db: Session = Depends(get_db),
) -> SyncMessagesResult:
    """
    Accept an array of messages from an offline client.

    Each message is inserted idempotently: if a ``message_id`` already
    exists the item is marked as a duplicate and skipped.  New messages
    are persisted and, if the recipient is currently connected, delivered
    immediately.
    """
    results: list[SyncMessagesResultItem] = []
    now = datetime.now(timezone.utc)

    for msg_in in batch.messages:
        # Check for existing duplicate
        existing = (
            db.query(Message)
            .filter(Message.message_id == msg_in.message_id)
            .first()
        )
        if existing is not None:
            results.append(
                SyncMessagesResultItem(
                    message_id=msg_in.message_id,
                    action="duplicate",
                    detail="Message already exists",
                )
            )
            continue

        new_msg = Message(
            message_id=msg_in.message_id,
            sender_id=None,  # Offline sync — sender identity unknown without JWT
            recipient_id=msg_in.recipient_id,
            content=msg_in.content,
            lamport=msg_in.lamport,
            sent_at=msg_in.sent_at,
            created_at=now,
            metadata_=msg_in.metadata,
            direction="inbound",
        )
        db.add(new_msg)

        try:
            db.flush()
        except IntegrityError:
            db.rollback()
            results.append(
                SyncMessagesResultItem(
                    message_id=msg_in.message_id,
                    action="duplicate",
                    detail="Concurrent duplicate detected",
                )
            )
            continue

        results.append(
            SyncMessagesResultItem(
                message_id=msg_in.message_id,
                action="created",
            )
        )

        # Publish event for downstream consumers
        await event_bus.publish(
            "message_created",
            {
                "message_id": new_msg.message_id,
                "sender_id": new_msg.sender_id,
                "recipient_id": new_msg.recipient_id,
                "source": "offline_sync",
            },
        )

        # Attempt immediate delivery if recipient is connected
        if msg_in.recipient_id is not None and peer_manager.is_user_connected(
            msg_in.recipient_id
        ):
            payload = {
                "event": "message",
                "message_id": new_msg.message_id,
                "sender_id": new_msg.sender_id,
                "content": new_msg.content,
                "lamport": new_msg.lamport,
                "sent_at": new_msg.sent_at.isoformat() if new_msg.sent_at else None,
            }
            sent = await peer_manager.send_to_user(msg_in.recipient_id, payload)
            if sent:
                new_msg.delivered = True
                new_msg.delivered_at = now

    db.commit()

    return SyncMessagesResult(synced=results, total=len(results))
