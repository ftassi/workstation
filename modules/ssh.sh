#!/bin/bash
set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

info "Inizio provisioning SSH..."

# Definizione dei percorsi
SECRETS_DIR="$(dirname "$0")/../secrets/ssh"
TARGET_DIR="$HOME/.ssh"

# Controlla se la directory dei secrets esiste
if [ ! -d "$SECRETS_DIR" ]; then
    error "Directory dei secrets SSH non trovata: $SECRETS_DIR"
    exit 1
fi

# Crea la directory ~/.ssh se non esiste e imposta i permessi
if [ ! -d "$TARGET_DIR" ]; then
    info "Creazione della directory ~/.ssh..."
    mkdir -p "$TARGET_DIR"
    chmod 700 "$TARGET_DIR"
fi

# Array dei file da copiare
FILES=("config" "id_rsa" "id_rsa.pub")

for file in "${FILES[@]}"; do
    if [ -f "$SECRETS_DIR/$file" ]; then
        info "Copio $file in $TARGET_DIR..."
        cp "$SECRETS_DIR/$file" "$TARGET_DIR/$file"
        # Imposta i permessi corretti per ogni file
        case "$file" in
            "config")
                chmod 600 "$TARGET_DIR/$file"
                ;;
            "id_rsa")
                chmod 600 "$TARGET_DIR/$file"
                ;;
            "id_rsa.pub")
                chmod 644 "$TARGET_DIR/$file"
                ;;
        esac
    else
        error "File $file non trovato in $SECRETS_DIR"
        exit 1
    fi
done

# Aggiorna known_hosts con la chiave di GitHub per evitare prompt interattivi
info "Aggiorno known_hosts con la chiave di GitHub..."
ssh-keyscan github.com >> "$TARGET_DIR/known_hosts" 2>/dev/null

# Test di connessione SSH a GitHub in modalità non interattiva
info "Verifica della connessione SSH a GitHub..."
SSH_TEST_OUTPUT=$(ssh -T -o BatchMode=yes -o StrictHostKeyChecking=yes git@github.com 2>&1 || true)

# Verifica che l'output contenga una risposta tipica (es. "Hi <username>!" oppure "successfully authenticated")
if echo "$SSH_TEST_OUTPUT" | grep -q "successfully authenticated"; then
    success "Connessione SSH a GitHub verificata con successo."
elif echo "$SSH_TEST_OUTPUT" | grep -q "Hi "; then
    success "Connessione SSH a GitHub verificata con successo."
else
    error "Test di connessione SSH a GitHub fallito. Output:"
    echo "$SSH_TEST_OUTPUT"
    exit 1
fi

success "Provisioning SSH completato con successo."
