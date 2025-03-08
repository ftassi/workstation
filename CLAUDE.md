# Workstation Setup Scripts - Assistant Guide

## Commands
- **Run main setup**: `./main.sh`
- **Decrypt secrets**: `./decrypt.sh <file.gpg>` (interattivo)
- **Encrypt secrets**: `./encrypt.sh <file>` (interattivo)
- **Run specific module**: `./modules/[module].sh` (e.g., `./modules/dev.sh`)
- **Check script syntax**: `shellcheck [script_path]`

## Code Style
- **Bash**: Scripts use `-e` flag (exit on error)
- **Functions**: Use snake_case with descriptive names
- **Variables**: Use uppercase for constants, lowercase for locals
- **Error Handling**: Use `error()` for error messages and appropriate exit codes
- **Logging**: Use `info()`, `success()`, e `error()` functions from common.sh
- **Documentation**: Add comments for non-obvious functions
- **Modularity**: Use separate scripts in modules/ for each component
- **Secret Management**: Use git-crypt for encrypted files in secrets/
- **Security**: Password prompts use `read -s` for secure input

## Repository Structure
- **modules/**: Contains independent setup scripts for components
- **distrobox/**: Scripts for container-based environments
- **secrets/**: Encrypted files (SSH keys, configs)
- **main.sh**: Main entry point that calls all modules