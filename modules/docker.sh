#!/bin/bash
#
# Script di provisioning per Docker
# Installa e configura Docker Engine e Docker Compose
# Richiede: curl, apt

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

# Imposta la gestione errori avanzata
setup_error_handling

# Rimozione di eventuali pacchetti Docker incompatibili
info "Rimozione di pacchetti Docker incompatibili, se presenti..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    if dpkg -l | grep -q "$pkg"; then
        sudo apt-get remove -y "$pkg"
        info "Rimosso pacchetto incompatibile: $pkg"
    fi
done

# Installazione delle dipendenze necessarie
info "Installazione delle dipendenze necessarie..."
apt_update_if_needed
sudo apt-get install -y ca-certificates curl gnupg

# Aggiunta della chiave GPG ufficiale di Docker in modo idempotente
add_gpg_key "https://download.docker.com/linux/ubuntu/gpg" "/etc/apt/keyrings/docker.asc"

# Aggiunta del repository Docker in modo idempotente
# Determina il nome in codice di Ubuntu
CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
DEB_LINE="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $CODENAME stable"
add_apt_repository "docker.list" "$DEB_LINE"

# Verifica se Docker è già installato (opzionale)
if command -v docker &>/dev/null; then
    info "Docker è già installato. Procedo con la configurazione..."
fi

# Installazione di Docker Engine, CLI e plugin
info "Installazione di Docker Engine, CLI e plugin..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Aggiunta dell'utente corrente al gruppo docker per eseguire comandi senza sudo
info "Aggiunta dell'utente corrente al gruppo Docker..."
CURRENT_USER=$(whoami)

# Verifica se l'utente è già nel gruppo docker
if groups "$CURRENT_USER" | grep -q "\bdocker\b"; then
    info "L'utente $CURRENT_USER è già nel gruppo docker."
else
    sudo usermod -aG docker "$CURRENT_USER"
    info "Utente $CURRENT_USER aggiunto al gruppo docker."
    
    # Attiva il gruppo docker nella sessione corrente senza logout/login
    info "Attivazione del gruppo docker nella sessione corrente..."
    
    # Salva una copia dello script che deve essere eseguito in una nuova shell
    TEMP_SCRIPT=$(mktemp)
    cat > "$TEMP_SCRIPT" << 'EOF'
#!/bin/bash
# Inclusione delle funzioni comuni per i messaggi di log
source "$(dirname "$0")/../common.sh"
# Verifica se l'utente può eseguire docker
if docker info &>/dev/null; then
    info "Gruppo docker attivato correttamente."
else
    info "ATTENZIONE: Non è stato possibile attivare il gruppo docker nella sessione corrente."
    info "Per utilizzare docker senza sudo, dovrai disconnetterti e riconnetterti."
fi
EOF
    chmod +x "$TEMP_SCRIPT"
    
    # Esegui il comando newgrp in una nuova shell
    info "Tentativo di attivare il gruppo docker senza riavvio della sessione..."
    newgrp docker << EONG
bash "$TEMP_SCRIPT"
EONG
    
    # Rimuovi il file temporaneo
    rm "$TEMP_SCRIPT"
fi

# Verifica dell'installazione di Docker
info "Verifica dell'installazione di Docker..."
if docker --version &>/dev/null; then
    docker --version
    docker compose version
    info "Per verificare il funzionamento completo di Docker, esegui: docker run hello-world"
else
    info "Docker è installato ma potrebbe essere necessario riavviare la sessione per utilizzarlo senza sudo."
    info "Dopo aver riavviato la sessione, verifica con: docker run hello-world"
fi

success "Base provisioning completato."
