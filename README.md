# Provisioning della Workstation

Questo repository contiene una serie di script per il provisioning automatizzato di una workstation basata su Ubuntu 24.04 LTS. 

## Setup iniziale

Il provisioning della workstation inizia con l'esecuzione dello script `setup.sh`, che decodifica la chiave utilizzata
per cifrare il repository con `git-crypt` e fornisce i permessi sudo temporanei per l'utente corrente.
La master password richiesta per la decodifica della chiave è l'unico secret mnemonico necessario per il provisioning.
Tutti gli altri secret sono criptati con git-crypt e disponibili dopo il setup in `secrets/`
### Esecuzione

```bash
sudo ./setup.sh
```

> **Nota:** Dopo il provisioning, il file `/etc/sudoers.d/zz_provisioning_<utente>` deve essere rimosso manualmente per revocare i privilegi sudo temporanei.

## Esecuzione del provisioning principale

Una volta completato il setup iniziale, si esegue lo script `main.sh` per avviare il provisioning completo.
Il provisioning scarica e installa il mio repository dei dotfiles, installa i pacchetti software e le configurazioni di sistema necessarie.
Crea alcune distrobox per l'ambiente di sviluppo e per l'ide neovim, installa regolith e alcune applicazioni gui di base.

Volendo eseguire solo alcune porzioni del provisioning, è possibile invocare direttamente gli script in `modules/`

### Esecuzione

```bash
sudo ./main.sh
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

