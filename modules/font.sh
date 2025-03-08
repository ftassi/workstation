#!/bin/bash
#
# Script di provisioning per font
# Installa e configura i font necessari per il sistema
# Richiede: curl, unzip

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

# Imposta la gestione errori avanzata
setup_error_handling

##############################
# Configurazione di base
##############################
FONT_VERSION="3.3.0"
FONT_NAME="JetBrainsMono"
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v${FONT_VERSION}/${FONT_NAME}.zip"
FONT_DIR="$HOME/.fonts/jetbrains-mono-nerd"
TEMP_DIR="/tmp"

##############################
# Verifica se il font è installato
##############################
is_font_installed() {
    fc-list -f '%{family}\n' | awk '!x[$0]++' | grep -q "JetBrainsMono Nerd"
    return $?
}

check_font_installed() {
    info "Verifica se il font JetBrainsMono Nerd Font è già installato..."
    
    if is_font_installed; then
        success "Il font JetBrainsMono Nerd Font è già installato. Nessuna azione necessaria."
        exit 0
    else
        info "Il font JetBrainsMono Nerd Font non è installato. Procedo con l'installazione..."
    fi
}

info "Inizio installazione del font JetBrainsMono Nerd Font..."

##############################
# Installazione dei pacchetti necessari
##############################
install_dependencies() {
    info "Verifica/installazione delle dipendenze necessarie..."
    if ! command -v unzip &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y unzip
        success "Unzip installato."
    else
        info "Unzip è già presente."
    fi
}

##############################
# Scarica e installa il font
##############################
install_font() {
    info "Scaricamento e installazione del font JetBrainsMono Nerd Font v${FONT_VERSION}..."
    
    # Scarica il font
    info "Scaricamento del font da ${FONT_URL}..."
    curl -fsSL "$FONT_URL" -o "$TEMP_DIR/${FONT_NAME}.zip"
    success "Font scaricato in $TEMP_DIR/${FONT_NAME}.zip."
    
    # Estrai il font
    info "Estrazione del font..."
    unzip -q "$TEMP_DIR/${FONT_NAME}.zip" -d "$TEMP_DIR/${FONT_NAME}"
    success "Font estratto."
    
    # Crea la directory dei font se non esiste
    mkdir -p "$FONT_DIR"
    info "Directory dei font creata: $FONT_DIR"
    
    # Sposta i file dei font nella directory dei font
    info "Spostamento dei file dei font nella directory dei font..."
    mv "$TEMP_DIR/${FONT_NAME}/"*.ttf "$FONT_DIR/"
    success "File dei font spostati in $FONT_DIR."
    
    # Aggiorna la cache dei font
    info "Aggiornamento della cache dei font..."
    fc-cache -f -v > /dev/null
    success "Cache dei font aggiornata."
    
    # Pulizia
    info "Pulizia dei file temporanei..."
    rm -rf "$TEMP_DIR/${FONT_NAME}.zip" "$TEMP_DIR/${FONT_NAME}"
    success "File temporanei rimossi."
}

##############################
# Verifica l'installazione
##############################
verify_installation() {
    info "Verifica dell'installazione del font..."
    
    if is_font_installed; then
        success "Font JetBrainsMono Nerd Font installato correttamente."
    else
        error "Installazione del font non riuscita. Controlla manualmente."
        cleanup "Errore durante l'esecuzione"
    fi
}

##############################
# Esecuzione dei ruoli in ordine
##############################
check_font_installed
install_dependencies
install_font
verify_installation

success "Installazione del font JetBrainsMono Nerd Font completata con successo."
