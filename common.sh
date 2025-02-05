#!/bin/bash

PASSWORD_FILE=".passwords"

# Colorazioni per il logging (assicurarsi che queste variabili siano definite in common.sh oppure definirle qui)
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Funzioni di logging
info()    { echo -e "${GREEN}[INFO] $1${RESET}"; }
error()   { echo -e "${RED}[ERRORE] $1${RESET}"; }
success() { echo -e "${GREEN}[SUCCESSO] $1${RESET}"; }

# Funzione per terminare lo script in caso di errore (se necessario eseguire cleanup)

cleanup() {
    error "Si è verificato un errore. Uscita dallo script."
    exit 1
}
# Funzione per leggere la master password da .passwords
get_master_password() {
    if [ ! -f "$PASSWORD_FILE" ]; then
        echo -e "\e[31m[ERRORE] Il file .passwords non esiste. Crealo con setup.sh.\e[0m"
        exit 1
    fi

    source "$PASSWORD_FILE"

    if [ -z "$MASTER_PASSWORD" ]; then
        echo -e "\e[31m[ERRORE] MASTER_PASSWORD non trovata in .passwords.\e[0m"
        exit 1
    fi

    echo "$MASTER_PASSWORD"
}

# Funzione per installare pacchetti con apt in modo idempotente
install_package() {
    local PACKAGE=$1

    if dpkg -s "$PACKAGE" &> /dev/null; then
        echo -e "\e[34m[INFO] Il pacchetto $PACKAGE è già installato. Skipping.\e[0m"
    else
        echo -e "\e[32m[INFO] Installazione di $PACKAGE...\e[0m"
        apt-get update -qq && apt-get install -y "$PACKAGE"
    fi
}
