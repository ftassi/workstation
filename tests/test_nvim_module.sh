#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"
source "$REPO_DIR/tests/common_test_utils.sh"

log_info "Avvio container Ubuntu 24.04..."
docker run --name test-container --rm -d -v "$REPO_DIR:/workstation" ubuntu:24.04 sleep infinity

log_info "Installazione requisiti minimi..."
docker exec test-container bash -c "apt-get update && apt-get install -y sudo curl apt-utils gpg wget git build-essential"

log_info "FASE 1: Prima esecuzione del modulo nvim.sh..."
docker exec -e HOME=/root test-container bash -c "cd /workstation && ./modules/nvim.sh"

log_info "Verifica delle installazioni dopo la prima esecuzione..."

assert_binary_exists "nvim"

assert_directory_exists "/root/.nvm"
if docker exec test-container bash -c "source /root/.nvm/nvm.sh && node --version"; then
  log_success "✅ Node.js è stato installato tramite NVM"
else
  log_error "❌ Node.js NON è stato installato o NVM non è configurato correttamente"
fi

assert_binary_exists "luarocks"
assert_binary_exists "cargo"

if docker exec test-container bash -c "test -d /root/.config/nvim"; then
  log_success "✅ Directory di configurazione Neovim è stata creata"
else
  log_error "❌ Directory di configurazione Neovim NON è stata creata"
fi

log_info "FASE 2: Seconda esecuzione per verificare idempotenza..."
docker exec -e HOME=/root test-container bash -c "cd /workstation && ./modules/nvim.sh"

log_info "Verifica idempotenza delle configurazioni..."
if docker exec test-container bash -c "test -f /root/.bashrc"; then
  num_nvim_references=$(docker exec test-container bash -c "grep -c 'nvim\|neovim' /root/.bashrc" || echo "0")
  if [ "$num_nvim_references" -le "1" ]; then
    log_success "✅ Configurazione neovim non è stata duplicata in .bashrc"
  else
    log_error "❌ Configurazione neovim è stata duplicata in .bashrc ($num_nvim_references occorrenze)"
  fi
fi

if docker exec test-container bash -c "test -f /root/.config/nvim/init.lua"; then
  assert_no_duplicate_lines "/root/.config/nvim/init.lua"
fi

log_info "Pulizia ambiente di test..."
docker stop test-container

log_success "Test completato con successo! 🎉"