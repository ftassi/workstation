#!/bin/bash

set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

# Verifica che sia stato passato un file come argomento
if [ "$#" -ne 1 ]; then
    error "[USO] $0 <file_da_cifrare>"
    exit 1
fi

FILE="$1"

# Controllo che il file esista
if [ ! -f "$FILE" ]; then
    error "Il file $FILE non esiste."
    exit 1
fi

# Richiedi la master password all'utente
MASTER_PASSWORD=$(prompt_master_password)

# Cifra il file con GPG in modalità simmetrica
gpg --batch --yes --symmetric --cipher-algo AES256 --passphrase "$MASTER_PASSWORD" "$FILE"

success "File cifrato con successo: ${FILE}.gpg"
