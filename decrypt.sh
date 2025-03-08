#!/bin/bash
#
# Script per decifrare un file .gpg utilizzando una password master
# Richiede: gpg

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

# Imposta la gestione errori avanzata
setup_error_handling

# Verifica che sia stato passato un file come argomento
if [ "$#" -ne 1 ]; then
    cleanup "[USO] $0 <file_da_decriptare.gpg>"
fi

FILE="$1"

# Controllo che il file esista
if [ ! -f "$FILE" ]; then
    cleanup "Il file $FILE non esiste."
fi

# Determina il nome del file decriptato (senza .gpg)
DECRYPTED_FILE="${FILE%.gpg}"

# Richiedi la master password all'utente
MASTER_PASSWORD=$(prompt_master_password)

# Decripta il file con GPG in modalità simmetrica
gpg --batch --yes --passphrase "$MASTER_PASSWORD" --output "$DECRYPTED_FILE" --decrypt "$FILE"

success "File decriptato con successo: $DECRYPTED_FILE"
