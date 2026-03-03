# SPDX-License-Identifier: GPL-3.0-or-later
"""
Day 4 test scaffolding — incidents, assignment, WebSocket, event bus.

NOTE: The project models use PostGIS Geometry columns (via GeoAlchemy2),
which are incompatible with SQLite. These tests therefore focus on:
  - Pure-function unit tests (Haversine, schema validation, event bus)
  - Pydantic schema validation tests
  - WebSocket connection tests (via ASGI TestClient, no DB needed)

Full integration tests should be run against a PostgreSQL+PostGIS instance.
"""
from __future__ import annotations

import asyncio
import uuid
from datetime import datetime, timezone

import pytest

# ---------------------------------------------------------------------------
# 1. Haversine distance tests (pure math — no DB)
# ---------------------------------------------------------------------------

from app.services.assignment import _haversine, WORKLOAD_WEIGHT


class TestHaversineDistance:
    """Validate Haversine formula against known distances."""

    def test_chennai_to_delhi(self):
        """Chennai (13.08, 80.27) → Delhi (28.61, 77.21) ≈ 1,757 km."""
        dist = _haversine(13.08, 80.27, 28.61, 77.21)
        assert 1_700 < dist < 1_800

    def test_same_point_zero_distance(self):
        """Same coordinates should yield 0 km."""
        dist = _haversine(13.08, 80.27, 13.08, 80.27)
        assert dist == pytest.approx(0.0, abs=0.01)

    def test_north_pole_to_south_pole(self):
        """North pole to south pole ≈ ~20,015 km (half circumference)."""
        dist = _haversine(90.0, 0.0, -90.0, 0.0)
        assert 19_900 < dist < 20_100

    def test_equator_quarter_circumference(self):
        """(0,0) to (0,90) should be ≈ ~10,008 km (quarter circumference)."""
        dist = _haversine(0.0, 0.0, 0.0, 90.0)
        assert 9_900 < dist < 10_100

    def test_negative_coordinates(self):
        """Negative lat/lon should work (Southern/Western hemispheres)."""
        dist = _haversine(-33.87, 151.21, -37.81, 144.96)  # Sydney → Melbourne
        assert 700 < dist < 900


# ---------------------------------------------------------------------------
# 2. Pydantic schema validation tests
# ---------------------------------------------------------------------------

from app.schemas.incident import IncidentCreate, IncidentOut, IncidentUpdate, IncidentBatch


class TestIncidentSchemas:
    """Validate input/output schemas."""

    def test_valid_incident_create(self):
        inc = IncidentCreate(
            identifier="INC-001",
            sender="node-1",
            type="flood",
            latitude=13.08,
            longitude=80.27,
            priority=5,
        )
        assert inc.identifier == "INC-001"
        assert inc.latitude == pytest.approx(13.08)

    def test_invalid_latitude_rejects(self):
        with pytest.raises(ValueError, match="latitude"):
            IncidentCreate(
                identifier="INC-002",
                sender="node-1",
                latitude=999.0,
                longitude=0.0,
            )

    def test_invalid_longitude_rejects(self):
        with pytest.raises(ValueError, match="longitude"):
            IncidentCreate(
                identifier="INC-003",
                sender="node-1",
                latitude=0.0,
                longitude=-200.0,
            )

    def test_incident_update_optional_fields(self):
        upd = IncidentUpdate(status="Resolved")
        assert upd.status == "Resolved"
        assert upd.assigned_responder_id is None

    def test_incident_batch_parses(self):
        batch = IncidentBatch(
            incidents=[
                {
                    "identifier": "INC-B1",
                    "sender": "offline-node",
                    "client_id": "client-abc",
                    "latitude": 10.0,
                    "longitude": 76.0,
                },
                {
                    "identifier": "INC-B2",
                    "sender": "offline-node",
                    "latitude": 11.0,
                    "longitude": 77.0,
                },
            ]
        )
        assert len(batch.incidents) == 2
        assert batch.incidents[0].client_id == "client-abc"


from app.schemas.responder import ResponderOut, ResponderUpdate


