#!/bin/bash
set -eo pipefail

VENV="/home/anbu/25_class/Sem_4/FOSS/.venv_openrescue/bin/activate"
source "$VENV"

export DATABASE_URL="sqlite:///./demo.db"
mkdir -p artifacts/demo

# 1. Start backend if not running
if ! pgrep -f "uvicorn.*app.main:app" > /dev/null; then
    echo "Starting backend..."
    cd backend
    nohup python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 > ../artifacts/demo/backend.log 2>&1 &
    cd ..
    sleep 3
fi

# 2. Start mDNS advertiser
pkill -f "discovery/main.py" || true
nohup python discovery/main.py > artifacts/demo/mdns.log 2>&1 &
MDNS_PID=$!
sleep 2

# 3. and 4. websockets already installed via venv
# 5. Start clients
echo "Client B listening..." > artifacts/demo/client_B.log
python -u scripts/ws_client_B.py >> artifacts/demo/client_B.log 2>&1 &
CB_PID=$!
sleep 2

python -u scripts/ws_client_A.py > artifacts/demo/client_A.log 2>&1
sleep 1
kill $CB_PID || true
kill $MDNS_PID || true

# 7. Capture screenshots
cp artifacts/screenshots/api_docs.png artifacts/demo/api_docs.png || {
    echo "api_docs.png not found, please ensure it exists or browser subagent grabbed it."
}
python scripts/gen_screens.py

# 8. Package results
cd artifacts
tar -czvf demo_results.tar.gz demo/api_docs.png demo/websocket_demo.png demo/mdns_service.png demo/client_A.log demo/client_B.log demo/mdns.log
cd ..
echo "Done"
