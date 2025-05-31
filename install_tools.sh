#!/usr/bin/env bash
set -euo pipefail

CONTAINER="greenbone-cli"

# Sprawdź, czy kontener greenbone-cli działa
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "Kontener '${CONTAINER}' nie działa. Uruchom go najpierw (docker-compose up -d)."
  exit 1
fi

echo "Aktualizuję listę pakietów w kontenerze '${CONTAINER}'..."
docker exec -u root "${CONTAINER}" apt-get update

echo "Instaluję iproute2 oraz nmap w kontenerze '${CONTAINER}'..."
docker exec -u root "${CONTAINER}" \
  apt-get install -y --no-install-recommends iproute2 nmap

echo "Czyszczę cache apt w kontenerze '${CONTAINER}'..."
docker exec -u root "${CONTAINER}" rm -rf /var/lib/apt/lists/*

echo "Pakiety zostały zainstalowane pomyślnie."
