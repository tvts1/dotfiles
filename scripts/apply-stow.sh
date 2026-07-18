#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

modules=(
    desktop
    fish
    gtk
    hypr
    kitty
    starship
    thunar
    walker
    waybar
)

log "Applying dotfiles with GNU Stow"

if ! command_exists stow; then
    error "GNU Stow is not installed."
    exit 1
fi

for module in "${modules[@]}"; do
    if [[ -d "$DOTFILES_DIR/$module" ]]; then
        stow \
            --dir="$DOTFILES_DIR" \
            --target="$HOME" \
            --restow \
            "$module"

        success "Applied $module"
    else
        warning "Module not found: $module"
    fi
done
