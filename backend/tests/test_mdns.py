# SPDX-License-Identifier: GPL-3.0-or-later
"""
Day 5 – mDNS advertiser & discovery tests.

All tests mock ``python-zeroconf`` so they run without multicast networking
and are safe for CI environments.
"""
from __future__ import annotations

import asyncio
import os
import socket
import time
from typing import Any, Dict, List
from unittest.mock import MagicMock, patch, PropertyMock

import pytest

# Ensure a DATABASE_URL is set so importing app modules doesn't fail
os.environ.setdefault("DATABASE_URL", "sqlite:///./test_mdns.db")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _make_mock_service_info(
    name: str = "OpenRescue-Server-host-abcd1234._openrescue._tcp.local.",
    addresses: list[bytes] | None = None,
    port: int = 8000,
    properties: dict[bytes, bytes] | None = None,
) -> MagicMock:
    """Create a mock ``ServiceInfo`` with sensible defaults."""
    info = MagicMock()
    info.name = name
    info.port = port
    info.parsed_addresses.return_value = ["192.168.1.100"]
    info.properties = properties or {
        b"node_type": b"server",
        b"node_id": b"abcd1234abcd",
        b"api_path": b"/health",
        b"version": b"0.1.0",
    }
    info.addresses = addresses or [socket.inet_aton("192.168.1.100")]
    return info


# ===================================================================
# 1. MDNSAdvertiser tests
# ===================================================================


class TestMDNSAdvertiser:
    """Test the service advertiser (mocked zeroconf)."""

    @patch("app.services.mdns_advertiser.Zeroconf")
    @patch("app.services.mdns_advertiser.ServiceInfo")
    @patch("app.services.mdns_advertiser._ZEROCONF_AVAILABLE", True)
    def test_start_registers_service(self, MockServiceInfo, MockZeroconf):
        """start() should create a Zeroconf instance and call register_service."""
        from app.services.mdns_advertiser import MDNSAdvertiser

        mock_zc = MagicMock()
        MockZeroconf.return_value = mock_zc

        adv = MDNSAdvertiser(
            service_type="_openrescue._tcp.local.",
            port=8000,
            service_name_prefix="OpenRescue-Server",
        )

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(adv.start())
            # Verify register_service was called
            mock_zc.register_service.assert_called_once()
            # The first positional arg should be the ServiceInfo built internally
            call_args = mock_zc.register_service.call_args
            assert call_args is not None
        finally:
            loop.run_until_complete(adv.stop())
            loop.close()

    @patch("app.services.mdns_advertiser.Zeroconf")
    @patch("app.services.mdns_advertiser.ServiceInfo")
    @patch("app.services.mdns_advertiser._ZEROCONF_AVAILABLE", True)
    def test_stop_unregisters_and_closes(self, MockServiceInfo, MockZeroconf):
        """stop() should unregister the service and close zeroconf."""
        from app.services.mdns_advertiser import MDNSAdvertiser

        mock_zc = MagicMock()
        MockZeroconf.return_value = mock_zc

        adv = MDNSAdvertiser(
            service_type="_openrescue._tcp.local.",
            port=8000,
        )

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(adv.start())
            loop.run_until_complete(adv.stop())

            mock_zc.unregister_service.assert_called_once()
            mock_zc.close.assert_called_once()
        finally:
            loop.close()

    @patch("app.services.mdns_advertiser.Zeroconf")
    @patch("app.services.mdns_advertiser.ServiceInfo")
    @patch("app.services.mdns_advertiser._ZEROCONF_AVAILABLE", True)
    def test_service_name_contains_prefix(self, MockServiceInfo, MockZeroconf):
        """The constructed service name should contain the configured prefix."""
        from app.services.mdns_advertiser import MDNSAdvertiser

        mock_zc = MagicMock()
        MockZeroconf.return_value = mock_zc

        adv = MDNSAdvertiser(
            service_type="_openrescue._tcp.local.",
            port=9000,
            service_name_prefix="TestPrefix",
        )

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(adv.start())
            # ServiceInfo was constructed – check the name arg
            si_call = MockServiceInfo.call_args
            assert si_call is not None
            # name= is a keyword arg
            name_arg = si_call.kwargs.get("name", si_call.args[1] if len(si_call.args) > 1 else "")
            assert "TestPrefix" in str(name_arg)
        finally:
            loop.run_until_complete(adv.stop())
            loop.close()

    @patch("app.services.mdns_advertiser.Zeroconf")
    @patch("app.services.mdns_advertiser.ServiceInfo")
    @patch("app.services.mdns_advertiser._ZEROCONF_AVAILABLE", True)
    def test_txt_records_no_secrets(self, MockServiceInfo, MockZeroconf):
        """TXT records should only contain safe metadata keys."""
        from app.services.mdns_advertiser import MDNSAdvertiser

        mock_zc = MagicMock()
        MockZeroconf.return_value = mock_zc

        adv = MDNSAdvertiser(
            service_type="_openrescue._tcp.local.",
            port=8000,
        )

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(adv.start())
            si_call = MockServiceInfo.call_args
            properties = si_call.kwargs.get("properties", {})
            allowed_keys = {"node_type", "node_id", "api_path", "version"}
            assert set(properties.keys()) <= allowed_keys
            # Specifically no password, token, secret keys
            for key in properties:
                assert "secret" not in key.lower()
                assert "token" not in key.lower()
                assert "password" not in key.lower()
        finally:
            loop.run_until_complete(adv.stop())
            loop.close()

    def test_start_noop_when_zeroconf_unavailable(self):
        """When zeroconf is not installed, start() should be a no-op (no crash)."""
        from app.services.mdns_advertiser import MDNSAdvertiser

        adv = MDNSAdvertiser(
            service_type="_openrescue._tcp.local.",
            port=8000,
        )

        with patch("app.services.mdns_advertiser._ZEROCONF_AVAILABLE", False):
            loop = asyncio.new_event_loop()
            try:
                # Should not raise
                loop.run_until_complete(adv.start())
                loop.run_until_complete(adv.stop())
            finally:
                loop.close()


