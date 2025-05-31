#!/usr/bin/env bash
set -e

DOWNLOAD_DIR=$HOME/greenbone-community-container
RELEASE="24.10"

installed() {
    local failed=0
    if [ -z "$2" ]; then
        command -v "$1" &>/dev/null || failed=1
    else
        "$@" &>/dev/null || failed=1
    fi
    if [ $failed -ne 0 ]; then
        echo "$* is not available. "
        exit 1
    fi
}

installed curl
installed docker
installed docker compose

mkdir -p "$DOWNLOAD_DIR" && cd "$DOWNLOAD_DIR"

echo "Pobieranie repozytorium"
git clone https://github.com/Norbert397/BSO_greenbone_scanner_with_email_notify.git 

cd BSO_greenbone_scanner_with_email_notify

echo "Skonfiguruj pliki a nastepnie uzyj komendy 'docker compose -f docker-compose.yml pull' oraz docker compose -f docker-compose.yml up -d"
echo "Ustaw nowe haslo dla uzytkownika admin: docker compose -f docker-compose.yml exec -u gvmd gvmd gvmd --user=admin --new-password=<your_passwd>"
