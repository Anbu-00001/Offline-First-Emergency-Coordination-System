# SPDX-License-Identifier: GPL-3.0-or-later
"""
mDNS Service Discovery (Day 5).

Watches the local network for ``_openrescue._tcp.local.`` services and
maintains an in-memory registry of discovered servers.  Events are bridged
into the application's async :pydata:`event_bus` so that higher-level code
can react to servers appearing or disappearing.

Uses ``python-zeroconf``.  Falls back to a no-op when the library is absent.
"""
from __future__ import annotations

import asyncio
import logging
import time
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Lazy import
# ---------------------------------------------------------------------------
try:
    from zeroconf import ServiceBrowser, ServiceInfo, ServiceStateChange, Zeroconf, IPVersion
    _ZEROCONF_AVAILABLE = True
except ImportError:
    _ZEROCONF_AVAILABLE = False
    logger.warning(
        "python-zeroconf is not installed – mDNS discovery disabled. "
        "Install with: pip install zeroconf"
    )

from app.core.events import event_bus


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

@dataclass
class DiscoveredServer:
    """Lightweight record for a discovered OpenRescue server."""

    name: str
    ip: str
    port: int
    txt: Dict[str, str] = field(default_factory=dict)
    last_seen: float = field(default_factory=time.time)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "name": self.name,
            "ip": self.ip,
            "port": self.port,
            "txt": self.txt,
            "last_seen": self.last_seen,
        }


# ---------------------------------------------------------------------------
# Discovery service
# ---------------------------------------------------------------------------

class MDNSDiscovery:
    """Watch the local network for OpenRescue mDNS services.

    Parameters
    ----------
    service_type:
        DNS-SD service type to browse for.
    """

    def __init__(self, service_type: str) -> None:
        self._service_type = service_type
        self._zeroconf: Any = None
        self._browser: Any = None
        self._servers: Dict[str, DiscoveredServer] = {}
        self._loop: Optional[asyncio.AbstractEventLoop] = None
        self._running = False
        self._server_found_event: Optional[asyncio.Event] = None

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    async def start(self) -> None:
        """Start the mDNS browser and begin listening for services."""
        if not _ZEROCONF_AVAILABLE:
            logger.warning("MDNSDiscovery.start() skipped – zeroconf unavailable")
            return

        self._loop = asyncio.get_running_loop()
        self._server_found_event = asyncio.Event()

        try:
            self._zeroconf = Zeroconf(ip_version=IPVersion.V4Only)
            self._browser = ServiceBrowser(
                self._zeroconf,
                self._service_type,
                handlers=[self._on_state_change],
            )
            self._running = True
            logger.info(
                "mDNS discovery started, browsing for %s", self._service_type
            )
        except Exception:
            logger.exception("Failed to start mDNS discovery")
            await self.stop()

    async def stop(self) -> None:
        """Stop the browser and release resources."""
        self._running = False
        if self._browser:
            try:
                self._browser.cancel()
            except Exception:
                logger.exception("Error cancelling mDNS browser")
            self._browser = None

        if self._zeroconf:
            try:
                self._zeroconf.close()
            except Exception:
                logger.exception("Error closing mDNS zeroconf instance")
            self._zeroconf = None

        self._servers.clear()
        logger.info("mDNS discovery stopped")

    # ------------------------------------------------------------------
    # Public API
    # ------------------------------------------------------------------

    def get_available_servers(self) -> List[Dict[str, Any]]:
        """Return discovered servers sorted by *last_seen* (newest first)."""
        servers = sorted(
            self._servers.values(),
            key=lambda s: s.last_seen,
            reverse=True,
        )
        return [s.to_dict() for s in servers]

    async def await_server(self, timeout: float = 30.0) -> Optional[Dict[str, Any]]:
        """Block until at least one server is found, or *timeout* expires.

        Returns the newest server dict, or ``None`` on timeout.
        """
        if self._servers:
            return self.get_available_servers()[0]

        if self._server_found_event is None:
            return None

        try:
            await asyncio.wait_for(self._server_found_event.wait(), timeout=timeout)
            return self.get_available_servers()[0] if self._servers else None
        except asyncio.TimeoutError:
            logger.warning("await_server timed out after %.1fs", timeout)
            return None

    # ------------------------------------------------------------------
    # zeroconf callbacks (called from zeroconf's internal thread)
    # ------------------------------------------------------------------

    def _on_state_change(
        self,
        zeroconf: Any,
        service_type: str,
        name: str,
        state_change: Any,
    ) -> None:
        """Handle add/remove/update from the ServiceBrowser thread."""
        if self._loop is None:
            return

        if state_change == ServiceStateChange.Added:
            self._loop.call_soon_threadsafe(
                asyncio.ensure_future,
                self._handle_service_added(zeroconf, service_type, name),
            )
        elif state_change == ServiceStateChange.Removed:
            self._loop.call_soon_threadsafe(
                asyncio.ensure_future,
                self._handle_service_removed(name),
            )
        elif state_change == ServiceStateChange.Updated:
            self._loop.call_soon_threadsafe(
                asyncio.ensure_future,
                self._handle_service_added(zeroconf, service_type, name),
            )

    # ------------------------------------------------------------------
    # Async event handlers
    # ------------------------------------------------------------------

    async def _handle_service_added(
        self, zeroconf: Any, service_type: str, name: str
    ) -> None:
        """Resolve a newly discovered service and store it."""
        try:
            info: Optional[ServiceInfo] = zeroconf.get_service_info(service_type, name)
            if info is None:
                logger.debug("Could not resolve service info for %s", name)
                return

            # Prefer IPv4 addresses
            addresses = info.parsed_addresses()
            ipv4 = [a for a in addresses if ":" not in a]
            ip = ipv4[0] if ipv4 else (addresses[0] if addresses else "0.0.0.0")

            # Decode TXT properties
            txt: Dict[str, str] = {}
            if info.properties:
                for k, v in info.properties.items():
                    key = k.decode("utf-8") if isinstance(k, bytes) else str(k)
                    val = v.decode("utf-8") if isinstance(v, bytes) else str(v)
                    txt[key] = val

            is_update = name in self._servers
            server = DiscoveredServer(
                name=name, ip=ip, port=info.port, txt=txt, last_seen=time.time()
            )
            self._servers[name] = server

            event_name = "mdns.service_updated" if is_update else "mdns.service_added"
            logger.info(
                "%s: %s → %s:%d", event_name, name, ip, info.port
            )
            await event_bus.publish(event_name, server.to_dict())

            # Wake up anyone waiting in await_server()
            if self._server_found_event and not self._server_found_event.is_set():
                self._server_found_event.set()

        except Exception:
            logger.exception("Error resolving mDNS service %s", name)

    async def _handle_service_removed(self, name: str) -> None:
        """Remove a server that is no longer advertised."""
        removed = self._servers.pop(name, None)
        if removed:
            logger.info("mdns.service_removed: %s", name)
            await event_bus.publish("mdns.service_removed", {"name": name})
