#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"

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
