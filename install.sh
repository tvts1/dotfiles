#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

source "$DOTFILES_DIR/scripts/common.sh"

log "Starting Arch Linux dotfiles installation"

bash "$DOTFILES_DIR/scripts/install-paru.sh"
bash "$DOTFILES_DIR/scripts/install-packages.sh"
bash "$DOTFILES_DIR/scripts/apply-stow.sh"
bash "$DOTFILES_DIR/scripts/enable-services.sh"

success "Installation finished"
