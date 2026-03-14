#!/bin/bash
set -euo pipefail
REPO_ROOT="$(pwd)"
OUT="$REPO_ROOT/artifacts/fix_run"
VENV_PATH="/home/anbu/25_class/Sem_4/FOSS/.venv_openrescue/bin/activate"
UVICORN_PORT=8000
BACKEND_DIR="$REPO_ROOT/backend"
DISCOVERY_SCRIPT="discovery/main.py"
mkdir -p "$OUT"

echo "=== AUTOFIX: activate venv if present ==="
if [ -f "$VENV_PATH" ]; then
  # shellcheck source=/dev/null
  source "$VENV_PATH"
  echo "activated venv: $VENV_PATH" > "$OUT/venv.txt"
else
  echo "no venv found at $VENV_PATH" > "$OUT/venv.txt"
fi

echo "=== AUTOFIX: ensure critical python deps (bcrypt, alembic) ==="
# install compatible bcrypt and alembic; continue on failures but record them
pip install --quiet "bcrypt==4.0.1" alembic psycopg2-binary >/dev/null 2>&1 || echo "pip install bcrypt/alembic failed" >> "$OUT/pip_errors.log"

echo "=== AUTOFIX: detect DATABASE_URL and resolve host issues ==="
# pick DATABASE_URL from env or fallback to config files
CURRENT_DB_URL="${DATABASE_URL:-}"
if [ -z "$CURRENT_DB_URL" ]; then
  # try to read from .env or backend/.env or app/core/config.py patterns
  if [ -f ".env" ]; then
    CURRENT_DB_URL="$(grep -E '^DATABASE_URL=' .env | cut -d'=' -f2- || true)"
  fi
  if [ -z "$CURRENT_DB_URL" ] && [ -f "$BACKEND_DIR/.env" ]; then
    CURRENT_DB_URL="$(grep -E '^DATABASE_URL=' "$BACKEND_DIR/.env" | cut -d'=' -f2- || true)"
  fi
fi
echo "CURRENT_DB_URL='$CURRENT_DB_URL'" > "$OUT/db_url.before.txt"

# helper: extract host from postgres URL (postgresql://user:pass@host:port/db)
extract_host() {
  echo "$1" | sed -E 's#^[^@]+@([^:/]+).*#\1#' || true
}
DB_HOST="$(extract_host "$CURRENT_DB_URL" || true)"
echo "detected DB host: '$DB_HOST'" >> "$OUT/db_url.before.txt"

# check host resolution; if host appears to be 'db' and not resolvable, fallback to localhost for this run
if [ -n "$DB_HOST" ] && [ "$DB_HOST" != "localhost" ] && [ "$DB_HOST" != "127.0.0.1" ]; then
  if ! getent hosts "$DB_HOST" >/dev/null 2>&1; then
    echo "Host '$DB_HOST' not resolvable; will use temporary DATABASE_URL with localhost for this session" >> "$OUT/db_url.before.txt"
    # build fallback url by replacing host in CURRENT_DB_URL -> use sed
    if [ -n "$CURRENT_DB_URL" ]; then
      FALLBACK_DB_URL="$(echo "$CURRENT_DB_URL" | sed -E "s#(@)[^:/]+#\\1localhost#g")"
      export DATABASE_URL="$FALLBACK_DB_URL"
      echo "export DATABASE_URL set to fallback for this run" >> "$OUT/db_url.before.txt"
      echo "FALLBACK_DB_URL='$FALLBACK_DB_URL'" >> "$OUT/db_url.before.txt"
    fi
  else
    echo "Host '$DB_HOST' is resolvable" >> "$OUT/db_url.before.txt"
  fi
else
  echo "No DB host override needed" >> "$OUT/db_url.before.txt"
fi

echo "=== AUTOFIX: run DB migrations (alembic upgrade head) if available ==="
if [ -d "alembic" ] || [ -d "$BACKEND_DIR/alembic" ]; then
  echo "alembic directory found; attempting upgrade head" >> "$OUT/migrations.log" || true
  # try running alembic from repo root
  if command -v alembic >/dev/null 2>&1; then
    alembic upgrade head >> "$OUT/migrations.log" 2>&1 || echo "alembic upgrade failed (see migrations.log)" >> "$OUT/migrations.log"
  else
    # try to run via python -m alembic
    python -m alembic upgrade head >> "$OUT/migrations.log" 2>&1 || echo "python -m alembic upgrade failed" >> "$OUT/migrations.log"
  fi
else
  echo "No alembic migration folder found; attempting create_tables() helper if present" >> "$OUT/migrations.log"
  if python - <<PY 2>>"$OUT/migrations.log"
import importlib
try:
    m=importlib.import_module('app.core.database')
    if hasattr(m,'create_tables'):
        m.create_tables()
        print('create_tables() ok')
    else:
        print('no create_tables() helper')
except Exception as e:
    print('create_tables() failed:',e)
PY
  then
    echo "create_tables attempt logged" >> "$OUT/migrations.log"
  fi
fi

echo "=== AUTOFIX: restart backend (uvicorn) with updated env for this shell ==="
# kill old uvicorn if exists and start a new one from backend dir
if pgrep -f "uvicorn.*app.main:app" >/dev/null 2>&1; then
  pkill -f "uvicorn.*app.main:app" || true
  sleep 1
fi

