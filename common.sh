#!/bin/bash

# Colorazioni per il logging
GREEN="\033[0;32m"
RED="\033[0;31m"
RESET="\033[0m"

# Funzioni di logging
info()    { echo -e "${GREEN}[INFO] $1${RESET}"; }
error()   { echo -e "${RED}[ERRORE] $1${RESET}"; }
success() { echo -e "${GREEN}[SUCCESSO] $1${RESET}"; }

# Funzione per terminare lo script in caso di errore fatale
# Parametro opzionale: messaggio di errore personalizzato
die() {
    local error_message="${1:-Si è verificato un errore fatale. Uscita dallo script.}"
    error "$error_message"
    # Termina lo script con codice di errore
    exit 1
}

# Funzione per configurare la gestione degli errori
# Da chiamare all'inizio di ogni script
setup_error_handling() {
    # Impostazioni per gestione errori:
    # -e: termina script se un comando restituisce un valore diverso da zero
    # -u: termina script se si cerca di utilizzare variabili non definite
    # -o pipefail: se un comando in una pipe fallisce, fallisce l'intera pipe
    set -euo pipefail
    
    # Imposta il trap per la gestione degli errori
    # In caso di errore chiama la funzione die
    trap die ERR
}

# Funzione per ottenere la master password in modo sicuro
prompt_master_password() {
    info "[INPUT] Inserisci la master password:"
    read -s MASTER_PASSWORD
    echo ""
    echo "$MASTER_PASSWORD"
}

# Funzione per aggiungere una chiave GPG in modo idempotente
# $1: URL o percorso della chiave
# $2: percorso di destinazione della chiave
add_gpg_key() {
    local key_url="$1"
    local key_path="$2"
    
    if [ ! -f "$key_path" ]; then
        info "Aggiunta della chiave GPG in $key_path..."
        
        # Crea la directory se non esiste
        sudo install -m 0755 -d "$(dirname "$key_path")"
        
        # Se l'URL inizia con http o https, usa curl, altrimenti considera un file locale
        if [[ "$key_url" =~ ^https?:// ]]; then
            wget -qO - "$key_url" | gpg --dearmor | sudo tee "$key_path" > /dev/null
        else
            cat "$key_url" | gpg --dearmor | sudo tee "$key_path" > /dev/null
        fi
        
        # Imposta i permessi corretti
        sudo chmod a+r "$key_path"
        success "Chiave GPG aggiunta."
    else
        info "La chiave GPG è già presente in $key_path."
    fi
}

# Funzione per aggiungere un repository apt in modo idempotente
# $1: nome del file list (es. "docker.list")
# $2: contenuto del repository
add_apt_repository() {
    local repo_file="/etc/apt/sources.list.d/$1"
    local repo_content="$2"
    
    if [ ! -f "$repo_file" ]; then
        info "Aggiunta del repository in $repo_file..."
        echo "$repo_content" | sudo tee "$repo_file" > /dev/null
        success "Repository aggiunto."
        
        # Aggiorna apt solo se un nuovo repository è stato aggiunto
        info "Aggiornamento degli indici apt..."
        sudo apt-get update -qq
    else
        info "Il repository è già configurato in $repo_file."
    fi
}