# ===================================================================
# 2. MDNSDiscovery tests
# ===================================================================


class TestMDNSDiscovery:
    """Test the discovery browser (mocked zeroconf)."""

    @patch("app.services.mdns_discovery.ServiceBrowser")
    @patch("app.services.mdns_discovery.Zeroconf")
    @patch("app.services.mdns_discovery._ZEROCONF_AVAILABLE", True)
    def test_start_creates_browser(self, MockZeroconf, MockBrowser):
        """start() should create a Zeroconf instance and a ServiceBrowser."""
        from app.services.mdns_discovery import MDNSDiscovery

        mock_zc = MagicMock()
        MockZeroconf.return_value = mock_zc

        disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(disc.start())
            MockBrowser.assert_called_once()
            # First arg to ServiceBrowser should be the zeroconf instance
            assert MockBrowser.call_args[0][0] is mock_zc
        finally:
            loop.run_until_complete(disc.stop())
            loop.close()

    @patch("app.services.mdns_discovery.ServiceBrowser")
    @patch("app.services.mdns_discovery.Zeroconf")
    @patch("app.services.mdns_discovery._ZEROCONF_AVAILABLE", True)
    def test_handle_service_added_populates_servers(self, MockZeroconf, MockBrowser):
        """Simulating a service-added callback should populate get_available_servers()."""
        from app.services.mdns_discovery import MDNSDiscovery

        mock_zc = MagicMock()
        MockZeroconf.return_value = mock_zc
        mock_info = _make_mock_service_info()
        mock_zc.get_service_info.return_value = mock_info

        disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(disc.start())

            # Directly invoke the async handler
            loop.run_until_complete(
                disc._handle_service_added(mock_zc, "_openrescue._tcp.local.", mock_info.name)
            )

            servers = disc.get_available_servers()
            assert len(servers) == 1
            assert servers[0]["ip"] == "192.168.1.100"
            assert servers[0]["port"] == 8000
            assert servers[0]["txt"]["node_type"] == "server"
        finally:
            loop.run_until_complete(disc.stop())
            loop.close()

    @patch("app.services.mdns_discovery.ServiceBrowser")
    @patch("app.services.mdns_discovery.Zeroconf")
    @patch("app.services.mdns_discovery._ZEROCONF_AVAILABLE", True)
    def test_handle_service_removed_clears_server(self, MockZeroconf, MockBrowser):
        """After removing a service, get_available_servers() should be empty."""
        from app.services.mdns_discovery import MDNSDiscovery

        mock_zc = MagicMock()
        MockZeroconf.return_value = mock_zc
        mock_info = _make_mock_service_info()
        mock_zc.get_service_info.return_value = mock_info

        disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(disc.start())

            # Add then remove
            loop.run_until_complete(
                disc._handle_service_added(mock_zc, "_openrescue._tcp.local.", mock_info.name)
            )
            assert len(disc.get_available_servers()) == 1

            loop.run_until_complete(disc._handle_service_removed(mock_info.name))
            assert len(disc.get_available_servers()) == 0
        finally:
            loop.run_until_complete(disc.stop())
            loop.close()

    @patch("app.services.mdns_discovery.ServiceBrowser")
    @patch("app.services.mdns_discovery.Zeroconf")
    @patch("app.services.mdns_discovery._ZEROCONF_AVAILABLE", True)
    def test_get_available_servers_deduplicates(self, MockZeroconf, MockBrowser):
        """Adding the same service twice should not duplicate entries."""
        from app.services.mdns_discovery import MDNSDiscovery

        mock_zc = MagicMock()
        MockZeroconf.return_value = mock_zc
        mock_info = _make_mock_service_info()
        mock_zc.get_service_info.return_value = mock_info

        disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(disc.start())

            # Add same service twice
            loop.run_until_complete(
                disc._handle_service_added(mock_zc, "_openrescue._tcp.local.", mock_info.name)
            )
            loop.run_until_complete(
                disc._handle_service_added(mock_zc, "_openrescue._tcp.local.", mock_info.name)
            )

            servers = disc.get_available_servers()
            assert len(servers) == 1
        finally:
            loop.run_until_complete(disc.stop())
            loop.close()

    @patch("app.services.mdns_discovery.ServiceBrowser")
    @patch("app.services.mdns_discovery.Zeroconf")
    @patch("app.services.mdns_discovery._ZEROCONF_AVAILABLE", True)
    def test_servers_sorted_by_last_seen(self, MockZeroconf, MockBrowser):
        """get_available_servers() should return newest-first ordering."""
        from app.services.mdns_discovery import MDNSDiscovery

        mock_zc = MagicMock()
        MockZeroconf.return_value = mock_zc

        disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")

        loop = asyncio.new_event_loop()
        try:
            loop.run_until_complete(disc.start())

            # Add two different services with slight time gap
            info_a = _make_mock_service_info(name="ServiceA._openrescue._tcp.local.")
            info_b = _make_mock_service_info(name="ServiceB._openrescue._tcp.local.")
            mock_zc.get_service_info.return_value = info_a

            loop.run_until_complete(
                disc._handle_service_added(mock_zc, "_openrescue._tcp.local.", info_a.name)
            )

            # Small delay to ensure different timestamps
            time.sleep(0.05)
            mock_zc.get_service_info.return_value = info_b
            loop.run_until_complete(
                disc._handle_service_added(mock_zc, "_openrescue._tcp.local.", info_b.name)
            )

            servers = disc.get_available_servers()
            assert len(servers) == 2
            # B was added last, so it should be first
            assert servers[0]["name"] == info_b.name
        finally:
            loop.run_until_complete(disc.stop())
            loop.close()

    def test_start_noop_when_zeroconf_unavailable(self):
        """When zeroconf is missing, start() should be a no-op."""
        from app.services.mdns_discovery import MDNSDiscovery

        disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")

        with patch("app.services.mdns_discovery._ZEROCONF_AVAILABLE", False):
            loop = asyncio.new_event_loop()
            try:
                loop.run_until_complete(disc.start())
                assert disc.get_available_servers() == []
                loop.run_until_complete(disc.stop())
            finally:
                loop.close()


