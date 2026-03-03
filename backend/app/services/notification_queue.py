# SPDX-License-Identifier: GPL-3.0-or-later
"""
Background notification queue.

Uses an ``asyncio.Queue`` to decouple event producers (API endpoints,
assignment service) from consumers (WebSocket broadcast, logging).

A single background task drains the queue and publishes each job to
the ``event_bus``. Failed jobs are retried up to ``MAX_RETRIES`` times.
"""
from __future__ import annotations

import asyncio
import logging
from typing import Any, Dict

from app.core.events import event_bus

logger = logging.getLogger(__name__)

MAX_RETRIES: int = 3
RETRY_DELAY_SECONDS: float = 1.0

# Module-level queue — initialised once per process
notification_queue: asyncio.Queue[Dict[str, Any]] = asyncio.Queue()


async def enqueue(event_name: str, payload: Dict[str, Any]) -> None:
    """
    Put a notification job onto the queue.

    Args:
        event_name: e.g. ``incident_created``, ``incident_assigned``.
        payload: JSON-serializable dict to broadcast.
    """
    await notification_queue.put({"event": event_name, "data": payload})
    logger.debug("Enqueued event '%s'", event_name)


async def _process_job(job: Dict[str, Any]) -> None:
    """Publish a single job to the event bus with retries."""
    event_name = job["event"]
    payload = job["data"]

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            await event_bus.publish(event_name, payload)
            return
        except Exception:
            logger.exception(
                "Attempt %d/%d failed for event '%s'",
                attempt, MAX_RETRIES, event_name,
            )
            if attempt < MAX_RETRIES:
                await asyncio.sleep(RETRY_DELAY_SECONDS)

    logger.error("Dropping event '%s' after %d retries", event_name, MAX_RETRIES)


async def consume_forever() -> None:
    """
    Long-running coroutine that drains the notification queue.

    Designed to be started as a background task during app startup::

        asyncio.create_task(consume_forever())
    """
    logger.info("Notification queue consumer started")
    while True:
        job = await notification_queue.get()
        try:
            await _process_job(job)
        except Exception:
            logger.exception("Unexpected error in queue consumer")
        finally:
            notification_queue.task_done()
