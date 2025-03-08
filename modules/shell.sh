#!/bin/bash
#
# Script di provisioning per configurazioni shell
# Installa e configura zsh, oh-my-zsh e plugin correlati
# Richiede: git, curl

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

# Imposta la gestione errori avanzata
setup_error_handling

info "Inizio provisioning shell..."

#####################
# Verifica dei prerequisiti
#####################
if [ ! -d "$HOME/dotfiles" ]; then
    die "La directory dotfiles ($HOME/dotfiles) non esiste. Assicurati di aver eseguito il modulo dotfiles prima."
fi

#####################
# Sottomoduli (funzioni interne)
#####################

install_distrobox() {
    info "Installo dipendenze per distrobox..."
    apt_update_if_needed && sudo apt-get install -y curl podman xsel flatpak

    if ! command -v distrobox &>/dev/null; then
        info "Distrobox non trovato, installo..."
        curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh -s -- --prefix "$HOME/.local"
        export PATH="$HOME/.local/bin:$PATH"

        info "Installazione di podman (richiesto da distrobox)..."
        sudo apt-get install -y podman
        success "Distrobox installato."
    else
        info "Distrobox già installato."
    fi
}

install_cli_tools() {
    info "Aggiornamento repository e installazione dei pacchetti CLI moderni..."
    apt_update_if_needed
    sudo apt-get install -y software-properties-common
    add_apt_repository "aslatter-ppa.list" "deb http://ppa.launchpad.net/aslatter/ppa/ubuntu $(lsb_release -cs) main"

    # Pacchetti fondamentali per avere una shell moderna
    sudo apt-get install -y zsh zsh-antigen alacritty

    # Utility moderne che sostituiscono strumenti tradizionali
    sudo apt-get install -y eza bat fd-find ripgrep
    sudo apt-get install -y duf bpytop
    sudo apt-get install -y zoxide git-delta hyperfine
    sudo apt-get install -y direnv

    sudo snap install dust
                                    

    success "Pacchetti CLI moderni installati."
}


setup_zsh() {
    info "Configurazione di zsh..."
    HIST_DIR="$HOME/.local/share/zsh"
    HISTFILE="$HIST_DIR/histfile"
    mkdir -p "$HIST_DIR"
    if [ ! -f "$HISTFILE" ]; then
        touch "$HISTFILE"
        chmod 600 "$HISTFILE"
        info "Histfile creato in $HISTFILE con permessi 600."
    else
        chmod 600 "$HISTFILE"
        info "Histfile esistente in $HISTFILE, permessi aggiornati a 600."
    fi
    CURRENT_USER=$(whoami)
    sudo usermod --shell /usr/bin/zsh "$CURRENT_USER"
    success "Zsh impostata come shell predefinita per l'utente $CURRENT_USER."
}

link_shell_dotfiles() {
    info "Esecuzione del linking dei dotfiles per la shell..."
    # Lista dei gruppi di dotfiles da linkare per la configurazione della shell
    config_items=("alacritty" "zsh" "antigen")
    for item in "${config_items[@]}"; do
        if [ -d "$HOME/dotfiles/$item" ]; then
            info "Linking della configurazione '$item'..."
            (cd "$HOME/dotfiles" && stow "$item")
        else
            error "Configurazione '$item' non trovata nella directory $HOME/dotfiles."
            die "Errore durante l'esecuzione"
        fi
    done
    success "Linking dei dotfiles per la shell completato."
}

#####################
# Esecuzione in ordine controllato
#####################

install_distrobox
install_cli_tools
setup_zsh
link_shell_dotfiles

success "Provisioning shell completato con successo."
