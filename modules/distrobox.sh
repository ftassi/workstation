#!/bin/bash
#
# Script di provisioning per Distrobox
# Crea e configura container Distrobox per ambienti isolati
# Richiede: distrobox, podman

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

# Imposta la gestione errori avanzata
setup_error_handling

# Verifica che sia stato passato almeno un argomento (il nome della distrobox)
if [ "$#" -lt 1 ]; then
    cleanup "Utilizzo: $0 <nome_distrobox>"
fi

info "Creazione di una distrobox basata su ubuntu:22.04 per neovim..."

info "Il provisioning della distrobox deve essere completato manualmente."
info "Per connettersi alla distrobox, eseguire il comando:"
info "  distrobox-enter $1"
info "Per eseguire il provisioning della distrobox, eseguire lo script:"
info "  distrobox/$1.sh"
