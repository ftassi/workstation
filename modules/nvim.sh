#!/bin/bash
#
# Script di provisioning per Neovim
# Installa e configura l'editor Neovim e i plugin necessari
# Richiede: curl, tar, git

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

# Imposta la gestione errori avanzata
setup_error_handling

##############################
# Configurazione di base
##############################
NVIM_VERSION="0.10.3"
NVIM_TARBALL_URL="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux64.tar.gz"

# Directory in cui installare i file (namespace dedicato all'interno della distrobox)
INSTALL_DIR="$HOME/.local"

info "Inizio provisioning di Neovim in questa distrobox..."

##############################
# Installazione dei pacchetti minimi
##############################
install_common() {
    info "[COMMON] Aggiornamento repository e installazione dei pacchetti base..."
    apt_update_if_needed
    sudo apt-get install -y curl ca-certificates tar unzip ripgrep fd-find xsel
    success "[COMMON] Operazioni completate."
}

##############################
# Installa Neovim e le dipendenze base
##############################
install_neovim_main() {
    info "[NEOVIM MAIN] Installazione di Neovim e delle dipendenze base..."

    # Crea la directory di installazione se non esiste
    mkdir -p "$INSTALL_DIR"

    sudo apt-get remove --purge -y neovim
    if ! command -v nvim &>/dev/null; then
        info "[NEOVIM MAIN] Neovim non trovato: installazione di Neovim ${NVIM_VERSION}..."
        curl -fsSL "$NVIM_TARBALL_URL" -o /tmp/nvim.tar.gz \
            && sudo tar --no-same-owner -xzf /tmp/nvim.tar.gz -C "$INSTALL_DIR" --strip-components=1 \
            && rm /tmp/nvim.tar.gz
        sudo chown -R $USER:$USER ~/.local/bin/nvim ~/.local/lib/nvim ~/.local/share/nvim
        success "[NEOVIM MAIN] Neovim ${NVIM_VERSION} installato in $INSTALL_DIR."
        info "[ALTERNATIVES] Configurazione di Neovim come alternativa a vim..."
        sudo update-alternatives --install /usr/bin/vim vim "$INSTALL_DIR/bin/nvim" 60
        sudo update-alternatives --set vim "$INSTALL_DIR/bin/nvim"
        success "[ALTERNATIVES] Neovim configurato come default per 'vim'."

    else
        info "[NEOVIM MAIN] Neovim è già installato."
    fi

    # Installazione di pip per Python3 (se non è già presente)
    info "[PYTHON] Verifica/installazione di python..."
    if ! command -v pip3 &>/dev/null; then
        sudo apt-get install -y python3-pynvim python3-pip python3-dev
        info "[PYTHON] python installato."
    else
        info "[PYTHON] python è già presente."
    fi

    # Imposta la directory per nvm all'interno dell'INSTALL_DIR
    NVM_DIR="$INSTALL_DIR/.nvm"
    info "[NODE] Installazione di nvm in $NVM_DIR..."
    mkdir -p "$NVM_DIR"
    # Usa env per propagare NVM_DIR allo script di installazione
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | env NVM_DIR="$NVM_DIR" bash
    success "[NODE] nvm installato in $NVM_DIR."

    # Installa Node.js versione 22 tramite nvm
    info "[NODE] Installazione di Node.js versione 22 tramite nvm..."
    export NVM_DIR="$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && nvm install 22 && nvm use 22

    info "[NODE] Impostazione di Node.js versione 22 come default..."
    source "$NVM_DIR/nvm.sh" && nvm alias default 22

    info "[NODE] Installazione del pacchetto 'neovim' tramite npm..."
    if ! bash -c "export NVM_DIR=\"$NVM_DIR\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && npm list -g neovim >/dev/null 2>&1"; then
        bash -c "export NVM_DIR=\"$NVM_DIR\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && npm install -g neovim"
        info "[NODE] Pacchetto 'neovim' installato globalmente."
    else
        info "[NODE] Pacchetto 'neovim' già presente globalmente."
    fi


}

##############################
# Installa i tool LSP per Rust
##############################
install_neovim_lsp() {
    info "[NEOVIM LSP] Configurazione dei tool LSP..."

    # Installa rust-analyzer se non presente
    if ! command -v rust-analyzer &>/dev/null; then
        info "[NEOVIM LSP] rust-analyzer non trovato: installazione..."
        curl -L https://github.com/rust-analyzer/rust-analyzer/releases/latest/download/rust-analyzer-linux \
            -o /tmp/rust-analyzer \
            && sudo mv /tmp/rust-analyzer /usr/local/bin/rust-analyzer \
            && sudo chmod +x /usr/local/bin/rust-analyzer
        success "[NEOVIM LSP] rust-analyzer installato."
    else
        info "[NEOVIM LSP] rust-analyzer è già presente."
    fi

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

##############################
# Installa Luarocks (se necessario)
##############################
install_luarocks() {
    info "[LUA] Verifica/installazione di Luarocks..."
    if ! command -v luarocks &>/dev/null; then
        info "[LUA] Luarocks non trovato: installazione in corso..."
        apt_update_if_needed
        sudo apt-get install -y luarocks
        success "[LUA] Luarocks installato."
    else
        info "[LUA] Luarocks è già presente."
    fi
}

##############################
# Installazione delle dipendenze extra per i plugin
##############################
install_neovim_extra_deps() {
    info "[NEOVIM EXTRA] Installazione delle dipendenze extra per i plugin..."
    if ! command -v composer &>/dev/null; then
        info "[NEOVIM EXTRA] Composer non trovato: installazione..."
        sudo apt-get install -y composer
        success "[NEOVIM EXTRA] Composer installato."
    else
        info "[NEOVIM EXTRA] Composer è già presente."
    fi
}

##############################
# Installazione dei plugin Neovim tramite Plug
##############################
install_neovim_plugins() {
    info "[NEOVIM PLUGINS] Installazione dei plugin tramite Plug..."
    nvim --headless +PlugClean! +qa
    nvim --headless +PlugInstall! +qa
    info "[NEOVIM PLUGINS] Installazione dei plugin e degli LSP tramite Mason in corso..."
}


##############################
# Esecuzione dei ruoli in ordine
##############################
install_common
install_luarocks
install_neovim_main
install_neovim_lsp
install_neovim_extra_deps
install_neovim_plugins

success "Provisioning di Neovim nella distrobox completato con successo."
