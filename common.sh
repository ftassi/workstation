#!/bin/bash

PASSWORD_FILE=".passwords"
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

# Funzione per leggere la password di sudo da .passwords
get_sudo_password() {
    if [ ! -f "$PASSWORD_FILE" ]; then
        echo -e "\e[31m[ERRORE] Il file .passwords non esiste. Crealo con setup.sh.\e[0m"
        exit 1
    fi

    source "$PASSWORD_FILE"

    if [ -z "$SUDO_PASSWORD" ]; then
        echo -e "\e[31m[ERRORE] SUDO_PASSWORD non trovata in .passwords.\e[0m"
        exit 1
    fi

    echo "$SUDO_PASSWORD"
}

# Funzione per installare pacchetti con apt in modo idempotente
install_package() {
    local PACKAGE=$1

    if dpkg -s "$PACKAGE" &> /dev/null; then
        echo -e "\e[34m[INFO] Il pacchetto $PACKAGE è già installato. Skipping.\e[0m"
    else
        echo -e "\e[32m[INFO] Installazione di $PACKAGE...\e[0m"
        SUDO_PASSWORD=$(get_sudo_password)
        echo "$SUDO_PASSWORD" | sudo -S apt-get update -qq && sudo -S apt-get install -y "$PACKAGE"
    fi
}
#
# Funzione per eseguire comandi con sudo utilizzando la password dal file .passwords
sudo_exec() {
    echo "$SUDO_PASSWORD" | sudo -S "$@"
}
