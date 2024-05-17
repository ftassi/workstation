#!/usr/bin/env bash

set -x 

# Colori
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

sudo apt-get update 
sudo apt-get install -y \
    libssl-dev /
    git /
    curl /
    wget /
    httpie /
    tmux /
    exa /
    tar /
    gzip /
    unzip

if ! command -v op &> /dev/null; then

    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" |
    sudo tee /etc/apt/sources.list.d/1password.list

    sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
    sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol
    sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
    sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

    sudo apt update && sudo apt install 1password-cli

fi

#!/bin/bash

# Percorsi ai file segreti
MASTER_PASSWORD_FILE="./secrets/1password/master_password"
PERSONAL_SECRET_FILE="./secrets/1password/onep_personal_secret"
SOISY_SECRET_FILE="./secrets/1password/onep_soisy_secret"

# Decrittazione dei segreti
DECRYPT_SCRIPT="./decrypt.sh"

# Funzione per decriptare un segreto e assegnarlo a una variabile
decrypt_secret() {
  local secret_file=$1
  $DECRYPT_SCRIPT "$secret_file"
}

# Decripta i segreti e li assegna a variabili
MASTER_PASSWORD=$(decrypt_secret $MASTER_PASSWORD_FILE)
ONEP_PERSONAL_SECRET=$(decrypt_secret $PERSONAL_SECRET_FILE)
ONEP_SOISY_SECRET=$(decrypt_secret $SOISY_SECRET_FILE)

# Funzione per effettuare il login a 1Password
signin_1password_account() {
  local address=$1
  local email=$2
  local secret_key=$3
  local shorthand=$4

  echo -e "${BLUE}Effettuando il login all'account 1Password: $email (${shorthand})${NC}"
  echo "$MASTER_PASSWORD" | op account add --address "$address" --email "$email" --secret-key "$secret_key" --shorthand "$shorthand" --signin
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}Login all'account $shorthand effettuato con successo.${NC}"
  else
    echo -e "${RED}Errore nel login all'account $shorthand.${NC}"
  fi
}

# Effettua il login agli account 1Password
signin_1password_account "catena-tassi.1password.com" "tassi.francesco@gmail.com" "$ONEP_PERSONAL_SECRET" "personal"
signin_1password_account "my.1password.com" "francesco.tassi@soisy.it" "$ONEP_SOISY_SECRET" "soisy"


#AWS cli

AWS_CLI_INSTALLER_URL="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
INSTALL_DIR="$HOME/opt/aws-cli"
BIN_DIR="$HOME/opt/bin"
TMP_DIR="/tmp/aws"
INSTALLER_ZIP="/tmp/awscli-exe-linux-x86_64.zip"

# Funzione per verificare se aws-cli è già installato
is_aws_cli_installed() {
    if command -v aws &> /dev/null; then
        echo -e "${GREEN}aws-cli è già installato.${NC}"
        return 0
    else
        return 1
    fi
}

# Scarica l'installer di aws-cli solo se necessario
download_aws_cli_installer() {
    if [ ! -f "$INSTALLER_ZIP" ]; then
        echo -e "${BLUE}Scaricando l'installer di aws-cli...${NC}"
        curl -o "$INSTALLER_ZIP" "$AWS_CLI_INSTALLER_URL"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Installer di aws-cli scaricato con successo.${NC}"
        else
            echo -e "${RED}Errore durante il download dell'installer di aws-cli.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Installer di aws-cli già presente.${NC}"
    fi
}

# Estrai l'installer di aws-cli
extract_aws_cli_installer() {
    if [ ! -d "$TMP_DIR" ]; then
        echo -e "${BLUE}Estraendo l'installer di aws-cli...${NC}"
        unzip "$INSTALLER_ZIP" -d /tmp
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Installer di aws-cli estratto con successo.${NC}"
        else
            echo -e "${RED}Errore durante l'estrazione dell'installer di aws-cli.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Installer di aws-cli già estratto.${NC}"
    fi
}

# Installa aws-cli
install_aws_cli() {
    if [ ! -d "$INSTALL_DIR" ]; then
        echo -e "${BLUE}Installando aws-cli...${NC}"
        (cd "$TMP_DIR/aws" && ./install --bin-dir "$BIN_DIR" --install-dir "$INSTALL_DIR" --update)
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}aws-cli installato con successo.${NC}"
        else
            echo -e "${RED}Errore durante l'installazione di aws-cli.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}aws-cli è già installato nella directory specificata.${NC}"
    fi
}

# Eseguire le funzioni se aws-cli non è installato
if ! is_aws_cli_installed; then
    download_aws_cli_installer
    extract_aws_cli_installer
    install_aws_cli
fi

#TODO: Portare le credenziali aws nei dotfiles
#
# ./provision/dotfiles.sh
# Installare le configurazioni utilizzando stow
config_items=("git")
for item in "${config_items[@]}"; do
  if [ -d "$HOME/dotfiles/$item" ]; then
    (cd "$HOME/dotfiles" && stow "$item")
  else
    echo "Configurazione $item non trovata nella directory ~/dotfiles."
    exit 1
  fi
done

# Github cli
GITHUB_CLI_KEY_URL="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
GITHUB_CLI_KEY_PATH="/usr/share/keyrings/githubcli-archive-keyring.gpg"
GITHUB_CLI_REPO="deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main"
GITHUB_CLI_REPO_FILE="/etc/apt/sources.list.d/github-cli.list"

# Funzione per verificare se il file esiste
file_exists() {
    local file_path=$1
    if [ -f "$file_path" ]; then
        return 0
    else
        return 1
    fi
}

# Funzione per importare la chiave GPG
import_github_cli_key() {
    if ! file_exists "$GITHUB_CLI_KEY_PATH"; then
        echo -e "${BLUE}Importando la chiave GPG per GitHub CLI...${NC}"
        sudo curl -o "$GITHUB_CLI_KEY_PATH" "$GITHUB_CLI_KEY_URL"
        sudo chmod 644 "$GITHUB_CLI_KEY_PATH"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Chiave GPG per GitHub CLI importata con successo.${NC}"
        else
            echo -e "${RED}Errore durante l'importazione della chiave GPG per GitHub CLI.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}La chiave GPG per GitHub CLI è già presente.${NC}"
    fi
}

# Funzione per aggiungere il repository GitHub CLI
add_github_cli_repo() {
    if ! file_exists "$GITHUB_CLI_REPO_FILE"; then
        echo -e "${BLUE}Aggiungendo il repository GitHub CLI...${NC}"
        echo "$GITHUB_CLI_REPO" | sudo tee "$GITHUB_CLI_REPO_FILE" > /dev/null
        sudo apt-get update
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}Repository GitHub CLI aggiunto con successo.${NC}"
        else
            echo -e "${RED}Errore durante l'aggiunta del repository GitHub CLI.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}Il repository GitHub CLI è già presente.${NC}"
    fi
}

# Importa la chiave GPG e aggiungi il repository
import_github_cli_key
add_github_cli_repo

echo -e "${GREEN}Ricorda di effettuare la login con 1password eseguendo op plugin init gh${NC}"

sudo ln -s /usr/bin/distrobox-host-exec /usr/local/bin/podman
sudo ln -s /usr/bin/distrobox-host-exec /usr/local/bin/docker
