------------------------------------------------------------
OFFLINE-FIRST EMERGENCY COORDINATION SYSTEM
Development Timeline
------------------------------------------------------------

DAY 1:
Date:
Focus: Project Initialization & Authentication Setup

Tasks Completed:
- Initialized backend project structure
- Configured database connection
- Implemented user registration endpoint
- Implemented login endpoint
- Setup JWT-based authentication
- Created basic user model

Technical Details:
- Backend framework initialized
- Database integrated and connected
- Authentication flow secured using JWT
- Role foundation prepared for future authorization logic

Files Created/Modified:
- Main backend application file
- User model file
- Authentication routes file
- Database configuration file

Notes:
- Core backend foundation established
- Ready to begin Incident Model implementation in Day 2

------------------------------------------------------------

------------------------------------------------------------
DAY 2:
Date:
Focus: Incident Model & API Endpoints

Tasks Completed:
- Created Incident database model (fields: id, reporter_id, type, description, latitude, longitude, timestamp, status)
- Implemented POST /incidents endpoint to create new incident reports
- Implemented GET /incidents endpoint to list and filter incidents
- Added basic role-based authorization checks for incident operations (user vs responder vs admin)
- Added API input validation and error handling for incident submission

Technical Details:
- Incident schema persisted in PostgreSQL
- Backend routes added under incidents/ or equivalent
- Authentication (JWT) integrated with incident endpoints
- Basic request/response validation using existing validation library

Files Created/Modified:
- PROJECT_TIMELINE.txt (this update)
- incident model file (backend)
- incidents routes/controller file (backend)
- database migration or schema file (if applicable)
- tests/test_incidents.py (if test scaffolding added)

Notes:
- Core reporting functionality now available
- Next: implement WebSocket real-time notifications and frontend incident form (Day 3)

------------------------------------------------------------

------------------------------------------------------------
DAY 3:
Date:
Focus: FastAPI Core Architecture, Secure JWT Authentication & CAP XML Parser

Tasks Completed:
- Restructured backend into production-ready modular FastAPI architecture
- Implemented centralized configuration system using environment variables
- Integrated SQLAlchemy database session management
- Implemented secure JWT-based authentication system (HS256)
- Added password hashing using bcrypt
- Created protected route with token validation
- Implemented CAP (Common Alerting Protocol) compliant XML parser service.
- Added API endpoint to parse CAP XML and return structured JSON

Technical Details:
- Modular app structure (core, models, schemas, api, services)
- OAuth2PasswordBearer with token expiry and subject claim
- Secure password hashing with passlib
- Dependency-injected DB session
- CAP XML parsing using xml.etree.ElementTree
- Namespace-aware XML parsing
- Structured output validation and error handling for malformed CAP documents

Files Created/Modified:
- app/main.py
- app/core/config.py
- app/core/security.py
- app/core/database.py
- app/models/user.py
- app/schemas/user.py
- app/api/routes/auth.py
- app/api/routes/protected.py
- app/services/cap_parser.py
- requirements.txt
- PROJECT_TIMELINE.txt (this update)

Notes:
- Backend now follows scalable architecture principles
- Authentication layer secured and production-ready
- CAP parsing module establishes interoperability with emergency alert standards
- Ready to proceed with Incident integration and WebSocket real-time system (Day 4)

------------------------------------------------------------

------------------------------------------------------------
DAY 4:
Date:
Focus: Incident Domain, Automatic Responder Assignment & Real-Time Notification System

Tasks Completed:
- Extended Incident model with priority, assignment tracking, status enum expansion, and geo-coordinates (float latitude/longitude)
- Implemented Responder model with availability tracking and workload management
- Created full Incident CRUD endpoints (POST /incidents, GET /incidents, PATCH /incidents/{id})
- Implemented offline-first batch sync endpoint (POST /sync/incidents) with deduplication and idempotent merge logic
- Developed Haversine-based nearest-responder allocation algorithm
- Integrated transactional assignment using SELECT FOR UPDATE to prevent race conditions
- Built in-process event bus for backend domain events
- Implemented async notification queue with retry mechanism
- Added WebSocket endpoint (/ws/alerts) for real-time broadcast of incident lifecycle events
- Achieved full test coverage for Day 4 modules (20 tests passing)

Technical Details:
- Haversine formula used for distance-based responder scoring
- Assignment scoring considers distance + workload weight
- Database-level row locking ensures safe concurrent assignment
- Offline sync supports client-side queued incident reconciliation
- WebSocket broadcast architecture connected via internal event bus
- Async notification queue processes events non-blocking
- Coordinate validation enforced at schema level
- Clean separation: models, schemas, services, events, API routes

Files Created/Modified:
- app/models/incident.py
- app/models/responder.py
- app/schemas/incident.py
- app/schemas/responder.py
- app/api/routes/incidents.py
- app/api/routes/sync.py
- app/api/routes/ws.py
- app/services/assignment.py
- app/services/notification_queue.py
- app/core/events.py
- tests/test_incidents.py
- requirements.txt
- PROJECT_TIMELINE.txt (this update)

Commit Reference:
- ef80cc8 → feat(backend): add incidents, responder assignment, websocket notifications (Day 4)

Notes:
- Backend now supports complete emergency reporting lifecycle
- Real-time notification infrastructure operational
- Offline-first synchronization logic implemented
- Concurrency-safe responder assignment established
- Foundation ready for frontend integration and offline UI sync (Day 5)

