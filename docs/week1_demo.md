# Week 1 — OpenRescue Demo & Architecture

## Overview
This document contains a concise architecture diagram and the evidence files demonstrating Week-1 functionality:
- FastAPI backend (REST + WebSocket)
- mDNS advertiser for local discovery
- Client A & Client B WebSocket messaging (local)

## Architecture (Mermaid source)
See `week1_architecture.mmd` (Mermaid). If a PNG was generated it is saved as `week1_architecture.png`.

### How Client A and Client B communicate (local flow)
1. **Discovery**  
   - Server node advertises via mDNS (`_openrescue._tcp.local.`) including service port (e.g. 8000).
   - Client devices on the same Wi-Fi run an mDNS browser and resolve the service to `IP:PORT`.
2. **Authentication (optional)**  
   - Clients authenticate using `/auth/login` to obtain a JWT (if the WebSocket endpoint requires it).
   - Alternatively the system supports ephemeral pairing tokens for ad-hoc connections.
3. **WebSocket connection**  
   - Client A opens: `ws://<server-ip>:<port>/ws/peer?token=<jwt or pair_token>`
   - Client B opens similarly.
4. **Message exchange**  
   - Client A sends JSON message: `{ "message_id": "<uuid>", "content": "...", "sent_at": "<ts>" }`
   - Server persists the message (db), publishes an internal event, and the WebSocket manager delivers it to Client B if connected (or queues it for later).
   - Server sends receipt back to sender with delivery status.
5. **Offline & store-and-forward**  
   - If recipient is offline, server stores the message and marks `delivered=False`. When Client B reconnects the server delivers queued messages.

## Saved evidence (this folder)
- `docs/week1_architecture.mmd` — mermaid source
- `docs/week1_architecture.png` — rendered image (if generated)
- `docs/docs.html` — OpenAPI docs HTML
- `docs/screenshots/api_docs.png` — API docs snapshot (if created)
- `docs/client_A.log` / `docs/client_B.log` — demo attempt logs
- `docs/uvicorn_tail.log` / `docs/mdns_tail.log` — server log tails
- `PROJECT_TIMELINE.txt` updated (Day 7 entry appended)

