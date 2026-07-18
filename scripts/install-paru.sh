#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

if command_exists paru; then
    success "Paru is already installed"
    exit 0
fi

log "Installing Paru"

sudo pacman -S --needed --noconfirm base-devel git

BUILD_DIR="$(mktemp -d)"

cleanup() {
    rm -rf "$BUILD_DIR"
}

trap cleanup EXIT

git clone https://aur.archlinux.org/paru.git "$BUILD_DIR/paru"

cd "$BUILD_DIR/paru"
makepkg -si --noconfirm --needed

if command_exists paru; then
    success "Paru installed successfully"
else
    error "Paru installation failed"
    exit 1
fi
