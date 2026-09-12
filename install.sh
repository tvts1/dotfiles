#!/usr/bin/env bash
set -Eeuo pipefail
trap 'printf "Erro na linha %s. Revise a operação antes de repetir.\n" "$LINENO" >&2' ERR

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DRY_RUN=0 WITH_DEV_TOOLS=0 CONFIGURE_SYSTEM=0
ASDF_VERSION=0.20.0
# SHA-256 publicado na API oficial da release (asset digest), Linux x86_64.
ASDF_SHA256=9c25e1af7cc4c9d59ff3736eba14fd000480c32929258f80d8c5a8b290ebee14
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
ASDF_BIN=""
TEMP=""
trap 'if [[ -n "$TEMP" ]]; then rm -rf -- "$TEMP"; fi' EXIT

die() { printf 'Erro: %s\n' "$*" >&2; exit 1; }
run() {
    printf '+'; printf ' %q' "$@"; printf '\n'
    if ((!DRY_RUN)); then "$@"; fi
}
usage() {
    cat <<'HELP'
Uso: ./install.sh [--with-dev-tools] [--configure-system] [--dry-run]
  Padrão              Atualização completa Arch, dependências, asdf e Stow home.
  --with-dev-tools    Instala as versões exatas de home/.tool-versions.
  --configure-system Configura greetd e habilita serviços para o próximo boot.
  --dry-run          Somente leitura; não baixa, instala, escreve ou chama sudo.
  -h, --help         Mostra esta ajuda.
Conflitos abortam. Migração e rollback estão no README. Não execute como root.
HELP
}
for arg in "$@"; do
    case "$arg" in
        --with-dev-tools) WITH_DEV_TOOLS=1 ;;
        --configure-system) CONFIGURE_SYSTEM=1 ;;
        --dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) die "Opção desconhecida: $arg" ;;
    esac
