#!/usr/bin/env bash
set -euo pipefail

echo "Uruchamiam skan..."
docker exec greenbone-cli /opt/scripts/scan-lan-alerts.sh
