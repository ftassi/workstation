#!/bin/bash

set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

# Copia le chiavi ssh e imposta i permessi corretti
echo -e "${GREEN}[INFO] Copia delle chiavi ssh...${RESET}"
cp -r secrets/ssh ~/.ssh
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 664 ~/.ssh/config

# Verifica le chiavi SSH tentando di connettersi a GitHub
echo -e "${GREEN}[INFO] Verifica delle chiavi SSH...${RESET}"

# Evita il prompt interattivo per host sconosciuti
ssh -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | tee /tmp/github_ssh_check.log

# Controlla l'output per confermare l'autenticazione corretta
if grep -q "Hi .*! You've successfully authenticated" /tmp/github_ssh_check.log; then
    echo -e "${GREEN}[SUCCESSO] Le chiavi SSH sono corrette e l'autenticazione a GitHub è riuscita.${RESET}"
else
    echo -e "${RED}[ERRORE] Autenticazione SSH a GitHub fallita. Verifica le chiavi SSH installate.${RESET}"
    exit 1
fi
