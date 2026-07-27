#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

CHECK_ONLY=0
DRY_RUN=0

usage() {
    cat <<'EOF'
Usage: configure-default-shell.sh [--check | --dry-run]

Sets Zsh as the current user's login shell.

Options:
  --check    Verify the configured login shell without changing it.
  --dry-run  Validate the change and print what would be done.
  -h, --help Show this help.
EOF
}

while (($#)); do
    case "$1" in
        --check)
            CHECK_ONLY=1
            ;;
        --dry-run)
            DRY_RUN=1
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

if ((CHECK_ONLY && DRY_RUN)); then
    error "--check and --dry-run cannot be used together."
    exit 2
fi

if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root."
    exit 1
fi

for command_name in awk chsh getent id readlink zsh; do
    if ! command_exists "$command_name"; then
        error "Required command not found: $command_name"
        exit 1
    fi
done

account_shell() {
    local passwd_entry

    passwd_entry="$(getent passwd "$1" 2>/dev/null || true)"
    [[ -n "$passwd_entry" ]] || return 1
    awk -F: 'NR == 1 { print $7 }' <<< "$passwd_entry"
}

account_name="$(id -un)"
zsh_binary="$(readlink -f -- "$(command -v zsh)")"
zsh_shell=""

while IFS= read -r registered_shell; do
    case "$registered_shell" in
        "" | \#*) continue ;;
    esac

    if [[ -x "$registered_shell" &&
        "$(readlink -f -- "$registered_shell")" == "$zsh_binary" ]]; then
        zsh_shell="$registered_shell"
        break
    fi
done < /etc/shells

if [[ -z "$zsh_shell" ]]; then
    error "Zsh is not registered as a valid login shell in /etc/shells."
    exit 1
fi

if ! current_shell="$(account_shell "$account_name")" || [[ -z "$current_shell" ]]; then
    error "Could not determine the login shell for $account_name."
    exit 1
fi

if [[ "$(readlink -f -- "$current_shell")" == "$zsh_binary" ]]; then
    success "Zsh is already the default shell for $account_name"
    exit 0
fi

if ((CHECK_ONLY)); then
    error "Default shell for $account_name is $current_shell, expected $zsh_shell."
    exit 1
fi

if ((DRY_RUN)); then
    log "Would set the default shell for $account_name to $zsh_shell"
    exit 0
fi

log "Setting Zsh as the default shell for $account_name"
chsh -s "$zsh_shell" "$account_name"

if ! configured_shell="$(account_shell "$account_name")" ||
    [[ "$(readlink -f -- "$configured_shell")" != "$zsh_binary" ]]; then
    error "The login shell change could not be confirmed for $account_name."
    exit 1
fi

success "Zsh is now the default shell; start a new login session to use it"
