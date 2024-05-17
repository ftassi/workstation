#!/usr/bin/env bash

set -e 
#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "$0: missing arguments"
    echo "use: $0 <file_to_encrypt> <encypted_file>"
    exit 1
fi

# Assegna i parametri a variabili con nomi significativi
file_to_encrypt="$1"
encrypted_file="$2"

# Cripta il file
gpg --symmetric --cipher-algo AES256 --output "${encrypted_file}" "${file_to_encrypt}"

if [ "$?" -eq 0 ]; then
    echo "${encrypted_file} encrypted."
else
    echo "Error while encrypting file."
    exit 1
fi

