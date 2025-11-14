#!/usr/bin/env bash
set -euo pipefail

OUT_FILE="macs.txt"
IFACE="enp0s31f6"
TARGET="192.168.1.0/24" 

TMP_DIR=$(mktemp -d)
RAW_ALL="$TMP_DIR/all_macs_raw.txt"
: > "$RAW_ALL"

# Limpia la caché arp
ip neigh flush all

# arp-scan
if command -v arp-scan >/dev/null 2>&1; then
  arp-scan -l -I "$IFACE" > "$TMP_DIR/arp_scan.txt" 2>/dev/null
  awk '{ if ($2 ~ /([0-9a-f]{2}:){5}[0-9a-f]{2}/) print $2 }' "$TMP_DIR/arp_scan.txt" >> "$RAW_ALL" || true
fi

# nmap
if command -v nmap >/dev/null 2>&1; then
    nmap -sn "$TARGET" > "$TMP_DIR/nmap.txt" 2>/dev/null || true
    grep -i "MAC Address" "$TMP_DIR/nmap.txt" 2>/dev/null | awk '{ for(i=1;i<=NF;i++) if ($i=="Address") print $(i+1) }' >> "$RAW_ALL" || true
fi

# tabla ARP local
if command -v ip >/dev/null 2>&1; then
  ip neigh show dev "$IFACE" 2>/dev/null | awk '{ for(i=1;i<=NF;i++) if ($i ~ /([0-9a-f]{2}:){5}[0-9a-f]{2}/) print $i }' >> "$RAW_ALL" || true
elif command -v arp >/dev/null 2>&1; then
  arp -an 2>/dev/null | awk '{ for(i=1;i<=NF;i++) if ($i ~ /([0-9a-f]{2}:){5}[0-9a-f]{2}/) print $i }' >> "$RAW_ALL" || true
fi

# Normalizar y guardar
cat "$RAW_ALL" \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/-/:/g; s/[^0-9a-f:]//g' \
  | grep -E '^([0-9a-f]{2}:){5}[0-9a-f]{2}$' \
  | sort -u > "$OUT_FILE"

rm -rf "$TMP_DIR"
echo "MACs guardadas en $OUT_FILE" >&2
exit 0

