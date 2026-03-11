# Day 11 — Tile Prefetch Engine (5km Radius Caching)

Offline tile prefetching system for OpenRescue mobile. Downloads tile images to device storage for offline use when connectivity is available.

---

## Architecture

```
User triggers prefetch
       ↓
PrefetchController (ChangeNotifier)
       ↓
TilePrefetchService
  ├── Compute tile set (tile_math.dart)
  ├── Enqueue tiles (PrefetchDatabase / Drift)
  └── Download loop (async, 4 concurrent)
         ├── Check disk → skip
         ├── HTTP GET → atomic write
         ├── Retry w/ exponential backoff
         └── Persist progress (SQL)
       ↓
Tiles on disk: appDir/tiles/{z}/{x}/{y}.png
```

### Tile Math

Web Mercator / SlippyMap tile calculation:
- `metersPerTile(zoom, lat) = 156543.03 × cos(lat×π/180) × 256 / 2^zoom`
- `tilesRadius = ceil(radiusMeters / metersPerTile)`
- Tile set = all tiles within `[cx ± r, cy ± r]` for each zoom level

**5km radius example at India center (22.35°N, 78.67°E):**

| Zoom | Tile Size (~m) | Tiles Radius | Tiles at Zoom |
|------|---------------|--------------|---------------|
| 12   | ~9600m        | 1            | ~9             |
| 13   | ~4800m        | 2            | ~25            |
| 14   | ~2400m        | 3            | ~49            |
| 15   | ~1200m        | 5            | ~121           |
| 16   | ~600m         | 9            | ~361           |
| **Total** |          |              | **~565**       |

---

## Usage

### From the App UI

1. Open the MapScreen
2. Tap 🐛 (Debug Panel)
3. Tap **Tile Prefetch** button
4. Configure radius (default 5000m) and zoom range (12–16)
5. Tap **Start Prefetch**
6. Monitor progress, pause/resume/cancel as needed

### Programmatically

```dart
final service = context.read<TilePrefetchService>();
final jobId = await service.startJob(
  lat: 22.35,
  lon: 78.67,
  radiusMeters: 5000,
  minZoom: 12,
  maxZoom: 16,
);

// Monitor progress
service.getJobProgress(jobId).listen((progress) {
  print('${progress.tilesDone}/${progress.totalTiles}');
});

// Pause/Resume/Cancel
await service.pauseJob(jobId);
await service.resumeJob(jobId);
await service.cancelJob(jobId);
```

---

## Storage Layout

```
<appDocDir>/tiles/
├── 12/
│   ├── 2894/
│   │   ├── 1801.png
│   │   └── 1802.png
│   └── ...
├── 13/
├── 14/
├── 15/
└── 16/
```

### Inspecting Stored Tiles

```bash
# On device/emulator
adb shell ls /data/data/org.openrescue.mobile/app_flutter/tiles/

# Count downloaded tiles
adb shell find /data/data/org.openrescue.mobile/app_flutter/tiles/ -name '*.png' | wc -l
```

---

## Database Schema

Separate SQLite database: `openrescue_prefetch.sqlite`

### prefetch_jobs
| Column | Type | Description |
|--------|------|-------------|
| job_id | TEXT PK | UUID |
| lat, lon | REAL | Center point |
| radius_m | INT | Radius in meters |
| min_zoom, max_zoom | INT | Zoom range |
| total_tiles | INT | Total tile count |
| tiles_done | INT | Downloaded count |
| status | TEXT | running/paused/completed/cancelled |
| started_at | DATETIME | Job start time |
| finished_at | DATETIME? | Job end time |

### prefetch_tiles
| Column | Type | Description |
|--------|------|-------------|
| id | INT PK AUTO | Row ID |
| z, x, y | INT | Tile coordinates |
| status | TEXT | queued/in_progress/downloaded/failed/skipped |
| attempts | INT | Download attempt count |
| last_error | TEXT? | Last error message |
| file_path | TEXT? | Path to saved file |
| job_id | TEXT | FK to prefetch_jobs |
| created_at, updated_at | DATETIME | Timestamps |

---

## Safety & Limits

- **Max tiles per job:** 5000 (configurable via `kMaxTilesPerJob`)
- **Max retry attempts:** 5 per tile
- **Concurrency:** 4 parallel downloads
- **Backoff:** `baseDelay × 2^(attempt-1)` with ±20% jitter
- **Atomic writes:** temp file + rename prevents partial files
- **Queue persistence:** survives app restarts via SQL

---

## Cancellation & Cleanup

```bash
# From the prefetch screen: tap Cancel button

# To delete all cached tiles:
adb shell rm -rf /data/data/org.openrescue.mobile/app_flutter/tiles/
```

---

## Background Resume (Future)

Background fetch integration is scaffolded. When `background_fetch` package is added:
- `TilePrefetchService.resumePendingJobs()` picks up incomplete jobs
- Platform limitations:
  - **Android:** WorkManager with 15-min minimum interval
  - **iOS:** BGTaskScheduler, system-controlled frequency
  - Both platforms may throttle or delay background execution

---

## Environment Variables

No new env vars required. The prefetch system uses the existing `MapService.tileUrl` to determine the download source.
