#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
VOLTA_HOME="${VOLTA_HOME:-$HOME/.volta}"
JAVA_VERSION="${JAVA_VERSION:-}"
MAVEN_VERSION="${MAVEN_VERSION:-}"
NODE_VERSION="${NODE_VERSION:-lts}"
CHECK_ONLY=0
DRY_RUN=0
SKIP_JAVA=0
SKIP_NODE=0
REQUIRED_PACKAGES=(
    curl
    git
    unzip
    zip
    tar
    gzip
    xz
    base-devel
)

usage() {
    cat <<'EOF'
Usage: install-dev-toolchain.sh [options]

Options:
  --check          Verify the toolchain without installing anything.
  --dry-run        Print actions without changing the system.
  --java VERSION   Install and set a specific SDKMAN Java version.
  --maven VERSION  Install and set a specific SDKMAN Maven version.
  --node VERSION   Install a specific Volta Node version. Default: lts.
  --skip-java      Skip SDKMAN, Java, javac, and Maven installation.
  --skip-node      Skip Volta, Node, npm, and pnpm installation.
  -h, --help       Show this help.

Environment variables JAVA_VERSION, MAVEN_VERSION, and NODE_VERSION are also
supported. Empty JAVA_VERSION or MAVEN_VERSION means SDKMAN's latest stable
default. NODE_VERSION=lts maps to `volta install node`, which installs LTS.
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
        --java)
            [[ $# -ge 2 ]] || { error "--java requires a version"; exit 2; }
            JAVA_VERSION="$2"
            shift
            ;;
        --maven)
            [[ $# -ge 2 ]] || { error "--maven requires a version"; exit 2; }
            MAVEN_VERSION="$2"
            shift
            ;;
        --node)
            [[ $# -ge 2 ]] || { error "--node requires a version"; exit 2; }
            NODE_VERSION="$2"
            shift
            ;;
        --skip-java)
            SKIP_JAVA=1
            ;;
        --skip-node)
            SKIP_NODE=1
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

if [[ $EUID -eq 0 ]]; then
    error "Do not run this script as root."
    exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
    error "This script supports Arch Linux only."
    exit 1
fi

run_cmd() {
    if ((DRY_RUN)); then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi

    "$@"
}

run_admin() {
    if ((DRY_RUN)); then
        printf '[dry-run]'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi

    sudo "$@"
}

prepend_path() {
    local dir="$1"

    case ":$PATH:" in
        *":$dir:"*) ;;
        *) export PATH="$dir:$PATH" ;;
    esac
}

download_installer() {
    local url="$1"
    local target="$2"

    run_cmd curl \
        --fail \
        --show-error \
        --location \
        --proto '=https' \
        --tlsv1.2 \
        --output "$target" \
        "$url"
}

