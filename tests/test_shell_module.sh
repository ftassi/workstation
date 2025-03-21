#!/bin/bash

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$REPO_DIR/tests/common_test_utils.sh"

log_info "Avvio container Ubuntu 24.04..."
CONTAINER_NAME="test-container-shell-$$"
docker run --name $CONTAINER_NAME --rm -d -v "$REPO_DIR:/workstation" ubuntu:24.04 sleep infinity

log_info "Installazione requisiti minimi..."
docker exec $CONTAINER_NAME bash -c "apt-get update && apt-get install -y sudo curl apt-utils gpg git stow"

docker exec $CONTAINER_NAME bash -c "mkdir -p /root/dotfiles/zsh /root/dotfiles/antigen /root/dotfiles/alacritty"

log_info "FASE 1: Prima esecuzione del modulo shell.sh..."
docker exec -e HOME=/root $CONTAINER_NAME bash -c "cd /workstation && ./modules/shell.sh"

log_info "Verifica delle installazioni dopo la prima esecuzione..."

assert_package_installed "zsh"
assert_package_installed "distrobox"

assert_binary_exists "zsh"
assert_binary_exists "fzf"

log_info "Verifica configurazione ZSH..."
if docker exec $CONTAINER_NAME bash -c "test -f /root/.zshrc"; then
  log_success "✅ File di configurazione ZSH è stato creato"
else
  log_error "❌ File di configurazione ZSH NON è stato creato"
fi

log_info "Verifica shell predefinita..."
if docker exec $CONTAINER_NAME bash -c "getent passwd root | grep -q 'zsh'"; then
  log_success "✅ La shell predefinita è stata impostata a ZSH"
else
  log_info "ℹ️ La shell predefinita NON è stata impostata a ZSH (potrebbe essere normale in un container)"
fi

log_info "FASE 2: Seconda esecuzione per verificare idempotenza..."
docker exec -e HOME=/root $CONTAINER_NAME bash -c "cd /workstation && ./modules/shell.sh"

log_info "Verifica idempotenza delle configurazioni..."
assert_no_duplicate_lines "/root/.zshrc" 
assert_apt_repository_added_once "aslatter/ppa"

log_info "Pulizia ambiente di test..."
docker stop $CONTAINER_NAME

log_success "Test completato con successo! 🎉"