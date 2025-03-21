# Provisioning della Workstation

Questo repository contiene una serie di script per il provisioning automatizzato di una workstation basata su Ubuntu 24.04 LTS.

## Setup e provisioning semplificato

Per iniziare il provisioning completo su una nuova macchina, esegui semplicemente:

```bash
curl -sSL https://rebrand.ly/ftassi-workstation | bash
```

Questo comando scarica e esegue lo script di bootstrap, che:
1. Verifica automaticamente l'integrità dello script
2. Installa le dipendenze necessarie (git, gpg, git-crypt)
3. Clona il repository nella directory corrente
4. Decodifica la chiave git-crypt usando la master password
5. Sblocca i file crittografati del repository
6. Avvia il processo di provisioning completo

> **Nota importante:** Ti verrà richiesto di inserire la master password. Questa è l'unico secret mnemonico necessario per il provisioning completo.

## Esecuzione manuale di moduli specifici

Il provisioning installa i dotfiles, configura il sistema, crea distrobox per vari ambienti e installa applicazioni GUI di base. Se desideri eseguire solo porzioni specifiche del provisioning, puoi invocare direttamente gli script in `modules/`:

```bash
./modules/nome_modulo.sh
```

## Provisioning delle Distrobox

Il provisioning crea due ambienti `distrobox`:
- **nvim**: per avere un ide neovim isolato e pronto all'uso.
- **dev**: per l'ambiente di sviluppo.

Dopo la creazione delle distrobox tramite `main.sh`, è necessario eseguire il provisioning interno manualmente. 
Entrare nella distrobox ed eseguire:

```bash
distrobox enter nvim -- ./distrobox/nvim.sh
distrobox enter dev -- ./distrobox/dev.sh
```

## Gestione dei Secrets

I file sensibili sono crittografati con `git-crypt`. 
Gli script `encrypt.sh` e `decrypt.sh` gestiscono la cifratura e la decifratura tramite `gpg` dei file prima 
che il repository venga inizializzato con `git-crypt`. Ad esempio la chiave stessa di giy-crypt è cifrata con `gpg`.
Sono file di utility per la manutenzione del repository e non necessari al provisionig della macchina.

```bash
./encrypt.sh   # Per criptare i file
./decrypt.sh   # Per decriptare i file
```

Lo script di utility `repo.sh` permette di eseguire lock e unlock del repository git-crypt utilizando la chiave locale.

```bash

## Conclusione

Dopo aver completato il provisioning, rimuovere il file dei sudoers temporanei:

```bash
sudo rm /etc/sudoers.d/zz_provisioning_<utente>
```

Ora la workstation è pronta all'uso.