# ===================================================================
# 3. Event bus integration
# ===================================================================


class TestMDNSEventBusIntegration:
    """Verify that discovery events are published to the event bus."""

    @patch("app.services.mdns_discovery.ServiceBrowser")
    @patch("app.services.mdns_discovery.Zeroconf")
    @patch("app.services.mdns_discovery._ZEROCONF_AVAILABLE", True)
    def test_service_added_event_emitted(self, MockZeroconf, MockBrowser):
        """Adding a service should publish mdns.service_added on the event bus."""
        from app.core.events import EventBus
        from app.services.mdns_discovery import MDNSDiscovery
        import app.services.mdns_discovery as disc_mod

        captured: list[dict] = []

        async def capture(payload: dict):
            captured.append(payload)

        # Use a fresh event bus to avoid interference
        test_bus = EventBus()
        test_bus.subscribe("mdns.service_added", capture)
        original_bus = disc_mod.event_bus

        try:
            disc_mod.event_bus = test_bus

            mock_zc = MagicMock()
            MockZeroconf.return_value = mock_zc
            mock_info = _make_mock_service_info()
            mock_zc.get_service_info.return_value = mock_info

            disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")

            loop = asyncio.new_event_loop()
            try:
                loop.run_until_complete(disc.start())
                loop.run_until_complete(
                    disc._handle_service_added(mock_zc, "_openrescue._tcp.local.", mock_info.name)
                )

                assert len(captured) == 1
                assert captured[0]["ip"] == "192.168.1.100"
                assert captured[0]["name"] == mock_info.name
            finally:
                loop.run_until_complete(disc.stop())
                loop.close()
        finally:
            disc_mod.event_bus = original_bus

    @patch("app.services.mdns_discovery.ServiceBrowser")
    @patch("app.services.mdns_discovery.Zeroconf")
    @patch("app.services.mdns_discovery._ZEROCONF_AVAILABLE", True)
    def test_service_removed_event_emitted(self, MockZeroconf, MockBrowser):
        """Removing a service should publish mdns.service_removed."""
        from app.core.events import EventBus
        from app.services.mdns_discovery import MDNSDiscovery
        import app.services.mdns_discovery as disc_mod

        captured: list[dict] = []

        async def capture(payload: dict):
            captured.append(payload)

        test_bus = EventBus()
        test_bus.subscribe("mdns.service_removed", capture)
        original_bus = disc_mod.event_bus

        try:
            disc_mod.event_bus = test_bus

            mock_zc = MagicMock()
            MockZeroconf.return_value = mock_zc
            mock_info = _make_mock_service_info()
            mock_zc.get_service_info.return_value = mock_info

            disc = MDNSDiscovery(service_type="_openrescue._tcp.local.")

            loop = asyncio.new_event_loop()
            try:
                loop.run_until_complete(disc.start())
                # Add then remove
                loop.run_until_complete(
                    disc._handle_service_added(mock_zc, "_openrescue._tcp.local.", mock_info.name)
                )
                loop.run_until_complete(disc._handle_service_removed(mock_info.name))

                assert len(captured) == 1
                assert captured[0]["name"] == mock_info.name
            finally:
                loop.run_until_complete(disc.stop())
                loop.close()
        finally:
            disc_mod.event_bus = original_bus


# ===================================================================
# 4. Config flags
# ===================================================================


class TestMDNSConfig:
    """Verify that mDNS config flags exist and have correct defaults."""

    def test_default_config_values(self):
        from app.core.config import Settings

        s = Settings(
            _env_file=None,  # type: ignore[call-arg]
        )
        assert s.ENABLE_MDNS is False
        assert s.MDNS_SERVICE_TYPE == "_openrescue._tcp.local."
        assert s.MDNS_TTL_SECONDS == 120
        assert s.MDNS_PUBLISH_TTL_REFRESH_SECONDS == 45
        assert s.MDNS_SERVICE_NAME_PREFIX == "OpenRescue-Server"
        assert s.NODE_ROLE == "server"
        assert s.HTTP_PORT == 8000
        assert s.MDNS_FALLBACK_HOSTS == ""
