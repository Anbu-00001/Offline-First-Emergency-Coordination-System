# SPDX-License-Identifier: GPL-3.0-or-later
"""
WebSocket endpoint for real-time incident alerts.

Connects at ``/ws/alerts`` and broadcasts JSON messages:
    { "event": "<name>", "data": { ... } }

Supported events:
    - incident_created
    - incident_assigned
    - incident_updated
"""
from __future__ import annotations

import json
import logging
from typing import Dict, Optional

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt

from app.core.config import settings
from app.core.events import event_bus

logger = logging.getLogger(__name__)

router = APIRouter()


# ---------------------------------------------------------------------------
# Connection Manager
# ---------------------------------------------------------------------------

class ConnectionManager:
    """
    Manages active WebSocket connections.

    Provides helpers for personal messaging and fan-out broadcast.
    """

    def __init__(self) -> None:
        # ws -> {"user_id": ..., "role": ...}
        self._connections: Dict[WebSocket, Dict[str, Optional[str]]] = {}

    async def connect(
        self,
        websocket: WebSocket,
        user_id: Optional[str] = None,
        role: Optional[str] = None,
    ) -> None:
        await websocket.accept()
        self._connections[websocket] = {"user_id": user_id, "role": role}
        logger.info(
            "WS connected: user=%s role=%s  (total=%d)",
            user_id, role, len(self._connections),
        )

    def disconnect(self, websocket: WebSocket) -> None:
        self._connections.pop(websocket, None)
        logger.info("WS disconnected  (total=%d)", len(self._connections))

    async def send_personal_message(self, websocket: WebSocket, event: str, data: dict) -> None:
        """Send a JSON message to a single connection."""
        try:
            await websocket.send_json({"event": event, "data": data})
        except Exception:
            logger.exception("Failed to send personal message")

    async def broadcast(self, event: str, data: dict) -> None:
        """Fan-out a JSON message to every connected client."""
        message = {"event": event, "data": data}
        stale: list[WebSocket] = []
        for ws in self._connections:
            try:
                await ws.send_json(message)
            except Exception:
                stale.append(ws)
        for ws in stale:
            self.disconnect(ws)


# Module-level singleton
manager = ConnectionManager()


# ---------------------------------------------------------------------------
# Event-bus → WebSocket bridge (registered at app startup)
# ---------------------------------------------------------------------------

async def _ws_bridge(payload: dict) -> None:
    """Generic callback that forwards any event-bus payload to all WS clients."""
    event_name = payload.get("_event_name", "unknown")
    await manager.broadcast(event_name, payload)


def register_ws_events() -> None:
    """Subscribe the WS bridge to all incident events."""
    for evt in ("incident_created", "incident_assigned", "incident_updated"):
        async def _handler(payload: dict, _evt: str = evt) -> None:
            await manager.broadcast(_evt, payload)
        event_bus.subscribe(evt, _handler)
    logger.info("WebSocket bridge registered for incident events")


# ---------------------------------------------------------------------------
# WebSocket route
# ---------------------------------------------------------------------------

def _validate_ws_token(token: Optional[str]) -> tuple[Optional[str], Optional[str]]:
    """
    Extract user_id and role from a JWT token.

    Returns ``(None, None)`` for anonymous / invalid tokens (read-only access).
    """
    if not token:
        return None, None
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        role = payload.get("role", "user")
        return str(user_id) if user_id else None, role
    except JWTError:
        return None, None


@router.websocket("/alerts")
async def ws_alerts(
    websocket: WebSocket,
    token: Optional[str] = Query(None, description="JWT for authenticated access"),
) -> None:
    """
    WebSocket endpoint for real-time incident alerts.

    Connect with an optional ``?token=<JWT>`` query parameter.
    Authenticated responders / admins receive full payloads;
    anonymous connections receive read-only broadcasts.
    """
    user_id, role = _validate_ws_token(token)
    await manager.connect(websocket, user_id=user_id, role=role)

    try:
        while True:
            # Keep connection alive — accept pings / text from clients
            data = await websocket.receive_text()
            # Echo back for now (can handle commands in the future)
            try:
                msg = json.loads(data)
                logger.debug("WS received from user=%s: %s", user_id, msg)
            except json.JSONDecodeError:
                pass
    except WebSocketDisconnect:
        manager.disconnect(websocket)
    except Exception:
        manager.disconnect(websocket)
        logger.exception("WS error for user=%s", user_id)
