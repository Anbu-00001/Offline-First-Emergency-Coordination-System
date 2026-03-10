#!/usr/bin/env bash
set -euo pipefail

# Find repo root (assumes script is in scripts/)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Ensure artifacts directory exists
mkdir -p artifacts/mobile_setup

# Set up logging file
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="artifacts/mobile_setup/proxy_run_${TIMESTAMP}.txt"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "========================================="
echo "dev_backend_proxy.sh run at $TIMESTAMP"
echo "========================================="

# Test backend health
echo "Checking backend health at http://127.0.0.1:8000/health..."
set +e
HEALTH_CHECK=$(curl -sS http://127.0.0.1:8000/health)
HEALTH_EXIT=$?
set -e

if [ $HEALTH_EXIT -eq 0 ] && echo "$HEALTH_CHECK" | grep -q '"status":"ok"'; then
  echo "Backend is already running: $HEALTH_CHECK"
else
  echo "Backend is not fully responsive. Attempting best-effort start..."
  
  if [ -f "$REPO_ROOT/.venv_openrescue/bin/activate" ]; then
    echo "Found venv at $REPO_ROOT/.venv_openrescue. Attempting to start uvicorn..."
    
    # We must run this subshell so we don't pollute the script's environment, but we background it
    (
      set +e
      source "$REPO_ROOT/.venv_openrescue/bin/activate"
      cd backend
      nohup python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload > "$REPO_ROOT/artifacts/mobile_setup/uvicorn_start.log" 2>&1 &
    )
    
    echo "Wait up to 6 seconds for backend to start..."
    sleep 6
    
    set +e
    HEALTH_CHECK_AFTER=$(curl -sS http://127.0.0.1:8000/health)
    set -e
    echo "Health check after attempted start: ${HEALTH_CHECK_AFTER:-"FAILED"}"
  else
    echo "WARN: Virtualenv not found at $REPO_ROOT/.venv_openrescue. Cannot start backend automatically."
  fi
fi

# Run adb reverse
echo "Setting up adb reverse tcp:8000 tcp:8000..."
set +e
adb reverse tcp:8000 tcp:8000 > "artifacts/mobile_setup/adb_reverse.txt" 2>&1
ADB_EXIT=$?
set -e

if [ $ADB_EXIT -eq 0 ]; then
  echo "adb reverse succeeded."
else
  echo "WARN: adb reverse failed (is emulator running? Check adb_reverse.txt)."
fi

# Quick check from emulator side
echo "Checking backend health from emulator side (via adb shell)..."
set +e
adb shell curl -sS http://127.0.0.1:8000/health > "artifacts/mobile_setup/adb_emulator_health.txt" 2>&1
EMU_HEALTH_EXIT=$?
set -e

if [ $EMU_HEALTH_EXIT -eq 0 ]; then
  echo "Emulator-side check succeeded."
else
  echo "WARN: Emulator-side check failed (curl missing on emulator, or backend unreachable). Check adb_emulator_health.txt."
fi

echo "========================================="
echo "Summary:"
echo " - Backend Health Before: ${HEALTH_CHECK:-"FAILED"}"
echo " - adb reverse: $( [ $ADB_EXIT -eq 0 ] && echo "SUCCESS" || echo "FAILED" )"
echo " - Emulator health check: $( [ $EMU_HEALTH_EXIT -eq 0 ] && echo "SUCCESS" || echo "FAILED" )"
if [ -f "artifacts/mobile_setup/uvicorn_start.log" ]; then
  echo " - Uvicorn log: artifacts/mobile_setup/uvicorn_start.log"
fi
echo "========================================="
exit 0
