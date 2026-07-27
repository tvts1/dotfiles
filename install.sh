#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
export DOTFILES_DIR

source "$DOTFILES_DIR/scripts/common.sh"

WITH_DEV_TOOLS=0

usage() {
  cat <<'EOF'
Usage: install.sh [--with-dev-tools]

Options:
  --with-dev-tools  Also install SDKMAN, Java, Maven, Volta, Node, npm, and pnpm.
  -h, --help        Show this help.
EOF
}

while (($#)); do
  case "$1" in
    --with-dev-tools)
      WITH_DEV_TOOLS=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      error "Unknown option: $1"
      usage >&2
      exit 2
      ;;
  esac

  shift
done

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
bash "$DOTFILES_DIR/scripts/configure-elephant.sh"
bash "$DOTFILES_DIR/scripts/disable-thunar-wallpaper-plugin.sh"
bash "$DOTFILES_DIR/scripts/enable-services.sh"

if ((WITH_DEV_TOOLS)); then
  bash "$DOTFILES_DIR/scripts/install-dev-toolchain.sh"
else
  success "Skipped optional development toolchain"
fi

success "Installation finished"
