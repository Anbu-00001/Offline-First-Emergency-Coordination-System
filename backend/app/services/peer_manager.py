# SPDX-License-Identifier: GPL-3.0-or-later
"""
Peer connection manager for WebSocket message relay (Day 6).

Manages the mapping of ``user_id → set[WebSocket]`` and provides
helpers for targeted delivery, broadcast, and queued-message flush.
Publishes ``message_created`` / ``message_delivered`` events to the
in-process event bus.
"""
from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone
from typing import Any, Dict, Optional, Set

from fastapi import WebSocket
from sqlalchemy.orm import Session

from app.core.events import event_bus
from app.models.message import Message

logger = logging.getLogger(__name__)


class PeerManager:
    """
    Async-safe WebSocket connection manager with delivery awareness.

    Each authenticated user may have multiple simultaneous connections
    (e.g. phone + laptop).  Ephemeral (paired) sessions are tracked by
    a synthetic negative ID derived from the pairing token so they never
    collide with real user IDs.
    """

    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        # user_id → set of active WebSocket connections
        self._connections: Dict[int, Set[WebSocket]] = {}
        # ws → user_id reverse lookup for fast disconnect
        self._ws_user: Dict[WebSocket, int] = {}
        # Per-sender Lamport counter (in-memory, resets on restart)
        self._lamport_counters: Dict[int, int] = {}

    # ------------------------------------------------------------------
    # Connection lifecycle
    # ------------------------------------------------------------------

    async def connect(
        self,
        websocket: WebSocket,
        user_id: Optional[int] = None,
        ephemeral_pair: Optional[str] = None,
    ) -> int:
        """
        Accept and register a WebSocket connection.

        Args:
            websocket: The FastAPI WebSocket instance.
            user_id: Authenticated user ID (from JWT).
            ephemeral_pair: Pairing token string (used to derive a
                synthetic user ID when no JWT is provided).

        Returns:
            The effective user ID for this connection.
        """
        await websocket.accept()

        # Derive a synthetic ID for paired sessions
        if user_id is None and ephemeral_pair:
            user_id = -abs(hash(ephemeral_pair)) % (10**9)

        if user_id is None:
            user_id = 0  # Anonymous fallback

        async with self._lock:
            self._connections.setdefault(user_id, set()).add(websocket)
            self._ws_user[websocket] = user_id

        logger.info(
            "[peer_manager] WS connected: user_id=%s  ephemeral=%s  total_connections=%d",
            user_id,
            bool(ephemeral_pair),
            sum(len(s) for s in self._connections.values()),
        )
        return user_id

    async def disconnect(self, websocket: WebSocket) -> None:
        """Remove a WebSocket from the connection pool."""
        async with self._lock:
            uid = self._ws_user.pop(websocket, None)
            if uid is not None and uid in self._connections:
                self._connections[uid].discard(websocket)
                if not self._connections[uid]:
                    del self._connections[uid]
        logger.info(
            "[peer_manager] WS disconnected: user_id=%s  remaining=%d",
            uid,
            sum(len(s) for s in self._connections.values()),
        )

    # ------------------------------------------------------------------
    # Delivery helpers
    # ------------------------------------------------------------------

    async def send_to_user(self, user_id: int, payload: Dict[str, Any]) -> bool:
        """
        Send a JSON payload to all connections of a specific user.

        Returns True if at least one connection received the message.
        """
        async with self._lock:
            sockets = list(self._connections.get(user_id, []))

        if not sockets:
            return False

        stale: list[WebSocket] = []
        delivered = False
        for ws in sockets:
            try:
                await ws.send_json(payload)
                delivered = True
            except Exception:
                stale.append(ws)

        # Clean up broken connections
        for ws in stale:
            await self.disconnect(ws)

        return delivered

    async def broadcast(self, payload: Dict[str, Any]) -> None:
        """Fan-out a JSON message to every connected peer."""
        async with self._lock:
            all_sockets = [
                ws for socks in self._connections.values() for ws in socks
            ]

        stale: list[WebSocket] = []
        for ws in all_sockets:
            try:
                await ws.send_json(payload)
            except Exception:
                stale.append(ws)

        for ws in stale:
            await self.disconnect(ws)

    def is_user_connected(self, user_id: int) -> bool:
        """Check whether a user currently has active connections."""
        return bool(self._connections.get(user_id))

    # ------------------------------------------------------------------
    # Lamport counter
    # ------------------------------------------------------------------

    def next_lamport(self, user_id: int, client_lamport: int) -> int:
        """
        Return the next Lamport value, merging the client's counter
        with the server's tracked value for this sender.
        """
        current = self._lamport_counters.get(user_id, 0)
        new_val = max(current, client_lamport) + 1
        self._lamport_counters[user_id] = new_val
        return new_val

    # ------------------------------------------------------------------
    # Queued-message delivery (called on new connection)
    # ------------------------------------------------------------------

    async def deliver_queued_messages(
        self, user_id: int, db: Session
    ) -> int:
        """
        Deliver all undelivered messages for *user_id* and mark them
        as delivered in the database.

        Returns the number of messages delivered.
        """
        messages = (
            db.query(Message)
            .filter(
                Message.recipient_id == user_id,
                Message.delivered == False,  # noqa: E712
            )
            .order_by(Message.lamport.asc(), Message.created_at.asc())
            .all()
        )

        if not messages:
            return 0

        count = 0
        now = datetime.now(timezone.utc)
        for msg in messages:
            payload = {
                "event": "message",
                "message_id": msg.message_id,
                "sender_id": msg.sender_id,
                "content": msg.content,
                "lamport": msg.lamport,
                "sent_at": msg.sent_at.isoformat() if msg.sent_at else None,
            }
            sent = await self.send_to_user(user_id, payload)
            if sent:
                msg.delivered = True
                msg.delivered_at = now
                count += 1

                # Publish delivery event
                await event_bus.publish(
                    "message_delivered",
                    {"message_id": msg.message_id, "recipient_id": user_id},
                )

        db.commit()
        logger.info(
            "[peer_manager] Delivered %d queued messages to user_id=%s (pending=%d)",
            count, user_id, len(messages) - count,
        )
        return count


# Module-level singleton
peer_manager = PeerManager()
