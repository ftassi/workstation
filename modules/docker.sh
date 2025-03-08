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
sudo apt-get update -qq
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
sudo usermod -aG docker "$USER"

# Nota: Per applicare subito la modifica della membership, è consigliabile disconnettersi e riconnettersi.
info "Docker è stato installato e configurato correttamente."
info "Per applicare subito la modifica della membership, è consigliabile disconnettersi e riconnettersi."

# Verifica dell'installazione di Docker
info "Verifica dell'installazione di Docker..."
docker --version
docker compose version

info "Dopo aver riconnesso l'utente, esegui il comando 'docker run hello-world' per verificare il funzionamento di Docker."

success "Base provisioning completato."
