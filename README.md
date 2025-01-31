# Provisioning Workstation - Ubuntu 24.04

## Descrizione
Questo progetto fornisce una serie di script Bash idempotenti per il provisioning di workstation basate su Ubuntu 24.04 LTS. Gli script consentono di automatizzare la configurazione del sistema riducendo al minimo il numero di file necessari e garantendo che ogni esecuzione lasci il sistema in uno stato coerente.

## Struttura del Progetto
- `common.sh` - Contiene funzioni e variabili comuni utilizzate da tutti gli script.
- `enable_ssh_firewall.sh` - Abilita SSH, installa e configura il firewall UFW per accettare connessioni SSH. Può anche disattivare SSH e chiudere le porte del firewall quando non necessario.
- `setup.sh` - Chiede all'utente la master password e la password di sudo per creare il file `.passwords` e installa alcuni pacchetti di base.
- `encrypt.sh` - Permette di cifrare un qualsiasi file con `gpg` utilizzando crittografia simmetrica basata su una master password. Legge la master password dal file `.passwords` tramite `common.sh`.
- `decrypt.sh` - Permette di decifrare un file cifrato con `gpg` utilizzando una master password, anch'essa letta da `.passwords` tramite `common.sh`.

## Requisiti
- Ubuntu 24.04 LTS Desktop
- Accesso con privilegi sudo

## Gestione delle Password
Il file `.passwords` viene utilizzato per salvare in modo temporaneo:
- **MASTER_PASSWORD**: utilizzata per cifrare e decifrare i file con `gpg`.
- **SUDO_PASSWORD**: utilizzata negli script di provisioning per eseguire comandi `sudo` senza richiedere input manuale.

Il file `.passwords` viene creato dallo script `setup.sh` e deve essere mantenuto sicuro. Ha permessi `600` per evitare accessi non autorizzati.

## Installazione
1. Clonare il repository o copiare gli script su una chiavetta USB:
   ```bash
   git clone <URL_DEL_REPO> provisioning-repo
   cd provisioning-repo
   ```

2. Creare il file `.passwords` con le credenziali richieste:
   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

3. Sbloccare i secrets e avviare il provisioning:
   ```bash
   ./setup.sh
   ```

4. Per cifrare un file con `gpg` in modalità simmetrica:
   ```bash
   chmod +x encrypt.sh
   ./encrypt.sh <file_da_cifrare>
   ```
   Questo genererà un file cifrato `<file_da_cifrare>.gpg`. Lo script leggerà automaticamente la master password da `.passwords` tramite `common.sh`.

5. Per decifrare un file cifrato con `gpg`:
   ```bash
   chmod +x decrypt.sh
   ./decrypt.sh <file_cifrato.gpg>
   ```
   Questo genererà il file decriptato con il nome originale senza l'estensione `.gpg`.

## Funzioni Riutilizzabili
### Lettura delle Password
Negli script di provisioning vengono utilizzate le seguenti funzioni per leggere le credenziali salvate in `.passwords`, definite in `common.sh`.

#### **Funzione `get_master_password`**
```bash
get_master_password() {
    local PASSWORD_FILE=".passwords"
    
    if [ ! -f "$PASSWORD_FILE" ]; then
        echo -e "\e[31m[ERRORE] Il file .passwords non esiste. Crealo con setup.sh.\e[0m"
        exit 1
    fi
    
    source "$PASSWORD_FILE"
    
    if [ -z "$MASTER_PASSWORD" ]; then
        echo -e "\e[31m[ERRORE] MASTER_PASSWORD non trovata in .passwords.\e[0m"
        exit 1
    fi
    
    echo "$MASTER_PASSWORD"
}
```

#### **Funzione `get_sudo_password`**
```bash
get_sudo_password() {
    local PASSWORD_FILE=".passwords"
    
    if [ ! -f "$PASSWORD_FILE" ]; then
        echo -e "\e[31m[ERRORE] Il file .passwords non esiste. Crealo con setup.sh.\e[0m"
        exit 1
    fi
    
    source "$PASSWORD_FILE"
    
    if [ -z "$SUDO_PASSWORD" ]; then
        echo -e "\e[31m[ERRORE] SUDO_PASSWORD non trovata in .passwords.\e[0m"
        exit 1
    fi
    
    echo "$SUDO_PASSWORD"
}
```

### Installazione idempotente di pacchetti con `apt`
Negli script di provisioning viene utilizzata la funzione `install_package()` per installare pacchetti in modo idempotente, definita in `common.sh`.

#### **Funzione `install_package`**
```bash
install_package() {
    local PACKAGE=$1
    
    if dpkg -s "$PACKAGE" &> /dev/null; then
        echo -e "\e[34m[INFO] Il pacchetto $PACKAGE è già installato. Skipping.\e[0m"
    else
        echo -e "\e[32m[INFO] Installazione di $PACKAGE...\e[0m"
        SUDO_PASSWORD=$(get_sudo_password)
        echo "$SUDO_PASSWORD" | sudo -S apt-get update -qq && sudo -S apt-get install -y "$PACKAGE"
    fi
}
```

## Stato degli Script
- ✅ `common.sh` - Implementato e testato
- ✅ `enable_ssh_firewall.sh` - Implementato e testato
- ✅ `setup.sh` - Implementato e testato
- ✅ `encrypt.sh` - Implementato e testato
- ✅ `decrypt.sh` - Implementato e testato

## Prossimi Passi
- Implementazione di ulteriori script per configurare utenti, pacchetti e impostazioni di sistema.

---
Questo file verrà aggiornato man mano che nuovi script vengono aggiunti o modificati.

