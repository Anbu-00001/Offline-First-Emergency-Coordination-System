# SPDX-License-Identifier: GPL-3.0-or-later
"""
Day 7 – Week-1 integration tests.

Validates the full stack: health endpoint, WebSocket peer messaging,
two-client broadcast, discovery + health-check flow, and client connector.

Uses SQLite, mocked mDNS, and the Starlette TestClient — no real
multicast networking or PostgreSQL is required.
"""
from __future__ import annotations

import asyncio
import json
import os
import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

# Set test database before importing app modules
os.environ.setdefault("DATABASE_URL", "sqlite:///./test_week1.db")

from app.core.config import settings
from app.core.database import Base, engine, SessionLocal
from app.core.security import create_access_token
from app.models.message import Message
from app.models.pairing import PairingToken

from starlette.testclient import TestClient
from app.main import app

client = TestClient(app)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture(autouse=True, scope="module")
def setup_database():
    """Create required tables for Week 1 integration tests."""
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
    db = SessionLocal()
    try:
        yield db
    finally:
        db.rollback()
        db.close()


def _make_jwt(user_id: int = 1) -> str:
    return create_access_token(subject=str(user_id))


def _ensure_user(db, email: str = "week1test@test.com") -> int:
    """Ensure a test user exists and return their ID."""
    from app.models.user import User
    from app.core.security import get_password_hash

    user = db.query(User).filter(User.email == email).first()
    if not user:
        user = User(
            email=email,
            hashed_password=get_password_hash("testpass"),
            role="user",
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    return user.id


# ===================================================================
# 1. Health endpoint
# ===================================================================

class TestHealthEndpoint:
    """Verify the /health endpoint is reachable."""

    def test_health_returns_ok(self):
        resp = client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ok"
        assert "service" in data


# ===================================================================
# 2. WebSocket peer connection + message exchange
# ===================================================================

class TestWebSocketPeerMessaging:
    """End-to-end WebSocket messaging via /ws/peer."""

    def test_connect_and_send_message(self, db_session):
        """Connect with JWT, send a message, receive a receipt."""
        uid = _ensure_user(db_session, "ws_e2e@test.com")
        token = _make_jwt(uid)
        msg_id = str(uuid.uuid4())

        with client.websocket_connect(f"/ws/peer?token={token}") as ws:
            ws.send_text(
                json.dumps({
                    "message_id": msg_id,
                    "content": "Hello from Week 1 test",
                    "lamport": 1,
                    "sent_at": datetime.now(timezone.utc).isoformat(),
                })
            )
            # Broadcast → sender receives the message back + a receipt
            events = []
            for _ in range(2):
                events.append(ws.receive_json())

            event_types = {e["event"] for e in events}
            assert "receipt" in event_types
            receipt = next(e for e in events if e["event"] == "receipt")
            assert receipt["message_id"] == msg_id
            assert receipt["status"] == "broadcast"

    def test_ping_pong(self, db_session):
        """Verify ping/pong heartbeat works."""
        uid = _ensure_user(db_session, "ping@test.com")
        token = _make_jwt(uid)

        with client.websocket_connect(f"/ws/peer?token={token}") as ws:
            ws.send_text('{"type":"ping"}')
            resp = ws.receive_json()
            assert resp["event"] == "pong"

    def test_invalid_message_returns_error(self, db_session):
        """Sending invalid JSON should return an error event."""
        uid = _ensure_user(db_session, "invalid@test.com")
        token = _make_jwt(uid)

        with client.websocket_connect(f"/ws/peer?token={token}") as ws:
            ws.send_text('{"not_a_message": true}')
            resp = ws.receive_json()
            assert resp["event"] == "error"


# ===================================================================
# 3. Two-client broadcast
# ===================================================================

class TestTwoClientBroadcast:
    """Verify that a broadcast message reaches another connected client."""

    def test_broadcast_reaches_second_client(self, db_session):
        """Client A sends a broadcast, Client B receives it."""
        uid_a = _ensure_user(db_session, "client_a@test.com")
        uid_b = _ensure_user(db_session, "client_b@test.com")
        token_a = _make_jwt(uid_a)
        token_b = _make_jwt(uid_b)
        msg_id = str(uuid.uuid4())

        with client.websocket_connect(f"/ws/peer?token={token_b}") as ws_b:
            with client.websocket_connect(f"/ws/peer?token={token_a}") as ws_a:
                # A sends a broadcast (no recipient_id)
                ws_a.send_text(
                    json.dumps({
                        "message_id": msg_id,
                        "content": "Broadcast from A",
                        "lamport": 1,
                        "sent_at": datetime.now(timezone.utc).isoformat(),
                    })
                )
                # A gets both the broadcast echo and a receipt
                a_events = []
                for _ in range(2):
                    a_events.append(ws_a.receive_json())
                a_event_types = {e["event"] for e in a_events}
                assert "receipt" in a_event_types
                receipt = next(e for e in a_events if e["event"] == "receipt")
                assert receipt["status"] == "broadcast"

            # B should have received the broadcast message
            msg = ws_b.receive_json()
            assert msg["event"] == "message"
            assert msg["content"] == "Broadcast from A"
            assert msg["message_id"] == msg_id


# ===================================================================
# 4. Discovery + health check (mocked)
# ===================================================================

class TestDiscoverAndConnect:
    """Test discover_and_connect() with mocked mDNS and HTTP."""

    @patch("app.services.mdns_discovery.ServiceBrowser")
    @patch("app.services.mdns_discovery.Zeroconf")
    @patch("app.services.mdns_discovery._ZEROCONF_AVAILABLE", True)
    def test_discover_and_connect_success(self, MockZeroconf, MockBrowser):
        """discover_and_connect() returns server info when health check passes."""
        from app.services.mdns_discovery import MDNSDiscovery

        mock_zc = MagicMock()
        MockZeroconf.return_value = mock_zc

        # Set up mock service info
        mock_info = MagicMock()
        mock_info.name = "TestServer._openrescue._tcp.local."
        mock_info.port = 8000
        mock_info.parsed_addresses.return_value = ["192.168.1.50"]
        mock_info.properties = {
            b"node_type": b"server",
            b"version": b"0.1.0",
        }
        mock_zc.get_service_info.return_value = mock_info

        disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(disc.start())

            # Simulate service discovery
            loop.run_until_complete(
                disc._handle_service_added(
                    mock_zc, "_openrescue._tcp.local.", mock_info.name
                )
            )

            # Mock the httpx health check
            mock_response = MagicMock()
            mock_response.status_code = 200

            mock_httpx_client = AsyncMock()
            mock_httpx_client.get = AsyncMock(return_value=mock_response)
            mock_httpx_client.__aenter__ = AsyncMock(return_value=mock_httpx_client)
            mock_httpx_client.__aexit__ = AsyncMock(return_value=False)

            with patch("httpx.AsyncClient", return_value=mock_httpx_client):
                result = loop.run_until_complete(
                    disc.discover_and_connect(timeout=5.0, max_retries=1)
                )

            assert result is not None
            assert result["ip"] == "192.168.1.50"
            assert result["port"] == 8000
        finally:
            loop.run_until_complete(disc.stop())
            loop.close()

    @patch("app.services.mdns_discovery.ServiceBrowser")
    @patch("app.services.mdns_discovery.Zeroconf")
    @patch("app.services.mdns_discovery._ZEROCONF_AVAILABLE", True)
    def test_discover_and_connect_no_server(self, MockZeroconf, MockBrowser):
        """discover_and_connect() returns None when no server is found."""
        from app.services.mdns_discovery import MDNSDiscovery

        mock_zc = MagicMock()
        MockZeroconf.return_value = mock_zc

        disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(disc.start())

            result = loop.run_until_complete(
                disc.discover_and_connect(timeout=1.0, max_retries=1)
            )
            assert result is None
        finally:
            loop.run_until_complete(disc.stop())
            loop.close()


# ===================================================================
# 5. Client connector unit tests (mocked WebSocket)
# ===================================================================

class TestClientConnector:
    """Unit tests for ClientConnector (no real network)."""

    def test_send_text_message(self):
        """send_text_message() sends JSON over the mock WebSocket."""
        from app.services.client_connector import ClientConnector

        connector = ClientConnector(server_ip="127.0.0.1", server_port=8000)

        # Mock the websocket
        mock_ws = AsyncMock()
        mock_ws.send = AsyncMock()
        mock_ws.recv = AsyncMock(side_effect=asyncio.CancelledError)
        mock_ws.close = AsyncMock()

        connector._ws = mock_ws
        connector._running = True

        loop = asyncio.new_event_loop()
        try:
            msg_id = loop.run_until_complete(
                connector.send_text_message("Test message")
            )
            assert msg_id is not None
            mock_ws.send.assert_called_once()

            # Verify the sent payload
            sent_raw = mock_ws.send.call_args[0][0]
            sent_data = json.loads(sent_raw)
            assert sent_data["content"] == "Test message"
            assert sent_data["message_id"] == msg_id
            assert sent_data["lamport"] == 1
        finally:
            loop.run_until_complete(connector.disconnect())
            loop.close()

    def test_send_fails_when_not_connected(self):
        """send_text_message() returns None when not connected."""
        from app.services.client_connector import ClientConnector

        connector = ClientConnector(server_ip="127.0.0.1", server_port=8000)

        loop = asyncio.new_event_loop()
        try:
            msg_id = loop.run_until_complete(
                connector.send_text_message("Should fail")
            )
            assert msg_id is None
        finally:
            loop.close()

    def test_is_connected_property(self):
        """is_connected reflects internal state correctly."""
        from app.services.client_connector import ClientConnector

        connector = ClientConnector(server_ip="127.0.0.1", server_port=8000)
        assert connector.is_connected is False

        connector._ws = MagicMock()
        connector._running = True
        assert connector.is_connected is True

    def test_message_callback_registration(self):
        """on_message() registers callbacks correctly."""
        from app.services.client_connector import ClientConnector

        connector = ClientConnector(server_ip="127.0.0.1", server_port=8000)

        async def handler(data):
            pass

        connector.on_message(handler)
        assert len(connector._callbacks) == 1

    def test_lamport_increments(self):
        """Each send should increment the Lamport counter."""
        from app.services.client_connector import ClientConnector

        connector = ClientConnector(server_ip="127.0.0.1", server_port=8000)
        mock_ws = AsyncMock()
        mock_ws.send = AsyncMock()
        mock_ws.close = AsyncMock()
        connector._ws = mock_ws
        connector._running = True

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(connector.send_text_message("Msg 1"))
            loop.run_until_complete(connector.send_text_message("Msg 2"))

            assert connector._lamport == 2

            # Verify second message has lamport=2
            calls = mock_ws.send.call_args_list
            second_payload = json.loads(calls[1][0][0])
            assert second_payload["lamport"] == 2
        finally:
            loop.run_until_complete(connector.disconnect())
            loop.close()


# ===================================================================
# 6. Delivery receipt confirmation
# ===================================================================

class TestDeliveryReceipt:
    """Confirm delivery receipt contains expected fields."""

    def test_receipt_has_required_fields(self, db_session):
        uid = _ensure_user(db_session, "receipt@test.com")
        token = _make_jwt(uid)
        msg_id = str(uuid.uuid4())

        with client.websocket_connect(f"/ws/peer?token={token}") as ws:
            ws.send_text(
                json.dumps({
                    "message_id": msg_id,
                    "content": "Receipt test",
                    "lamport": 0,
                    "sent_at": datetime.now(timezone.utc).isoformat(),
                })
            )
            # Broadcast echo + receipt may arrive in either order
            events = []
            for _ in range(2):
                events.append(ws.receive_json())
            receipt = next(e for e in events if e["event"] == "receipt")
            assert "event" in receipt
            assert "message_id" in receipt
            assert "status" in receipt
            assert receipt["event"] == "receipt"
