# FOSS Compliance Audit

**Project:** OpenRescue  
**Date:** March 25, 2026  
**Status:** 100% FOSS Compliant 🟢  

---

## 1. Executive Summary
This document serves as the official FOSS compliance audit for the OpenRescue project. The codebase has been fully scanned for proprietary dependencies, telemetry services, and closed APIs. 
**Result:** No proprietary or restricted packages were found.

---

## 2. Dependency Audit

### Mobile App (`mobile_app/pubspec.yaml`)
All Flutter dependencies are fully open-source and approved:
- `flutter_map` (Leaflet-based)
- `drift` / `sqlite3_flutter_libs` (SQLite)
- `http` / `dio` (Networking)
- `provider` (State Management)
*No Google Maps SDK or Firebase packages detected.*

### Backend / API (`backend/requirements.txt`)
All Python dependencies are standard FOSS:
- `fastapi` / `uvicorn` / `websockets`
- `SQLAlchemy` / `GeoAlchemy2` / `alembic`
- `redis` / `psycopg2-binary`

### P2P Node (`backend/p2p-node/go.mod`)
All Go dependencies are standard FOSS:
- `go-libp2p`
- `go-libp2p-pubsub`
- `gorilla/websocket`

---

## 3. Remediation & Compliance Actions Taken

### 3.1 API Usage Compliance
- **Nominatim Reverse Geocoding:** Verified the presence of the required `User-Agent` header (`OpenRescue/1.0`). Added a 1-request-per-second rate limiter to strictly respect Nominatim's usage policy.

### 3.2 UI Attributions
- **Map Attribution:** `RichAttributionWidget` added to the `FlutterMap` widget to explicitly display "© OpenStreetMap contributors" in the UI.

### 3.3 Telemetry and Tracking
- Conducted codebase scan for `analytics`, `crashlytics`, and `telemetry`. No instances found. User data strictly remains on-device or circulates solely through the secure P2P network.

### 3.4 Offline Verification
- Routing operates locally via the OSRM Docker container.
- Map tiles fallback locally via the `FallbackFileTileProvider`.
- Real-time incident syncing operates entirely via mDNS P2P without requiring a backend server.

---

## 4. Licensing
- **License:** Project is licensed under `GPL-3.0` (present in repository root).
- **Notices:** A top-level `NOTICE` file has been added explicitly detailing attributions for OpenStreetMap, OSRM, and libp2p.
