#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

CHECK_ONLY=0
DRY_RUN=0
REQUIRED_PROVIDERS=(
    desktopapplications
    providerlist
    runner
)

usage() {
    cat <<'EOF'
Usage: configure-elephant.sh [--check] [--dry-run]

Configures Elephant as the single backend startup mechanism for Walker.
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

run_cmd() {
    if ((DRY_RUN)); then
        printf '[dry-run] %q' "$1"
        shift
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi

    "$@"
}

provider_package() {
    case "$1" in
        desktopapplications) printf '%s\n' elephant-desktopapplications ;;
        providerlist) printf '%s\n' elephant-providerlist ;;
        runner) printf '%s\n' elephant-runner ;;
        *) printf 'elephant-%s\n' "$1" ;;
    esac
}

list_providers() {
    elephant listproviders
}

require_commands() {
    local missing=0

    for command_name in walker elephant systemctl; do
        if command_exists "$command_name"; then
            success "Found $command_name"
        else
            error "Missing command: $command_name"
            missing=1
        fi
    done

    return "$missing"
}

require_providers() {
    local providers provider missing=0 package

    providers="$(list_providers 2>/dev/null || true)"
    if [[ -z "$providers" ]]; then
        error "Could not list Elephant providers with: elephant listproviders"
        return 1
    fi

    for provider in "${REQUIRED_PROVIDERS[@]}"; do
        if grep -Fxq -- "$provider" <<< "$providers"; then
            success "Elephant provider is installed: $provider"
        else
            package="$(provider_package "$provider")"
            error "Missing Elephant provider: $provider (install AUR package: $package)"
            missing=1
        fi
    done

    return "$missing"
}

show_service_status() {
    if ! systemctl --user status elephant.service --no-pager; then
        warning "Elephant user service is not running or the user systemd bus is unavailable"
        return 1
    fi
}

enable_elephant_service() {
    local service_file="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/elephant.service"

    log "Enabling Elephant user service"

    run_cmd elephant service enable

    if ((DRY_RUN)); then
        run_cmd systemctl --user enable --now elephant.service
        return 0
    fi

    if [[ ! -f "$service_file" ]]; then
        error "Elephant did not create the expected user service: $service_file"
        return 1
    fi

    systemctl --user daemon-reload
    systemctl --user enable --now elephant.service

    success "Elephant user service enabled"
}

log "Checking Walker and Elephant"
require_commands
require_providers

if ((CHECK_ONLY)); then
    show_service_status
    success "Elephant check finished"
    exit 0
fi

enable_elephant_service

if ((DRY_RUN)); then
    success "Elephant dry run finished"
    exit 0
fi

show_service_status

success "Elephant configuration finished"
