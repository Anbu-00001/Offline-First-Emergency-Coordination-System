# SPDX-License-Identifier: GPL-3.0-or-later
"""
Background message redelivery worker (Day 6).

Periodically scans for undelivered messages whose recipients are
currently connected and attempts delivery.  Integrates into the
FastAPI startup lifecycle via ``asyncio.create_task``.
"""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone

from app.core.database import SessionLocal
from app.models.message import Message
from app.services.peer_manager import peer_manager
from app.core.events import event_bus

logger = logging.getLogger(__name__)

# How often (seconds) to scan for undelivered messages
SCAN_INTERVAL: float = 10.0
# Max messages to process per cycle
BATCH_SIZE: int = 50


async def _redeliver_cycle() -> int:
    """
    Single redelivery pass.

    Returns the number of messages successfully delivered.
    """
    db = SessionLocal()
    delivered_count = 0
    try:
        pending = (
            db.query(Message)
            .filter(
                Message.delivered == False,  # noqa: E712
                Message.recipient_id.isnot(None),
            )
            .order_by(Message.created_at.asc())
            .limit(BATCH_SIZE)
            .all()
        )

        if not pending:
            return 0

        now = datetime.now(timezone.utc)
        for msg in pending:
            if not peer_manager.is_user_connected(msg.recipient_id):
                continue

            payload = {
                "event": "message",
                "message_id": msg.message_id,
                "sender_id": msg.sender_id,
                "content": msg.content,
                "lamport": msg.lamport,
                "sent_at": msg.sent_at.isoformat() if msg.sent_at else None,
            }
            sent = await peer_manager.send_to_user(msg.recipient_id, payload)
            if sent:
                msg.delivered = True
                msg.delivered_at = now
                delivered_count += 1

                await event_bus.publish(
                    "message_delivered",
                    {
                        "message_id": msg.message_id,
                        "recipient_id": msg.recipient_id,
                    },
                )

        if delivered_count:
            db.commit()
            logger.info("Message worker redelivered %d message(s)", delivered_count)
    except Exception:
        db.rollback()
        logger.exception("Error in message redelivery cycle")
    finally:
        db.close()

    return delivered_count


async def message_worker_loop() -> None:
    """
    Long-running coroutine for background message redelivery.

    Start via ``asyncio.create_task(message_worker_loop())``
    during app startup.
    """
    logger.info("Message redelivery worker started (interval=%ss)", SCAN_INTERVAL)
    while True:
        try:
            await _redeliver_cycle()
        except Exception:
            logger.exception("Unexpected error in message worker loop")
        await asyncio.sleep(SCAN_INTERVAL)
