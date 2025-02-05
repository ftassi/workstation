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

info "Creo la distrobox nvim..."
bash "modules/distrobox.sh" "nvim" 
info "Distrobox nvim creata con successo. Ricordarti di eseguire il provisioning con distrobox/nvim.sh"

info "Creo la distrobox dev..."
bash "modules/distrobox.sh" "dev" 
info "Distrobox dev creata con successo. Ricordarti di eseguire il provisioning con distrobox/dev.sh"

success "Provisioning completato con successo!"
