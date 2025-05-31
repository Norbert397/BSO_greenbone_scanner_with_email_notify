#!/usr/bin/env bash
# Filename: scan-lan-alerts.sh
set -euo pipefail

# 1. Parametry – dopasuj je do swojego środowiska lub przyjmij jako argumenty skryptu
GMP_USER="admin"
GMP_PASS="admin" # domyslne
SCRIPT_PATH="/opt/scripts/start-alert-scan.gmp.py"
SCAN_CONFIG=5 # opcja jaki skan wykonac
RECIPIENT="who_to_send@domain.com"
SENDER="your_mail@domain.com"
PORT_LIST_ID="33d0cd82-57c6-11e1-8ed1-406186ea4fc5"
TARGET_NAME="SkanSieciLAN"

# 2. Odkryj żywe hosty w LAN
mapfile -t HOSTS < <( /opt/scripts/discover-lan-hosts.sh )

if [ ${#HOSTS[@]} -eq 0 ]; then
  echo "Brak żywych hostów w LAN – nic do zrobienia." >&2
  exit 1
fi

# (opcjonalnie) Dodaj 'localhost' na początek
HOSTS=( localhost "${HOSTS[@]}" )
#HOSTS=localhost  # dla testow - wykomentowac na produkcji

# 3. Zbuduj argumenty ++hosts
#    -> będzie wyglądać: ++hosts localhost 192.168.73.1 192.168.73.5 ...
HOSTS_ARGS=( ++hosts "${HOSTS[@]}" )

# 4. Uruchom gvm-script
gvm-script --gmp-username "$GMP_USER" --gmp-password "$GMP_PASS" socket "$SCRIPT_PATH" "${HOSTS_ARGS[@]}" ++port-list-id "$PORT_LIST_ID" +C "$SCAN_CONFIG" ++target-name="$TARGET_NAME" ++recipient "$RECIPIENT" ++sender "$SENDER"