done
[[ $EUID -ne 0 ]] || die 'Execute como usuário normal.'
[[ -f /etc/arch-release ]] || die 'Este instalador requer Arch Linux.'
[[ $(uname -m) == x86_64 ]] || die 'Release e pacotes verificados apenas para Arch x86_64.'
[[ "$HOME" == /* && -d "$HOME" && "$ASDF_DATA_DIR" == /* ]] || die 'HOME e ASDF_DATA_DIR devem ser caminhos absolutos.'
[[ ${XDG_CONFIG_HOME:-$HOME/.config} == "$HOME/.config" ]] || die 'O pacote home usa ~/.config; XDG_CONFIG_HOME personalizado requer adaptar os destinos primeiro.'

# Não atravessar diretórios vinculados: nem Stow nem arquivos gerados podem
# escrever por um ancestral que aponta para outra árvore.
check_parents() {
    local parent
    parent="$(dirname -- "$1")"
    while [[ "$parent" != / ]]; do
        [[ ! -L "$parent" ]] || die "Diretório ancestral é symlink: $parent. Revise manualmente."
        [[ ! -e "$parent" || -d "$parent" ]] || die "Ancestral não é diretório: $parent"
        parent="$(dirname -- "$parent")"
    done
}
check_home() {
    local source target rel
    while IFS= read -r -d '' source; do
        rel="${source#"$ROOT/home/"}"; target="$HOME/$rel"
        check_parents "$target"
        if [[ -L "$target" ]]; then
            [[ $(readlink -m -- "$target") == "$source" ]] || die "Link antigo/conflitante: $target -> $(readlink -- "$target"). Use a migração do README."
        elif [[ -e "$target" ]]; then
            die "Arquivo real conflitante: $target. Faça backup pontual e libere o destino."
        fi
    done < <(find "$ROOT/home" -type f -print0)
    if command -v stow >/dev/null; then
        stow --simulate --verbose --no-folding --dir="$ROOT" --target="$HOME" home || die 'Conflitos do Stow; nada foi aplicado.'
    else
        printf 'Stow ausente: verificação de caminhos feita; simulação GNU será obrigatória após instalar dependências.\n'
    fi
}

# Reutilização exige versão conhecida; nunca substituir executável existente.
check_asdf() {
    local candidate version owner
    check_parents "$HOME/.local/bin/asdf"
    candidate="$(type -P asdf || :)"
    if [[ -e "$HOME/.local/bin/asdf" || -L "$HOME/.local/bin/asdf" ]]; then
        candidate="$HOME/.local/bin/asdf"
    fi
    if [[ -n "$candidate" ]]; then
        [[ -x "$candidate" && -f "$candidate" ]] || die "asdf não executável: $candidate"
        ASDF_BIN="$(readlink -f -- "$candidate")"
        version="$("$ASDF_BIN" version)" || die 'Não foi possível identificar a versão do asdf.'
        if owner="$(pacman -Qo "$ASDF_BIN" 2>/dev/null)"; then
            printf 'asdf administrado pelo sistema: %s\n' "$owner"
        else
            printf 'asdf fora do pacman: %s\n' "$ASDF_BIN"
        fi
        printf 'Versão existente: %s\n' "$version"
        [[ "$version" == "v$ASDF_VERSION" || "$version" == "v$ASDF_VERSION "* ]] || die "Esperado asdf $ASDF_VERSION. Migre a instalação existente manualmente; nenhum binário será sobrescrito."
    else
        ASDF_BIN="$HOME/.local/bin/asdf"
    fi
}

declare -A PLUGIN_URL=(
    [java]=https://github.com/halcyon/asdf-java.git
    [maven]=https://github.com/halcyon/asdf-maven.git
    [nodejs]=https://github.com/asdf-vm/asdf-nodejs.git
    [pnpm]=https://github.com/jonathanmorley/asdf-pnpm.git
)
declare -A PLUGIN_REF=(
    [java]=f8551422c07b0132dc74278672587b08e0aa61ef
    [maven]=674e23a8e239147ccf835252a41459c72f497c94
    [nodejs]=779c8dc84b3bdab38c2c80622d315c2c3267f74b
    [pnpm]=c99c5df3b9029a6e009368107b2bc2b2dfadbbfc
)
declare -A VERSION
while read -r tool version extra; do
    [[ -n "$tool" && "$tool" != \#* ]] || continue
    [[ -v PLUGIN_URL[$tool] && -n "$version" && -z "$extra" ]] || die 'Linha inválida em home/.tool-versions.'
    [[ ! -v VERSION[$tool] ]] || die "Ferramenta duplicada: $tool"
    VERSION[$tool]="$version"
done < "$ROOT/home/.tool-versions"
for tool in java maven nodejs pnpm; do
    [[ -v VERSION[$tool] ]] || die "Versão ausente: $tool"
done

canonical_plugin_origin() {
    local origin="${1%/}"
    origin="${origin%.git}"
    case "$origin" in
        git@github.com:*) origin="https://github.com/${origin#git@github.com:}" ;;
        ssh://git@github.com/*) origin="https://github.com/${origin#ssh://git@github.com/}" ;;
    esac
    printf '%s\n' "$origin"
}

check_plugins() {
    local tool directory origin revision
    for tool in java maven nodejs pnpm; do
        directory="$ASDF_DATA_DIR/plugins/$tool"
        check_parents "$directory/placeholder"
        if [[ -e "$directory" || -L "$directory" ]]; then
            [[ -d "$directory" ]] || die "Caminho do plugin não é diretório: $directory"
            [[ $(git -C "$directory" rev-parse --is-inside-work-tree 2>/dev/null) == true ]] ||
                die "Plugin não é um repositório Git válido: $directory"
            origin="$(git -C "$directory" remote get-url origin)" || die "Plugin sem origem: $directory"
            [[ $(canonical_plugin_origin "$origin") == "$(canonical_plugin_origin "${PLUGIN_URL[$tool]}")" ]] ||
                die "Origem incompatível para $tool: $origin (esperada: ${PLUGIN_URL[$tool]})"
            [[ -z $(git -C "$directory" status --porcelain) ]] || die "Plugin com mudanças locais: $directory"
            revision="$(git -C "$directory" rev-parse HEAD)"
            printf 'Reutilizando plugin %s em %s (%s)\n' "$tool" "$revision" "$origin"
        else
            printf 'Plugin %s ausente; será adicionado de %s na revisão %s.\n' \
                "$tool" "${PLUGIN_URL[$tool]}" "${PLUGIN_REF[$tool]}"
        fi
    done
}

prepare_asdf() {
    local asset="asdf-v$ASDF_VERSION-linux-amd64.tar.gz" completion="$HOME/.config/fish/completions/asdf.fish"
    if [[ ! -x "$ASDF_BIN" ]]; then
        if ((DRY_RUN)); then
            printf 'Baixaria https://github.com/asdf-vm/asdf/releases/download/v%s/%s\nVerificaria SHA-256 %s antes de instalar em %s\n' "$ASDF_VERSION" "$asset" "$ASDF_SHA256" "$ASDF_BIN"
        else
            curl --fail --location --show-error --proto '=https' --tlsv1.2 \
                "https://github.com/asdf-vm/asdf/releases/download/v$ASDF_VERSION/$asset" -o "$TEMP/$asset"
            printf '%s  %s\n' "$ASDF_SHA256" "$TEMP/$asset" | sha256sum --check --strict
            tar -xzf "$TEMP/$asset" -C "$TEMP" asdf
            [[ $("$TEMP/asdf" version) == "v$ASDF_VERSION"* ]] || die 'Versão inesperada no download.'
            mkdir -p -- "$HOME/.local/bin"
            [[ ! -e "$ASDF_BIN" && ! -L "$ASDF_BIN" ]] || die "Destino apareceu durante a instalação: $ASDF_BIN"
            install -m 0755 -- "$TEMP/asdf" "$ASDF_BIN"
        fi
    fi
    if ((DRY_RUN)); then
        printf 'Geraria uma vez: asdf completion fish → %s (recusa conteúdo conflitante).\n' "$completion"
    else
        "$ASDF_BIN" completion fish > "$TEMP/asdf.fish"
        if [[ -e "$completion" ]]; then
            cmp -s "$TEMP/asdf.fish" "$completion" || die "Completion conflitante: $completion. Preserve-a antes de repetir."
        else
            mkdir -p -- "$(dirname -- "$completion")"
            install -m 0644 -- "$TEMP/asdf.fish" "$completion"
        fi
    fi
}

install_toolchain() {
    local tool directory revision
    # Evita seleção herdada do projeto de onde o instalador foi chamado.
    export ASDF_NODEJS_VERSION="${VERSION[nodejs]}" ASDF_JAVA_VERSION="${VERSION[java]}"
    export PATH="$ASDF_DATA_DIR/shims:$(dirname -- "$ASDF_BIN"):$PATH"
    for tool in java maven nodejs pnpm; do
        directory="$ASDF_DATA_DIR/plugins/$tool"
        if [[ ! -d "$directory" ]]; then
            run "$ASDF_BIN" plugin add "$tool" "${PLUGIN_URL[$tool]}"
            run "$ASDF_BIN" plugin update "$tool" "${PLUGIN_REF[$tool]}"
            if ((!DRY_RUN)); then
                revision="$(git -C "$directory" rev-parse HEAD)"
                [[ "$revision" == "${PLUGIN_REF[$tool]}" ]] ||
                    die "Plugin $tool ficou em $revision; esperada ${PLUGIN_REF[$tool]}."
            fi
        fi
        if ((!DRY_RUN)) && "$ASDF_BIN" where "$tool" "${VERSION[$tool]}" >/dev/null 2>&1; then
            printf 'Já instalado: %s %s\n' "$tool" "${VERSION[$tool]}"
        else
            run "$ASDF_BIN" install "$tool" "${VERSION[$tool]}"
        fi
        run "$ASDF_BIN" reshim "$tool" "${VERSION[$tool]}"
    done
}

check_system() {
    local unit display
    for unit in gdm.service sddm.service lightdm.service ly.service lxdm.service; do
        if systemctl is-enabled --quiet "$unit" 2>/dev/null || systemctl is-active --quiet "$unit" 2>/dev/null; then
            die "Display manager concorrente: $unit. Revise e desabilite manualmente antes de configurar greetd."
        fi
    done
    if [[ -L /etc/systemd/system/display-manager.service ]]; then
        display="$(readlink -f /etc/systemd/system/display-manager.service)"
        [[ ${display##*/} == greetd.service ]] || die "Display manager concorrente: $display"
    fi
    [[ ! -L /etc/greetd && ! -L /etc/greetd/config.toml ]] || die 'Configuração greetd é symlink; revise manualmente.'
    if [[ -e /etc/greetd/config.toml ]] && ! cmp -s "$ROOT/system/greetd/config.toml" /etc/greetd/config.toml; then
        printf 'Configuração greetd existente difere do template:\n'
        diff -u /etc/greetd/config.toml "$ROOT/system/greetd/config.toml" || [[ $? == 1 ]]
        if ((!DRY_RUN)); then
            [[ -t 0 ]] || die 'Substituição do greetd exige confirmação em terminal, após revisar o diff.'
            read -r -p 'Criar backup datado e substituir greetd? [s/N] ' answer
            [[ "$answer" == s ]] || die 'greetd preservado.'
        else
            printf 'Exigiria confirmação em terminal e backup datado antes da substituição.\n'
        fi
    fi
}
configure_system() {
    local executable unit backup
    for executable in /usr/bin/greetd /usr/bin/tuigreet /usr/bin/niri-session /usr/bin/niri /usr/bin/noctalia /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1; do
        if ((!DRY_RUN)); then [[ -x "$executable" ]] || die "Executável ausente: $executable"; fi
    done
    if ((!DRY_RUN)); then
        getent passwd greeter >/dev/null || die 'Conta greeter ausente.'
        getent group greeter >/dev/null || die 'Grupo greeter ausente.'
        /usr/bin/noctalia --version | grep -q 'v5\.' || die 'Esta configuração requer Noctalia v5.'
        local help option
        help="$(/usr/bin/tuigreet --help)"
        for option in --time --remember --remember-session --user-menu --cmd; do
            grep -Fq -- "$option" <<< "$help" || die "tuigreet não suporta $option"
        done
    fi
    if ! cmp -s "$ROOT/system/greetd/config.toml" /etc/greetd/config.toml; then
        if [[ -e /etc/greetd/config.toml ]]; then
            backup="/etc/greetd/config.toml.backup-$(date +%Y%m%d-%H%M%S)-$$"
            run sudo cp -a -- /etc/greetd/config.toml "$backup"
        fi
        run sudo install -D -m 0644 -- "$ROOT/system/greetd/config.toml" /etc/greetd/config.toml
    fi
    run sudo install -d -o greeter -g greeter -m 0755 /var/cache/tuigreet
    for unit in NetworkManager.service bluetooth.service docker.service fstrim.timer greetd.service; do
        if ((DRY_RUN)); then
            printf 'Habilitaria %s para o próximo boot, se a unidade existir e não estiver habilitada.\n' "$unit"
        elif [[ $(systemctl show "$unit" -p LoadState --value) == not-found ]]; then
            die "Unidade ausente: $unit"
        elif ! systemctl is-enabled --quiet "$unit"; then
            run sudo systemctl enable "$unit"
        fi
    done
}

