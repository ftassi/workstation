#!/usr/bin/env bash

set -e 

# Colori
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

MIN_DOCKER_VERSION="26.0.0"
INSTALL_DOCKER=true

echo -e "${BLUE}Questo script configura le tue chiavi ssh e installa docker per avere un setup minimo funzionante${NC}"
echo -e "${GREEN}Configurazione SSH${NC}"

mkdir -p ~/.ssh
chmod 0700 ~/.ssh

# Verifica se la directory ~/.ssh esiste già
if [ ! -f ~/.ssh/id_rsa ]; then
    echo -e "${BLUE}Installazione chiave RSA${NC}"
    ./decrypt.sh ./secrets/ssh/id_rsa ~/.ssh/id_rsa
    cp ./secrets/ssh/id_rsa.pub ~/.ssh/id_rsa.pub

    chmod 0600 ~/.ssh/id_rsa
    chmod 0644 ~/.ssh/id_rsa.pub
fi

if [ ! -f ~/.ssh/config ]; then
    echo -e "${BLUE}Installazione configurazione SSH${NC}"
    ./decrypt.sh ./secrets/ssh/config ~/.ssh/config
    cp ./secrets/ssh/id_rsa.pub ~/.ssh/id_rsa.pub

    chmod 0664 ~/.ssh/config
fi

echo -e "${GREEN}Configurazione SSH completata${NC}"

# Funzione per confrontare le versioni
version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

# Controlla se Docker è installato e ottiene la versione
if command -v docker &> /dev/null; then
    # Docker è installato, controlla la versione
    INSTALLED_DOCKER_VERSION=$(docker --version | grep -oP '\d+\.\d+\.\d+')
    echo -e "${GREEN}Docker trovato: versione $INSTALLED_DOCKER_VERSION${NC}"

    # Confronta la versione installata con quella minima richiesta
    if version_gt $MIN_DOCKER_VERSION $INSTALLED_DOCKER_VERSION; then
        INSTALL_DOCKER=false
    else
        echo -e "${GREEN}La versione installata di Docker soddisfa i requisiti. Nessuna installazione necessaria.${NC}"
        INSTALL_DOCKER=false
    fi
else
    echo -e "${RED}Docker non è installato.${NC}"
    INSTALL_DOCKER=true
    # Comandi per installare Docker
fi

if [ "$INSTALL_DOCKER" = true ]; then
    echo -e "${BLUE}La versione di Docker è inferiore alla versione minima richiesta ($MIN_DOCKER_VERSION). Procedo con l'installazione...${NC}"
    # Docker setup
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt-cache policy docker-ce
    sudo apt install -y docker-ce

    sudo usermod -aG docker ${USER}
fi
