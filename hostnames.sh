#!/bin/bash

# Uso: ./obtener_hostnames.sh usuario contraseña archivo_ips.txt archivo_salida.txt

USUARIO="$1"
PASSWORD="$2"
ARCHIVO="ips.txt"
SALIDA="hostnames.txt"

if [ -z "$USUARIO" ] || [ -z "$PASSWORD" ]; then
    echo "Uso: $0 usuario contraseña"
    exit 1
fi

echo -e "IP\tHostname" > "$SALIDA"

while read -r IP || [ -n "$IP" ]; do
    if [ -z "$IP" ]; then
        continue
    fi
    hostname_remoto=$(sshpass -p "$PASSWORD" ssh -n -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$USUARIO@$IP" 'hostname' 2>/dev/null)
    if [ $? -eq 0 ] && [ ! -z "$hostname_remoto" ]; then
        echo -e "$IP\t$hostname_remoto" >> "$SALIDA"
    else
        echo -e "$IP\tERROR" >> "$SALIDA"
    fi
done < "$ARCHIVO"

# Cambiar orden columnas e ordenar por hostname
(echo -e "Hostname\tIP"; tail -n +2 "$SALIDA" | awk -F'\t' '{print $2 "\t" $1}' | sort) > "${SALIDA}.tmp" && mv "${SALIDA}.tmp" "$SALIDA"

echo "Resultados guardados en $SALIDA"


