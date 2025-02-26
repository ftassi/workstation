#!/bin/bash
set -e

# Download and install https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip
# 669  unzip JetBrainsMono.zip
# 670  ls -la ~/Downloads
# 671  mkdir .fonts
# 672  cd .fonts
# 673  mkdir jetbrains-mono-nerd
# 674  mv ~/Downloads/Jet*.ttf jetbrains-mono-nerd/
# 675  ls -la jetbrains-mono-nerd
# 676  fc-cache -f -v
# 677  fc-list -f '%{family}\n' | awk '!x[$0]++' | grep Jet
# 678  fc-list -f '%{family}\n' | awk '!x[$0]++' | grep JetBrainsMono
