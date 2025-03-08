#!/bin/bash
#
# Script per cifrare un file con GPG utilizzando una password master
# Richiede: gpg

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

# Imposta la gestione errori avanzata
setup_error_handling

# Verifica che sia stato passato un file come argomento
if [ "$#" -ne 1 ]; then
    cleanup "[USO] $0 <file_da_cifrare>"
fi

FILE="$1"

# Controllo che il file esista
if [ ! -f "$FILE" ]; then
    cleanup "Il file $FILE non esiste."
fi

# Richiedi la master password all'utente
MASTER_PASSWORD=$(prompt_master_password)

# Cifra il file con GPG in modalità simmetrica
gpg --batch --yes --symmetric --cipher-algo AES256 --passphrase "$MASTER_PASSWORD" "$FILE"

success "File cifrato con successo: ${FILE}.gpg"
