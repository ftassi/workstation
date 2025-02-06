#!/bin/bash
set -euo pipefail

# Inclusione delle funzioni comuni (assicurati che common.sh definisca anche le funzioni 'info', 'error' e 'cleanup')
source "$(dirname "$0")/../common.sh"

# Verifica che sia stato passato almeno un argomento (il nome della distrobox)
if [ "$#" -lt 1 ]; then
    error "Utilizzo: $0 <nome_distrobox>"
    exit 1
fi

# Imposta una trap per eseguire la funzione di cleanup in caso di errore (assicurati che 'cleanup' sia definita in common.sh)
trap cleanup ERR

info "Creazione di una distrobox basata su ubuntu:22.04 per neovim..."
$HOME/.local/bin/distrobox-create --yes --name "$1" --image "ubuntu:22.04"

info "Il provisioning della distrobox deve essere completato manualmente."
info "Per connettersi alla distrobox, eseguire il comando:"
info "  distrobox-enter $1"
info "Per eseguire il provisioning della distrobox, eseguire lo script:"
info "  distrobox/$1.sh"