# start backend
( cd "$BACKEND_DIR" && nohup python -m uvicorn app.main:app --host 0.0.0.0 --port "$UVICORN_PORT" --log-level info > "$OUT/uvicorn.log" 2>&1 & echo $! > "$OUT/uvicorn.pid" )

# wait for health
echo "waiting for /health..."
for i in $(seq 1 20); do
  if curl -s -f "http://127.0.0.1:${UVICORN_PORT}/health" >/dev/null 2>&1; then
    echo "backend healthy" > "$OUT/backend_health.txt"
    break
  fi
  sleep 1
done
if [ ! -f "$OUT/backend_health.txt" ]; then
  echo "backend did not become healthy in time; check $OUT/uvicorn.log" > "$OUT/backend_health.txt"
fi

echo "=== AUTOFIX: ensure mDNS advertiser (discovery/main.py) is running ==="
# kill previous advertiser if exists and start new one
if pgrep -f "$DISCOVERY_SCRIPT" >/dev/null 2>&1; then
  pkill -f "$DISCOVERY_SCRIPT" || true
  sleep 1
fi
if [ -f "$DISCOVERY_SCRIPT" ]; then
  nohup python "$DISCOVERY_SCRIPT" > "$OUT/mdns_advertiser.log" 2>&1 & echo $! > "$OUT/mdns.pid"
  sleep 2
  echo "started discovery advertiser (pid from $OUT/mdns.pid)" >> "$OUT/mdns_advertiser.log" || true
else
  echo "discovery script not found at $DISCOVERY_SCRIPT" > "$OUT/mdns_advertiser.log"
fi

echo "=== AUTOFIX: try install screenshot tools (wkhtmltoimage or scrot) ==="
# attempt apt-get install if apt exists and sudo is available
if command -v apt-get >/dev/null 2>&1 && command -v sudo >/dev/null 2>&1; then
  # try install wkhtmltopdf and scrot (non-fatal)
  echo "Skipped sudo apt-get" > "$OUT/install_tools.log"
else
  echo "apt-get or sudo not available; skipping screenshot tool install" > "$OUT/install_tools.log"
fi

echo "=== AUTOFIX: capture API docs screenshot or save HTML ==="
# prefer wkhtmltoimage; fallback to saving docs.html via curl
mkdir -p "$OUT/screenshots"
if command -v wkhtmltoimage >/dev/null 2>&1; then
  wkhtmltoimage "http://127.0.0.1:${UVICORN_PORT}/docs" "$OUT/screenshots/api_docs.png" >/dev/null 2>&1 || echo "wkhtmltoimage failed" >> "$OUT/install_tools.log"
else
  curl -sS "http://127.0.0.1:${UVICORN_PORT}/docs" -o "$OUT/screenshots/docs.html" || true
  echo "saved docs.html to $OUT/screenshots/docs.html" >> "$OUT/install_tools.log"
fi

echo "=== AUTOFIX: run a final verification smoke test (health, openapi, websocket, mdns scan) ==="
# health
curl -sS "http://127.0.0.1:${UVICORN_PORT}/health" -o "$OUT/verify_health.json" || echo "health failed" > "$OUT/verify_health.json"
# openapi
curl -sS "http://127.0.0.1:${UVICORN_PORT}/openapi.json" -o "$OUT/verify_openapi.json" || true

# websocket quick test (best-effort)
python - "$UVICORN_PORT" <<'PY' > "$OUT/verify_ws.txt" 2>&1 || true
import asyncio, websockets, json, sys
async def t():
    uri=f"ws://127.0.0.1:{sys.argv[1]}/ws/peer"
    try:
        async with websockets.connect(uri, open_timeout=3) as ws:
            await ws.send('{"test":"ping"}')
            try:
                r = await asyncio.wait_for(ws.recv(), timeout=3)
                print('recv->', r)
            except Exception as e:
                print('no-recv', e)
    except Exception as e:
        print('connect-failed', e)
asyncio.run(t())
PY

# mDNS scan
python - <<'PY' > "$OUT/verify_mdns.txt" 2>&1 || true
from zeroconf import Zeroconf, ServiceBrowser
import time
out=[]
class L:
    def add_service(self, zc,t,n):
        info=zc.get_service_info(t,n)
        if info:
            out.append((n,info.parsed_addresses(),info.port))
zc=Zeroconf()
ServiceBrowser(zc,"_openrescue._tcp.local.",L())
time.sleep(3)
zc.close()
print(out)
PY

echo "=== AUTOFIX: collect tail logs ==="
tail -n 200 "$OUT/uvicorn.log" > "$OUT/uvicorn_tail.log" 2>/dev/null || true
tail -n 200 "$OUT/mdns_advertiser.log" > "$OUT/mdns_tail.log" 2>/dev/null || true

echo "=== AUTOFIX: package artifacts ==="
tar -czf "$REPO_ROOT/artifacts/fix_run_artifacts.tar.gz" -C "$REPO_ROOT" artifacts/fix_run || true

echo "AUTOFIX complete. Artifacts: $REPO_ROOT/artifacts/fix_run_artifacts.tar.gz"
echo "Please download/open that tarball; check verify files in artifacts/fix_run/ (verify_health.json, verify_openapi.json, verify_ws.txt, verify_mdns.txt, uvicorn_tail.log, mdns_tail.log)."
exit 0
