import asyncio
import logging

from fastapi import FastAPI, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app.core.config import settings
from app.api.routes import auth, protected, incidents, sync, ws
from app.api.routes import mdns_debug
from app.api.routes import peer_ws, pairing, sync_messages
from app.services.cap_parser import parse_cap_xml
from app.services.notification_queue import consume_forever
from app.services.message_worker import message_worker_loop
from app.api.routes.ws import register_ws_events

logger = logging.getLogger(__name__)

app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="OpenRescue Decentralized Emergency System API",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost", "http://localhost:3000", "http://127.0.0.1", "http://127.0.0.1:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Day 1–3 routers -------------------------------------------------------
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(protected.router, prefix="/api", tags=["protected"])

# --- Day 4 routers ----------------------------------------------------------
app.include_router(incidents.router, prefix="/incidents", tags=["incidents"])
app.include_router(sync.router, prefix="/sync", tags=["sync"])
app.include_router(ws.router, prefix="/ws", tags=["websocket"])

# --- Day 6 routers ----------------------------------------------------------
app.include_router(peer_ws.router, prefix="/ws", tags=["peer-messaging"])
app.include_router(pairing.router, prefix="/pairing", tags=["pairing"])
app.include_router(sync_messages.router, prefix="/sync", tags=["sync-messages"])

# --- Day 5 debug router (development only) ----------------------------------
if settings.ENVIRONMENT in ("development", "testing"):
    app.include_router(mdns_debug.router, tags=["mdns-debug"])

# --- mDNS globals (set during startup, read by debug endpoint) --------------
_mdns_advertiser = None
_mdns_discovery = None


# --- Startup events ---------------------------------------------------------
@app.on_event("startup")
async def startup_event() -> None:
    """Start background services on application boot."""
    global _mdns_advertiser, _mdns_discovery

    # Day 4 – notification queue & WebSocket bridge
    asyncio.create_task(consume_forever())
    register_ws_events()

    # Day 6 – message redelivery background worker
    asyncio.create_task(message_worker_loop())

    # Day 5 – mDNS advertisement / discovery
    if settings.ENABLE_MDNS:
        try:
            if settings.NODE_ROLE == "server":
                from app.services.mdns_advertiser import MDNSAdvertiser

                _mdns_advertiser = MDNSAdvertiser(
                    service_type=settings.MDNS_SERVICE_TYPE,
                    port=settings.HTTP_PORT,
                    service_name_prefix=settings.MDNS_SERVICE_NAME_PREFIX,
                    ttl_seconds=settings.MDNS_TTL_SECONDS,
                    refresh_seconds=settings.MDNS_PUBLISH_TTL_REFRESH_SECONDS,
                    version=settings.VERSION,
                )
                asyncio.create_task(_mdns_advertiser.start())
                logger.info("mDNS advertiser started (server mode)")
            else:
                from app.services.mdns_discovery import MDNSDiscovery

                _mdns_discovery = MDNSDiscovery(
                    service_type=settings.MDNS_SERVICE_TYPE,
                )
                asyncio.create_task(_mdns_discovery.start())
                logger.info("mDNS discovery started (client mode)")
        except Exception:
            logger.exception("Failed to initialise mDNS – continuing without discovery")


@app.on_event("shutdown")
async def shutdown_event() -> None:
    """Gracefully stop mDNS services."""
    global _mdns_advertiser, _mdns_discovery

    if _mdns_advertiser:
        await _mdns_advertiser.stop()
        _mdns_advertiser = None
        logger.info("mDNS advertiser stopped")

    if _mdns_discovery:
        await _mdns_discovery.stop()
        _mdns_discovery = None
        logger.info("mDNS discovery stopped")


@app.get("/health")
def health_check():
    return {"status": "ok", "service": settings.PROJECT_NAME}

class XMLPayload(BaseModel):
    xml_data: str

@app.post("/parse-cap")
def parse_cap(payload: XMLPayload):
    try:
        result = parse_cap_xml(payload.xml_data)
        return {"status": "success", "data": result}
    except ValueError as e:
        return {"status": "error", "message": str(e)}
