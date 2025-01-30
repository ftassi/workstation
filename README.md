# Provisioning Workstation - Ubuntu 24.04

## Descrizione
Questo progetto fornisce una serie di script Bash idempotenti per il provisioning di workstation basate su Ubuntu 24.04 LTS. Gli script consentono di automatizzare la configurazione del sistema riducendo al minimo il numero di file necessari e garantendo che ogni esecuzione lasci il sistema in uno stato coerente.

## Struttura del Progetto
- `enable_ssh_firewall.sh` - Abilita SSH, installa e configura il firewall UFW per accettare connessioni SSH. Può anche disattivare SSH e chiudere le porte del firewall quando non necessario.

## Requisiti
- Ubuntu 24.04 LTS Desktop
- Accesso con privilegi sudo

## Installazione
1. Clonare il repository o copiare gli script su una chiavetta USB.
2. Eseguire lo script desiderato:
   ```bash
   chmod +x enable_ssh_firewall.sh
   ./enable_ssh_firewall.sh
   ```

3. Per disattivare SSH e chiudere le porte del firewall:
   ```bash
   ./enable_ssh_firewall.sh --disable
   ```

## Stato degli Script
- ✅ `enable_ssh_firewall.sh` - Implementato e testato

## Prossimi Passi
- Implementazione di ulteriori script per configurare utenti, pacchetti e impostazioni di sistema.

---
Questo file verrà aggiornato man mano che nuovi script vengono aggiunti o modificati.

