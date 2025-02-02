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

success "Provisioning completato con successo!"
