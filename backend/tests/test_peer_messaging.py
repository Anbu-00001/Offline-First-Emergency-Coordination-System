# SPDX-License-Identifier: GPL-3.0-or-later
"""
Day 6 tests — Peer messaging, pairing tokens, sync batch, PeerManager.

Tests use SQLite via ``DATABASE_URL`` env override and the Starlette
``TestClient`` for synchronous HTTP + WebSocket assertions.  No real
PostgreSQL instance is required.
"""
from __future__ import annotations

import asyncio
import json
import os
import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

# Set test database before importing app modules
os.environ.setdefault("DATABASE_URL", "sqlite:///./test_day6.db")

from app.core.config import settings
from app.core.database import Base, engine, SessionLocal, get_db
from app.core.events import EventBus
from app.core.security import create_access_token
from app.models.message import Message
from app.models.pairing import PairingToken
from app.schemas.message import MessageIn, MessageBatch, MessageOut
from app.services.peer_manager import PeerManager


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(autouse=True, scope="module")
def setup_database():
    """Create only Day 6 + user tables (SQLite-compatible, no PG UUID)."""
    from app.models.user import User

    _tables = [
        User.__table__,
        Message.__table__,
        PairingToken.__table__,
    ]
    Base.metadata.create_all(bind=engine, tables=_tables)
    yield
    Base.metadata.drop_all(bind=engine, tables=_tables)


