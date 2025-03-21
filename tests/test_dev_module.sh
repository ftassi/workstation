#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/tests/common_test_utils.sh"

start_test_container 

log_info "Installazione requisiti minimi..."
docker exec test-container bash -c "apt-get update && apt-get install -y sudo curl apt-utils gpg"

log_info "FASE 1: Prima esecuzione del modulo dev.sh..."
docker exec -e HOME=/root test-container bash -c "cd /workstation && ./modules/dev.sh"

log_info "Verifica delle installazioni dopo la prima esecuzione..."

assert_package_installed "git"
assert_package_installed "jq"
assert_package_installed "curl"
assert_package_installed "wget"
assert_package_installed "httpie"
assert_package_installed "tmux"

assert_package_installed "eza"
assert_package_installed "bat"
assert_package_installed "ripgrep"
assert_package_installed "zoxide"

assert_package_installed "gh"
assert_binary_exists "gh"

assert_binary_exists "/root/.local/aws/bin/aws"

assert_binary_exists "/root/.local/cargo/bin/cargo"
assert_binary_exists "/root/.local/cargo/bin/rustc"

log_info "FASE 2: Seconda esecuzione per verificare idempotenza..."
docker exec -e HOME=/root test-container bash -c "cd /workstation && ./modules/dev.sh"

if docker exec test-container bash -c "test -f /root/.config/git/config"; then
  assert_no_duplicate_lines "/root/.config/git/config"
fi

log_info "Pulizia ambiente di test..."
docker stop test-container

log_success "Test completato con successo! 🎉"
