#!/bin/bash
set -euo pipefail

# Inclusione delle funzioni comuni (es. info, error, success)
source "$(dirname "$0")/../common.sh"

##############################
# Configurazione di base
##############################
CONTAINER_NAME="nvim"
IMAGE="ubuntu:22.04"
# Neovim: installa la versione 0.10.3 scaricando il tarball ufficiale
NVIM_VERSION="0.10.3"
NVIM_TARBALL_URL="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux64.tar.gz"
# La directory dei dotfiles per neovim (già clonata dal modulo dotfiles)
DOTFILES_NVIM="$HOME/dotfiles/nvim"

info "Inizio provisioning della distrobox nvim..."

##############################
# Creazione della distrobox
##############################
if distrobox-list | grep -q "^${CONTAINER_NAME}\$"; then
    info "La distrobox '${CONTAINER_NAME}' esiste già."
else
    info "Creazione della distrobox '${CONTAINER_NAME}' dall'immagine ${IMAGE}..."
    # Creazione della distrobox montando la directory dei dotfiles per nvim
    distrobox-create --name "${CONTAINER_NAME}" --image "${IMAGE}" --yes
    success "Distrobox '${CONTAINER_NAME}' creata con successo."
fi

# Funzione per eseguire comandi all'interno della distrobox
enter() {
    distrobox-enter --name "${CONTAINER_NAME}" -- "$@"
}

##############################
# Ruolo comune (base) – installazione dei pacchetti minimi
##############################
role_common() {
    info "[COMMON] Aggiornamento repository e installazione dei pacchetti base..."
    enter sudo apt-get update -qq
    enter sudo apt-get install -y curl ca-certificates tar unzip
    success "[COMMON] Operazioni completate."
}

##############################
# Ruolo Neovim Main – installa Neovim e dipendenze per il suo corretto funzionamento
##############################
role_neovim_main() {
    info "[NEOVIM MAIN] Installazione di Neovim e delle dipendenze base..."

    # Installa le dipendenze per Neovim: python3-neovim, nodejs, npm
    enter sudo apt-get install -y python3-neovim nodejs npm

    # Verifica che la versione di Python sia >= 3.10
    PYTHON_VERSION=$(enter python3 --version 2>&1 | awk '{print $2}')
    if printf '%s\n' "$PYTHON_VERSION" "3.10" | sort -V -C; then
        info "[NEOVIM MAIN] Python version $PYTHON_VERSION è >= 3.10."
    else
        error "[NEOVIM MAIN] Python version $PYTHON_VERSION è inferiore a 3.10. Tentativo di aggiornamento..."
        enter sudo apt-get install -y python3.10 python3.10-venv python3.10-dev
    fi

    if ! enter command -v nvim &>/dev/null; then
        info "[NEOVIM MAIN] Neovim non trovato: installazione di Neovim ${NVIM_VERSION}..."
        enter bash -c "curl -fsSL '${NVIM_TARBALL_URL}' -o /tmp/nvim.tar.gz && sudo tar -xzf /tmp/nvim.tar.gz -C /usr/local --strip-components=1 && rm /tmp/nvim.tar.gz"
        success "[NEOVIM MAIN] Neovim ${NVIM_VERSION} installato."
    else
        info "[NEOVIM MAIN] Neovim è già installato."
    fi

    # Verifica che la directory dei dotfiles per neovim sia disponibile nella distrobox
    if ! enter test -d "/home/${USER}/dotfiles/nvim"; then
        error "[NEOVIM MAIN] La directory dei dotfiles per neovim non è presente nella distrobox."
        exit 1
    else
        success "[NEOVIM MAIN] La directory dei dotfiles per neovim è disponibile."
    fi
}

##############################
# Ruolo Neovim LSP – installa i tool a supporto degli LSP per Rust
##############################
role_neovim_lsp() {
    info "[NEOVIM LSP] Configurazione dei tool LSP..."
    # Rimuoviamo riferimenti a Go; installiamo strumenti per Rust.
    
    # Installa rust-analyzer se non presente
    if ! enter command -v rust-analyzer &>/dev/null; then
        info "[NEOVIM LSP] rust-analyzer non trovato: installazione..."
        enter bash -c "curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-linux -o /tmp/rust-analyzer && sudo mv /tmp/rust-analyzer /usr/local/bin/rust-analyzer && sudo chmod +x /usr/local/bin/rust-analyzer"
        success "[NEOVIM LSP] rust-analyzer installato."
    else
        info "[NEOVIM LSP] rust-analyzer è già presente."
    fi

    # Installa cargo se non presente, utilizzando rustup
    if ! enter command -v cargo &>/dev/null; then
        info "[NEOVIM LSP] cargo non trovato: installazione tramite rustup..."
        enter bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
        success "[NEOVIM LSP] cargo (rustup) installato."
    else
        info "[NEOVIM LSP] cargo è già presente."
    fi

    # Eventuali altre dipendenze per il supporto LSP di Rust possono essere aggiunte qui.
}

##############################
# Esportazione di Neovim per l'host
##############################
export_nvim() {
    info "Esportazione di Neovim dalla distrobox per esecuzione dall'host..."
    # Adattiamo il comando dalla documentazione:
    # Exporta il binario /usr/local/bin/nvim dalla distrobox in modo che l'host lo veda in ~/.local/bin
    distrobox-export --bin /usr/local/bin/nvim --export-path "$HOME/.local/bin" --extra-flags "-p"
    success "Neovim esportato correttamente. Ora puoi eseguirlo dall'host."
}

##############################
# Esecuzione dei ruoli in ordine
##############################
role_common
role_neovim_main
role_neovim_lsp
export_nvim

success "Provisioning della distrobox nvim completato con successo."
