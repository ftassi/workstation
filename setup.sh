#/bin/bash

set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

# Se il file delle password esiste, informiamo l'utente
if [ -f "$PASSWORD_FILE" ]; then
    info "Il file .passwords esiste già. Skipping."
else
    info "Creazione del file .passwords..."

    info "[INPUT] Inserisci la master password:"
    read -s MASTER_PASSWORD
    echo ""

    info "[INPUT] Inserisci la password di sudo:"
    read -s SUDO_PASSWORD
    echo ""

    echo "MASTER_PASSWORD=$MASTER_PASSWORD" > "$PASSWORD_FILE"
    echo "SUDO_PASSWORD=$SUDO_PASSWORD" >> "$PASSWORD_FILE"

    chmod 600 "$PASSWORD_FILE"
    
    success "File .passwords creato con successo."
fi

info "Inizializzazione del provisioning..."
info "Installazione dei pacchetti base..."

install_package "git"
install_package "gpg"
install_package "git-crypt"

# Controllo che il repository sia stato clonato correttamente
if [ ! -f "git-crypt.key.gpg" ]; then
    error "Il file git-crypt.key.gpg non esiste. Assicurati di aver clonato il repository corretto."
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

success "Secrets sbloccati con successo."

# Verifica lo stato di git-crypt
git-crypt status
