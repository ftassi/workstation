# How to use

If ansible is not installed in the host just run

`sudo ./provision.sh` 

to install it 

To install a playbook locally execute 

`ansible-playbook playbook-name.yml --vault-password-file=./vault_pass.txt --ask-become`

You could either:
* create a ./vault_pass.txt file containing the vault file (be sure to not commit this you fool!)
* use --ask-vault-pass option to avoid file with plain password

# TODO

 - vim distrobox (lack clipboard access)[https://github.com/89luca89/distrobox/blob/main/docs/useful_tips.md#copy-text-to-host-clipboard]
 - replace podman with docker (quick) or solve podman compose issue (better?)
 - find a way to provision also gui applications. Especially for the browser there is a lot of setup that need to be done manually after installation.
