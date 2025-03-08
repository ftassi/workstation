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
cleanup() {
    error "Si è verificato un errore. Uscita dallo script."
    exit 1
}

# Funzione per ottenere la master password in modo sicuro
prompt_master_password() {
    info "[INPUT] Inserisci la master password:"
    read -s MASTER_PASSWORD
    echo ""
    echo "$MASTER_PASSWORD"
}