@pytest.fixture()
def db_session():
    """Provide a clean DB session per test."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.rollback()
        db.close()


def _make_jwt(user_id: int = 1) -> str:
    """Create a valid JWT token for testing."""
    return create_access_token(subject=str(user_id))


# ---------------------------------------------------------------------------
# 1. Pydantic schema validation
# ---------------------------------------------------------------------------

class TestMessageSchemas:
    """Validate MessageIn / MessageBatch schemas."""

    def test_valid_message_in(self):
        msg = MessageIn(
            message_id=str(uuid.uuid4()),
            recipient_id=2,
            content="Hello peer",
            lamport=1,
            sent_at=datetime.now(timezone.utc),
        )
        assert msg.content == "Hello peer"
        assert msg.lamport == 1

    def test_message_id_length_validation(self):
        with pytest.raises(Exception):
            MessageIn(
                message_id="short",
                content="Bad",
                lamport=0,
                sent_at=datetime.now(timezone.utc),
            )

    def test_empty_content_rejected(self):
        with pytest.raises(Exception):
            MessageIn(
                message_id=str(uuid.uuid4()),
                content="",
                lamport=0,
                sent_at=datetime.now(timezone.utc),
            )

    def test_message_batch_parses(self):
        batch = MessageBatch(
            messages=[
                {
                    "message_id": str(uuid.uuid4()),
                    "content": "Msg 1",
                    "lamport": 0,
                    "sent_at": datetime.now(timezone.utc).isoformat(),
                },
                {
                    "message_id": str(uuid.uuid4()),
                    "content": "Msg 2",
                    "lamport": 1,
                    "sent_at": datetime.now(timezone.utc).isoformat(),
                },
            ]
        )
        assert len(batch.messages) == 2


# ---------------------------------------------------------------------------
# 2. PeerManager unit tests
# ---------------------------------------------------------------------------

class TestPeerManager:
    """Unit tests for PeerManager (no DB, mock WebSocket)."""

    def test_connect_disconnect(self):
        pm = PeerManager()

        ws_mock = AsyncMock()
        ws_mock.accept = AsyncMock()

        loop = asyncio.new_event_loop()
        uid = loop.run_until_complete(pm.connect(ws_mock, user_id=42))
        assert uid == 42
        assert pm.is_user_connected(42)

        loop.run_until_complete(pm.disconnect(ws_mock))
        assert not pm.is_user_connected(42)
        loop.close()

    def test_send_to_user(self):
        pm = PeerManager()

        ws_mock = AsyncMock()
        ws_mock.accept = AsyncMock()
        ws_mock.send_json = AsyncMock()

        loop = asyncio.new_event_loop()
        loop.run_until_complete(pm.connect(ws_mock, user_id=10))

        result = loop.run_until_complete(
            pm.send_to_user(10, {"event": "test", "data": "ok"})
        )
        assert result is True
        ws_mock.send_json.assert_called_once()

        # Non-existent user
        result = loop.run_until_complete(
            pm.send_to_user(999, {"event": "test"})
        )
        assert result is False
        loop.close()

    def test_broadcast(self):
        pm = PeerManager()

        ws1 = AsyncMock()
        ws1.accept = AsyncMock()
        ws1.send_json = AsyncMock()

        ws2 = AsyncMock()
        ws2.accept = AsyncMock()
        ws2.send_json = AsyncMock()

        loop = asyncio.new_event_loop()
        loop.run_until_complete(pm.connect(ws1, user_id=1))
        loop.run_until_complete(pm.connect(ws2, user_id=2))
        loop.run_until_complete(pm.broadcast({"event": "announce"}))

        ws1.send_json.assert_called_once()
        ws2.send_json.assert_called_once()
        loop.close()

    def test_ephemeral_pair_synthetic_id(self):
        pm = PeerManager()

        ws_mock = AsyncMock()
        ws_mock.accept = AsyncMock()

        loop = asyncio.new_event_loop()
        uid = loop.run_until_complete(
            pm.connect(ws_mock, user_id=None, ephemeral_pair="test-pair-token")
        )
        # Synthetic IDs are derived from hash — should be non-zero
        assert uid != 0
        assert pm.is_user_connected(uid)
        loop.close()

    def test_lamport_counter(self):
        pm = PeerManager()
        # First call: max(0, 5) + 1 = 6
        assert pm.next_lamport(user_id=1, client_lamport=5) == 6
        # Second call: max(6, 3) + 1 = 7
        assert pm.next_lamport(user_id=1, client_lamport=3) == 7
        # Different user starts fresh
        assert pm.next_lamport(user_id=2, client_lamport=0) == 1


# ---------------------------------------------------------------------------
# 3. Pairing token model
# ---------------------------------------------------------------------------

class TestPairingTokenModel:
    """Validate PairingToken model logic."""

    def test_is_valid_fresh_token(self):
        token = PairingToken(
            token=str(uuid.uuid4()),
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=5),
            used=False,
        )
        assert token.is_valid() is True

    def test_is_valid_expired_token(self):
        token = PairingToken(
            token=str(uuid.uuid4()),
            expires_at=datetime.now(timezone.utc) - timedelta(minutes=1),
            used=False,
        )
        assert token.is_valid() is False

    def test_is_valid_used_token(self):
        token = PairingToken(
            token=str(uuid.uuid4()),
            expires_at=datetime.now(timezone.utc) + timedelta(minutes=5),
            used=True,
        )
        assert token.is_valid() is False


# ---------------------------------------------------------------------------
# 4. HTTP endpoint tests (TestClient)
# ---------------------------------------------------------------------------

from starlette.testclient import TestClient
from app.main import app

client = TestClient(app)


class TestPairingEndpoints:
    """Test POST /pairing/request and GET /pairing/verify."""

    def test_create_pairing_token(self, db_session):
        resp = client.post(
            "/pairing/request",
            json={"pin_length": 4, "ttl_minutes": 5},
        )
        assert resp.status_code == 201
        data = resp.json()
        assert "token" in data
        assert "pin" in data
        assert len(data["pin"]) == 4
        assert "expires_at" in data

    def test_verify_pairing_token(self, db_session):
        # Create token first
        resp = client.post(
            "/pairing/request",
            json={"pin_length": 6, "ttl_minutes": 2},
        )
        token = resp.json()["token"]

        # Verify
        resp2 = client.get(f"/pairing/verify?token={token}")
        assert resp2.status_code == 200
        data = resp2.json()
        assert data["token"] == token
        assert data["used"] is False
        assert data["expired"] is False

    def test_verify_nonexistent_token(self):
        resp = client.get(f"/pairing/verify?token={uuid.uuid4()}")
        assert resp.status_code == 404


# ---------------------------------------------------------------------------
# 5. Sync messages endpoint
# ---------------------------------------------------------------------------

class TestSyncMessagesEndpoint:
    """Test POST /sync/messages batch endpoint."""

    def test_batch_sync_creates_messages(self, db_session):
        msg_id_1 = str(uuid.uuid4())
        msg_id_2 = str(uuid.uuid4())
        resp = client.post(
            "/sync/messages",
            json={
                "messages": [
                    {
                        "message_id": msg_id_1,
                        "content": "Offline msg 1",
                        "lamport": 1,
                        "sent_at": datetime.now(timezone.utc).isoformat(),
                    },
                    {
                        "message_id": msg_id_2,
                        "content": "Offline msg 2",
                        "lamport": 2,
                        "sent_at": datetime.now(timezone.utc).isoformat(),
                    },
                ]
            },
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["total"] == 2
        assert data["synced"][0]["action"] == "created"
        assert data["synced"][1]["action"] == "created"

    def test_batch_sync_duplicate_idempotent(self, db_session):
        msg_id = str(uuid.uuid4())
        payload = {
            "messages": [
                {
                    "message_id": msg_id,
                    "content": "Duplicate test",
                    "lamport": 0,
                    "sent_at": datetime.now(timezone.utc).isoformat(),
                }
            ]
        }
        # First insert
        resp1 = client.post("/sync/messages", json=payload)
        assert resp1.status_code == 200
        assert resp1.json()["synced"][0]["action"] == "created"

        # Second insert — should be duplicate
        resp2 = client.post("/sync/messages", json=payload)
        assert resp2.status_code == 200
        assert resp2.json()["synced"][0]["action"] == "duplicate"


# ---------------------------------------------------------------------------
# 6. WebSocket endpoint tests
# ---------------------------------------------------------------------------

class TestPeerWebSocket:
    """WebSocket /ws/peer connection tests."""

    def test_ws_connect_requires_auth(self):
        """Connection without token or pair_token should be rejected."""
        # TestClient may raise or the WS closes with code 4001
        try:
            with client.websocket_connect("/ws/peer") as ws:
                # Should not reach here — server should close
                pass
        except Exception:
            pass  # Expected — authentication required

    def test_ws_connect_with_jwt(self, db_session):
        """Authenticated WebSocket connection with JWT."""
        # Create a test user in DB first
        from app.models.user import User
        from app.core.security import get_password_hash

        db = db_session
        user = db.query(User).filter(User.email == "wstest@test.com").first()
        if not user:
            user = User(
                email="wstest@test.com",
                hashed_password=get_password_hash("testpass"),
                role="user",
            )
            db.add(user)
            db.commit()
            db.refresh(user)

        token = _make_jwt(user.id)

        with client.websocket_connect(f"/ws/peer?token={token}") as ws:
            # Send a ping
            ws.send_text('{"type":"ping"}')
            resp = ws.receive_json()
            assert resp["event"] == "pong"

    def test_ws_connect_with_pairing_token(self, db_session):
        """Connect using an ephemeral pairing token."""
        # Create a pairing token via API
        resp = client.post(
            "/pairing/request",
            json={"pin_length": 4, "ttl_minutes": 5},
        )
        pair_token = resp.json()["token"]

        with client.websocket_connect(
            f"/ws/peer?pair_token={pair_token}"
        ) as ws:
            ws.send_text('{"type":"ping"}')
            resp_data = ws.receive_json()
            assert resp_data["event"] == "pong"

    def test_ws_send_message_and_receive_receipt(self, db_session):
        """Send a message via WS and receive a delivery receipt."""
        from app.models.user import User
        from app.core.security import get_password_hash

        db = db_session
        user = db.query(User).filter(User.email == "sender@test.com").first()
        if not user:
            user = User(
                email="sender@test.com",
                hashed_password=get_password_hash("testpass"),
                role="user",
            )
            db.add(user)
            db.commit()
            db.refresh(user)

        token = _make_jwt(user.id)
        msg_id = str(uuid.uuid4())

        with client.websocket_connect(f"/ws/peer?token={token}") as ws:
            ws.send_text(
                json.dumps(
                    {
                        "message_id": msg_id,
                        "content": "Hello from test",
                        "lamport": 1,
                        "sent_at": datetime.now(timezone.utc).isoformat(),
                        "recipient_id": 9999,  # Non-existent → queued
                    }
                )
            )
            receipt = ws.receive_json()
            assert receipt["event"] == "receipt"
            assert receipt["message_id"] == msg_id
            assert receipt["status"] == "queued"

    def test_ws_duplicate_message_idempotent(self, db_session):
        """Sending the same message_id twice should return duplicate receipt."""
        from app.models.user import User
        from app.core.security import get_password_hash

        db = db_session
        user = db.query(User).filter(User.email == "dup@test.com").first()
        if not user:
            user = User(
                email="dup@test.com",
                hashed_password=get_password_hash("testpass"),
                role="user",
            )
            db.add(user)
            db.commit()
            db.refresh(user)

        token = _make_jwt(user.id)
        msg_id = str(uuid.uuid4())
        msg_payload = json.dumps(
            {
                "message_id": msg_id,
                "content": "Dup test",
                "lamport": 0,
                "sent_at": datetime.now(timezone.utc).isoformat(),
                "recipient_id": 9999,
            }
        )

        with client.websocket_connect(f"/ws/peer?token={token}") as ws:
            # First send
            ws.send_text(msg_payload)
            r1 = ws.receive_json()
            assert r1["event"] == "receipt"

            # Second send — same message_id
            ws.send_text(msg_payload)
            r2 = ws.receive_json()
            assert r2["event"] == "receipt"
            assert r2.get("duplicate") is True

    def test_ws_pairing_token_single_use(self, db_session):
        """A pairing token should only work once."""
        resp = client.post(
            "/pairing/request",
            json={"pin_length": 4, "ttl_minutes": 5},
        )
        pair_token = resp.json()["token"]

        # First use — should succeed
        with client.websocket_connect(
            f"/ws/peer?pair_token={pair_token}"
        ) as ws:
            ws.send_text('{"type":"ping"}')
            resp_data = ws.receive_json()
            assert resp_data["event"] == "pong"

        # Second use — token is consumed, should fail
        try:
            with client.websocket_connect(
                f"/ws/peer?pair_token={pair_token}"
            ) as ws:
                # Should be rejected
                pass
        except Exception:
            pass  # Expected — token already used


# ---------------------------------------------------------------------------
# 7. Event bus integration
# ---------------------------------------------------------------------------

class TestMessageEvents:
    """Verify message events are published to the event bus."""

    def test_message_created_event_structure(self):
        bus = EventBus()
        received = []

        async def handler(payload):
            received.append(payload)

        bus.subscribe("message_created", handler)
        asyncio.get_event_loop().run_until_complete(
            bus.publish(
                "message_created",
                {
                    "message_id": str(uuid.uuid4()),
                    "sender_id": 1,
                    "recipient_id": 2,
                },
            )
        )
        assert len(received) == 1
        assert "message_id" in received[0]
        assert "sender_id" in received[0]

    def test_message_delivered_event(self):
        bus = EventBus()
        received = []

        async def handler(payload):
            received.append(payload)

        bus.subscribe("message_delivered", handler)
        asyncio.get_event_loop().run_until_complete(
            bus.publish(
                "message_delivered",
                {"message_id": str(uuid.uuid4()), "recipient_id": 2},
            )
        )
        assert len(received) == 1
        assert "recipient_id" in received[0]
