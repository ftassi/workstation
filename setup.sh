#!/bin/bash

set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

# Ottieni il nome dell'utente corrente (quello che vuoi abilitare)
CURRENT_USER=$(logname 2>/dev/null || echo "$SUDO_USER")

info "Aggiunta dell'utente $CURRENT_USER ai sudoers..."
info "Dopo il provisioning elimina il file /etc/sudoers.d/zz_provisioning_${CURRENT_USER} per rimuovere i privilegi."

# Verifica che l'utente sia stato trovato
if [ -z "$CURRENT_USER" ]; then
    echo "Impossibile determinare l'utente corrente."
    exit 1
fi

# Scegli un nome per il file in modo che venga letto per ultimo (ordine lessicografico)
SUDOERS_FILE="/etc/sudoers.d/zz_provisioning_${CURRENT_USER}"

# Crea il file con la regola per l'utente corrente
echo "${CURRENT_USER} ALL=(ALL) NOPASSWD: ALL" > "$SUDOERS_FILE"

# Imposta i permessi corretti (0440)
chmod 0440 "$SUDOERS_FILE"

# Verifica la sintassi del file
visudo -cf "$SUDOERS_FILE" && echo "File sudoers creato correttamente in $SUDOERS_FILE" || echo "Errore di sintassi in $SUDOERS_FILE"

info "Inizializzazione del provisioning..."
info "Installazione dei pacchetti base..."

sudo apt-get update -qq && sudo apt-get install -y git tig gpg git-crypt

# Controllo che il repository sia stato clonato correttamente
if [ ! -f "git-crypt.key.gpg" ]; then
    error "Il file git-crypt.key.gpg non esiste. Assicurati di aver clonato il repository corretto."
    exit 1
fi

info "[INPUT] Inserisci la master password:"
read -s MASTER_PASSWORD
echo ""

# Decripta la chiave AES di git-crypt
gpg --batch --yes --passphrase "$MASTER_PASSWORD" --output git-crypt.key --decrypt git-crypt.key.gpg

# Sblocca i secrets criptati con git-crypt
sudo -u "$SUDO_USER" git-crypt unlock git-crypt.key

# Rimuove la chiave temporanea
rm git-crypt.key

success "Secrets sbloccati con successo."

# Verifica lo stato di git-crypt
sudo -u "$SUDO_USER" git-crypt status
