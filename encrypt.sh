#!/bin/bash

set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

# Verifica che sia stato passato un file come argomento
if [ "$#" -ne 1 ]; then
    echo -e "${RED}[USO] $0 <file_da_cifrare>${RESET}"
    exit 1
fi

FILE="$1"

# Controllo che il file esista
if [ ! -f "$FILE" ]; then
    echo -e "${RED}[ERRORE] Il file $FILE non esiste.${RESET}"
    exit 1
fi

# Recupera la master password dal file .passwords
MASTER_PASSWORD=$(get_master_password)

# Cifra il file con GPG in modalità simmetrica
gpg --batch --yes --symmetric --cipher-algo AES256 --passphrase "$MASTER_PASSWORD" "$FILE"

echo -e "${GREEN}[INFO] File cifrato con successo: ${FILE}.gpg${RESET}"
