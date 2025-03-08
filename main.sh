#!/bin/bash
#
# Script principale di provisioning della workstation
# Esegue in sequenza tutti i moduli di installazione
#

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

# Imposta la gestione errori avanzata
setup_error_handling

info "Avvio provisioning completo..."

# Eseguiamo un apt-get update iniziale per assicurarci che gli indici siano freschi
apt_update_if_needed

# Definizione dell'ordine dei moduli
MODULES=(
  "modules/ssh.sh"
  "modules/docker.sh"
  "modules/dotfiles.sh"
  "modules/shell.sh"
  "modules/regolith.sh"
  "modules/gui.sh"
  "modules/dev.sh"
  "modules/nvim.sh"
)

for module in "${MODULES[@]}"; do
  if [ -x "$module" ]; then
      info "Esecuzione di $(basename "$module")..."
      bash "$module"
  else
      die "Modulo $(basename "$module") non eseguibile o non trovato."
  fi
done

# DISTROBOXES=(
#   "nvim"
#   "dev"
# )
#
# for distrobox in "${DISTROBOXES[@]}"; do
#   if [ -x "modules/distrobox.sh" ]; then
#       info "Creazione di distrobox $(basename "$distrobox")..."
#       bash "modules/distrobox.sh" "$distrobox"
#       info "Distrobox $(basename "$distrobox") creata con successo. Ricordarti di eseguire il provisioning con distrobox/$(basename "$distrobox").sh"
#   else
#       die "Modulo distrobox non eseguibile o non trovato."
#   fi
# done

success "Provisioning completato con successo!"
