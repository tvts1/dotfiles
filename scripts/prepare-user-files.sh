#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

HYPR_CONFIG_DIR="$HOME/.config/hypr"
GTK4_CONFIG_DIR="$HOME/.config/gtk-4.0"
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
HYPR_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
GTK4_THEME_DIR="/usr/share/themes/Colloid-Purple-Dark/gtk-4.0"

create_directory() {
    local dir="$1"

    mkdir -p -- "$dir"
    success "Ensured directory: $dir"
}

write_generated_file() {
    local target="$1"
    local content_file="$2"

    if [[ -L "$target" ]] && path_is_within_dotfiles "$target"; then
        unlink -- "$target"
    elif [[ -e "$target" || -L "$target" ]]; then
        if cmp -s -- "$content_file" "$target"; then
            return 0
        fi

        backup_path "$target"
    fi

    install -m 0644 -- "$content_file" "$target"
}

render_hyprlock_config() {
    local target="$HYPR_CONFIG_DIR/hyprlock.conf"
    local tmp current_wallpaper_link="$HYPR_CONFIG_DIR/current-wallpaper"

    tmp="$(mktemp)"
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == *"{{CURRENT_WALLPAPER_LINK}}"* ]]; then
            printf '%s\n' "${line//\{\{CURRENT_WALLPAPER_LINK\}\}/$current_wallpaper_link}"
        else
            printf '%s\n' "$line"
        fi
    done < "$DOTFILES_DIR/hypr/.config/hypr/hyprlock.conf.tmpl" > "$tmp"

    write_generated_file "$target" "$tmp"
    rm -f -- "$tmp"
    success "Prepared Hyprlock config: $target"
}

configure_gtk4_theme_links() {
    local name source target
    local names=(gtk.css gtk-dark.css assets)

    if [[ -f "$GTK4_THEME_DIR/gtk.css" && -f "$GTK4_THEME_DIR/gtk-dark.css" && -d "$GTK4_THEME_DIR/assets" ]]; then
        for name in "${names[@]}"; do
            source="$GTK4_THEME_DIR/$name"
            target="$GTK4_CONFIG_DIR/$name"

            if [[ -L "$target" ]]; then
                ln -sfn -- "$source" "$target"
            elif [[ -e "$target" ]]; then
                warning "GTK 4 target exists and was left unchanged: $target"
            else
                ln -s -- "$source" "$target"
            fi
        done

        success "GTK 4 Colloid links are configured"
        return 0
    fi

    warning "GTK 4 theme not found: $GTK4_THEME_DIR"

    for name in "${names[@]}"; do
        target="$GTK4_CONFIG_DIR/$name"

        if [[ -L "$target" ]]; then
            source="$(readlink -- "$target")"

            if [[ "$source" == "$GTK4_THEME_DIR/"* || ! -e "$target" ]]; then
                unlink -- "$target"
                warning "Removed unavailable GTK 4 theme link: $target"
            fi
        fi
    done
}

log "Preparing user files and directories"

create_directory "$SCREENSHOT_DIR"
create_directory "$WALLPAPER_DIR"
create_directory "$HYPR_CONFIG_DIR"
create_directory "$HYPR_STATE_DIR"
create_directory "$GTK4_CONFIG_DIR"

render_hyprlock_config
configure_gtk4_theme_links
print_backups

success "User files prepared"