------------------------------------------------------------

------------------------------------------------------------
DAY 5:
Date:
Focus: Local Service Discovery using mDNS (Zeroconf)

Tasks Completed:
- Implemented local network service discovery using Python zeroconf (mDNS / DNS-SD)
- Created mDNS advertiser module for server nodes
- Server nodes now broadcast `_openrescue._tcp.local.` service on the LAN
- Implemented discovery client that listens for available servers on the same Wi-Fi network
- Added automatic resolution of discovered services to IP address and port
- Implemented service metadata using TXT records (node_type, node_id, version)
- Integrated discovery system with application startup lifecycle
- Added graceful registration and deregistration during startup and shutdown
- Implemented fallback-safe behavior if zeroconf is unavailable
- Added unit and integration tests for discovery events and service resolution

Technical Details:
- Service discovery implemented using python-zeroconf library
- Advertised service type: `_openrescue._tcp.local.`
- Discovery handled via ServiceBrowser with event callbacks
- In-memory registry tracks discovered servers with last-seen timestamps
- Discovery events bridged into internal event bus
- Clients can query available servers without needing IP configuration
- TXT records limited to non-sensitive metadata to maintain security

Files Created/Modified:
- app/services/mdns_advertiser.py
- app/services/mdns_discovery.py
- app/api/routes/mdns_debug.py
- app/core/config.py
- tests/test_mdns.py
- requirements.txt
- PROJECT_TIMELINE.txt (this update)

Notes:
- Enables zero-configuration discovery of local servers on shared networks
- Critical foundation for offline and disaster-network scenarios
- Allows client devices to locate coordination servers automatically
- Prepares infrastructure for peer-to-peer fallback and mesh-style discovery in future phases

------------------------------------------------------------

------------------------------------------------------------
DAY 6:
Date:
Focus: Local Peer Messaging & WebSocket Communication

Tasks Completed:
- Implemented local peer messaging system over WebSockets
- Added dedicated peer WebSocket endpoint allowing two devices to exchange text messages
- Integrated messaging with previously implemented mDNS discovery system
- Enabled clients to discover the local server automatically and connect without knowing its IP address
- Implemented message persistence and store-and-forward delivery logic
- Added message idempotency using unique message IDs to prevent duplicates
- Implemented delivery acknowledgements and queued message handling for offline recipients
- Created optional ephemeral pairing tokens to allow temporary device-to-device messaging sessions
- Added message synchronization endpoint for batched offline uploads
- Added tests covering WebSocket connections, message delivery, duplicate protection, and pairing flows

Technical Details:
- WebSocket endpoint `/ws/peer` supports authenticated users via JWT
- Optional pairing-token authentication enables ad-hoc device pairing
- Messages stored with unique UUID message IDs for idempotent processing
- Lamport-style counters used for lightweight ordering across peers
- Store-and-forward logic ensures messages are delivered when recipients reconnect
- Internal event bus used to trigger message delivery events
- Delivery receipts returned to senders confirming queued or delivered state
- Background worker attempts redelivery of queued messages
- Designed to work fully offline on a local network

Files Created/Modified:
- app/models/message.py
- app/models/pairing.py
- app/schemas/message.py
- app/services/peer_manager.py
- app/services/message_worker.py
- app/api/routes/peer_ws.py
- app/api/routes/pairing.py
- app/api/routes/sync_messages.py
- tests/test_peer_messaging.py
- PROJECT_TIMELINE.txt (this update)

Notes:
- Enables devices on the same local network to communicate via the discovered server
- Establishes the first peer-to-peer communication layer in the system
- Works even when internet connectivity is unavailable
- Prepares infrastructure for mesh networking and decentralized communication in future phases

------------------------------------------------------------

------------------------------------------------------------
DAY 7:
Date:
Focus: Week-1 Integration, Local Discovery Validation & WebSocket Demo

Tasks Completed:
- Integrated mDNS advertiser with backend so server is discoverable on local Wi-Fi
- Implemented demo flow and documentation validating two clients locate the server and exchange messages via WebSocket
- Created architecture diagram (Mermaid) and demo documentation explaining the mDNS→WebSocket flow and store-and-forward behavior
- Collected evidence files: API docs HTML, uvicorn/mdns log tails, simple client demo logs
- Created docs/week1_demo.md explaining the architecture and client communication
- Ensured DB migrations were applied (or create_tables() was executed) and fallbacked to local DB when container host 'db' was not resolvable during local dev

