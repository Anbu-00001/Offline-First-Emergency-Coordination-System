#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "Starting OpenRescue Dev Environment Helper..."
"$REPO_ROOT/scripts/dev_backend_proxy.sh"

echo ""
echo "========================================="
echo "Development environment prepared!"
echo "Then run \`cd mobile_app && flutter run\` or use \`flutter run -d <device-id>\`"
echo "========================================="
