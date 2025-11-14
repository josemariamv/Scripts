#!/bin/bash
# Configura estos valores según tu red
MACS="macs.txt"
OUTPUT="ips.txt"
RANGO="192.168.0.0/23"  # Cambia el rango a tu red real

# Escanea la red y guarda resultados en un archivo temporal
sudo nmap -sn $RANGO > /tmp/mapa.tmp

# Por cada MAC en tu archivo, busca la IP en el escaneo de nmap
> "$OUTPUT"
while read -r mac; do
  # Busca 2 líneas antes y toma la IP (funciona con la salida de nmap)
  ip=$(grep -B2 -i "$mac" /tmp/mapa.tmp | grep "Nmap scan report" | awk '{print $5}')
  if [[ -n "$ip" ]]; then
    echo "$ip" >> "$OUTPUT"
  fi
done < "$MACS"

# Borra archivo temporal
rm /tmp/mapa.tmp

