#!/bin/bash
#
# Script di provisioning per ambiente di sviluppo
# Installa e configura strumenti di sviluppo, AWS CLI, GitHub CLI e Rust
# Richiede: curl, apt, wget

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

# Imposta la gestione errori avanzata
setup_error_handling


##############################
# Configurazione di base
##############################
# Directory in cui installare i file (namespace dedicato all'interno della distrobox)
INSTALL_DIR="$HOME/.local/"
# Directory per i symlink dei binari (se dovessi voler esportarli all'host in futuro)
EXPORT_BIN_DIR="$HOME/.local/bin"

info "Provisioning dell'ambiente di sviluppo..."

##############################
# Installazione dei pacchetti minimi
##############################
install_common() {
    info "[COMMON] Aggiornamento repository e installazione dei pacchetti base..."
    apt_update_if_needed
    sudo apt-get install -y \
        libssl-dev \
        git \
        tig \
        jq \
        curl \
        wget \
        httpie \
        tmux \
        tar \
        gzip \
        unzip
    success "[COMMON] Operazioni completate."

    info "Aggiornamento repository e installazione dei pacchetti CLI moderni..."
    sudo apt-get install -y \
        eza \
        bat \
        fd-find \
        ripgrep \
        duf \
        bpytop \
        zoxide \
        git-delta \
        hyperfine \
        direnv && success "Pacchetti CLI moderni installati."

}

##############################
# Installazione aws cli
##############################
install_awscli() {
    AWS_CLI_INSTALLER_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
    AWS_CLI_INSTALL_DIR="$INSTALL_DIR/aws"
    AWS_CLI_BIN_DIR="$AWS_CLI_INSTALL_DIR/bin"
    
    if [ -x "$AWS_CLI_BIN_DIR/aws" ]; then
        info "[AWSCLI] AWS CLI è già installato nell'ambiente isolato"
    else
        info "[AWSCLI] Installazione di AWS CLI..."
        curl "$AWS_CLI_INSTALLER_URL" -o "/tmp/awscliv2.zip"
        unzip /tmp/awscliv2.zip -d /tmp
        # Installa AWS CLI nella directory isolata
        /tmp/aws/install -i "$AWS_CLI_INSTALL_DIR" -b "$AWS_CLI_BIN_DIR"
        rm -rf /tmp/aws /tmp/awscliv2.zip
        success "[AWSCLI] Installazione completata."
    fi
}

##############################
# Installazione GitHub CLI
##############################
install_githubcli() {
    info "[GITHUBCLI] Installazione di GitHub CLI..."
    type -p wget >/dev/null || (apt_update_if_needed && sudo apt-get install wget -y)
    add_gpg_key "https://cli.github.com/packages/githubcli-archive-keyring.gpg" "/etc/apt/keyrings/githubcli-archive-keyring.gpg"
    add_apt_repository "github-cli.list" "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"
    sudo apt install gh -y
}

##############################
# Installa rust e cargo 
##############################
install_rust() {
    # Imposta le directory isolate per Cargo e Rustup all'interno del namespace
    local cargo_home="$INSTALL_DIR/cargo"
    local rustup_home="$INSTALL_DIR/rustup"

    # Installa cargo (e Rustup) in ambiente isolato se il binario non è presente
    if ! [ -x "$cargo_home/bin/cargo" ]; then
        info "[NEOVIM LSP] cargo non trovato nell'ambiente isolato: installazione tramite rustup in ambiente isolato..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
            | env CARGO_HOME="$cargo_home" RUSTUP_HOME="$rustup_home" sh -s -- -y
        success "[NEOVIM LSP] cargo (rustup) installato in ambiente isolato."
    else
        info "[NEOVIM LSP] cargo è già presente nell'ambiente isolato."
    fi
}

install_common
install_awscli
install_githubcli
install_rust
