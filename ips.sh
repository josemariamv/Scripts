#!/usr/bin/env bash
set -u

MAC_FILE="macs.txt"
OUT_FILE="ips.txt"
IFACE="enp0s31f6"

# Obtener IPv4/cidr y broadcast
IFADDR=$(ip -4 -o addr show dev "$IFACE" 2>/dev/null | awk '{print $4}' | head -n1 || true)
BRD=$(ip -4 addr show dev "$IFACE" 2>/dev/null | awk '/brd/ {for(i=1;i<=NF;i++) if ($i=="brd") print $(i+1)}' | head -n1 || true)

TMP_DIR=$(mktemp -d)
ARP_RAW="$TMP_DIR/arp_scan_raw.txt"
ARP_NORM="$TMP_DIR/arp_scan_norm.txt"

# ping broadcast
sudo ping -b -c 2 -W 1 "$BRD" >/dev/null 2>&1 || true

# arp-scan
arp-scan -l -I "$IFACE" > "$ARP_RAW" 2>/dev/null

if [[ ! -s "$ARP_RAW" ]]; then
  # Si no hay salida válida, limpiamos y salimos con error
  rm -rf "$TMP_DIR"
  echo "Error: arp-scan no devolvió resultados. Comprueba permisos/interfaz/red." >&2
  exit 6
fi

# Normalizar salida
tr '[:upper:]' '[:lower:]' < "$ARP_RAW" | sed 's/-/:/g' > "$ARP_NORM"

# Preparar fichero de salida
: > "$OUT_FILE" || { echo "Error: no se puede escribir en $OUT_FILE" >&2; rm -rf "$TMP_DIR"; exit 7; }

# Asociativo para evitar duplicados (bash 4+)
declare -A seen_ips
while IFS= read -r rawmac || [[ -n "$rawmac" ]]; do
  mac=$(echo "$rawmac" | tr '[:upper:]' '[:lower:]' | sed 's/-/:/g' | xargs)
  [[ -z "$mac" ]] && continue

  # buscar coincidencia exacta de MAC en la salida normalizada
  line=$(grep -i -m1 "$mac" "$ARP_NORM" || true)
  if [[ -n "$line" ]]; then
    ip=$(echo "$line" | awk '{print $1}')
    # si ip no se ha visto antes, escribirla
    if [[ -n "$ip" && -z "${seen_ips[$ip]:-}" ]]; then
      echo "$ip" >> "$OUT_FILE"
      seen_ips["$ip"]=1
    fi
  fi
done < "$MAC_FILE"

# limpiar
rm -rf "$TMP_DIR"

echo "IPs guardadas en $OUT_FILE" >&2
exit 0

