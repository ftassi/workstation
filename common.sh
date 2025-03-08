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
        # Marchiamo che l'update sarà necessario prima di iniziare la modifica
        mark_apt_update_needed
        
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

# File temporaneo per tenere traccia del timestamp dell'ultimo apt update
APT_UPDATE_TIMESTAMP_FILE="/tmp/apt_update_timestamp"
# Intervallo in secondi dopo il quale fare un nuovo apt update (5 minuti)
APT_UPDATE_INTERVAL=300

# Funzione per eseguire apt update solo se necessario
apt_update_if_needed() {
    # Forza l'update se il parametro "force" è passato
    local force=${1:-0}
    local current_time
    current_time=$(date +%s)
    local next_update_time=0
    
    # Se il file esiste, leggi il timestamp del prossimo update necessario
    if [ -f "$APT_UPDATE_TIMESTAMP_FILE" ]; then
        next_update_time=$(cat "$APT_UPDATE_TIMESTAMP_FILE")
    fi
    
    # Se è ora di fare update o se force=1
    if [ "$force" -eq 1 ] || [ "$current_time" -ge "$next_update_time" ]; then
        info "Aggiornamento degli indici apt..."
        sudo apt-get update -qq
        # Imposta il prossimo update a current_time + intervallo
        echo $((current_time + APT_UPDATE_INTERVAL)) > "$APT_UPDATE_TIMESTAMP_FILE"
        success "Indici apt aggiornati. Prossimo update non prima di $(date -d @$((current_time + APT_UPDATE_INTERVAL)))"
    else
        # Calcola quanto tempo manca al prossimo update
        local remaining=$((next_update_time - current_time))
        info "Indici apt già aggiornati, prossimo update tra $remaining secondi."
    fi
}

# Funzione per marcare gli indici apt come necessitanti un aggiornamento immediato
mark_apt_update_needed() {
    # Imposta il timestamp a 0 per forzare un update immediato al prossimo controllo
    echo "0" > "$APT_UPDATE_TIMESTAMP_FILE"
    info "Marcato aggiornamento apt come necessario."
}

# Funzione per aggiungere un repository apt in modo idempotente
# $1: nome del file list (es. "docker.list")
# $2: contenuto del repository
add_apt_repository() {
    local repo_file="/etc/apt/sources.list.d/$1"
    local repo_content="$2"
    
    if [ ! -f "$repo_file" ]; then
        # Marchiamo che l'update sarà necessario prima di iniziare la modifica
        mark_apt_update_needed
        
        info "Aggiunta del repository in $repo_file..."
        echo "$repo_content" | sudo tee "$repo_file" > /dev/null
        success "Repository aggiunto."
        
        # Aggiorna apt solo se un nuovo repository è stato aggiunto
        apt_update_if_needed 1  # Forza l'update
    else
        info "Il repository è già configurato in $repo_file."
    fi
}

