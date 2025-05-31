#!/usr/bin/env bash
# Filename: discover-lan-hosts.sh
set -euo pipefail

# 1. Pobranie interfejsu domyślnego i podsieci
#    przyjmujemy, że mamy 'ip' w kontenerze
default_route=$(ip route show default | head -n1)
# np. "default via 192.168.1.1 dev eth0 proto static metric 100"
iface=$(awk '/default/ { for(i=1;i<=NF;i++) if($i=="dev") print $(i+1) }' <<<"$default_route")
cidr=$(ip -o -f inet addr show dev "$iface" \
       | awk '{print $4}')
if [[ -z "$iface" || -z "$cidr" ]]; then
  echo "Nie udało się wykryć podsieci. Interface: '$iface', CIDR: '$cidr'" >&2
  exit 1
fi

echo "Wykryta podsieć: $cidr (interfejs $iface)" >&2

# 2. Skanowanie metodą ping scan
#    -n: nie rozwiązuje DNS
#    -sn: tylko sprawdzenie żywych hostów
#    -oG - : wynik w formacie grepable na stdout
nmap -n -sn "$cidr" -oG - \
  | awk '/Up$/{ print $2 }'
