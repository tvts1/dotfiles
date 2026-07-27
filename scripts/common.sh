#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)}"
BACKUP_TIMESTAMP="${BACKUP_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.dotfiles-backup/$BACKUP_TIMESTAMP}"
BACKED_UP_PATHS=()

log() {
    printf '\n\033[1;34m==>\033[0m %s\n' "$1"
}

success() {
    printf '\033[1;32m✔\033[0m %s\n' "$1"
}

warning() {
    printf '\033[1;33m!\033[0m %s\n' "$1"
}

error() {
    printf '\033[1;31m✘\033[0m %s\n' "$1" >&2
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

path_is_within_dotfiles() {
    local path="$1"
    local resolved

    resolved="$(readlink -f -- "$path" 2>/dev/null || true)"
    [[ -n "$resolved" && ( "$resolved" == "$DOTFILES_DIR" || "$resolved" == "$DOTFILES_DIR/"* ) ]]
}

backup_path() {
    local target="$1"
    local rel backup_target candidate counter

    if [[ ! -e "$target" && ! -L "$target" ]]; then
        return 0
    fi

    if [[ "$target" == "$HOME/"* ]]; then
        rel="${target#"$HOME"/}"
    else
        rel="${target#/}"
    fi

    backup_target="$BACKUP_ROOT/$rel"
    candidate="$backup_target"
    counter=1

    while [[ -e "$candidate" || -L "$candidate" ]]; do
        candidate="$backup_target.$counter"
        ((counter++))
    done

    mkdir -p -- "$(dirname -- "$candidate")"
    mv -- "$target" "$candidate"
    BACKED_UP_PATHS+=("$target -> $candidate")
}

print_backups() {
    if (( ${#BACKED_UP_PATHS[@]} == 0 )); then
        return 0
    fi

    warning "Moved conflicting paths to backup:"

    local moved
    for moved in "${BACKED_UP_PATHS[@]}"; do
        printf '  %s\n' "$moved"
    done
}
