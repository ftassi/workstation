#!/bin/bash
set -euo pipefail

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

trap cleanup ERR

# Lettura della password sudo
SUDO_PASSWORD=$(get_sudo_password)

# Rimozione di eventuali pacchetti Docker incompatibili
info "Rimozione di pacchetti Docker incompatibili, se presenti..."
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    if dpkg -l | grep -q "$pkg"; then
        run_sudo apt-get remove -y "$pkg"
        info "Rimosso pacchetto incompatibile: $pkg"
    fi
done

# Installazione delle dipendenze necessarie
info "Installazione delle dipendenze necessarie..."
run_sudo apt-get update -qq
run_sudo apt-get install -y ca-certificates curl gnupg

# Aggiunta della chiave GPG ufficiale di Docker
info "Aggiunta della chiave GPG ufficiale di Docker..."
run_sudo install -m 0755 -d /etc/apt/keyrings
run_sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
run_sudo chmod a+r /etc/apt/keyrings/docker.asc

# Aggiunta del repository Docker
info "Aggiunta del repository Docker..."
# Nota: utilizziamo un subshell per garantire che la variabile UBUNTU_CODENAME venga impostata correttamente.
CODENAME=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
DEB_LINE="deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $CODENAME stable"
echo "$SUDO_PASSWORD" | sudo -S bash -c "cat > /etc/apt/sources.list.d/docker.list" <<< "$DEB_LINE"
run_sudo apt-get update -qq

# Verifica se Docker è già installato (opzionale)
if command -v docker &>/dev/null; then
    info "Docker è già installato. Procedo con la configurazione..."
fi

# Installazione di Docker Engine, CLI e plugin
info "Installazione di Docker Engine, CLI e plugin..."
run_sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Aggiunta dell'utente corrente al gruppo docker per eseguire comandi senza sudo
info "Aggiunta dell'utente corrente al gruppo Docker..."
run_sudo usermod -aG docker "$USER"

# Uso di newgrp per applicare immediatamente la modifica dei gruppi
# Inseriamo i passaggi successivi in un blocco qui-document
info "Ricarica dei gruppi e applicazione immediata delle modifiche..."
newgrp docker <<'EOF'
# I comandi all'interno di questo blocco verranno eseguiti con il gruppo aggiornato

info() {
    echo -e "\033[0;32m[INFO] $1\033[0m"
}
success() {
    echo -e "\033[0;32m[SUCCESSO] $1\033[0m"
}

info "Docker è stato installato e configurato correttamente."

# Verifica dell'installazione di Docker
info "Verifica dell'installazione di Docker..."
docker --version
docker compose version

success "Base provisioning completato."
EOF