class TestResponderSchemas:
    """Validate responder schemas."""

    def test_responder_update_validates_lat(self):
        with pytest.raises(ValueError, match="latitude"):
            ResponderUpdate(last_known_latitude=100.0)

    def test_responder_update_valid(self):
        upd = ResponderUpdate(
            name="Alpha Team",
            available=True,
            last_known_latitude=13.0,
            last_known_longitude=80.0,
        )
        assert upd.name == "Alpha Team"


# ---------------------------------------------------------------------------
# 3. Event bus tests (async)
# ---------------------------------------------------------------------------

from app.core.events import EventBus


class TestEventBus:
    """In-process pub/sub event bus tests."""

    def test_subscribe_and_publish(self):
        bus = EventBus()
        received = []

        async def handler(payload):
            received.append(payload)

        bus.subscribe("test_event", handler)
        asyncio.get_event_loop().run_until_complete(
            bus.publish("test_event", {"key": "value"})
        )
        assert len(received) == 1
        assert received[0]["key"] == "value"

    def test_multiple_subscribers(self):
        bus = EventBus()
        results_a = []
        results_b = []

        async def handler_a(payload):
            results_a.append(payload)

        async def handler_b(payload):
            results_b.append(payload)

        bus.subscribe("multi", handler_a)
        bus.subscribe("multi", handler_b)
        asyncio.get_event_loop().run_until_complete(
            bus.publish("multi", {"n": 1})
        )
        assert len(results_a) == 1
        assert len(results_b) == 1

    def test_unsubscribe(self):
        bus = EventBus()
        received = []

        async def handler(payload):
            received.append(payload)

        bus.subscribe("unsub_test", handler)
        bus.unsubscribe("unsub_test", handler)
        asyncio.get_event_loop().run_until_complete(
            bus.publish("unsub_test", {"x": 1})
        )
        assert len(received) == 0

    def test_publish_no_subscribers_no_error(self):
        bus = EventBus()
        # Should not raise
        asyncio.get_event_loop().run_until_complete(
            bus.publish("nonexistent", {})
        )

    def test_failing_subscriber_does_not_block_others(self):
        bus = EventBus()
        results = []

        async def bad_handler(payload):
            raise RuntimeError("intentional failure")

        async def good_handler(payload):
            results.append(payload)

        bus.subscribe("mixed", bad_handler)
        bus.subscribe("mixed", good_handler)
        asyncio.get_event_loop().run_until_complete(
            bus.publish("mixed", {"val": 42})
        )
        # good_handler should still receive the event
        assert len(results) == 1
        assert results[0]["val"] == 42


# ---------------------------------------------------------------------------
# 4. Notification queue tests
# ---------------------------------------------------------------------------

from app.services.notification_queue import enqueue, notification_queue


class TestNotificationQueue:
    """Basic notification queue enqueue test."""

    def test_enqueue_adds_to_queue(self):
        # Drain any existing items
        while not notification_queue.empty():
            notification_queue.get_nowait()

        asyncio.get_event_loop().run_until_complete(
            enqueue("test_incident", {"id": "123"})
        )
        assert not notification_queue.empty()
        job = notification_queue.get_nowait()
        assert job["event"] == "test_incident"
        assert job["data"]["id"] == "123"


# ---------------------------------------------------------------------------
# 5. WebSocket connection test (uses ASGI transport, no DB queries)
# ---------------------------------------------------------------------------

import os
os.environ.setdefault("DATABASE_URL", "sqlite:///./test_day4.db")

from app.main import app
from starlette.testclient import TestClient

# We need to patch the engine for the test client to work,
# but WebSocket itself doesn't touch the DB
ws_client = TestClient(app)


class TestWebSocket:
    """WebSocket /ws/alerts connection tests."""

    def test_ws_connect_anonymous(self):
        """Anonymous WebSocket connection should be accepted."""
        with ws_client.websocket_connect("/ws/alerts") as ws:
            ws.send_text('{"type": "ping"}')
            # Connection stays open — no error

    def test_ws_connect_with_invalid_token(self):
        """Invalid token should still connect in read-only mode."""
        with ws_client.websocket_connect("/ws/alerts?token=bad") as ws:
            ws.send_text('{"type": "hello"}')
