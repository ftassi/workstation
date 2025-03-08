#!/bin/bash
#
# Script di provisioning per applicazioni GUI
# Installa e configura applicazioni desktop come browser e strumenti grafici
# Richiede: wget, curl, apt

# Inclusione delle funzioni comuni
source "$(dirname "$0")/../common.sh"

# Imposta la gestione errori avanzata
setup_error_handling

info "Installazione degli applicativi GUI..."

# Aggiornamento della lista dei pacchetti e installazione dei tool necessari
info "Aggiornamento del sistema e installazione delle dipendenze..."
apt_update_if_needed
sudo apt install -y wget curl gnupg2 software-properties-common apt-transport-https

##############################
# Installazione di Google Chrome
##############################
if command -v google-chrome &>/dev/null; then
    info "Google Chrome è già installato."
else
    info "Installazione di Google Chrome..."
    # Scarica il pacchetto deb di Chrome
    wget -O /tmp/google-chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    # Installa il pacchetto e risolve eventuali dipendenze mancanti
    sudo dpkg -i /tmp/google-chrome.deb || sudo apt install -f -y
fi

##############################
# Installazione di Slack
##############################

if command -v slack &>/dev/null; then
    info "Slack è già installato."
else
    info "Installazione di Slack..."
    # Scarica il pacchetto deb di Slack
    # (Controlla sul sito ufficiale di Slack per aggiornare la versione se necessario)
    wget -O /tmp/slack.deb https://downloads.slack-edge.com/desktop-releases/linux/x64/4.41.105/slack-desktop-4.41.105-amd64.deb
    # Installa il pacchetto e risolve eventuali dipendenze mancanti
    sudo dpkg -i /tmp/slack.deb || sudo apt install -f -y
fi

##############################
# Installazione di 1Password
##############################
if [ "$(dpkg -l | awk '/1password/ {print }'|wc -l)" -ge 1 ]; then
    info "1password è già installato"
else
    info "Installazione di 1Password..."
    # Scarica il pacchetto deb di Chrome
    wget -O /tmp/1password-latest.deb https://downloads.1password.com/linux/debian/amd64/stable/1password-latest.deb
    # Installa il pacchetto e risolve eventuali dipendenze mancanti
    sudo dpkg -i /tmp/1password-latest.deb || sudo apt install -f -y
fi

##############################
# Installazione di Firefox dal repository ufficiale Mozilla
##############################
if command -v firefox &>/dev/null; then
    info "Firefox è già installato, ma potrebbe essere la versione Snap"
    info "Verifico la versione installata..."
    FIREFOX_PATH=$(which firefox)
    if [[ "$FIREFOX_PATH" == *"snap"* ]]; then
        info "Trovata versione Snap di Firefox. Procedo a rimuoverla e installare la versione dal repository Mozilla..."
        sudo snap remove firefox
        
        # Backup del profilo Snap se necessario
        if [ -d "$HOME/snap/firefox/common/.mozilla/firefox/" ]; then
            info "Effettuo backup del profilo Firefox Snap..."
            mkdir -p ~/.mozilla/firefox/
            cp -a ~/snap/firefox/common/.mozilla/firefox/* ~/.mozilla/firefox/
            info "Profilo Firefox Snap copiato in ~/.mozilla/firefox/"
        fi
    elif [[ "$FIREFOX_PATH" == *"flatpak"* ]] || [[ -d "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox/" ]]; then
        info "Trovata versione Flatpak di Firefox."
        
        # Backup del profilo Flatpak se necessario
        if [ -d "$HOME/.var/app/org.mozilla.firefox/.mozilla/firefox/" ]; then
            info "Effettuo backup del profilo Firefox Flatpak..."
            mkdir -p ~/.mozilla/firefox/
            cp -a ~/.var/app/org.mozilla.firefox/.mozilla/firefox/* ~/.mozilla/firefox/
            info "Profilo Firefox Flatpak copiato in ~/.mozilla/firefox/"
        fi
    else
        info "Firefox è già installato e non sembra essere una versione Snap o Flatpak."
    fi
fi

# Installazione di Firefox dal repository ufficiale Mozilla
if ! command -v firefox &>/dev/null || [[ "$(which firefox)" == *"snap"* ]] || [[ "$(which firefox)" == *"flatpak"* ]]; then
    info "Installazione di Firefox dal repository ufficiale Mozilla..."
    
    # Crea la directory per le chiavi GPT del repository
    info "Creazione della directory per le chiavi APT..."
    sudo install -d -m 0755 /etc/apt/keyrings
    
    # Importa la chiave di firma del repository Mozilla APT
    info "Importazione della chiave di firma Mozilla..."
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
    
    # Verifica l'impronta della chiave GPG
    info "Verifica dell'impronta della chiave GPG..."
    FINGERPRINT=$(gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | awk '/pub/{getline; gsub(/^ +| +$/,""); print}')
    EXPECTED_FINGERPRINT="35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3"
    
    if [ "$FINGERPRINT" == "$EXPECTED_FINGERPRINT" ]; then
        info "Impronta della chiave verificata correttamente: $FINGERPRINT"
    else
        info "ATTENZIONE: L'impronta della chiave ($FINGERPRINT) non corrisponde a quella prevista ($EXPECTED_FINGERPRINT)"
        info "Continuo comunque con l'installazione..."
    fi
    
    # Aggiungi il repository Mozilla
    info "Aggiunta del repository Mozilla..."
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
    
    # Configura APT per dare priorità ai pacchetti dal repository Mozilla
    info "Configurazione delle preferenze APT per il repository Mozilla..."
    echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
    
    # Aggiorna la lista dei pacchetti e installa Firefox
    info "Aggiornamento degli indici e installazione di Firefox..."
    apt_update_if_needed 1
    sudo apt-get install -y firefox
    
    # Installa anche il pacchetto della lingua italiana se necessario
    if [ "$(locale | grep LANG | cut -d= -f2 | cut -d_ -f1)" == "it" ]; then
        info "Installazione del pacchetto di lingua italiana per Firefox..."
        sudo apt-get install -y firefox-l10n-it
    fi
    
    info "Firefox installato dal repository ufficiale Mozilla."
else
    info "Firefox è già installato. Verifico se proviene dal repository Mozilla..."
    
    # Controlla se il repository Mozilla è configurato
    if ! grep -q "packages.mozilla.org" /etc/apt/sources.list.d/* 2>/dev/null; then
        info "Repository Mozilla non configurato. Procedo con la configurazione e l'aggiornamento di Firefox..."
        
        # Configura il repository Mozilla per gli aggiornamenti futuri
        sudo install -d -m 0755 /etc/apt/keyrings
        wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
        echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list > /dev/null
        echo '
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
' | sudo tee /etc/apt/preferences.d/mozilla > /dev/null
        
        info "Repository Mozilla configurato per gli aggiornamenti futuri."
    else
        info "Repository Mozilla già configurato."
    fi
fi


info "Installazione completata con successo!"
