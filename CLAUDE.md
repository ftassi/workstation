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

## Error Handling
- All scripts must include `setup_error_handling()` after sourcing common.sh
- Use `die "Error message"` instead of `error` + `exit 1`
- Trap on ERR is automatically configured by setup_error_handling

## Repository Structure
- **modules/**: Contains independent setup scripts for components
- **distrobox/**: Scripts for container-based environments
- **secrets/**: Encrypted files (SSH keys, configs)
- **main.sh**: Main entry point that calls all modules