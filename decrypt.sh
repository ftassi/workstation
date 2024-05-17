#!/usr/bin/env bash

set -e

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "$0: wrong number of arguments"
    echo "use: $0 <file_to_decrypt> [<decrypted_file>]"
    exit 1
fi

# Assegna i parametri a variabili con nomi significativi
file_to_decrypt="$1"
decrypted_file="${2:-}"

# Decripta il file
if [ -z "$decrypted_file" ]; then
    # Nessun file di output specificato, stampa l'output
    gpg --decrypt "${file_to_decrypt}"
else
    # File di output specificato, salva l'output nel file
    gpg --output "${decrypted_file}" --decrypt "${file_to_decrypt}"
    if [ "$?" -eq 0 ]; then
        echo "${decrypted_file} decrypted."
    else
        echo "Error while decrypting file."
        exit 1
    fi
fi