Files added:
- docs/week1_architecture.mmd
- docs/week1_architecture.png (if render available)
- docs/week1_demo.md
- docs/screenshots/* (api docs, mdns, websocket logs if available)
- PROJECT_TIMELINE.txt (this update)

Notes:
- The WebSocket endpoint may require authentication (JWT or pairing tokens). For demo, the recommended flow is: register → login → obtain JWT → connect to ws://<server>/ws/peer?token=<jwt> and exchange messages.
- If screenshots are not rendered in this environment, the saved HTML and logs are valid evidence and can be converted to PNG on a local machine.
------------------------------------------------------------

DAY 8:
Date:
Focus: Mobile Client Foundation (Flutter)

Summary:
Implemented the first operational version of the OpenRescue mobile client using Flutter.

Key Achievements:

* Created Flutter project under `mobile_app/`.
* Established clean architecture separation:

  * data layer (Drift database)
  * domain models
  * repository layer
  * UI layer.
* Implemented API client to communicate with FastAPI backend.
* Implemented WebSocket service for real-time messaging.
* Implemented local database initialization using Drift for offline storage.
* Added mDNS discovery client scaffold for locating the local server.
* Added incident repository with proper domain ↔ database mapping.
* Fixed type mismatch between database Incident entity and domain Incident model using mapper layer.
* Verified Flutter build and emulator deployment.
* Confirmed Flutter app launches successfully on Android emulator.

Dev Environment Work:

* Configured adb reverse for emulator → backend connectivity.
* Added helper scripts for development environment setup.
* Confirmed backend reachable via:
  http://127.0.0.1:8000

Architecture Status:
The system now supports:
Client (Flutter) → Repository → API/WebSocket → FastAPI Backend.

This establishes the base required for the upcoming geospatial engine integration.

Next Step:
Week 2 Day-9: Integrate MapLibre map engine and render incident markers on the map.

---

------------------------------------------------------------
DAY 9:
Date:
Focus: Map Rendering, Tile Architecture, and Offline Map Preparation

Summary:
Implemented the mobile map rendering layer for the OpenRescue mobile client. 
The system now displays OpenStreetMap tiles, incident markers, and provides a 
debug panel to inspect tile resolution and offline tile behavior.

Major Work Completed:

1. Map Rendering Engine
- Integrated flutter_map for raster tile rendering
- Replaced MapLibre GL Native due to OpenGL limitations on Linux development environments
- Ensured cross-platform compatibility using Skia rendering

2. Tile Architecture Implementation
Implemented a three-tier tile resolution system:

Tile Resolver Priority:
1. Local MBTiles tile server (offline mode)
2. Backend tile server
3. OpenStreetMap remote tiles (fallback)

This architecture ensures that the system continues functioning even if
external internet connectivity is unavailable.

3. Tile Layer Configuration
Configured FlutterMap TileLayer with:
- NetworkTileProvider
- Valid user agent
- Correct zoom constraints

Tile URL:
https://tile.openstreetmap.org/{z}/{x}/{y}.png

4. Incident Marker Layer
Connected the IncidentRepository stream to the map UI.

Flow:
IncidentRepository.watchIncidents()
        ↓
MapScreen
        ↓
MarkerLayer
        ↓
Interactive incident markers

5. Debug Diagnostics
Implemented an in-app Map Debug Panel that displays:
- active tile URL
- MBTiles detection
- tile server state
- tile request counters
- tile resolution logs

This panel helps diagnose tile failures and offline tile availability.

6. Offline Map Preparation
Prepared the architecture required for future MBTiles offline tile loading.

MBTiles Location (planned):
/data/user/0/<package>/app_flutter/tiles/dev.mbtiles

7. Map Interaction
Implemented:
- long-press to create incident with coordinates
- marker interaction
- bottom sheet UI actions (view / assign / navigate)

Architecture Established:

Mobile Map Stack

Flutter UI
     ↓
FlutterMap Renderer
     ↓
TileLayer
     ↓
MapService.resolveTileUrl()
     ↓
MBTiles → Backend → OSM Fallback
     ↓
IncidentRepository
     ↓
Drift Offline Database

Deliverables:
- fully functional mobile map screen
- OSM tile rendering
- incident marker visualization
- tile diagnostics panel
- offline tile architecture ready for MBTiles integration

------------------------------------------------------------

------------------------------------------------------------
DAY 10:
Date:
Focus: Dockerized Vector Tile Server & India Map Bounds

Summary:
Added a Dockerized tileserver-gl service for serving vector MBTiles
(with rasterized tile output) and restricted the default mobile map
view and panning to India geographic bounds. All changes are additive
and non-breaking — removing them reverts to the previous world-view
behavior.

Major Work Completed:

1. Dockerized Tileserver
- Created docker-compose.tileserver.yml with klokantech/tileserver-gl
- Configurable port via TILESERVER_PORT env var (default: 8080)
- Volumes mount docker/tileserver/data/ for MBTiles files

2. Helper Scripts
- scripts/prepare_mbtiles_india.sh:
  Creates data directory, downloads MBTiles if MBTILES_URL is set,
  otherwise prints instructions for obtaining India MBTiles
- scripts/start_tileserver.sh:
  Orchestrates preparation, container startup, health check, and logging

3. India Map Bounds (Mobile)
- Added geographic constants in map_service.dart:
  indiaSouth, indiaWest, indiaNorth, indiaEast,
  indiaCenter, indiaDefaultZoom, indiaBounds
- Updated MapOptions in map_screen.dart:
  initialCenter = indiaCenter (22.35°N, 78.67°E)
  initialZoom = 5.0, minZoom = 4, maxZoom = 18
  cameraConstraint = CameraConstraint.containCenter(bounds: indiaBounds)
- Panning restricted to India bounding box by default

4. Tests
- india_bounds_test.dart: validates bounds constants, center containment,
  major Indian cities within bounds, foreign cities outside bounds

5. Documentation
- docs/day10_vector_tiles.md: tile server setup, MBTiles sourcing,
  verification commands, ADB push for offline testing, config.json usage

Files Created:
- docker-compose.tileserver.yml
- docker/tileserver/README.md
- scripts/prepare_mbtiles_india.sh
- scripts/start_tileserver.sh
- docs/day10_vector_tiles.md
- mobile_app/test/india_bounds_test.dart

Files Modified:
- mobile_app/lib/features/map/map_service.dart
- mobile_app/lib/features/map/map_screen.dart
- .env.example
- PROJECT_TIMELINE.txt (this update)

Architecture:

Mobile App Tile Resolution (unchanged):
  MBTiles (on-device) → tileserver-gl (Docker) → OSM fallback

Map View:
  India center (22.35°N, 78.67°E) → zoom 5 → bounds-restricted panning

Notes:
- MBTiles files are NOT committed (too large); use prepare_mbtiles_india.sh
- Tileserver is developer-only; not required for app to function
- All existing tests, debug panel, and raster fallback remain intact
------------------------------------------------------------

------------------------------------------------------------
DAY 10 (Update):
Date:
Focus: Vector Tile Style, MapLibre Web Demo, OSRM Routing Scaffold & TILESERVER_URL

Summary:
Extended Day 10 with full vector tile style configuration, a browser-based
MapLibre GL JS preview, OSRM routing backend scaffolding, and TILESERVER_URL
support in the mobile app. All changes are additive and FOSS-compliant.

Major Work Completed:

1. Tileserver Style & Config
- Created docker/tileserver/styles/openrescue-style.json (Mapbox Style v8)
  Layers: water, landcover, buildings, roads, admin boundaries, place labels
- Created docker/tileserver/config.json for tileserver-gl
- Updated docker-compose.tileserver.yml with styles and config volume mounts
- Style is Maputnik-compatible for visual editing

2. MapLibre Web Demo
- Created web/maplibre-demo/index.html (standalone developer tool)
- MapLibre GL JS v4 (BSD-3-Clause license)
- India-bounded view with vector/raster toggle
- Auto-fallback to MapLibre public demotiles if tileserver offline
- No Node.js or build tools required

3. OSRM Routing Scaffolding
- Created docker/osrm/docker-compose.osrm.yml
  Official osrm/osrm-backend image, MLD algorithm, port 5000
- Created scripts/prepare_osrm_india.sh
  Downloads PBF if OSM_PBF_URL set, runs extract/partition/customize
  Prints detailed instructions with hardware recommendations if no URL
- Created scripts/start_osrm.sh
  Checks for .osrm files, starts container, health-checks, saves logs

4. Mobile TILESERVER_URL Integration
- Added --dart-define=TILESERVER_URL support in map_service.dart
- Resolution chain: MBTiles → TILESERVER_URL → config.json → OSM fallback
- Static getter configuredTileserverUrl for debug UI and tests
- Debug panel in map_screen.dart shows TILESERVER_URL status

5. Tests
- Created india_tileserver_test.dart:
  Verifies configuredTileserverUrl accessibility, OSM fallback,
  fallbackMode, bounds constants, tileServerPort, isUsingMBTiles

6. Documentation
- Expanded docs/day10_vector_tiles.md with MapLibre, OSRM, and
  TILESERVER_URL sections
- Updated .env.example with OSM_PBF_URL and OSRM_PORT
- Updated .gitignore for *.mbtiles, *.osrm*, *.osm.pbf, docker/osrm/data/

Files Created:
- docker/tileserver/styles/openrescue-style.json
- docker/tileserver/config.json
- web/maplibre-demo/index.html
- web/maplibre-demo/README.md
- docker/osrm/docker-compose.osrm.yml
- scripts/prepare_osrm_india.sh
- scripts/start_osrm.sh
- mobile_app/test/india_tileserver_test.dart

Files Modified:
- docker-compose.tileserver.yml
- docker/tileserver/README.md
- mobile_app/lib/features/map/map_service.dart
- mobile_app/lib/features/map/map_screen.dart
- docs/day10_vector_tiles.md
- .env.example
- .gitignore
- PROJECT_TIMELINE.txt (this update)

Architecture:

Tile Resolution (updated):
  MBTiles (on-device) → TILESERVER_URL → config → OSM fallback

OSRM Routing (new, optional):
  Client → OSRM Backend (Docker, port 5000) → Processed .osrm data

Web Preview (new):
  Browser → MapLibre GL JS → tileserver-gl (vector) or OSM CDN (raster)

Notes:
- No large data files committed (MBTiles, PBF, OSRM data)
- All new services are optional — existing functionality unchanged
- Only FOSS images and libraries used (tileserver-gl, osrm-backend, MapLibre)
- OSRM fully operational once PBF is processed; scripts handle the full flow

------------------------------------------------------------

------------------------------------------------------------
DAY 11:
Date:
Focus: Tile Prefetch Engine (5km Radius Caching)

Summary:
Implemented a robust tile prefetching system for the OpenRescue mobile app.
Responders can download map tiles for offline use around a specified location.
The system features persistent SQL-based queue management, async concurrent
downloads, exponential backoff with jitter, pause/resume/cancel, and a
dedicated UI screen accessible from the Map Debug Panel.

Major Work Completed:

1. Core Tile Math (tile_math.dart)
- Pure functions: lonToTileX, latToTileY, metersPerTile, tilesInRadius
- Deterministic tile set computation for any lat/lon, radius, zoom range
- Safety guardrail: kMaxTilesPerJob = 5000 tiles per job

2. Prefetch Database (Separate Drift DB)
- Dedicated SQLite database: openrescue_prefetch.sqlite
- PrefetchJobs table: job metadata, status tracking, progress
- PrefetchTiles table: individual tile records with retry tracking
- In-memory constructor for unit testing

3. Tiles Repository
- CRUD operations for jobs and tiles
- Batch enqueue, next-batch dequeue, status transitions
- Progress increment, failed tile requeue, status counts

4. Tile Prefetch Service
- Async download engine with 4 concurrent downloads (configurable)
- Exponential backoff: baseDelay × 2^(attempt-1) with ±20% jitter
- Atomic writes (temp file + rename) to prevent partial files
- Disk-existence check to skip already-cached tiles
- Per-job pause/resume/cancel via flag checks
- Stream-based progress updates via Drift watch queries
- resumePendingJobs() for background fetch integration

5. Prefetch UI
- PrefetchController (ChangeNotifier) wrapping the service
- PrefetchScreen with radius/zoom config, tile estimation,
  start/pause/resume/cancel, progress bar, status badges
- Accessible from Map Debug Panel via "Tile Prefetch" button

6. Tests
- tile_math_test.dart: 22 tests covering tile X/Y conversion,
  metersPerTile scaling, tilesRadius, tilesInRadius, totalTilesForJob
- prefetch_queue_test.dart: in-memory Drift tests for job lifecycle,
  tile enqueue/dequeue, status transitions, progress tracking, cleanup

7. Provider Integration
- PrefetchDatabase, TilesRepository, TilePrefetchService,
  PrefetchController added to main.dart provider tree
- MapScreen debug panel includes Tile Prefetch navigation

Files Created:
- mobile_app/lib/core/map/tile_math.dart
- mobile_app/lib/data/db/prefetch_database.dart
- mobile_app/lib/data/db/prefetch_database.g.dart (generated)
- mobile_app/lib/data/tiles_repository.dart
- mobile_app/lib/services/tile_prefetch_service.dart
- mobile_app/lib/features/prefetch/prefetch_controller.dart
- mobile_app/lib/features/prefetch/prefetch_screen.dart
- mobile_app/test/tile_math_test.dart
- mobile_app/test/prefetch_queue_test.dart
- docs/day11_prefetch.md

Files Modified:
- mobile_app/lib/main.dart (provider wiring)
- mobile_app/lib/features/map/map_screen.dart (debug panel nav)
- PROJECT_TIMELINE.txt (this update)

Architecture:

Tile Storage:
  appDocDir/tiles/{z}/{x}/{y}.png

Download Chain:
  TilePrefetchService → HTTP GET → atomic write → SQL update
  4 concurrent downloads, 5 retry attempts, exponential backoff

Persistence:
  openrescue_prefetch.sqlite (separate from main DB)
  Survives app restarts, supports pause/resume

Notes:
- Default max 5000 tiles per job (prevents accidental large downloads)
- 5km radius at zooms 12–16 ≈ 565 tiles (well within limit)
- Background fetch scaffolded but requires background_fetch package
- All downloads use configured tile URL from MapService
- Existing raster fallback and MBTiles logic unchanged

------------------------------------------------------------

DAY 12 — Responder Activation & Tile Prefetch Trigger

Summary:
Implemented the Responder Activation system which triggers offline tile prefetching when a responder marks themselves as ACTIVE.

Architecture Components Added:

• ResponderStateService
  - Manages responder mode (inactive / active)
  - Persists state using SharedPreferences
  - Emits state changes via Stream<ResponderState>

• LocationService
  - Retrieves device GPS coordinates
  - Handles permission checks
  - Provides LatLng used for prefetch center

• ResponderController
  - Listens to responder state transitions
  - On ACTIVE state:
        retrieves device location
        triggers TilePrefetchService.startPrefetchForRadius()
  - Ensures prefetch runs once per activation session

• TilePrefetchService Extension
  - Added method startPrefetchForRadius(center, radiusMeters)
  - Calculates tile coverage for zoom levels 14–16
  - Enqueues tiles into Drift-backed PrefetchQueue
  - Maintains asynchronous background downloading

• ResponderToggle UI
  - FloatingActionButton.extended
  - Allows users to toggle responder mode
  - Integrated into MapScreen above the incident FAB

Testing & Verification:

• Unit tests added:
  responder_prefetch_test.dart

• Tests confirm:
  - activation triggers location lookup
  - tile prefetch is invoked
  - PrefetchQueue receives tiles
  - activation runs once per session

Verification Results:

flutter analyze → PASS  
flutter test → PASS  
Architecture integrity → PASS  

Notes:
No backend changes were introduced. Existing modules such as MapService, MBTilesTileServer, incident_repository, and marker rendering remain unaffected.

------------------------------------------------------------

DAY 13 — OSRM Routing Integration

Summary:
Integrated the OSRM routing engine into the OpenRescue mobile application to enable navigation between the responder's current location and an incident location.

Architecture Components Added:

• OSRMService
  - Responsible for querying the OSRM routing API
  - Sends HTTP requests to /route/v1/driving endpoint
  - Parses GeoJSON route geometry
  - Converts coordinates to List<LatLng> for map rendering

• RouteController
  - Manages route state for the UI
  - Exposes Stream<List<LatLng>> routeStream
  - Requests routes from OSRMService
  - Emits updated routes for reactive map rendering

• Map Rendering Integration
  - Added PolylineLayer to flutter_map
  - Route drawn between tile layer and marker layer
  - Uses List<LatLng> emitted by RouteController

• Navigation Trigger
  - "Navigate" button added to incident popup
  - Retrieves current location via LocationService
  - Destination uses incident coordinates
  - Calls RouteController.requestRoute()

Testing & Verification:

• Unit tests implemented in:
  osrm_service_test.dart

• Tests verify:
  - route API parsing
  - coordinate conversion to LatLng
  - correct handling of empty routes

Verification Results:

flutter analyze → PASS  
flutter test → PASS  
Architecture integrity → PASS  

Notes:
No changes were made to backend services. Existing components including MapService, TilePrefetchService, PrefetchQueue, MBTilesTileServer, and IncidentRepository remain unchanged.

Routing currently targets a configurable OSRM endpoint defined in the mobile configuration.

------------------------------------------------------------

DAY 14 — System Stabilization & Bug Fixes

Summary:
Technical summary of the fixes and stabilization efforts completed to ensure a robust mobile experience and reliable mapping subsystems.

Fixes Completed:
• Removed incorrect minimap overlay rendering in FlutterMap UI.
• Fixed GPS location pointer to accurately center on user coordinates.
• Implemented functional incident detail view with reverse geocoding and landmark resolution.
• Implemented responder assignment interface using mock responder proximity data.
• Fixed tile prefetch worker status tracking and ensured persistent queue integrity.
• Verified offline tile storage path and local tile prioritization.

------------------------------------------------------------

WEEK 2 SUMMARY — Offline Mapping & Navigation Infrastructure

Major Technical Achievements:
• Integrated FlutterMap with OpenStreetMap raster tiles.
• Implemented offline tile caching and tile-prefetch system using geographic radius calculation.
• Added persistent download queue with concurrency control for tile workers.
• Integrated OSRM routing backend for local navigation.
• Implemented responder mode enabling incident navigation workflow.
• Built modular services architecture (MapService, RoutingService, PrefetchQueue, IncidentRepository).
• Established offline-first mapping pipeline for disaster scenarios.

------------------------------------------------------------

DAY 15 — Decentralized P2P Communication Layer

Summary:
Implemented the foundational decentralized peer-to-peer messaging layer using a local Go daemon with GossipSub for discovery and communication.

Implementation Details:
• Implemented local P2P daemon using Go and go-libp2p.
• Enabled peer discovery using mDNS for automatic device discovery on LAN networks.
• Implemented GossipSub pub-sub topic: openrescue.incident for decentralized incident broadcasting.
• Added HTTP broadcast endpoint (POST /broadcast) for Flutter integration.
• Added WebSocket event stream (ws://localhost:7000/events) for receiving peer messages.
• Integrated Flutter P2PService to send and receive incident events.
• Connected P2P messaging with IncidentRepository to persist peer incidents in the Drift database.
• Verified successful broadcast pipeline: device A incident → GossipSub → device B database insertion.

Technical Architecture Note — Why Go is used for the P2P Mesh Layer

OpenRescue uses Go to implement the decentralized peer-to-peer communication layer for several architectural reasons:

• Go provides mature implementations of libp2p through the go-libp2p library, which powers the GossipSub pub-sub protocol used for decentralized messaging.

• Flutter/Dart currently lacks a stable and production-ready libp2p implementation. Implementing P2P networking directly in Flutter would require building low-level networking primitives manually.

• Go is highly efficient for network daemons due to its lightweight goroutines and built-in concurrency model. This makes it ideal for managing multiple peer connections and message propagation across a mesh network.

• The Go P2P daemon runs as a lightweight background service that handles:
  * peer discovery using mDNS
  * GossipSub message broadcasting
  * peer connection management
  * message propagation across devices

• The Flutter mobile application communicates with this daemon through a simple HTTP and WebSocket bridge. This clean separation allows the UI layer to remain simple while the networking complexity is handled by Go.

Architecture overview:

Flutter Mobile App
       ↓
P2PService (WebSocket + HTTP bridge)
       ↓
Go P2P Daemon
       ↓
go-libp2p GossipSub Mesh Network
       ↓
Other OpenRescue devices

This design keeps the networking layer modular, open-source, and highly scalable while maintaining compatibility with FOSS networking standards.

------------------------------------------------------------

DAY 16 — P2P Message Stabilization & Deduplication Layer

Summary:
Stabilized the P2P messaging system to ensure reliable incident propagation across devices. Introduced a standardized network message envelope, dual-layer deduplication (network + database), an outgoing message queue for offline resilience, and enhanced peer network logging.

Architecture Components Added:

• NetworkEnvelope (Go + Dart)
  - Standardized message format: msg_id, msg_type, origin_peer, timestamp, payload
  - Forward-compatible: unknown fields in payload are preserved
  - Supports future msg_type values (incident_update, incident_resolve)

• Server-Side Dedup Cache (Go daemon)
  - Ring-buffer based cache in PubSubManager (1000 entries)
  - O(1) duplicate detection using map + circular buffer
  - Self-echo prevention for locally broadcast messages

• MessageCache (Flutter)
  - LRU dedup cache using LinkedHashSet (1000 entries)
  - Prevents GossipSub loop duplicates at the network layer
  - Integrated into P2PService WebSocket message handler

• Repository Protection (Flutter)
  - _handleIncomingP2PIncident uses incident_id from envelope payload as DB primary key
  - Checks for existing records before insertion
  - Prevents DB duplicates even if network dedup misses

• Outgoing Message Queue (Flutter)
  - Messages queued locally when HTTP POST to daemon fails
  - Queued messages flushed in order upon WebSocket reconnection
  - Ensures no messages are lost during transient connectivity issues

• Enhanced Logging
  - Go daemon: [Discovery], [PubSub], [API] prefixed structured logs
  - Logs peer discovered/connected, message published/received/duplicate
  - Flutter: [P2P] and [IncidentRepo] debug logs for broadcast/receive/dedup

Files Created:
- mobile_app/lib/models/network_envelope.dart
- mobile_app/lib/services/message_cache.dart

Files Modified:
- backend/p2p-node/pubsub.go (NetworkEnvelope struct, dedup cache)
- backend/p2p-node/api.go (envelope-aware handlers)
- backend/p2p-node/main.go (channel type update)
- backend/p2p-node/discovery.go (enhanced logging)
- backend/p2p-node/go.mod, go.sum (uuid dependency)
- mobile_app/lib/services/p2p_service.dart (envelope, dedup, queue)
- mobile_app/lib/data/repositories/incident_repository.dart (DB dedup)
- mobile_app/test/map_screen_widget_test.dart (constructor fix)
- PROJECT_TIMELINE.txt (this update)

Message Flow:
  Device A creates incident
    ↓
  P2PService wraps in NetworkEnvelope (msg_id, payload)
    ↓
  POST /broadcast → Go daemon stamps origin_peer
    ↓
  GossipSub broadcast to peers
    ↓
  Device B Go daemon dedup check → forward to WebSocket
    ↓
  Flutter P2PService MessageCache dedup → parse payload
    ↓
  IncidentRepository DB-level dedup → insert if new
    ↓
  Incident marker appears on map

Verification:
  Go build → PASS
  Flutter analyze → PASS (only pre-existing info-level naming warnings)

------------------------------------------------------------

DAY 17 — Initial State Synchronization Layer

Summary:
Implemented the initial state synchronization layer so that when a new device joins the mesh network, it automatically fetches existing incidents from connected peers. This ensures late-joining devices have a complete view of the current incident landscape without relying on a central server.

Architecture Components Added:

• Peer Connection Hook (Go daemon)
  - When a new peer is discovered and connected via mDNS, the daemon
    automatically broadcasts a sync_request message to the network.
  - PubSubManager is now initialized before mDNS discovery to enable this.
  - sync_request is triggered once per peer connection event.

• Sync Request Handling (Flutter)
  - P2PService listens for sync_request messages via dedicated stream.
  - IncidentRepository responds by fetching all local incidents from the
    Drift database and sending them as batched sync_response messages.

• Sync Response Format
  - Incidents are sent in batches of 50 per message to avoid network flooding.
  - Each sync_response envelope contains:
    msg_id, msg_type: "sync_response", origin_peer, payload: { incidents: [...] }

• Sync Response Handling (Flutter)
  - P2PService routes sync_response messages to a dedicated stream.
  - IncidentRepository parses incident payloads and inserts each one
    through the existing _handleIncomingP2PIncident deduplication logic.
  - DB-level dedup prevents duplicate insertions.

• Peer Sync State Map
  - P2PService maintains a _peerSyncState map (peer_id → sync_completed).
  - Prevents responding to duplicate sync_request messages from the same peer.
  - Prevents infinite sync loops across the network.

• Deduplication Compatibility
  - All sync messages pass through MessageCache (Flutter) and dedupCache (Go).
  - sync_response msg_ids are added to the dedup cache before sending.

Message Flow (Late-Join Sync):
  Device B connects to mesh via mDNS
    ↓
  Go daemon broadcasts sync_request (SYNC_REQUEST_SENT)
    ↓
  Device A Flutter receives sync_request
    ↓
  IncidentRepository fetches all local incidents
    ↓
  P2PService sends batched sync_response (SYNC_RESPONSE_SENT)
    ↓
  Device B Flutter receives sync_response (SYNC_RESPONSE_RECEIVED)
    ↓
  IncidentRepository merges incidents via dedup logic (INCIDENT_MERGED)
    ↓
  Incidents appear on Device B map

Logging Added:
  Go daemon:
    [Discovery] SYNC_REQUEST_SENT
  Flutter:
    [P2P] SYNC_REQUEST_RECEIVED
    [P2P] SYNC_RESPONSE_RECEIVED
    [P2P] SYNC_RESPONSE_SENT
    [IncidentRepo] SYNC_RESPONSE_SENT
    [IncidentRepo] SYNC_RESPONSE_RECEIVED
    [IncidentRepo] INCIDENT_MERGED

Files Modified:
- backend/p2p-node/main.go (reordered PubSub init before Discovery)
- backend/p2p-node/discovery.go (sync_request broadcast on peer connect)
- mobile_app/lib/services/p2p_service.dart (sync streams, peer state map, batch response)
- mobile_app/lib/data/repositories/incident_repository.dart (sync handlers, getAllIncidents)
- PROJECT_TIMELINE.txt (this update)

Verification:
  Go build → PASS
  Flutter analyze → PASS

------------------------------------------------------------

DAY 18:
Date:
Focus: Causal Message Ordering (GossipLog)

Summary:
Implemented Lamport logical clocks for distributed event ordering and introduced message dependency tracking using `prev_msg_ids`. Built the GossipLog service to store and validate the message DAG. Added a pending queue to handle out-of-order message delivery, resulting in messages being applied only when their dependencies are satisfied. Prevented invalid state transitions in distributed incident updates and established the foundation for causal consistency and future CRDT logic.

Tasks Completed:
- Implemented Lamport logical clocks for distributed event ordering
- Introduced message dependency tracking using prev_msg_ids
- Built GossipLog service to store and validate message DAG
- Added pending queue to handle out-of-order message delivery
- Ensured messages are applied only when dependencies are satisfied
- Prevented invalid state transitions in distributed incident updates
- Established foundation for causal consistency and future CRDT logic

Technical Details:
- Go backend extended with GossipLog struct handling log, pending queue, and HEADS tracking
- Envelope extended with Clock and PrevMsgIDs
- Dart frontend mirrored GossipLog logic in GossipLogService
- P2PService routes causal messages (create, resolve) through GossipLog, while bulk syncing runs parallel

Files Created/Modified:
- backend/p2p-node/gossip_log.go
- backend/p2p-node/pubsub.go
- backend/p2p-node/main.go
- mobile_app/lib/models/network_envelope.dart
- mobile_app/lib/services/gossip_log_service.dart
- mobile_app/lib/services/p2p_service.dart
- mobile_app/test/gossip_log_service_test.dart

Notes:
- Full system verification (Day 15-18) successfully passed, confirming P2P broadcast, deduplication, sync, and causal consistency.

DAY 19:
Date:
Focus: Head-Based Synchronization

Content:
• Implemented HEAD exchange protocol to compare distributed state across peers
• Built missing message detection using DAG head comparison
• Added message_request and message_response protocols
• Ensured forward causal delivery using dependency-aware ordering
• Integrated sync with GossipLog for consistency-safe application
• Prevented redundant data transfer by requesting only missing messages
• Enabled full peer-to-peer state convergence without central server

------------------------------------------------------------

DAY 20:
Date:
Focus: Week 3 Day 20 – Robust Sync Engine & Convergence Guarantees

Content:
• Introduced sync session management per peer to track request/response lifecycle and prevent redundant operations
• Implemented request deduplication ensuring previously requested message IDs are not re-fetched
• Added batch-based message_request protocol to improve network efficiency and reduce overhead
• Enforced bounded synchronization using iteration limits to prevent infinite request loops
• Defined deterministic sync termination conditions when no missing messages remain
• Integrated response deduplication to avoid repeated message transfers within a session
• Strengthened forward causal delivery by ensuring topological ordering before message propagation
• Added retry control with delay strategy to handle network latency without flooding peers
• Implemented structured logging for sync lifecycle (start, progress, completion, termination)
• Verified multi-device convergence without redundant transfers or inconsistent states

------------------------------------------------------------


------------------------------------------------------------

DAY 21:
Week 3 Day 21 – CRDT-Based Conflict Resolution

Content:

• Implemented CRDT-based conflict resolution for decentralized incident state management
• Designed monotonic state machine (PENDING → ASSIGNED → RESOLVED) with strict priority enforcement
• Integrated logical clock-based tie-breaking for deterministic state resolution
• Prevented state rollback under concurrent and out-of-order updates
• Embedded CRDT merge logic within IncidentRepository ensuring compatibility with GossipLog causal ordering
• Enabled conflict-free convergence across multiple peers without central coordination
• Added structured logging for CRDT operations (merge applied, state updated, conflict resolved)
• Validated system using comprehensive multi-device and multi-conflict test scenarios
• Ensured deterministic convergence under concurrent updates across distributed peers

---

Day 25: Distance-Based Avoidance Routing

Implemented a route safety evaluation layer integrated with the existing OSRM routing pipeline. Each generated route is validated against active incidents using a Haversine distance threshold to detect proximity risks. Unsafe routes trigger alternative route evaluation, ensuring responders are not guided through hazardous zones. The implementation is fully offline, FOSS-compliant, and does not modify the OSRM backend.

Day 26: Polygon-Based Spatial Avoidance

Enhanced routing intelligence by introducing polygon-based danger zone modelling. Incident locations are converted into dynamic polygons, and routes are evaluated using point-in-polygon and polyline intersection logic. A hybrid validation system (distance + polygon) ensures accurate avoidance of complex hazard regions. This upgrade maintains architectural stability, avoids external dependencies, and preserves full offline capability.

---

Day 27: Deterministic Polygon Synchronization

Implemented distributed polygon consistency using deterministic derivation instead of network transmission. Each device generates identical danger zones from incident data using a pure polygon generation function, ensuring zero divergence across the mesh network. Integrated with the existing P2P GossipSub and CRDT pipeline, guaranteeing consistent routing avoidance behavior across all devices without transmitting geometry data.

---

Day 28: Full FOSS Compliance Audit

Performed a comprehensive FOSS audit across all project layers. Verified that every dependency is open-source (GPL, MIT, Apache, BSD). Replaced any proprietary candidates with FOSS alternatives (OpenStreetMap, OSRM, libp2p). Ensured proper licensing with a GPL-3.0 LICENSE file and a detailed NOTICE file for attributions. Updated UI to include mandatory "© OpenStreetMap contributors" attribution. Verified 100% offline functionality for maps, routing, and P2P synchronization.
