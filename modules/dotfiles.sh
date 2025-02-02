#!/bin/bash
set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

info "Inizio provisioning dotfiles..."

#####################
# Configurazione
#####################

# Repository e branch da clonare
DOTFILES_REPO="git@github.com:ftassi/dotfiles.git"
DOTFILES_BRANCH="main"

# Directory di destinazione per il clone del repository
TARGET_DIR="$HOME/dotfiles"

# Calcola la directory base del provisioning (root del progetto)
BASE_DIR="$(cd "$(dirname "$0")/../" && pwd)"

# Percorso assoluto della chiave git-crypt (nella directory secrets del provisioning)
GIT_CRYPT_KEY_PATH="$BASE_DIR/secrets/dotfiles/git-crypt.key"

#####################
# Installazione di stow
#####################

info "Verifica installazione di stow..."
if ! command -v stow &>/dev/null; then
    info "stow non trovato, installo..."
    install_package "stow"
    success "stow installato."
else
    info "stow è già presente."
fi

#####################
# Clonazione/Aggiornamento del repository dotfiles
#####################

if [ ! -d "$TARGET_DIR" ]; then
    info "Clonazione del repository dotfiles da $DOTFILES_REPO (branch: $DOTFILES_BRANCH)..."
    git clone --branch "$DOTFILES_BRANCH" "$DOTFILES_REPO" "$TARGET_DIR"
    success "Repository clonata in $TARGET_DIR."
else
    info "Il repository dotfiles è già presente in $TARGET_DIR. Aggiorno il repository..."
    cd "$TARGET_DIR"
    git pull origin "$DOTFILES_BRANCH"
    cd - >/dev/null
fi

#####################
# Decriptazione dei secret tramite git-crypt
#####################

info "Decripto i secret dei dotfiles..."
cd "$TARGET_DIR"
if [ -f "$GIT_CRYPT_KEY_PATH" ]; then
    git-crypt unlock "$GIT_CRYPT_KEY_PATH"
    success "git-crypt ha sbloccato i secret."
else
    error "Chiave git-crypt non trovata in $GIT_CRYPT_KEY_PATH."
    exit 1
fi
cd - >/dev/null

#####################
# Installazione dei dotfiles tramite stow
#####################

# Elenco dei gruppi di dotfiles da linkare (modifica l'elenco in base alle tue necessità)
DOTFILES_LIST=("git" "intelephense")

info "Installazione dei dotfiles tramite stow..."
for package in "${DOTFILES_LIST[@]}"; do
    info "Stowing del gruppo '$package'..."
    stow -d "$TARGET_DIR" -t "$HOME" "$package"
done

success "Dotfiles installati correttamente."
success "Provisioning dotfiles completato."
