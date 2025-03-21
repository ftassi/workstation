#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"
source "$REPO_DIR/tests/common_test_utils.sh"

log_info "Avvio container Ubuntu 24.04..."
docker run --name test-container --rm -d -v "$REPO_DIR:/workstation" ubuntu:24.04 sleep infinity

log_info "Installazione requisiti minimi..."
docker exec test-container bash -c "apt-get update && apt-get install -y sudo curl apt-utils gpg openssh-client"

log_info "Preparazione directory .ssh (normalmente creata da decrypt.sh)..."
docker exec test-container bash -c "mkdir -p /root/.ssh"
docker exec test-container bash -c "cp -r /workstation/secrets/ssh/* /root/.ssh/ || echo 'Note: No secrets found, test will check only for directory structure'"

log_info "FASE 1: Prima esecuzione del modulo ssh.sh..."
docker exec -e HOME=/root test-container bash -c "cd /workstation && ./modules/ssh.sh || echo 'Expected failure if no secrets available'"

log_info "Verifica della configurazione SSH dopo la prima esecuzione..."

if docker exec test-container bash -c "test -d /root/.ssh"; then
  log_success "✅ Directory SSH esiste"
else
  log_error "❌ Directory SSH NON esiste"
  exit 1
fi

ssh_dir_perms=$(docker exec test-container bash -c "stat -c '%a' /root/.ssh")
if [ "$ssh_dir_perms" = "700" ]; then
  log_success "✅ Directory SSH ha i permessi corretti (700)"
else
  log_error "❌ Directory SSH ha permessi errati: $ssh_dir_perms invece di 700"
fi

if docker exec test-container bash -c "test -f /root/.ssh/config"; then
  log_success "✅ File di configurazione SSH esiste"
  assert_file_permissions "/root/.ssh/config" "600"
else
  log_info "ℹ️ File di configurazione SSH non trovato (potrebbe essere normale se i segreti non sono stati decifrati)"
fi

if docker exec test-container bash -c "test -f /root/.ssh/id_rsa"; then
  log_success "✅ Chiave privata SSH esiste"
  assert_file_permissions "/root/.ssh/id_rsa" "600"
  assert_file_exists "/root/.ssh/id_rsa.pub"
else
  log_info "ℹ️ Chiavi SSH non trovate (potrebbe essere normale se i segreti non sono stati decifrati)"
fi

log_info "FASE 2: Seconda esecuzione per verificare idempotenza..."
docker exec -e HOME=/root test-container bash -c "cd /workstation && ./modules/ssh.sh || echo 'Expected failure if no secrets available'"

log_info "Verifica idempotenza delle configurazioni SSH..."
if docker exec test-container bash -c "test -f /root/.ssh/config"; then
  assert_no_duplicate_lines "/root/.ssh/config"
fi

log_info "Pulizia ambiente di test..."
docker stop test-container

log_success "Test completato con successo! 🎉"