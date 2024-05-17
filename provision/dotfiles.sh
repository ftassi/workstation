#!/bin/bash

set -x 

# Funzione per installare i pacchetti necessari
install_packages() {
  sudo apt-get update
  sudo apt-get install -y git git-crypt stow
}

# Funzione per copiare la chiave git-crypt
copy_git_crypt_key() {
  local encrypted_key="./secrets/dotfiles/.git-crypt-key"
  local decrypted_key="$HOME/.git-crypt-key"
  if [ -f "$encrypted_key" ]; then
    ./decrypt.sh $encrypted_key $decrypted_key
    chmod 600 "$decrypted_key"
  else
    echo "Chiave git crypt mancante"
    exit 1
  fi
}

check_dotfiles_repo() {
  if [ -d "$HOME/dotfiles/.git" ]; then
    return 0
  else
    return 1
  fi
}

clone_dotfiles_repo() {
  if ! check_dotfiles_repo; then
    git clone git@github.com:ftassi/dotfiles.git "$HOME/dotfiles"
  fi
}

unlock_secrets() {
  if ! check_dotfiles_repo; then
    (cd "$HOME/dotfiles" && git-crypt unlock "$HOME/.git-crypt-key")
  fi
}

# Eseguire le funzioni
install_packages
copy_git_crypt_key
clone_dotfiles_repo
unlock_secrets
