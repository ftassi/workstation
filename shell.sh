#!/usr/bin/env bash

set -e 
set -x 

./provision/dotfiles.sh
./provision/nerdfonts.sh
./provision/fzf.sh

# Distrobox
if ! command -v distrobox &> /dev/null; then
    echo -e "${GREEN}Distrobox già installato${NC}"
else
    echo -e "${BLUE}Installazione di distrobox${NC}"

    curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh -s -- --prefix ~/opt
    sudo apt-get install -y podman
fi

# Installare i pacchetti comuni
sudo apt-get update
sudo apt-get install -y zsh-antigen zsh exa alacritty

# Installare le configurazioni utilizzando stow
config_items=("alacritty" "zsh" "antigen")
for item in "${config_items[@]}"; do
  if [ -d "$HOME/dotfiles/$item" ]; then
    (cd "$HOME/dotfiles" && stow "$item")
  else
    echo "Configurazione $item non trovata nella directory ~/dotfiles."
    exit 1
  fi
done

# Creare la directory histfile
  if [ ! -f "$HOME/.local/share/zsh/histfile" ]; then
    mkdir -p "$HOME/.local/share/zsh"
    touch "$HOME/.local/share/zsh/histfile"
    chmod 644 "$HOME/.local/share/zsh/histfile"
  fi
done

# Impostare zsh come shell predefinita per l'utente
username_on_the_host=$(whoami)
sudo usermod --shell /usr/bin/zsh "$username_on_the_host"
