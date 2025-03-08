#!/bin/bash
#
# Bootstrap script per il provisioning della workstation
# Esegue il setup iniziale e avvia il processo di provisioning

set -euo pipefail

# Colori per output
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RESET="\033[0m"

# Funzioni di logging
info() { echo -e "${GREEN}[INFO] $1${RESET}"; }
error() { echo -e "${RED}[ERRORE] $1${RESET}"; }
warning() { echo -e "${YELLOW}[ATTENZIONE] $1${RESET}"; }
prompt() { echo -e "${CYAN}[INPUT] $1${RESET}"; }

# Directory corrente
CURRENT_DIR=$(pwd)

# Mostra banner iniziale
show_banner() {
    echo -e "${GREEN}"
    echo "  _      __           __        __        __  _           "
    echo " | | /| / /__  ____  / /__ ___ / /_____ _/ /_(_)__  ___   "
    echo " | |/ |/ / _ \/ __/ /  '_/(_-</ __/ __  / __/ / _ \/ _ \  "
    echo " |__/|__/\___/_/   /_/\_\/___/\__/\_,_/\__/_/\___/_//_/  "
    echo "                                                          "
    echo -e "${RESET}"
    echo "Script di bootstrap per il provisioning della workstation"
    echo "Questo script preparerà l'ambiente e avvierà il provisioning"
    echo -e "\n"
}

# Verifica e installa le dipendenze minime
check_dependencies() {
    info "Verifico le dipendenze minime..."
    
    # Verifica e installa git
    if ! command -v git &>/dev/null; then
        info "Git non trovato, installazione in corso..."
        sudo apt update
        sudo apt install -y git
        info "Git installato."
    else
        info "Git già installato."
    fi
    
    # Verifica e installa gnupg
    if ! command -v gpg &>/dev/null; then
        info "GnuPG non trovato, installazione in corso..."
        sudo apt update
        sudo apt install -y gnupg
        info "GnuPG installato."
    else
        info "GnuPG già installato."
    fi
    
    # Verifica e installa git-crypt
    if ! command -v git-crypt &>/dev/null; then
        info "git-crypt non trovato, installazione in corso..."
        sudo apt update
        sudo apt install -y git-crypt
        info "git-crypt installato."
    else
        info "git-crypt già installato."
    fi
}

# Clona il repository se necessario
clone_repository() {
    if [ -d "$CURRENT_DIR/.git" ]; then
        info "Repository git già presente nella directory corrente."
        return
    fi
    
    REPO_URL="https://github.com/ftassi/workstation.git"
    info "Clonazione del repository '$REPO_URL' nella directory corrente..."
    
    if [ "$(ls -A $CURRENT_DIR)" ]; then
        # La directory non è vuota
        warning "La directory corrente non è vuota."
        prompt "Vuoi clonare il repository in questa directory? [s/N]: "
        read -r response
        if [[ ! "$response" =~ ^[Ss]$ ]]; then
            error "Operazione annullata."
            exit 1
        fi
        
        git clone "$REPO_URL" temp_workstation
        mv temp_workstation/* temp_workstation/.* "$CURRENT_DIR" 2>/dev/null || true
        rm -rf temp_workstation
    else
        # La directory è vuota
        git clone "$REPO_URL" .
    fi
    
    info "Repository clonato con successo."
}

# Sblocca i file crittografati
unlock_encrypted_files() {
    if [ ! -f "./git-crypt.key.gpg" ]; then
        error "Il file git-crypt.key.gpg non esiste. Assicurati che il repository sia stato clonato correttamente."
        exit 1
    fi
    
    info "Sblocco dei file crittografati..."
    prompt "Inserisci la master password per decrittare i file:"
    read -s MASTER_PASSWORD
    echo ""
    
    # Utilizza la master password per decrittare la chiave git-crypt
    echo "$MASTER_PASSWORD" | gpg --batch --yes --passphrase-fd 0 -o git-crypt.key -d git-crypt.key.gpg
    
    # Verifica che la chiave sia stata estratta correttamente
    if [ ! -f "./git-crypt.key" ]; then
        error "Impossibile decrittare la chiave git-crypt. Verifica la password."
        exit 1
    fi
    
    # Sblocca il repository con git-crypt
    git-crypt unlock git-crypt.key
    
    # Rimuovi la chiave git-crypt in chiaro (per sicurezza)
    rm -f git-crypt.key
    
    info "File crittografati sbloccati con successo."
}

# Avvia il provisioning
start_provisioning() {
    info "Preparazione completata. Pronto per iniziare il provisioning."
    prompt "Vuoi avviare il provisioning ora? [S/n]: "
    read -r response
    if [[ "$response" =~ ^[Nn]$ ]]; then
        info "Provisioning non avviato. Puoi avviarlo manualmente con ./main.sh"
        exit 0
    fi
    
    info "Avvio del provisioning..."
    
    # Rendi lo script eseguibile se necessario
    if [ ! -x "./main.sh" ]; then
        chmod +x ./main.sh
    fi
    
    # Esegui lo script principale
    ./main.sh
}

# Esecuzione principale
main() {
    show_banner
    check_dependencies
    clone_repository
    unlock_encrypted_files
    start_provisioning
}

# Avvia l'esecuzione
main