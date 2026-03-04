# SPDX-License-Identifier: GPL-3.0-or-later
"""
mDNS Service Advertiser (Day 5).

Registers the OpenRescue Server as a DNS-SD service on the local network
so that client nodes can discover it automatically via multicast DNS.

Uses ``python-zeroconf`` for cross-platform, pure-Python mDNS.  If the
library is not installed the advertiser becomes a silent no-op so that
the rest of the application continues to function.
"""
from __future__ import annotations

import asyncio
import logging
import platform
import socket
import uuid
from typing import Any, Optional

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Lazy import – allow graceful degradation when zeroconf is missing
# ---------------------------------------------------------------------------
try:
    from zeroconf import ServiceInfo, Zeroconf, IPVersion
    _ZEROCONF_AVAILABLE = True
except ImportError:
    _ZEROCONF_AVAILABLE = False
    logger.warning(
        "python-zeroconf is not installed – mDNS advertisement disabled. "
        "Install with: pip install zeroconf"
    )


class MDNSAdvertiser:
    """Advertise the OpenRescue server via mDNS/DNS-SD.

    Parameters
    ----------
    service_type:
        DNS-SD service type, e.g. ``_openrescue._tcp.local.``.
    port:
        HTTP port the server listens on.
    service_name_prefix:
        Human-readable prefix for the service instance name.
    ttl_seconds:
        DNS record TTL in seconds.
    refresh_seconds:
        How often to re-register the service (should be < *ttl_seconds*).
    node_id:
        Unique node identifier; auto-generated if omitted.
    version:
        Application version string (placed in TXT record).
    """

    def __init__(
        self,
        service_type: str,
        port: int,
        service_name_prefix: str = "OpenRescue-Server",
        ttl_seconds: int = 120,
        refresh_seconds: int = 45,
        node_id: Optional[str] = None,
        version: str = "0.1.0",
    ) -> None:
        self._service_type = service_type
        self._port = port
        self._prefix = service_name_prefix
        self._ttl = ttl_seconds
        self._refresh = refresh_seconds
        self._node_id = node_id or uuid.uuid4().hex[:12]
        self._version = version

        self._zeroconf: Any = None
        self._info: Any = None
        self._refresh_task: Optional[asyncio.Task[None]] = None
        self._running = False

    # ------------------------------------------------------------------
    # Lifecycle
    # ------------------------------------------------------------------

    async def start(self) -> None:
        """Register the service and start the periodic refresh loop."""
        if not _ZEROCONF_AVAILABLE:
            logger.warning("MDNSAdvertiser.start() skipped – zeroconf unavailable")
            return

        try:
            self._zeroconf = Zeroconf(ip_version=IPVersion.V4Only)
            self._info = self._build_service_info()
            self._zeroconf.register_service(self._info, ttl=self._ttl)
            self._running = True
            logger.info(
                "mDNS service registered: %s on port %d",
                self._info.name,
                self._port,
            )
            self._refresh_task = asyncio.create_task(self._refresh_loop())
        except Exception:
            logger.exception("Failed to start mDNS advertiser")
            await self.stop()

    async def stop(self) -> None:
        """Unregister the service and release resources."""
        self._running = False
        if self._refresh_task and not self._refresh_task.done():
            self._refresh_task.cancel()
            try:
                await self._refresh_task
            except asyncio.CancelledError:
                pass
            self._refresh_task = None

        if self._zeroconf:
            try:
                if self._info:
                    self._zeroconf.unregister_service(self._info)
                    logger.info("mDNS service unregistered: %s", self._info.name)
                self._zeroconf.close()
            except Exception:
                logger.exception("Error during mDNS advertiser shutdown")
            finally:
                self._zeroconf = None
                self._info = None

    # ------------------------------------------------------------------
    # Internal helpers
    # ------------------------------------------------------------------

    def _build_service_info(self) -> "ServiceInfo":
        """Construct the ``ServiceInfo`` record for DNS-SD registration."""
        hostname = platform.node() or "unknown"
        short_uuid = self._node_id[:8]
        service_name = f"{self._prefix}-{hostname}-{short_uuid}.{self._service_type}"

        # Resolve local IPv4 address
        try:
            local_ip = socket.gethostbyname(socket.gethostname())
        except socket.gaierror:
            local_ip = "127.0.0.1"

        # TXT records – keep payload small, no secrets
        txt_records: dict[str, str] = {
            "node_type": "server",
            "node_id": self._node_id,
            "api_path": "/health",
            "version": self._version,
        }

        return ServiceInfo(
            type_=self._service_type,
            name=service_name,
            addresses=[socket.inet_aton(local_ip)],
            port=self._port,
            properties=txt_records,
            server=f"{hostname}.local.",
        )

    async def _refresh_loop(self) -> None:
        """Periodically re-register the service to keep mDNS records alive."""
        backoff = 1.0
        max_backoff = 60.0

        while self._running:
            try:
                await asyncio.sleep(self._refresh)
                if not self._running:
                    break
                if self._zeroconf and self._info:
                    self._zeroconf.update_service(self._info)
                    logger.debug("mDNS service refreshed: %s", self._info.name)
                    backoff = 1.0  # reset on success
            except asyncio.CancelledError:
                break
            except Exception:
                logger.exception(
                    "mDNS refresh error, retrying in %.0fs", backoff
                )
                await asyncio.sleep(backoff)
                backoff = min(backoff * 2, max_backoff)
                # Re-create zeroconf on persistent failures
                try:
                    if self._zeroconf:
                        self._zeroconf.close()
                    self._zeroconf = Zeroconf(ip_version=IPVersion.V4Only)
                    self._info = self._build_service_info()
                    self._zeroconf.register_service(self._info, ttl=self._ttl)
                    logger.info("mDNS re-registered after error recovery")
                except Exception:
                    logger.exception("mDNS re-registration failed")
