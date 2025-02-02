#!/bin/bash

set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

# Lettura della password sudo
SUDO_PASSWORD=$(get_sudo_password)

# Rimozione di eventuali pacchetti Docker incompatibili
echo -e "${GREEN}[INFO] Rimozione di pacchetti Docker incompatibili, se presenti...${RESET}"
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    if dpkg -l | grep -q "$pkg"; then
        sudo_exec apt-get remove -y "$pkg"
        echo -e "${GREEN}[INFO] Rimosso pacchetto incompatibile: $pkg${RESET}"
    fi
done

# Installazione delle dipendenze necessarie
echo -e "${GREEN}[INFO] Installazione delle dipendenze necessarie...${RESET}"
sudo_exec apt-get update -qq
sudo_exec apt-get install -y ca-certificates curl gnupg

# Aggiunta della chiave GPG ufficiale di Docker
echo -e "${GREEN}[INFO] Aggiunta della chiave GPG ufficiale di Docker...${RESET}"
sudo_exec install -m 0755 -d /etc/apt/keyrings
sudo_exec curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo_exec chmod a+r /etc/apt/keyrings/docker.asc

# Aggiunta del repository Docker
echo -e "${GREEN}[INFO] Aggiunta del repository Docker...${RESET}"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo_exec tee /etc/apt/sources.list.d/docker.list > /dev/null

# Installazione di Docker Engine, CLI e plugin
echo -e "${GREEN}[INFO] Installazione di Docker Engine, CLI e plugin...${RESET}"
sudo_exec apt-get update -qq
sudo_exec apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Aggiunta dell'utente al gruppo docker per eseguire comandi senza sudo
echo -e "${GREEN}[INFO] Aggiunta dell'utente corrente al gruppo Docker...${RESET}"
sudo_exec usermod -aG docker "$USER"

# Ricarica del gruppo senza dover effettuare il logout
newgrp docker <<EONG
echo -e "${GREEN}[INFO] Docker è stato installato e configurato correttamente.${RESET}"
EONG

# Verifica dell'installazione di Docker
echo -e "${GREEN}[INFO] Verifica dell'installazione di Docker...${RESET}"
docker --version
docker compose version

echo -e "${GREEN}[SUCCESSO] Base provisioning completato.${RESET}"
