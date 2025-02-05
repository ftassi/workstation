#!/bin/bash
set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

info "Installazione degli applicativi GUI..."

# Lettura della password run_sudo
SUDO_PASSWORD=$(get_sudo_password)
 
# Aggiornamento della lista dei pacchetti e installazione dei tool necessari
info "Aggiornamento del sistema e installazione delle dipendenze..."
run_sudo apt update
run_sudo apt install -y wget curl gnupg2 software-properties-common apt-transport-https

##############################
# Installazione di Google Chrome
##############################
if command -v google-chrome &>/dev/null; then
    info "Google Chrome è già installato."
else
    info "Installazione di Google Chrome..."
    # Scarica il pacchetto deb di Chrome
    wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    # Installa il pacchetto e risolve eventuali dipendenze mancanti
    run_sudo dpkg -i /tmp/google-chrome.deb || run_sudo apt install -f -y
fi

##############################
# Installazione di Slack
##############################

if command -v slack &>/dev/null; then
    info "Slack è già installato."
else
    info "Installazione di Slack..."
    # Scarica il pacchetto deb di Slack
    # (Controlla sul sito ufficiale di Slack per aggiornare la versione se necessario)
    wget -O /tmp/slack.deb https://downloads.slack-edge.com/desktop-releases/linux/x64/4.41.105/slack-desktop-4.41.105-amd64.deb
    # Installa il pacchetto e risolve eventuali dipendenze mancanti
    run_sudo dpkg -i /tmp/slack.deb || run_sudo apt install -f -y
fi

##############################
# Installazione di 1Password
##############################
if [ "$(dpkg -l | awk '/1password/ {print }'|wc -l)" -ge 1 ]; then
    info "1password è già installato"
else
    info "Installazione di 1Password..."
    # Scarica il pacchetto deb di Chrome
    wget -O /tmp/1password-latest.deb https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb
    # Installa il pacchetto e risolve eventuali dipendenze mancanti
    run_sudo dpkg -i /tmp/1password-latest.deb || run_sudo apt install -f -y
fi

##############################
# Installazione di Firefox
##############################
if command -v firefox &>/dev/null; then
    info "Firefox è già installato."
else
    info "Installazione di Firefox..."
    # Su Ubuntu 22.04 Firefox viene installato come Snap per impostazione predefinita.
    run_sudo apt install -y firefox
fi


info "Installazione completata con successo!"
