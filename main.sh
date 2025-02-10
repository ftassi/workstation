#!/bin/bash
set -e

# Inclusione delle funzioni comuni
source "$(dirname "$0")/common.sh"

info "Avvio provisioning completo..."

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
      error "Modulo $(basename "$module") non eseguibile o non trovato."
      exit 1
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
#       error "Modulo distrobox non eseguibile o non trovato."
#       exit 1
#   fi
# done


success "Provisioning completato con successo!"
