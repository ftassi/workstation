#!/bin/bash
set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

info "Installazione di regolith-desktop..."

info "Aggiunta della chiave GPG di Regolith..."
wget -qO - https://regolith-desktop.org/regolith.key | \
gpg --dearmor | sudo tee /usr/share/keyrings/regolith-archive-keyring.gpg > /dev/null

info "Aggiunta del repository di Regolith..."
echo deb "[arch=amd64 signed-by=/usr/share/keyrings/regolith-archive-keyring.gpg] \
https://regolith-desktop.org/release-3_2-ubuntu-noble-amd64 noble main" | \
sudo tee /etc/apt/sources.list.d/regolith.list

info "Aggiornamento dei repository e installazione di regolith-desktop..."
sudo apt update -qq 
sudo apt install -y regolith-desktop regolith-session-flashback regolith-look-lascaille

success "Regolith Desktop installato con successo!"
success "Riavvia il sistema per attivare Regolith Desktop."
