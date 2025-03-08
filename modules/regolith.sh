#!/bin/bash
#
# Script di provisioning per Regolith Desktop
# Installa e configura l'ambiente desktop Regolith basato su i3wm
# Richiede: wget, gpg, apt

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

# Imposta la gestione errori avanzata
setup_error_handling

info "Installazione di regolith-desktop..."

# Aggiunta della chiave GPG di Regolith in modo idempotente
add_gpg_key "https://regolith-desktop.org/regolith.key" "/usr/share/keyrings/regolith-archive-keyring.gpg"

# Aggiunta del repository di Regolith in modo idempotente
REPO_LINE="deb [arch=amd64 signed-by=/usr/share/keyrings/regolith-archive-keyring.gpg] https://regolith-desktop.org/release-3_2-ubuntu-noble-amd64 noble main"
add_apt_repository "regolith.list" "$REPO_LINE"

info "Installazione di regolith-desktop..."
sudo apt install -y regolith-desktop regolith-session-flashback regolith-look-nord

regolith-look set nord

stow -d "$HOME/dotfiles" -t "$HOME" regolith

success "Regolith Desktop installato con successo!"
success "Riavvia il sistema per attivare Regolith Desktop."
