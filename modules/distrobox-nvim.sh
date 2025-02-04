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

# Directory in cui installare i file all'interno della distrobox
INSTALL_DIR="$HOME/opt/distroboxes/${CONTAINER_NAME}"
# Directory per i symlink dei binari, visibile all'host
EXPORT_BIN_DIR="$HOME/.local/distroboxes/${CONTAINER_NAME}/bin"

info "Inizio provisioning della distrobox nvim..."

##############################
# Creazione della distrobox
##############################
if distrobox-list | grep -q "^${CONTAINER_NAME}\$"; then
    info "La distrobox '${CONTAINER_NAME}' esiste già."
else
    info "Creazione della distrobox '${CONTAINER_NAME}' dall'immagine ${IMAGE}..."
    distrobox-create --name "${CONTAINER_NAME}" --image "${IMAGE}"
    success "Distrobox '${CONTAINER_NAME}' creata con successo."
fi

# Funzione per eseguire comandi all'interno della distrobox
enter() {
    distrobox-enter --name "${CONTAINER_NAME}" -- "$@"
}

##############################
# Ruolo comune (base) – installazione dei pacchetti minimi
##############################
install_common() {
    info "[COMMON] Aggiornamento repository e installazione dei pacchetti base..."
    enter sudo apt-get update -qq
    enter sudo apt-get install -y curl ca-certificates tar unzip ripgrep fd-find xsel
    success "[COMMON] Operazioni completate."
}

##############################
# Ruolo Neovim Main – installa Neovim e le dipendenze base
##############################
install_neovim_main() {
    info "[NEOVIM MAIN] Installazione di Neovim e delle dipendenze base..."

    # Crea la directory di installazione specifica per questa distrobox (se non esiste)
    enter mkdir -p "$INSTALL_DIR"

    # Installazione di pip per Python3 (se non è già presente)
    info "[PYTHON] Verifica/installazione di python..."
    if ! enter command -v pip3 &>/dev/null; then
        enter sudo apt-get install -y python3-neovim python3-pip python3.10 python3.10-venv python3.10-dev python3-pip
        info "[PYTHON] python installato."
    else
        info "[PYTHON] python è già presente."
    fi

    $NVN_DIR="$HOME/opt/distroboxes/nvim/.nvm"
    # Installazione di nvm in una directory dedicata alla distrobox nvim
    info "[NODE] Installazione di nvm nella directory dedicata alla distrobox..."
    enter bash -c "mkdir -p \"$NVN_DIR\""
    enter bash -c 'export NVM_DIR=\"$NVM_DIR\" && curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
    success "[NODE] nvm installato in $NVN_DIR."

    # Usando nvm installiamo Node.js versione 22 e impostiamo la versione in uso
    info "[NODE] Installazione di Node.js versione 22 tramite nvm..."
    enter bash -c "export NVM_DIR=\"$NVM_DIR\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && nvm install 22 && nvm use 22"

    info "[NODE] Impostazione di Node.js versione 22 come default..."
    enter bash -c "export NVM_DIR=\"$NVM_DIR\" && . \"\$NVM_DIR/nvm.sh\" && nvm alias default 22"

    info "[NODE] Verifica delle versioni di Node.js e npm..."
    NODE_VERSION=$(enter bash -c "export NVM_DIR=\"$NVM_DIR\" && . \"\$NVM_DIR/nvm.sh\" && node --version")
    NPM_VERSION=$(enter bash -c "export NVM_DIR=\"$NVM_DIR\" && . \"\$NVM_DIR/nvm.sh\" && npm --version")
    info "[NODE] Node.js version: $NODE_VERSION, npm version: $NPM_VERSION"

    info "[NODE] Verifica/installazione del pacchetto 'neovim' tramite npm..."
    if ! enter bash -c "export NVM_DIR=\"$NVM_DIR\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && npm list -g neovim >/dev/null 2>&1"; then
        enter bash -c "export NVM_DIR=\"$NVM_DIR\" && [ -s \"\$NVM_DIR/nvm.sh\" ] && . \"\$NVM_DIR/nvm.sh\" && npm install -g neovim"
        info "[NODE] Pacchetto 'neovim' installato globalmente."
    else
        info "[NODE] Pacchetto 'neovim' già presente globalmente."
    fi

    if ! enter command -v nvim &>/dev/null; then
        info "[NEOVIM MAIN] Neovim non trovato: installazione di Neovim ${NVIM_VERSION}..."
        enter bash -c "curl -fsSL \"$NVIM_TARBALL_URL\" -o /tmp/nvim.tar.gz && sudo tar --no-same-owner -xzf /tmp/nvim.tar.gz -C \"$INSTALL_DIR\" --strip-components=1 && rm /tmp/nvim.tar.gz"
        success "[NEOVIM MAIN] Neovim ${NVIM_VERSION} installato in $INSTALL_DIR."
    else
        info "[NEOVIM MAIN] Neovim è già installato."
    fi

    info "[ALTERNATIVES] Configurazione di Neovim come alternativa a vim..."
    # Registra Neovim come alternativa per 'vim' con una priorità (ad esempio, 60)
    enter sudo update-alternatives --install /usr/bin/vim vim "$HOME/.local/distroboxes/nvim/bin/nvim" 60
    # Imposta Neovim come default per 'vim'
    enter sudo update-alternatives --set vim "$HOME/.local/distroboxes/nvim/bin/nvim"
    success "[ALTERNATIVES] Neovim configurato come default per 'vim'."


}

