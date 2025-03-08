#!/bin/bash

set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

# Verifica che sia stato passato un file come argomento
if [ "$#" -ne 1 ]; then
    error "[USO] $0 <file_da_decriptare.gpg>"
    exit 1
fi

FILE="$1"

# Controllo che il file esista
if [ ! -f "$FILE" ]; then
    error "Il file $FILE non esiste."
    exit 1
fi

# Determina il nome del file decriptato (senza .gpg)
DECRYPTED_FILE="${FILE%.gpg}"

# Richiedi la master password all'utente
MASTER_PASSWORD=$(prompt_master_password)

# Decripta il file con GPG in modalità simmetrica
gpg --batch --yes --passphrase "$MASTER_PASSWORD" --output "$DECRYPTED_FILE" --decrypt "$FILE"

success "File decriptato con successo: $DECRYPTED_FILE"
