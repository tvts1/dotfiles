#!/usr/bin/env bash

set -euo pipefail

usage() {
    printf 'Usage: %s IMAGE\n' "$(basename -- "$0")" >&2
}

info() {
    printf '%s\n' "$*"
}

die() {
    printf 'Error: %s\n' "$*" >&2
    exit 1
}

is_dry_run() {
    [[ "${DRY_RUN:-0}" == "1" ]]
}

is_supported_image() {
    local path="$1"

    case "${path,,}" in
        *.jpg | *.jpeg | *.png | *.webp | *.jxl)
            return 0
            ;;
    esac

    return 1
}

require_runtime_commands() {
    local command_name

    for command_name in realpath hyprctl hyprpaper; do
        command -v "$command_name" >/dev/null 2>&1 ||
            die "required command not found: $command_name"
    done
}

hyprpaper_ipc_ready() {
    hyprctl hyprpaper listactive >/dev/null 2>&1
}

start_hyprpaper_if_needed() {
    if hyprpaper_ipc_ready; then
        return 0
    fi

    hyprpaper -c "$HOME/.config/hypr/hyprpaper.conf" >/dev/null 2>&1 &
}

wait_for_hyprpaper_ipc() {
    local attempts=50

    while (( attempts > 0 )); do
        if hyprpaper_ipc_ready; then
            return 0
        fi

        sleep 0.1
        ((attempts--))
    done

    return 1
}

apply_wallpaper() {
    local path="$1"

    hyprctl hyprpaper wallpaper ",$path,cover" >/dev/null
}

save_current_wallpaper() {
    local path="$1"
    local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/hypr"
    local state_file="$state_dir/current-wallpaper"
    local link_path="$HOME/.config/hypr/current-wallpaper"

    mkdir -p -- "$state_dir" "$(dirname -- "$link_path")"
    printf '%s\n' "$path" > "$state_file"
    ln -sfn -- "$path" "$link_path"
}

main() {
    if (( $# == 0 )); then
        usage
        exit 2
    fi

    if (( $# != 1 )); then
        usage
        die "expected exactly one image path"
    fi

    local input_path="$1"
    local wallpaper_path

    [[ -f "$input_path" ]] || die "image file does not exist: $input_path"

    wallpaper_path="$(realpath -- "$input_path")"

    is_supported_image "$wallpaper_path" ||
        die "unsupported image type: $wallpaper_path"

    if is_dry_run; then
        info "DRY_RUN: would apply wallpaper: $wallpaper_path"
        info "DRY_RUN: would save state and update current-wallpaper link"
        return 0
    fi

    require_runtime_commands
    start_hyprpaper_if_needed
    wait_for_hyprpaper_ipc ||
        die "Hyprpaper IPC did not become available within 5 seconds"
    apply_wallpaper "$wallpaper_path"
    save_current_wallpaper "$wallpaper_path"

    info "Wallpaper applied: $wallpaper_path"
}

main "$@"
