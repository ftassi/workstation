#!/bin/bash

set -x 

# Variabili
FONT_DIR="$HOME/.local/share/fonts"
FILES=(
  "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf MesloLGS NF Regular.ttf"
  "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf MesloLGS NF Bold.ttf"
  "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf MesloLGS NF Italic.ttf"
  "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf MesloLGS NF Bold Italic.ttf"
)

# Creare la directory dei font se non esiste
mkdir -p "$FONT_DIR"
chmod 755 "$FONT_DIR"

# Scaricare e installare Nerd Fonts solo se non esistono già
for FILE in "${FILES[@]}"; do
  URL="${FILE%% *}"
  DEST="$FONT_DIR/${FILE##* }"
  if [ ! -f "$DEST" ]; then
    curl -fLo "$DEST" "$URL"
    chmod 644 "$DEST"
  else
    echo "Il file $DEST esiste già, salto il download."
  fi
done

# Aggiornare la cache dei font
sudo -u "$USER" fc-cache -fv
