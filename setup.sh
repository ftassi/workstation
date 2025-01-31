#!/bin/bash

set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

# Se il file delle password esiste, informiamo l'utente
if [ -f "$PASSWORD_FILE" ]; then
    echo -e "${GREEN}[INFO] Il file .passwords esiste già. Skipping.${RESET}"
else
    echo -e "${GREEN}[INFO] Creazione del file .passwords...${RESET}"

    echo -e "${GREEN}[INPUT] Inserisci la master password:${RESET}"
    read -s MASTER_PASSWORD

    echo -e "${GREEN}[INPUT] Inserisci la password di sudo:${RESET}"
    read -s SUDO_PASSWORD

    echo "MASTER_PASSWORD=$MASTER_PASSWORD" > "$PASSWORD_FILE"
    echo "SUDO_PASSWORD=$SUDO_PASSWORD" >> "$PASSWORD_FILE"

    chmod 600 "$PASSWORD_FILE"
    
    echo -e "${GREEN}[INFO] File .passwords creato con successo.${RESET}"
fi

echo -e "${GREEN}[INFO] Inizializzazione del provisioning...${RESET}"
echo -e "${GREEN}[INFO] Installazione dei pacchetti base...${RESET}"

install_package "git"
install_package "gpg"
install_package "git-crypt"

# Controllo che il repository sia stato clonato correttamente
if [ ! -f "git-crypt.key.gpg" ]; then
    echo -e "${RED}[ERRORE] Il file git-crypt.key.gpg non esiste. Assicurati di aver clonato il repository corretto.${RESET}"
    exit 1
fi

# Recupera la master password dal file .passwords
MASTER_PASSWORD=$(get_master_password)

# Decripta la chiave AES di git-crypt
gpg --batch --yes --passphrase "$MASTER_PASSWORD" --output git-crypt.key --decrypt git-crypt.key.gpg

# Sblocca i secrets criptati con git-crypt
git-crypt unlock git-crypt.key

# Rimuove la chiave temporanea
rm git-crypt.key

echo -e "${GREEN}[INFO] Secrets sbloccati con successo.${RESET}"

# Verifica lo stato di git-crypt
git-crypt status
