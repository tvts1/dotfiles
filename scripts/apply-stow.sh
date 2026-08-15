#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

modules=(
    desktop
    gtk
    kitty
    niri
    noctalia
    nvim
    starship
    thunar
    zsh
)

log "Applying dotfiles with GNU Stow"

if ! command_exists stow; then
    error "GNU Stow is not installed."
    exit 1
fi

for module in "${modules[@]}"; do
    if [[ ! -d "$DOTFILES_DIR/$module" ]]; then
        error "Configured Stow module does not exist: $module"
        exit 1
    fi
done

remove_broken_dotfiles_links() {
    local link raw_target resolved_target
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"

    [[ -d "$config_home" ]] || return 0

    while IFS= read -r -d '' link; do
        raw_target="$(readlink -- "$link")"
        if [[ "$raw_target" == /* ]]; then
            resolved_target="$(readlink -m -- "$raw_target")"
        else
            resolved_target="$(readlink -m -- "$(dirname -- "$link")/$raw_target")"
        fi

        if [[ "$resolved_target" == "$DOTFILES_DIR/"* ]]; then
            unlink -- "$link"
            warning "Removed retired dotfiles link: $link"
        fi
    done < <(find "$config_home" -xtype l -print0)
}

target_points_to_source() {
    local target="$1"
    local source="$2"
    local target_resolved source_resolved

    target_resolved="$(readlink -f -- "$target" 2>/dev/null || true)"
    source_resolved="$(readlink -f -- "$source" 2>/dev/null || true)"

    [[ -n "$target_resolved" && -n "$source_resolved" && "$target_resolved" == "$source_resolved" ]]
}

detect_and_backup_conflicts() {
    local module="$1"
    local source rel target

    while IFS= read -r -d '' source; do
        rel="${source#"$DOTFILES_DIR/$module"/}"

        target="$HOME/$rel"

        if [[ ! -e "$target" && ! -L "$target" ]]; then
            continue
        fi

        if target_points_to_source "$target" "$source"; then
            continue
        fi

        if [[ -L "$target" ]] && path_is_within_dotfiles "$target"; then
            backup_path "$target"
            continue
        fi

        if [[ -f "$target" || -L "$target" ]]; then
            backup_path "$target"
        fi
    done < <(
        find "$DOTFILES_DIR/$module" \( -type f -o -type l \) \
            ! -name '.stow-local-ignore' \
            ! -name '*.tmpl' \
            -print0
    )
}

remove_broken_dotfiles_links

for module in "${modules[@]}"; do
    detect_and_backup_conflicts "$module"

    stow \
        --dir="$DOTFILES_DIR" \
        --target="$HOME" \
        --no-folding \
        --restow \
        "$module"

    success "Applied $module"
done

print_backups