##############################
# Ruolo Neovim LSP – installa i tool LSP per Rust
##############################
install_neovim_lsp() {
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

    # Installa cargo se non presente, tramite rustup
    if ! enter command -v cargo &>/dev/null; then
        info "[NEOVIM LSP] cargo non trovato: installazione tramite rustup..."
        enter bash -c "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
        success "[NEOVIM LSP] cargo (rustup) installato."
    else
        info "[NEOVIM LSP] cargo è già presente."
    fi
}

install_luarocks() {
    info "[LUA] Verifica/installazione di Luarocks..."
    if ! enter command -v luarocks &>/dev/null; then
        info "[LUA] Luarocks non trovato: installazione in corso..."
        enter sudo apt-get update -qq
        enter sudo apt-get install -y luarocks
        success "[LUA] Luarocks installato."
    else
        info "[LUA] Luarocks è già presente."
    fi
}

##############################
# Ruolo Extra – installazione delle dipendenze extra per i plugin
##############################
install_neovim_extra_deps() {
    info "[NEOVIM EXTRA] Installazione delle dipendenze extra per i plugin..."
    # Installa composer, necessario per alcuni plugin (es. telescope-fzy-native)
    if ! enter command -v composer &>/dev/null; then
        info "[NEOVIM EXTRA] Composer non trovato: installazione..."
        enter sudo apt-get install -y composer
        success "[NEOVIM EXTRA] Composer installato."
    else
        info "[NEOVIM EXTRA] Composer è già presente."
    fi
}

##############################
# Installazione dei plugin Neovim tramite Mason
##############################
install_neovim_plugins() {
    #
    # Verifica che la directory dei dotfiles per neovim sia disponibile nella distrobox
    if ! enter test -d "/home/${USER}/dotfiles/nvim"; then
        error "[NEOVIM PLUGINS] La directory dei dotfiles per neovim non è presente nella distrobox."
        error "[NEOVIM PLUGINS] Assicurati di aver clonato i dotfiles per neovim nella distrobox."
        exit 1
    else
        success "[NEOVIM MAIN] La directory dei dotfiles per neovim è disponibile."
    fi

    info "[NEOVIM PLUGINS] Installa plugin tramite Plug..."
    enter nvim --headless +PlugClean! +qa
    enter nvim --headless +PlugInstall! +qa
    info "[NEOVIM PLUGINS] Installazione dei plugin e degli LSP tramite Mason..."
    # Esegue Neovim in modalità headless per avviare Mason e installare tutti i plugin e LSP configurati
}

##############################
# Esportazione di Neovim per l'host
##############################
export_nvim() {
    info "Esportazione di Neovim dalla distrobox per esecuzione dall'host..."
    # Esporta il binario installato in INSTALL_DIR/bin/nvim verso EXPORT_BIN_DIR
    enter distrobox-export --bin "${HOME}/.local/bin/nvim" --export-path "$EXPORT_BIN_DIR" --extra-flags "-p"
    success "Neovim esportato correttamente. I symlink sono stati creati in $EXPORT_BIN_DIR."
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
# export_nvim

success "Provisioning della distrobox nvim completato con successo."
