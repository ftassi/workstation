#!/usr/bin/env bash

set -e 
#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "$0: missing arguments"
    echo "use: $0 <file_to_decrypt> <encypted_file>"
    exit 1
fi

# Assegna i parametri a variabili con nomi significativi
file_to_decrypt="$1"
decrypted_file="$2"

# Cripta il file
gpg --output "${decrypted_file}" --decrypt "${file_to_decrypt}"

if [ "$?" -eq 0 ]; then
    echo "${decrypted_file} decrypted."
else
    echo "Error while decrypting file."
    exit 1
fi

