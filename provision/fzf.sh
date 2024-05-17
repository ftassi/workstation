#!/bin/bash

set -x 

# Rimuovere fzf se installato dal repository
sudo apt-get remove -y fzf

fzf_repo="$HOME/.fzf/.git"
if [ ! -d "$fzf_repo" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
fi

config_items=("fzf")
for item in "${config_items[@]}"; do
  if [ -d "$HOME/dotfiles/$item" ]; then
    (cd "$HOME/dotfiles" && stow "$item")
  else
    echo "Configurazione $item non trovata nella directory ~/dotfiles."
    exit 1
  fi
done
