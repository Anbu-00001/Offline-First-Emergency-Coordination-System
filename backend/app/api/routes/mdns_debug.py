# SPDX-License-Identifier: GPL-3.0-or-later
"""
Debug endpoint for mDNS discovery (Day 5).

Exposes currently discovered servers when running in development mode.
"""
from __future__ import annotations

from fastapi import APIRouter, HTTPException

from app.core.config import settings

router = APIRouter(tags=["mdns-debug"])


@router.get("/mdns/servers")
def list_discovered_servers():
    """Return the list of mDNS-discovered servers.

    Only available in development/debug environments. In production this
    endpoint should be protected behind admin role verification.
    """
    if settings.ENVIRONMENT not in ("development", "testing"):
        raise HTTPException(status_code=403, detail="Endpoint disabled in production")

    # Import lazily – the discovery instance may not exist
    try:
        from app.main import _mdns_discovery  # type: ignore[attr-defined]

        if _mdns_discovery is None:
            return {"servers": [], "note": "mDNS discovery not active"}
        return {"servers": _mdns_discovery.get_available_servers()}
    except (ImportError, AttributeError):
        return {"servers": [], "note": "mDNS discovery not initialised"}