install_base_dependencies() {
    local missing=() package

    for package in "${REQUIRED_PACKAGES[@]}"; do
        if ! pacman -Q "$package" >/dev/null 2>&1; then
            missing+=("$package")
        fi
    done

    if (( ${#missing[@]} == 0 )); then
        success "Development bootstrap dependencies are already installed"
        return 0
    fi

    log "Installing development bootstrap dependencies"
    run_admin pacman -Syu --needed --noconfirm "${missing[@]}"
}

load_sdkman() {
    export SDKMAN_DIR

    if [[ ! -f "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        return 1
    fi

    set +u
    source "$SDKMAN_DIR/bin/sdkman-init.sh"
    set -u
}

set_sdkman_config() {
    local key="$1"
    local value="$2"
    local config="$SDKMAN_DIR/etc/config"

    [[ -f "$config" ]] || return 0

    if grep -q "^$key=" "$config"; then
        sed -i "s|^$key=.*|$key=$value|" "$config"
    else
        printf '%s=%s\n' "$key" "$value" >> "$config"
    fi
}

install_sdkman() {
    local installer tmp_dir

    if [[ -f "$SDKMAN_DIR/bin/sdkman-init.sh" ]]; then
        success "SDKMAN is already installed"
        return 0
    fi

    log "Installing SDKMAN"
    tmp_dir="$(mktemp -d)"
    installer="$tmp_dir/sdkman-install.sh"
    trap 'rm -rf -- "$tmp_dir"' RETURN

    download_installer "https://get.sdkman.io?ci=true&rcupdate=false" "$installer"
    run_cmd bash "$installer"

    trap - RETURN
    rm -rf -- "$tmp_dir"
}

sdk_candidate_current_exists() {
    local candidate="$1"

    [[ -e "$SDKMAN_DIR/candidates/$candidate/current" ]]
}

sdk_candidate_version_exists() {
    local candidate="$1"
    local version="$2"

    [[ -d "$SDKMAN_DIR/candidates/$candidate/$version" ]]
}

install_sdk_candidate() {
    local candidate="$1"
    local executable="$2"
    local version="$3"

    if [[ -n "$version" ]]; then
        if sdk_candidate_version_exists "$candidate" "$version"; then
            success "SDKMAN $candidate $version is already installed"
        else
            log "Installing SDKMAN $candidate $version"
            run_cmd sdk install "$candidate" "$version"
        fi

        run_cmd sdk default "$candidate" "$version"
        return 0
    fi

    if sdk_candidate_current_exists "$candidate" && command_exists "$executable"; then
        success "SDKMAN $candidate is already configured"
        return 0
    fi

    log "Installing SDKMAN $candidate latest stable default"
    run_cmd sdk install "$candidate"
}

install_java_stack() {
    install_sdkman

    if ((DRY_RUN)); then
        export SDKMAN_DIR
        if [[ -n "$JAVA_VERSION" ]]; then
            run_cmd sdk install java "$JAVA_VERSION"
            run_cmd sdk default java "$JAVA_VERSION"
        else
            run_cmd sdk install java
        fi

        if [[ -n "$MAVEN_VERSION" ]]; then
            run_cmd sdk install maven "$MAVEN_VERSION"
            run_cmd sdk default maven "$MAVEN_VERSION"
        else
            run_cmd sdk install maven
        fi

        return 0
    fi

    load_sdkman || {
        error "SDKMAN was not installed correctly"
        return 1
    }

    set_sdkman_config sdkman_auto_answer true
    set_sdkman_config sdkman_colour_enable false

    install_sdk_candidate java java "$JAVA_VERSION"
    install_sdk_candidate maven mvn "$MAVEN_VERSION"
}

install_volta() {
    local installer tmp_dir

    export VOLTA_HOME
    prepend_path "$VOLTA_HOME/bin"

    if [[ -x "$VOLTA_HOME/bin/volta" ]]; then
        success "Volta is already installed"
        return 0
    fi

    log "Installing Volta"
    tmp_dir="$(mktemp -d)"
    installer="$tmp_dir/volta-install.sh"
    trap 'rm -rf -- "$tmp_dir"' RETURN

    download_installer "https://get.volta.sh" "$installer"
    run_cmd bash "$installer" --skip-setup

    trap - RETURN
    rm -rf -- "$tmp_dir"
    prepend_path "$VOLTA_HOME/bin"
}

volta_node_spec() {
    case "$NODE_VERSION" in
        "" | lts | LTS)
            printf '%s\n' node
            ;;
        *)
            printf 'node@%s\n' "$NODE_VERSION"
            ;;
    esac
}

install_node_stack() {
    local node_spec

    export VOLTA_HOME
    export VOLTA_FEATURE_PNPM=1

    install_volta
    prepend_path "$VOLTA_HOME/bin"

    node_spec="$(volta_node_spec)"

    log "Installing Node with Volta: $node_spec"
    run_cmd volta install "$node_spec"

    log "Installing pnpm with Volta native pnpm support"
    run_cmd volta install pnpm
}

check_command() {
    local command_name="$1"

    if command_exists "$command_name"; then
        success "Found $command_name"
        return 0
    fi

    error "Missing command: $command_name"
    return 1
}

print_version() {
    local label="$1"
    shift

    printf '\n%s\n' "$label"
    "$@"
}

check_toolchain() {
    local failed=0

    export VOLTA_HOME
    export VOLTA_FEATURE_PNPM=1
    prepend_path "$VOLTA_HOME/bin"

    if ((SKIP_JAVA == 0)); then
        load_sdkman || {
            error "SDKMAN is not installed at $SDKMAN_DIR"
            failed=1
        }

        check_command sdk || failed=1
        check_command java || failed=1
        check_command javac || failed=1
        check_command mvn || failed=1
    fi

    if ((SKIP_NODE == 0)); then
        check_command volta || failed=1
        check_command node || failed=1
        check_command npm || failed=1
        check_command pnpm || failed=1
    fi

    return "$failed"
}

print_versions() {
    export VOLTA_HOME
    export VOLTA_FEATURE_PNPM=1
    prepend_path "$VOLTA_HOME/bin"

    if ((SKIP_JAVA == 0)); then
        load_sdkman || true
        print_version "java --version" java --version
        print_version "javac --version" javac --version
        print_version "mvn --version" mvn --version
    fi

    if ((SKIP_NODE == 0)); then
        print_version "volta --version" volta --version
        print_version "node --version" node --version
        print_version "npm --version" npm --version
        print_version "pnpm --version" pnpm --version
    fi
}

if ((CHECK_ONLY)); then
    log "Checking development toolchain"
    check_toolchain
    print_versions
    success "Development toolchain check finished"
    exit 0
fi

install_base_dependencies

if ((SKIP_JAVA == 0)); then
    install_java_stack
fi

if ((SKIP_NODE == 0)); then
    install_node_stack
fi

if ((DRY_RUN)); then
    success "Development toolchain dry run finished"
    exit 0
fi

check_toolchain
print_versions

success "Development toolchain installation finished"
