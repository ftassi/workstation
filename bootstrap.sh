#!/bin/bash
#
# Bootstrap script per il provisioning della workstation
# Esegue il setup iniziale e avvia il processo di provisioning
# 
# Questo script clona il repository in una directory 'provisioning'
# nella directory corrente, sblocca i file crittografati e opzionalmente
# avvia il provisioning completo.

set -euo pipefail

# Funzione per gestire l'interruzione dello script
cleanup_and_exit() {
    echo -e "\n[ATTENZIONE] Script interrotto dall'utente."
    exit 1
}

# Imposta il trap per catturare Ctrl+C
trap cleanup_and_exit INT

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

# Directory di provisioning (sottodirectory della directory corrente)
PROVISIONING_DIR="$(pwd)/provisioning"

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
    
    # Verifica e installa curl
    if ! command -v curl &>/dev/null; then
        info "curl non trovato, installazione in corso..."
        sudo apt update
        sudo apt install -y curl
        info "curl installato."
    else
        info "curl già installato."
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

# Clona il repository nella directory di provisioning
clone_repository() {
    # Verifica se la directory provisioning esiste già
    if [ -d "$PROVISIONING_DIR" ]; then
        error "La directory '$PROVISIONING_DIR' esiste già."
        info "Per favore, rimuovi o rinomina la directory e riprova."
        exit 1
    fi
    
    # Crea la directory provisioning
    info "Creazione della directory '$PROVISIONING_DIR'..."
    mkdir -p "$PROVISIONING_DIR"
    
    # Clona il repository
    REPO_URL="https://github.com/ftassi/workstation.git"
    info "Clonazione del repository '$REPO_URL' nella directory '$PROVISIONING_DIR'..."
    git clone "$REPO_URL" "$PROVISIONING_DIR"
    
    # Cambia directory nel repository clonato
    cd "$PROVISIONING_DIR"
    
    info "Repository clonato con successo in '$PROVISIONING_DIR'."
}

# Sblocca i file crittografati
unlock_encrypted_files() {
    if [ ! -f "./git-crypt.key.gpg" ]; then
        error "Il file git-crypt.key.gpg non esiste. Assicurati che il repository sia stato clonato correttamente."
        exit 1
    fi
    
    info "Sblocco dei file crittografati..."
    
    # Tentativi di inserimento password
    local attempts=0
    local max_attempts=3
    
    while [ "$attempts" -lt "$max_attempts" ]; do
        prompt "Inserisci la master password per decrittare i file:"
        read -s MASTER_PASSWORD
        echo ""
        
        # Utilizza la master password per decrittare la chiave git-crypt
        if echo "$MASTER_PASSWORD" | gpg --batch --yes --passphrase-fd 0 -o git-crypt.key -d git-crypt.key.gpg 2>/dev/null; then
            # Sblocca il repository con git-crypt
            if git-crypt unlock git-crypt.key; then
                # Rimuovi la chiave git-crypt in chiaro (per sicurezza)
                rm -f git-crypt.key
                info "File crittografati sbloccati con successo."
                return 0
            else
                error "Errore durante lo sblocco del repository con git-crypt."
                rm -f git-crypt.key
                exit 1
            fi
        else
            attempts=$((attempts + 1))
            
            if [ "$attempts" -eq "$max_attempts" ]; then
                error "Troppi tentativi falliti. Impossibile sbloccare i file crittografati."
                exit 1
            else
                error "Password non corretta. Riprova. (tentativo $attempts di $max_attempts)"
            fi
        fi
    done
}

# Chiede all'utente se procedere con il setup del repository o con il provisioning completo
prompt_setup_options() {
    info "Preparazione completata."
    echo ""
    echo "Scegli come procedere:"
    echo "1) Solo setup del repository (clone e sblocco file crittografati)"
    echo "2) Setup repository e provisioning completo"
    echo ""
    
    # Limita i tentativi a 3 per evitare ricorsione infinita
    local attempts=0
    local max_attempts=3
    
    while [ "$attempts" -lt "$max_attempts" ]; do
        prompt "Seleziona un'opzione [1/2]: "
        read -r option
        
        case "$option" in
            1)
                info "Setup del repository completato in '$PROVISIONING_DIR'."
                info "Quando vorrai procedere con il provisioning, esegui:"
                info "cd '$PROVISIONING_DIR' && ./main.sh"
                exit 0
                ;;
            2)
                start_provisioning
                return
                ;;
            *)
                warning "Opzione non valida. Seleziona 1 o 2."
                attempts=$((attempts + 1))
                
                if [ "$attempts" -eq "$max_attempts" ]; then
                    error "Troppi tentativi non validi. Uscita."
                    exit 1
                fi
                ;;
        esac
    done
}

# Avvia il provisioning
start_provisioning() {
    info "Avvio del provisioning..."
    
    # Rendi lo script eseguibile se necessario
    if [ ! -x "./main.sh" ]; then
        chmod +x ./main.sh
    fi
    
    # Esegui lo script principale
    ./main.sh
    
    # Ritorna al codice di uscita dello script principale
    return $?
}

# Nota: Meccanismo di verifica dell'integrità rimosso
# Non necessario dato il basso profilo di rischio e l'uso personale con GitHub protetto da 2FA

# Esecuzione principale
main() {
    show_banner
    check_dependencies
    clone_repository
    unlock_encrypted_files
    prompt_setup_options
}

# Avvia l'esecuzione
main