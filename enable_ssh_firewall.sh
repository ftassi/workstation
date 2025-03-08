#!/bin/bash

set -e

usage() {
    echo "Usage: $0 [--disable]"
    exit 1
}

DISABLE=false
if [[ "$1" == "--disable" ]]; then
    DISABLE=true
fi

if [ "$DISABLE" = false ]; then
    # Controlla se OpenSSH Server è installato
    if ! dpkg -l | grep -q "openssh-server"; then
        echo "Installazione di OpenSSH Server..."
        source "$(dirname "$0")/common.sh"
        apt_update_if_needed && sudo apt install -y openssh-server
    else
        echo "OpenSSH Server è già installato."
    fi

    # Abilita e avvia il servizio SSH se non è già attivo
    if ! systemctl is-active --quiet ssh; then
        echo "Abilitazione e avvio del servizio SSH..."
        sudo systemctl enable ssh
        sudo systemctl start ssh
    else
        echo "Il servizio SSH è già attivo."
    fi

    # Controlla se il firewall UFW è installato
    if ! command -v ufw &> /dev/null; then
        echo "Installazione di UFW..."
        # Se non abbiamo già caricato common.sh, caricalo
        if ! type apt_update_if_needed &>/dev/null; then
            source "$(dirname "$0")/common.sh"
        fi
        apt_update_if_needed && sudo apt install -y ufw
    else
        echo "UFW è già installato."
    fi

    # Abilita UFW se non è già attivo
    if ! sudo ufw status | grep -q "Status: active"; then
        echo "Abilitazione di UFW..."
        sudo ufw enable
    else
        echo "UFW è già abilitato."
    fi

    # Consenti il traffico SSH se non è già consentito
    if ! sudo ufw status | grep -q "OpenSSH"; then
        echo "Consentire il traffico SSH su UFW..."
        sudo ufw allow OpenSSH
    else
        echo "Il traffico SSH è già consentito."
    fi
else
    echo "Disattivazione SSH e chiusura porte firewall..."
    sudo systemctl stop ssh
    sudo systemctl disable ssh
    sudo ufw deny OpenSSH
    echo "SSH disabilitato e porte firewall chiuse."
fi

# Mostra lo stato finale del firewall
sudo ufw status verbose
