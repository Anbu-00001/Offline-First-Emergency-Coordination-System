# Week 1 Demo — Local Discovery & WebSocket Messaging

This document describes how to run the **OpenRescue Week-1 demo**: a local server advertises via mDNS, a client discovers it, connects via WebSocket, and they exchange a text message.

## Prerequisites

```bash
cd backend
pip install -r requirements.txt
```

Ensure `zeroconf`, `websockets`, and `httpx` are installed (all listed in `requirements.txt`).

## 1. Start the Server

```bash
# Terminal 1 — Server
cd backend
ENABLE_MDNS=true NODE_ROLE=server uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The server will:
- Start the FastAPI application on port 8000
- Advertise itself via mDNS as `_openrescue._tcp.local.`
- Accept WebSocket connections at `/ws/peer`

## 2. Run the Client Demo

### Option A: Automatic mDNS Discovery

```bash
# Terminal 2 — Client (discovers server automatically)
cd backend
python scripts/demo_local_chat.py
```

### Option B: Direct Connection (skip mDNS)

```bash
# Terminal 2 — Client (connect directly)
cd backend
python scripts/demo_local_chat.py --host 127.0.0.1 --port 8000
```

## 3. Expected Output

### Server Terminal
```
INFO  mDNS advertiser started (server mode)
INFO  Peer WS connected: user_id=0 (total connections=1)
```

### Client Terminal
```
🔌  Connecting to 127.0.0.1:8000 …
✅  Connected!

📤  Sent message: id=<uuid>  content='Hello from device B'
✅  Receipt: message_id=<uuid>  status=broadcast

👂  Listening for messages (10 seconds)…

👋  Demo complete — disconnected.
```

## 4. Verify the Full Stack

Run the verification script against a running server:

```bash
cd backend
python scripts/verify_week1_stack.py --host 127.0.0.1 --port 8000
```

Expected output:
```
OpenRescue Week-1 Stack Verification
Target: http://127.0.0.1:8000

──────────────────────────────────────────────────
  ✓ PASS  Health endpoint (/health)
  ⊘ SKIP  mDNS discovery — no server advertised on LAN
  ✓ PASS  WebSocket endpoint reachable (/ws/peer)
  ✓ PASS  Ping/Pong heartbeat
  ✓ PASS  Message round-trip (status=broadcast)
──────────────────────────────────────────────────

All checks passed ✓
```

## 5. Run Tests

```bash
cd backend
pytest -q
```

All Day 1–7 tests should pass with no regressions.

## Architecture Summary

```
Device A (Server)                Device B (Client)
┌─────────────────┐            ┌─────────────────┐
│ FastAPI app      │            │ demo_local_chat  │
│  ├─ /health      │◄──────────│  ├─ mDNS discover│
│  ├─ /ws/peer     │◄══════════│  ├─ WS connect   │
│  └─ mDNS advert. │           │  └─ send message │
└─────────────────┘            └─────────────────┘
        ▲                              │
        │     WebSocket relay          │
        └──────────────────────────────┘
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_MDNS` | `false` | Enable mDNS advertisement/discovery |
| `NODE_ROLE` | `server` | `server` to advertise, `client` to discover |
| `CLIENT_MODE` | `false` | Auto-connect client on startup |
| `HTTP_PORT` | `8000` | Port for mDNS advertisement |
