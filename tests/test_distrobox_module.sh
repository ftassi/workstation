#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"
source "$REPO_DIR/tests/common_test_utils.sh"

log_info "Avvio container Ubuntu 24.04..."
docker run --name test-container --rm -d -v "$REPO_DIR:/workstation" ubuntu:24.04 sleep infinity

log_info "Installazione requisiti minimi..."
docker exec test-container bash -c "apt-get update && apt-get install -y sudo curl apt-utils gpg"

log_info "FASE 1: Prima esecuzione del modulo distrobox.sh..."
docker exec -e HOME=/root test-container bash -c "cd /workstation && ./modules/distrobox.sh"

log_info "Verifica delle installazioni dopo la prima esecuzione..."

assert_package_installed "distrobox"
assert_binary_exists "distrobox"

if docker exec test-container bash -c "command -v podman &>/dev/null"; then
  log_success "✅ Podman è installato (richiesto da distrobox)"
else
  log_info "ℹ️ Podman non è installato (potrebbe essere normale se distrobox usa Docker)"
fi

if docker exec test-container bash -c "ls -la /workstation/distrobox/*.sh 2>/dev/null"; then
  log_success "✅ Script di supporto distrobox sono disponibili"
else
  log_error "❌ Script di supporto distrobox NON sono disponibili o accessibili"
fi

log_info "FASE 2: Seconda esecuzione per verificare idempotenza..."
docker exec -e HOME=/root test-container bash -c "cd /workstation && ./modules/distrobox.sh"

log_info "Verifica idempotenza delle configurazioni..."
if docker exec test-container bash -c "test -f /root/.bashrc"; then
  num_distrobox_lines=$(docker exec test-container bash -c "grep -c 'distrobox' /root/.bashrc" || echo "0")
  if [ "$num_distrobox_lines" -le "1" ]; then
    log_success "✅ Configurazione distrobox non è stata duplicata in .bashrc"
  else
    log_error "❌ Configurazione distrobox è stata duplicata in .bashrc ($num_distrobox_lines occorrenze)"
  fi
fi

log_info "Pulizia ambiente di test..."
docker stop test-container

log_success "Test completato con successo! 🎉"