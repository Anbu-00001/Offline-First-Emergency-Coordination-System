import asyncio

from fastapi import FastAPI, Body
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from app.core.config import settings
from app.api.routes import auth, protected, incidents, sync, ws
from app.services.cap_parser import parse_cap_xml
from app.services.notification_queue import consume_forever
from app.api.routes.ws import register_ws_events

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


# --- Startup events (Day 4) -------------------------------------------------
@app.on_event("startup")
async def startup_event() -> None:
    """Start background services on application boot."""
    # Start the notification queue consumer as a background task
    asyncio.create_task(consume_forever())
    # Register event-bus → WebSocket bridge callbacks
    register_ws_events()


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
