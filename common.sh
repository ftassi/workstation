#!/bin/bash

# Colorazioni per il logging
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Funzioni di logging
info()    { echo -e "${GREEN}[INFO] $1${RESET}"; }
error()   { echo -e "${RED}[ERRORE] $1${RESET}"; }
success() { echo -e "${GREEN}[SUCCESSO] $1${RESET}"; }

# Funzione per terminare lo script in caso di errore
# Parametro opzionale: messaggio di errore personalizzato
cleanup() {
    local error_message="${1:-Si è verificato un errore. Uscita dallo script.}"
    error "$error_message"
    # Termina lo script con codice di errore
    exit 1
}

# Funzione per configurare la gestione degli errori
# Da chiamare all'inizio di ogni script
setup_error_handling() {
    # Impostazioni per gestione errori:
    # -e: termina script se un comando restituisce un valore diverso da zero
    # -u: termina script se si cerca di utilizzare variabili non definite
    # -o pipefail: se un comando in una pipe fallisce, fallisce l'intera pipe
    set -euo pipefail
    
    # Imposta il trap per la gestione degli errori
    # In caso di errore chiama la funzione cleanup
    trap cleanup ERR
}

# Funzione per ottenere la master password in modo sicuro
prompt_master_password() {
    info "[INPUT] Inserisci la master password:"
    read -s MASTER_PASSWORD
    echo ""
    echo "$MASTER_PASSWORD"
}

