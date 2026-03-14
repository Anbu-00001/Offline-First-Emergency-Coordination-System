#!/bin/bash
# ==========================================
# OpenRescue Development Environment Check
# ==========================================

echo "Checking Development Environment..."
echo "-----------------------------------"

FAILED=0

check_command() {
    local cmd=$1
    if command -v "$cmd" >/dev/null 2>&1; then
        echo "[PASS] $cmd is installed."
    else
        echo "[FAIL] $cmd is NOT installed."
        FAILED=1
    fi
}

check_command "docker"
check_command "flutter"
check_command "adb"
check_command "python"

echo "-----------------------------------"
if [ $FAILED -eq 0 ]; then
    echo "Environment Check: PASS. All required tools are installed."
    exit 0
else
    echo "Environment Check: FAIL. Please install missing dependencies."
    exit 1
fi