# Pré-validar também os destinos de arquivos gerados antes do pacman.
for directory in "$HOME/Pictures/Screenshots" "$HOME/Pictures/Wallpapers" "$HOME/.local/share/kitty/sessions"; do
    check_parents "$directory/placeholder"
done
check_home
check_asdf
check_parents "$HOME/.config/fish/completions/asdf.fish"
[[ ! -L "$HOME/.config/fish/completions/asdf.fish" ]] || die 'Completion asdf é symlink; revise antes de gerar.'
if ((WITH_DEV_TOOLS)); then check_plugins; fi
if ((CONFIGURE_SYSTEM)); then check_system; fi

mapfile -t packages < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$ROOT/packages.txt")
printf 'Atualização COMPLETA do Arch e instalação das dependências (confirmação do pacman):\n'
run sudo pacman -Syu --needed "${packages[@]}"
if ((!DRY_RUN)); then
    TEMP="$(mktemp -d)"
    # Repetir após pacman: pode ter havido alterações externas durante a espera.
    check_home
    noctalia --version | grep -q 'v5\.' || die 'Requer Noctalia v5; revise a geração antes de aplicar.'
    niri validate -c "$ROOT/home/.config/niri/config.kdl"
    noctalia config validate "$ROOT/home/.config/noctalia/config.toml"
fi
prepare_asdf
if ((WITH_DEV_TOOLS)); then install_toolchain; fi
# A simulação acima é obrigatória antes desta aplicação, sem --adopt.
run stow --no-folding --dir="$ROOT" --target="$HOME" home
for directory in "$HOME/Pictures/Screenshots" "$HOME/Pictures/Wallpapers" "$HOME/.local/share/kitty/sessions"; do
    check_parents "$directory/placeholder"
    run mkdir -p -- "$directory"
done
run xdg-user-dirs-update
if ((CONFIGURE_SYSTEM)); then configure_system; fi
printf 'Concluído%s. Valide Fish/asdf antes do chsh e mantenha o Zsh de recuperação.\n' "$([[ $DRY_RUN == 1 ]] && printf ' (simulação)' || :)"
