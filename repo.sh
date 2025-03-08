#!/bin/bash

set -e

print_usage() {
    echo "Utilizzo:"
    echo "  git-crypt unlock - per sbloccare il repository"
    echo "  git-crypt lock   - per bloccare il repository"
    exit 1
}

if [ $# -eq 0 ]; then
    print_usage
fi

command="$1"

case "$command" in
    "unlock")
        if [ ! -f "git-crypt.key" ]; then
            gpg --batch --yes --output git-crypt.key --decrypt git-crypt.key.gpg
        fi
        git-crypt unlock git-crypt.key
        ;;
    "lock")
        git-crypt lock
        rm git-crypt.key
        ;;
    *)
        print_usage
        ;;
esac
