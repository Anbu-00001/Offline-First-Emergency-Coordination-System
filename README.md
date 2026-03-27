<!-- 1. Top Badges -->
![License: GPL-3.0](https://img.shields.io/badge/License-GPL_3.0-blue.svg)
![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go)
![Offline-First](https://img.shields.io/badge/Offline--First-Fully_Supported-success)
![PRs Welcome](https://img.shields.io/badge/PRs-Welcome-brightgreen.svg)

<!-- 2. Hero Section -->
<div align="center">
  <img src="https://placehold.co/800x200/1e1e2e/02569B?text=OpenRescue&font=Montserrat" alt="OpenRescue Banner" width="100%" />
</div>

<!-- 3. Title & Tagline -->
# OpenRescue

> **Built for when the internet fails — enabling real-time emergency coordination through decentralized, offline-first technology.**

## System Workflows Overview

"OpenRescue is built as a decentralized, offline-first system where each component plays a critical role in ensuring reliability during network failures. The following diagrams break down how data flows across the system."

### 1. Complete System Architecture

```mermaid
flowchart LR

A[Flutter App Device]

DB[Local DB - Drift]
P2P[Go libp2p Daemon]
OSRM[OSRM Server]
Tiles[Offline Tile Storage]

CRDT[CRDT Merge Engine]
Poly[Polygon Generator]
Route[Routing Controller]
UI[Map UI]

Other[Other Devices]

A --> DB
A --> P2P
A --> OSRM
A --> Tiles

P2P --> Other

DB --> CRDT
CRDT --> Poly
Poly --> Route
Route --> OSRM

Tiles --> UI
OSRM --> UI
```

"This diagram shows how each device operates independently while still syncing with nearby devices using peer-to-peer communication."

### 2. Peer-to-Peer Incident Sync

```mermaid
sequenceDiagram
participant A as Device A
participant P as P2P Network
participant B as Device B

A->>P: Broadcast Incident
P->>B: Deliver Incident
B->>B: CRDT Merge
B->>B: Store in Local DB
```

"Incidents are broadcast over a decentralized mesh network, ensuring data reaches nearby devices without any central server."

### 3. Conflict Resolution & Sync (CRDT + HEAD)

```mermaid
flowchart TD
A[Incoming Incident] --> B[Check Local State]
B --> C{Conflict?}
C -->|Yes| D[Apply CRDT Rules]
C -->|No| E[Accept Directly]
D --> F[Update Local DB]
E --> F
F --> G[Update HEAD]
```

"This ensures all devices converge to the same state without conflicts, even if updates arrive out of order."

### 4. Deterministic Danger Zone Generation

```mermaid
flowchart TD
A[Incident Data] --> B[Polygon Generator]
B --> C[Deterministic Shape]
C --> D[Polygon Cache]
D --> E[Routing Avoidance]
```

"Polygons are generated locally using deterministic logic, ensuring all devices produce identical danger zones without sharing geometry."

### 5. Offline Routing with OSRM

```mermaid
flowchart LR
A[User Location] --> B[Routing Controller]
B --> C[OSRM Local Server]
C --> D[Route Geometry]
D --> E[Polyline Render]
```

"Routing is computed locally using OSRM, allowing navigation even without internet connectivity."

### 6. Offline Map System

```mermaid
flowchart TD
A[GPS Location] --> B[Tile Prefetch Service]
B --> C[Download Tiles]
C --> D[Local Storage]
D --> E[Flutter Map]
```

"Map tiles are downloaded in advance and stored locally, enabling seamless offline map usage."

---

<!-- 5. Table of Contents -->
## Table of Contents
- [The "Oh Crap" Scenario](#the-oh-crap-scenario)
- [Key Features (Show, Don't Tell)](#key-features-show-dont-tell)
- [Architecture & Data Flow](#architecture--data-flow)
- [Tech Stack](#tech-stack)
- [Frictionless Quickstart](#frictionless-quickstart)
- [Hackathon Journey & Roadmap](#hackathon-journey--roadmap)
- [Closing & License](#closing--license)

---

<!-- 6. The "Oh Crap" Scenario -->
## The "Oh Crap" Scenario

In the aftermath of a disaster, centralized communication infrastructure is the first to collapse. Fiber lines are cut, cell towers lose power, and the internet becomes an unreliable luxury. When this happens, **centralized systems fail precisely when they are most needed**. Coordination breaks down, leaving responders and victims in isolation, drastically increasing response times and directly impacting lives.

**OpenRescue is not just software—it's a life-saving tool.** It rethinks emergency response by removing dependence on a central point of failure. It empowers first responders to collaborate effectively even in absolute dead zones, where traditional technology fails.

---

<!-- 7. Key Features -->
## Key Features (Show, Don't Tell)

*   🗺️ **Offline Maps**: *Ground truth is always visible.* Pre-fetched tiles and an MBTiles provider mean mapping is fully functional without internet.
*   🧭 **Offline Routing via OSRM**: *Navigating around hazards in a dead zone.* Powered by a local Docker-based OSRM engine utilizing OpenStreetMap data entirely offline.
*   📡 **P2P Incident Sync via libp2p**: *Information spreads like fire across the network.* Leverages robust GossipSub mesh networking to automatically broadcast incident reports to nearby peers.
*   🔗 **CRDT Conflict Resolution**: *Multiple chaotic updates condense into one truth.* Uses Conflict-free Replicated Data Types (CRDTs) to ensure eventual consistency locally without ever touching a central server.
*   ⚠️ **Deterministic Danger Zones**: *Universal situational awareness.* Hazard polygons are computed identically across all devices using pure geometric functions, ensuring safety bounds match without network overhead.

---

<!-- 8. Architecture & Data Flow -->
## Architecture & Data Flow

<details>
<summary><b>🌐 Diagram 1: The Ad-Hoc Mesh Network Topology</b></summary>

```mermaid
graph TD
    A[Device A] <-->|GossipSub P2P| B[Device B]
    B <-->|GossipSub P2P| C[Device C]
    C <-->|GossipSub P2P| D[Device D]
    D <-->|GossipSub P2P| A
    A -.->|Broken Link x| Cloud[Central Cloud Server]
    B -.->|Broken Link x| Cloud
```

</details>

<details>
<summary><b>🛠️ Diagram 2: The Local Device Stack (Flutter + Go + OSRM)</b></summary>

```mermaid
flowchart LR
    UI[Flutter UI] <--> DB[Drift Local DB]
    DB --> PG[Polygon Generator]
    PG --> OSRM[Local OSRM Container]
    OSRM --> UI
    DB <--> P2P[libp2p Daemon]
```

</details>

<details>
<summary><b>🔄 Diagram 3: CRDT Conflict Resolution (How 2 Devices Merge Truth)</b></summary>

```mermaid
flowchart TD
    subgraph Disconnected
        A[Device A] -->|Create Incident| Inc1[Bridge Out]
        B[Device B] -->|Create Incident| Inc2[Road Block]
    end

    subgraph Connection Restored
        Inc1 -.->|P2P GossipSub| Merged
        Inc2 -.->|P2P GossipSub| Merged
    end

    subgraph Merged Truth via CRDT
        Merged[CRDT Merge Engine]
        Merged --> StateA[Device A State: Bridge Out + Road Block]
        Merged --> StateB[Device B State: Bridge Out + Road Block]
    end
```

</details>

<details>
<summary><b>⚠️ Diagram 4: Deterministic Danger Zone Generation</b></summary>

```mermaid
flowchart LR
    ID[Raw P2P Incident Coordinates] -->|Parse| Math[Geometric Math Engine]
    Math -->|Apply Radial Buffer| Poly[Generate Polygon Vertices]
    Poly --> DB[Map to GeoJSON / Local DB]
    DB --> MapUI[Render on Flutter Map]
    DB --> OSRM[Feed to OSRM Avoidance List]
```

</details>

<details>
<summary><b>📡 Diagram 5: P2P Incident Propagation Sequence</b></summary>

```mermaid
sequenceDiagram
    participant AppA as App A
    participant P2P as Mesh Network
    participant AppB as App B
    participant OSRM as OSRM B

    AppA->>AppA: Log Incident
    AppA->>AppA: Assign Lamport Timestamp
    AppA->>P2P: Broadcast via GossipSub
    P2P->>AppB: Receive Incident
    AppB->>AppB: Resolve CRDT
    AppB->>AppB: Generate Polygon
    AppB->>OSRM: Request Route Avoidance
    OSRM-->>AppB: Return Safe Route
    AppB->>AppB: Update Map UI
```

</details>

<details>
<summary><b>⚡ Diagram 6: System Lifecycle & Offline Fallback</b></summary>

```mermaid
stateDiagram-v2
    [*] --> Online
    Online --> FetchingMBTiles: Pre-fetching Map Tiles
    FetchingMBTiles --> Online
    
    Online --> NetworkFailure: Disaster Strikes
    NetworkFailure --> MeshMode
    
    state MeshMode {
        [*] --> LocalRouting
        LocalRouting --> P2P_Sync
        P2P_Sync --> CRDT_Merge
        CRDT_Merge --> MapUpdate
        MapUpdate --> [*]
    }
```

</details>

---

<!-- 9. Tech Stack -->
## Tech Stack

*   **Flutter**: Provides a **high-performance, cross-platform UI** ensuring we can rapidly deploy a unified responder interface to any mobile device in the field.
*   **Go (libp2p)**: The powerhouse behind our **decentralized peer-to-peer communication** layer, allowing ad-hoc mesh networking that works seamlessly without a central broker.
*   **OSRM (Open Source Routing Machine)**: Enables **fully offline routing** using raw local map data to dynamically calculate safe paths when external APIs are completely unreachable.
*   **Drift (SQLite)**: *Why Drift?* Reactive local storage ensures our mobile UI immediately updates the second P2P data syncs and CRDTs effectively merge, giving responders a flawless real-time experience.

---

<!-- 10. Frictionless Quickstart -->
## Frictionless Quickstart

We've made it as bulletproof as possible to boot up the decentralized stack locally.

### Prerequisites
- Docker & Docker Compose
- Flutter SDK
- Go 1.21+

> ⚠️ **Crucial Network Note:** The Flutter mobile app must connect to the machine's **local network IP address** (e.g., `192.168.1.X`), not `localhost`! If running on a physical device or emulator, update your config accordingly.

### Step 1: Spin up Local OSRM
Start the local offline routing engine.
```bash
docker compose -f docker-compose.osrm.yml up -d
```

### Step 2: Run Go P2P Node
Launch the decentralized mesh network daemon.
```bash
cd backend/p2p-node/ && go run main.go
```

### Step 3: Run Flutter App
Start the responder mobile interface.
```bash
cd mobile_app && flutter run
```

---

<!-- 11. Hackathon Journey & Roadmap -->
## Hackathon Journey & Roadmap

### Challenges We Conquered
Building a fully decentralized mesh system is inherently difficult. Our biggest hurdle was guaranteeing **CRDT convergence over flaky P2P connections**. Ensuring that incident states deterministically matched across all devices—without duplicate or orphaned polygons when reconnecting after signal drops—required intense synchronization logic. We also had to heavily focus on battery drain optimization since constant mesh broadcasting severely impacts mobile devices.

### What's Next 🚀
*   **Hardware Integration**: Extending the P2P layer over **LoRaWAN** hardware modules to cover massive geographical distances during complete cellular grid blackouts.
*   **Drone Node Relays**: Integrating aerial drones to act as temporary high-altitude P2P mesh relay points, expanding network coverage to otherwise isolated ground units.

---

<!-- 12. Closing & License -->
## Closing & License

OpenRescue is built with **Architectural Sovereignty**: 
- **100% Open-Source**: Every layer is fully FOSS compliant.
- **No Proprietary APIs**: No Google Maps, Firebase, or closed SDKs.
- **Fully Offline**: Designed to work where big-tech infrastructure ends.

Licensed under the [GPL-3.0 License](LICENSE).  
© OpenStreetMap contributors  
*Hackathon built. Real-world ready.*
