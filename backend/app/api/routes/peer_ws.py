# SPDX-License-Identifier: GPL-3.0-or-later
"""
WebSocket endpoint for peer-to-peer messaging (Day 6).

Connects at ``/ws/peer`` and relays JSON messages between authenticated
users or ephemeral paired sessions.  Supports JWT (``?token=``) and
pairing-token (``?pair_token=``) authentication.
"""
from __future__ import annotations

import json
import logging
from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt
from pydantic import ValidationError
from sqlalchemy.exc import IntegrityError

from app.core.config import settings
from app.core.database import SessionLocal
from app.core.events import event_bus
from app.models.message import Message
from app.models.pairing import PairingToken
from app.schemas.message import MessageIn
from app.services.peer_manager import peer_manager

logger = logging.getLogger(__name__)

router = APIRouter()


# ---------------------------------------------------------------------------
# Auth helpers
# ---------------------------------------------------------------------------

def _validate_jwt(token: Optional[str]) -> Optional[int]:
    """
    Extract ``user_id`` (int) from a JWT token.

    Returns ``None`` if the token is absent or invalid.
    """
    if not token:
        return None
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        sub = payload.get("sub")
        return int(sub) if sub is not None else None
    except (JWTError, ValueError, TypeError):
        return None


def _validate_pair_token(pair_token: Optional[str]) -> Optional[str]:
    """
    Validate a pairing token against the database.

    If valid, marks the token as **used** and returns the token string.
    Returns ``None`` if the token is missing, already used, or expired.
    """
    if not pair_token:
        return None

    db = SessionLocal()
    try:
        record = (
            db.query(PairingToken)
            .filter(PairingToken.token == pair_token)
            .first()
        )
        if record is None:
            logger.warning("Pairing token not found: %s", pair_token)
            return None

        if record.used:
            logger.warning("Pairing token already used: %s", pair_token)
            return None

        if record.expires_at.tzinfo is None:
            expires = record.expires_at.replace(tzinfo=timezone.utc)
        else:
            expires = record.expires_at

        if datetime.now(timezone.utc) >= expires:
            logger.warning("Pairing token expired: %s", pair_token)
            return None

        # Mark as used
        record.used = True
        db.commit()
        logger.info("Pairing token consumed: %s", pair_token)
        return pair_token
    except Exception:
        db.rollback()
        logger.exception("Error validating pairing token")
        return None
    finally:
        db.close()


# ---------------------------------------------------------------------------
# WebSocket route
# ---------------------------------------------------------------------------

