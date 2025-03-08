# Workstation Setup Scripts - Assistant Guide

## Commands
- **Run main setup**: `./main.sh`
- **Decrypt secrets**: `./decrypt.sh <file.gpg>` (interattivo)
- **Encrypt secrets**: `./encrypt.sh <file>` (interattivo)
- **Run specific module**: `./modules/[module].sh` (e.g., `./modules/dev.sh`)
- **Check script syntax**: `shellcheck [script_path]`

## Code Style
- **Bash**: Scripts use `set -euo pipefail` via setup_error_handling()
- **Functions**: Use snake_case with descriptive names
- **Variables**: Use uppercase for constants, lowercase for locals
- **Error Handling**: Use `die()` to exit on error with appropriate message
- **Logging**: Use `info()`, `success()`, and `error()` functions from common.sh
- **Documentation**: Header comments for script purpose and dependencies
- **Modularity**: Use separate scripts in modules/ for each component
- **Secret Management**: Use git-crypt for encrypted files in secrets/
- **Security**: Password prompts use `read -s` for secure input
- **Idempotenza**: Use functions like `add_gpg_key()` and `add_apt_repository()` for operations that should be performed only once

## Error Handling
- All scripts must include `setup_error_handling()` after sourcing common.sh
- Use `die "Error message"` instead of `error` + `exit 1`
- Trap on ERR is automatically configured by setup_error_handling

## Common Functions
- **add_gpg_key(url, path)**: Adds a GPG key in an idempotent way
- **add_apt_repository(name, content)**: Adds an apt repository in an idempotent way
- **setup_error_handling()**: Configures error handling with proper exit codes
- **die(message)**: Terminates the script with an error message
- **prompt_master_password()**: Securely prompts for the master password

## Repository Structure
- **modules/**: Contains independent setup scripts for components
- **distrobox/**: Scripts for container-based environments
- **secrets/**: Encrypted files (SSH keys, configs)
- **main.sh**: Main entry point that calls all modules