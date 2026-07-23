#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

source "$DOTFILES_DIR/scripts/common.sh"

if [[ ! -f /etc/arch-release ]]; then
  error "This installer supports Arch Linux only."
  exit 1
fi

if [[ $EUID -eq 0 ]]; then
  error "Do not run this installer as root."
  exit 1
fi

log "Starting Arch Linux dotfiles installation"

log "Installing bootstrap dependencies"
sudo pacman -Syu --needed --noconfirm git base-devel

bash "$DOTFILES_DIR/scripts/install-paru.sh"
bash "$DOTFILES_DIR/scripts/install-packages.sh"
bash "$DOTFILES_DIR/scripts/prepare-user-files.sh"
bash "$DOTFILES_DIR/scripts/apply-stow.sh"
bash "$DOTFILES_DIR/scripts/enable-services.sh"

success "Installation finished"