@router.websocket("/peer")
async def ws_peer(
    websocket: WebSocket,
    token: Optional[str] = Query(None, description="JWT for authenticated access"),
    pair_token: Optional[str] = Query(None, description="Ephemeral pairing token"),
) -> None:
    """
    WebSocket endpoint for peer-to-peer message relay.

    Authentication:
        - ``?token=<JWT>`` — standard authenticated session.
        - ``?pair_token=<UUID>`` — one-time ephemeral pairing session.
        - If neither is provided the connection is rejected.
    """
    # --- Authenticate -------------------------------------------------------
    user_id = _validate_jwt(token)
    ephemeral = None

    if user_id is None:
        ephemeral = _validate_pair_token(pair_token)
        if ephemeral is None:
            await websocket.close(code=4001, reason="Authentication required")
            return

    # --- Register with PeerManager ------------------------------------------
    effective_uid = await peer_manager.connect(
        websocket, user_id=user_id, ephemeral_pair=ephemeral
    )

    # --- Deliver any queued messages ----------------------------------------
    db = SessionLocal()
    try:
        await peer_manager.deliver_queued_messages(effective_uid, db)
    except Exception:
        logger.exception("Error delivering queued messages on connect")
    finally:
        db.close()

    # --- Message loop -------------------------------------------------------
    try:
        while True:
            raw = await websocket.receive_text()

            # Handle simple ping
            if raw.strip().lower() in ('{"type":"ping"}', "ping"):
                await websocket.send_json({"event": "pong"})
                continue

            # Parse and validate incoming message
            try:
                data = json.loads(raw)
                msg_in = MessageIn(**data)
            except (json.JSONDecodeError, ValidationError) as exc:
                await websocket.send_json(
                    {"event": "error", "detail": f"Invalid message: {exc}"}
                )
                continue

            # --- Persist message -------------------------------------------
            db = SessionLocal()
            try:
                # Compute Lamport counter
                lamport = peer_manager.next_lamport(effective_uid, msg_in.lamport)

                new_msg = Message(
                    message_id=msg_in.message_id,
                    sender_id=user_id,  # None for paired sessions
                    recipient_id=msg_in.recipient_id,
                    content=msg_in.content,
                    lamport=lamport,
                    sent_at=msg_in.sent_at,
                    metadata_=msg_in.metadata,
                    direction="inbound",
                )

                db.add(new_msg)
                try:
                    db.commit()
                    db.refresh(new_msg)
                except IntegrityError:
                    # Duplicate message_id — idempotent handling
                    db.rollback()
                    existing = (
                        db.query(Message)
                        .filter(Message.message_id == msg_in.message_id)
                        .first()
                    )
                    status = "delivered" if (existing and existing.delivered) else "queued"
                    await websocket.send_json(
                        {
                            "event": "receipt",
                            "message_id": msg_in.message_id,
                            "status": status,
                            "duplicate": True,
                        }
                    )
                    logger.debug(
                        "Duplicate message_id=%s (idempotent)", msg_in.message_id
                    )
                    continue

                # Publish event
                await event_bus.publish(
                    "message_created",
                    {
                        "message_id": new_msg.message_id,
                        "sender_id": new_msg.sender_id,
                        "recipient_id": new_msg.recipient_id,
                    },
                )

                # --- Attempt immediate delivery ---------------------------
                delivery_status = "queued"
                if msg_in.recipient_id is not None:
                    payload = {
                        "event": "message",
                        "message_id": new_msg.message_id,
                        "sender_id": new_msg.sender_id,
                        "content": new_msg.content,
                        "lamport": new_msg.lamport,
                        "sent_at": new_msg.sent_at.isoformat()
                        if new_msg.sent_at
                        else None,
                    }
                    sent = await peer_manager.send_to_user(
                        msg_in.recipient_id, payload
                    )
                    if sent:
                        new_msg.delivered = True
                        new_msg.delivered_at = datetime.now(timezone.utc)
                        db.commit()
                        delivery_status = "delivered"

                        await event_bus.publish(
                            "message_delivered",
                            {
                                "message_id": new_msg.message_id,
                                "recipient_id": msg_in.recipient_id,
                            },
                        )
                else:
                    # Broadcast (no specific recipient)
                    payload = {
                        "event": "message",
                        "message_id": new_msg.message_id,
                        "sender_id": new_msg.sender_id,
                        "content": new_msg.content,
                        "lamport": new_msg.lamport,
                        "sent_at": new_msg.sent_at.isoformat()
                        if new_msg.sent_at
                        else None,
                    }
                    await peer_manager.broadcast(payload)
                    delivery_status = "broadcast"

                # --- Send receipt to sender --------------------------------
                await websocket.send_json(
                    {
                        "event": "receipt",
                        "message_id": new_msg.message_id,
                        "status": delivery_status,
                    }
                )

            except Exception:
                db.rollback()
                logger.exception("Error processing message")
                await websocket.send_json(
                    {"event": "error", "detail": "Internal server error"}
                )
            finally:
                db.close()

    except WebSocketDisconnect:
        await peer_manager.disconnect(websocket)
    except Exception:
        await peer_manager.disconnect(websocket)
        logger.exception("Peer WS error for user_id=%s", effective_uid)
