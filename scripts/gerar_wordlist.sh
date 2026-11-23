#!/usr/bin/env bash
# Gera uma wordlist propria com o crunch.
# Exemplo: senhas de 6 a 8 caracteres com letras minusculas e numeros.
# Uso: ./gerar_wordlist.sh [arquivo_de_saida]

set -euo pipefail

SAIDA="${1:-wordlists/custom.txt}"

echo "[*] Gerando wordlist em ${SAIDA}..."
crunch 6 8 abcdefghijklmnopqrstuvwxyz0123456789 -o "${SAIDA}"

echo "[+] Pronto. Dica: o Kali ja tem listas prontas em /usr/share/wordlists/"
