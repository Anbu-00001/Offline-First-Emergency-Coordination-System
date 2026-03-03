# SPDX-License-Identifier: GPL-3.0-or-later
"""
Simple in-process event broadcaster (pub/sub).

Provides a lightweight mechanism for decoupled communication between
services without external dependencies (no Redis, no message broker).

Usage:
    from app.core.events import event_bus

    # Subscribe
    async def on_incident(payload):
        print(payload)

    event_bus.subscribe("incident_created", on_incident)

    # Publish
    await event_bus.publish("incident_created", {"id": "..."})
"""
from __future__ import annotations

import asyncio
import logging
from collections import defaultdict
from typing import Any, Callable, Coroutine, Dict, List

logger = logging.getLogger(__name__)

# Type alias for async callback
AsyncCallback = Callable[[Dict[str, Any]], Coroutine[Any, Any, None]]


class EventBus:
    """Thread-safe, async-first in-process event bus."""

    def __init__(self) -> None:
        self._subscribers: Dict[str, List[AsyncCallback]] = defaultdict(list)

    def subscribe(self, event_name: str, callback: AsyncCallback) -> None:
        """Register an async callback for the given event name."""
        self._subscribers[event_name].append(callback)
        logger.debug("Subscribed %s to event '%s'", callback.__name__, event_name)

    def unsubscribe(self, event_name: str, callback: AsyncCallback) -> None:
        """Remove a callback from the given event name."""
        try:
            self._subscribers[event_name].remove(callback)
        except ValueError:
            pass

    async def publish(self, event_name: str, payload: Dict[str, Any]) -> None:
        """
        Publish an event, invoking all registered callbacks concurrently.

        Errors in individual callbacks are logged and swallowed so that
        one failing subscriber does not block others.
        """
        callbacks = self._subscribers.get(event_name, [])
        if not callbacks:
            logger.debug("No subscribers for event '%s'", event_name)
            return

        logger.info(
            "Publishing event '%s' to %d subscriber(s)", event_name, len(callbacks)
        )
        results = await asyncio.gather(
            *(cb(payload) for cb in callbacks),
            return_exceptions=True,
        )
        for i, result in enumerate(results):
            if isinstance(result, Exception):
                logger.error(
                    "Subscriber %s raised %s for event '%s': %s",
                    callbacks[i].__name__,
                    type(result).__name__,
                    event_name,
                    result,
                )


# Module-level singleton
event_bus = EventBus()
