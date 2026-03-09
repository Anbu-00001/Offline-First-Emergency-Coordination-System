#!/usr/bin/env bash
# scripts/ensure_emulator_reverse.sh
# Ensures Android emulator reverse proxy is correctly set up for the backend.
# Retries up to 10 times waiting for an adb device.

set -e

echo "waiting for an adb device..."

MAX_RETRIES=10
RETRY_COUNT=0
DEVICE_FOUND=false

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  # Check if any device is listed
  if adb devices | grep -v "List" | grep -q "device$"; then
    echo "Device found!"
    DEVICE_FOUND=true
    break
  fi
  echo "No device found yet... waiting 2s (Attempt $((RETRY_COUNT+1))/$MAX_RETRIES)"
  sleep 2
  RETRY_COUNT=$((RETRY_COUNT+1))
done

if [ "$DEVICE_FOUND" = false ]; then
  echo "ERROR: Timed out waiting for adb device."
  # Print artifacts output
  mkdir -p artifacts
  echo "TIMEOUT" > artifacts/adb_reverse.txt
  exit 1
fi

echo "Setting up adb reverse tcp:8000 tcp:8000..."
if adb reverse tcp:8000 tcp:8000; then
  echo "adb reverse SUCCESS."
  mkdir -p artifacts
  echo "SUCCESS" > artifacts/adb_reverse.txt
else
  echo "adb reverse FAILED."
  mkdir -p artifacts
  echo "FAILED" > artifacts/adb_reverse.txt
  exit 1
fi

# Try to test connectivity from emulator to host
echo "Testing emulator connectivity to backend (optional)..."
if adb shell command -v curl >/dev/null 2>&1; then
  adb shell curl -I http://127.0.0.1:8000/health || echo "Emulator curl to 8000 failed."
  adb shell curl -I https://tile.openstreetmap.org/ || echo "Emulator curl to OSM failed."
else
  echo "curl not available on emulator, skipping."
fi

echo "DONE."
