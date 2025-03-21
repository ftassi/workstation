#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/." && pwd)"
source "$REPO_DIR/tests/common_test_utils.sh"

log_info "Avvio container Ubuntu 24.04..."
docker run --name test-container --rm -d -v "$REPO_DIR:/workstation" ubuntu:24.04 sleep infinity

log_info "Installazione requisiti minimi..."
docker exec test-container bash -c "apt-get update && apt-get install -y sudo curl apt-utils gpg"

log_info "FASE 1: Prima esecuzione del modulo docker.sh..."
docker exec -e HOME=/root test-container bash -c "cd /workstation && ./modules/docker.sh"

log_info "Verifica delle installazioni dopo la prima esecuzione..."

assert_package_installed "docker-ce"
assert_package_installed "docker-compose-plugin"

assert_binary_exists "docker"
assert_binary_exists "docker-compose"

log_info "Verifica appartenenza al gruppo docker..."
if docker exec test-container bash -c "getent group docker | grep -q 'root'"; then
  log_success "✅ Utente è stato aggiunto al gruppo docker"
else
  log_error "❌ Utente NON è stato aggiunto al gruppo docker"
fi

log_info "FASE 2: Seconda esecuzione per verificare idempotenza..."
docker exec -e HOME=/root test-container bash -c "cd /workstation && ./modules/docker.sh"

log_info "Verifica idempotenza delle configurazioni..."
assert_apt_repository_added_once "download.docker.com"

log_info "Pulizia ambiente di test..."
docker stop test-container

log_success "Test completato con successo! 🎉"