# SPDX-License-Identifier: GPL-3.0-or-later
"""
Client connector for WebSocket peer messaging (Day 7).

Provides an async client that connects to a discovered OpenRescue server
and exchanges text messages over the ``/ws/peer`` WebSocket endpoint.

Used by both the demo script and the optional ``CLIENT_MODE`` startup.
"""
from __future__ import annotations

import asyncio
import json
import logging
import uuid
from datetime import datetime, timezone
from typing import Any, Callable, Coroutine, Dict, List, Optional

logger = logging.getLogger(__name__)

# Type alias for message callback
MessageCallback = Callable[[Dict[str, Any]], Coroutine[Any, Any, None]]


class ClientConnector:
    """Maintain a WebSocket session with an OpenRescue server.

    Parameters
    ----------
    server_ip:
        IP address of the target server.
    server_port:
        Port of the target server.
    auth_token:
        Optional JWT for authenticated sessions.
    """

    def __init__(
        self,
        server_ip: str,
        server_port: int,
        auth_token: Optional[str] = None,
    ) -> None:
        self._ip = server_ip
        self._port = server_port
        self._token = auth_token
        self._ws: Any = None
        self._running = False
        self._receive_task: Optional[asyncio.Task] = None
        self._callbacks: List[MessageCallback] = []
        self._lamport: int = 0
        self._reconnect_backoff = 1.0
        self._max_backoff = 30.0

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    async def connect_to_server(self) -> bool:
        """Open a WebSocket connection to the server.

        Returns ``True`` on success, ``False`` on failure.
        """
        query = f"?token={self._token}" if self._token else ""
        ws_url = f"ws://{self._ip}:{self._port}/ws/peer{query}"

        try:
            import websockets
            self._ws = await websockets.connect(ws_url)
            self._running = True
            self._reconnect_backoff = 1.0  # reset on success
            logger.info(
                "ClientConnector: connected to %s:%d", self._ip, self._port,
            )
            # Start the receive loop as a background task
            self._receive_task = asyncio.create_task(self._receive_loop())
            return True
        except Exception as exc:
            logger.error(
                "ClientConnector: connection failed to %s:%d — %s",
                self._ip, self._port, exc,
            )
            return False

    async def disconnect(self) -> None:
        """Gracefully close the WebSocket connection."""
        self._running = False
        if self._receive_task and not self._receive_task.done():
            self._receive_task.cancel()
            try:
                await self._receive_task
            except asyncio.CancelledError:
                pass
            self._receive_task = None

        if self._ws:
            try:
                await self._ws.close()
            except Exception:
                pass
            self._ws = None
        logger.info("ClientConnector: disconnected")

    # ------------------------------------------------------------------
    # Messaging
    # ------------------------------------------------------------------

    async def send_text_message(
        self,
        content: str,
        recipient_id: Optional[int] = None,
    ) -> Optional[str]:
        """Send a text message through the WebSocket.

        Returns the generated ``message_id`` on success, or ``None``.
        """
        if not self._ws or not self._running:
            logger.warning("ClientConnector: cannot send — not connected")
            return None

        self._lamport += 1
        message_id = str(uuid.uuid4())
        payload = {
            "message_id": message_id,
            "content": content,
            "lamport": self._lamport,
            "sent_at": datetime.now(timezone.utc).isoformat(),
        }
        if recipient_id is not None:
            payload["recipient_id"] = recipient_id

        try:
            await self._ws.send(json.dumps(payload))
            logger.info(
                "ClientConnector: sent message %s (lamport=%d)",
                message_id, self._lamport,
            )
            return message_id
        except Exception as exc:
            logger.error("ClientConnector: send failed — %s", exc)
            return None

    def on_message(self, callback: MessageCallback) -> None:
        """Register an async callback for incoming messages."""
        self._callbacks.append(callback)

    # ------------------------------------------------------------------
    # Receive loop
    # ------------------------------------------------------------------

    async def _receive_loop(self) -> None:
        """Continuously read messages from the WebSocket."""
        try:
            while self._running and self._ws:
                raw = await self._ws.recv()
                try:
                    data = json.loads(raw)
                except json.JSONDecodeError:
                    logger.warning("ClientConnector: invalid JSON received")
                    continue

                logger.info(
                    "ClientConnector: received event=%s",
                    data.get("event", "unknown"),
                )

                # Fire registered callbacks
                for cb in self._callbacks:
                    try:
                        await cb(data)
                    except Exception:
                        logger.exception("ClientConnector: callback error")

        except asyncio.CancelledError:
            return
        except Exception as exc:
            if self._running:
                logger.warning(
                    "ClientConnector: receive loop error — %s", exc,
                )
                # Trigger reconnect
                asyncio.create_task(self.reconnect_if_needed())

    # ------------------------------------------------------------------
    # Reconnection
    # ------------------------------------------------------------------

    async def reconnect_if_needed(self) -> bool:
        """Attempt to reconnect with exponential backoff.

        Returns ``True`` if reconnection succeeded.
        """
        if not self._running:
            return False

        logger.info(
            "ClientConnector: reconnecting in %.1fs…",
            self._reconnect_backoff,
        )
        await asyncio.sleep(self._reconnect_backoff)
        self._reconnect_backoff = min(
            self._reconnect_backoff * 2, self._max_backoff,
        )

        # Clean up old connection
        if self._ws:
            try:
                await self._ws.close()
            except Exception:
                pass
            self._ws = None

        return await self.connect_to_server()

    # ------------------------------------------------------------------
    # Properties
    # ------------------------------------------------------------------

    @property
    def is_connected(self) -> bool:
        """Whether the WebSocket is currently open."""
        return self._ws is not None and self._running
