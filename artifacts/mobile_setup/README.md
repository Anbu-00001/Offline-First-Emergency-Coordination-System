# OpenRescue Mobile App

This is the Day-8 Flutter mobile client for OpenRescue.

## Features

*   **MapLibre Offline-Capable Map:** Displays mobile maps via MapLibre, supporting both remote Dev tile fallback and local MBTiles (via assets/tiles).
*   **mDNS Discovery:** Automatically scans `_openrescue._tcp.local` to find the backend server seamlessly on a local network.
*   **Robust API Client:** Uses Dio with exponential backoff and retry strategy for all requests (`/health`, `/auth/login`, `/incidents`, `/sync/incidents`).
*   **WebSocket Messaging:** Includes an auto-reconnecting WebSocket client with a local DB store-and-forward mechanism.
*   **Local DB & Sync:** Implements Drift/SQLite for local-first persistence. The Sync queue processes background updates reliably.
*   **Secure Auth Storage:** Employs `flutter_secure_storage` to keep JWT securely encrypted on devices.
*   **Clean Architecture:** Organizes under `core/`, `models/`, `data/`, and `features/`.

## Prerequisites & Backend Setup

1.  Make sure you start the backend first (see `backend/README.md` in the OpenRescue repository).
2.  Start the backend using uvicorn:
    ```bash
    cd ../backend
    source ../.venv_openrescue/bin/activate
    alembic upgrade head
    uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
    ```
3.  Ensure the mDNS advertiser is running via the custom Python scripts (or within the app) on `8000`.

## Local Dev Configuration

The app will prefer mDNS discovery when resolving the backend address.
If you need to bypass mDNS (e.g., CI, or running on an Emulator where mDNS propagation is tricky), you can override the base URL via config.

1.  Copy `assets/config.example.json` to `assets/config.json`.
2.  Set your desired `base_url`:
    ```json
    {
      "base_url": "http://10.0.2.2:8000"
    }
    ```
   *(Note: `10.0.2.2` is the special Android Emulator alias to `127.0.0.1` on your host machine. iOS uses `127.0.0.1`.)*

## Development Helpers (ADB Reverse Proxy)

When running on an Android emulator, resolving `127.0.0.1` points to the emulator itself, not your host machine where the backend is running.
To seamlessly bridge this gap without changing code or editing config files constantly:

1.  We use `adb reverse tcp:8000 tcp:8000` to map the emulator's port 8000 to the host's port 8000.
2.  Use the included helper script to set this up automatically:
    ```bash
    # From the repo root layer:
    ./scripts/start_dev_environment.sh
    # or directly:
    ./scripts/dev_backend_proxy.sh
    ```
    This script will check if the backend is healthy, optionally start it if needed (using `.venv_openrescue`), and then run the `adb reverse` command.
3.  *Note:* If you are deploying to a physical device on your network, `adb reverse` will map via USB, but for wireless debugging or untethered testing, ensure your `base_url` points to your machine's LAN IP (e.g., `192.168.1.100`) in `assets/config.json`.

## Running the App

Run the app safely on any active device or emulator. The Day-8 milestone is cross-platform capable.

1.  Launch your emulator using available scripts (e.g., `Scripts/run_emulator.sh`) or manually via Android Studio/Xcode.
2.  Run Flutter:
    ```bash
    cd mobile_app
    flutter run -d emulator-5554
    ```

## Acceptance Criteria

1.  **Map Display & Incident Loading:** Ensure `MapScreen` shows a MapLibre map and rendering markers from Local DB.
2.  **Config Discovery:** Logs will display if the base URL was pulled via mDNS, config.json fallback, or localhost defaults.
3.  **Peer Messaging:** Accessible via Map map action icon. Tests sending/receiving via WS protocol and SyncQueue.
4.  **No Backend Changes:** Strictly isolated to `mobile_app/*` folder.
