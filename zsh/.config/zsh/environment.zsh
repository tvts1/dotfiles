# Shared environment for login and interactive shells.

if [[ -n "${DOTFILES_ZSH_ENV_LOADED:-}" ]]; then
  return 0
fi
typeset -g DOTFILES_ZSH_ENV_LOADED=1

_dotfiles_path_prepend() {
  [[ $# -eq 1 && -d "$1" ]] || return 0

  case ":$PATH:" in
    *":$1:"*) ;;
    *) export PATH="$1:$PATH" ;;
  esac
}

export TERMINAL="kitty"
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="firefox"

if command -v bat >/dev/null 2>&1; then
  export PAGER="bat"
elif command -v less >/dev/null 2>&1; then
  export PAGER="less"
fi

if command -v locale >/dev/null 2>&1 &&
  locale -a 2>/dev/null | grep -Eiq '^en_US\.(utf8|UTF-8)$'; then
  export LANG="en_US.UTF-8"
fi

_dotfiles_path_prepend "$HOME/.local/bin"

# Volta manages Node.js, npm, pnpm and globally installed Node tools.
export VOLTA_HOME="$HOME/.volta"
export VOLTA_FEATURE_PNPM=1
_dotfiles_path_prepend "$VOLTA_HOME/bin"

# SDKMAN manages Java, Maven and Gradle. Do not add candidates/current paths
# manually; sdkman-init.sh selects and maintains them.
export SDKMAN_DIR="$HOME/.sdkman"

if [[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" &&
  -z "${SDKMAN_CANDIDATES_DIR:-}" ]]; then
  source "$SDKMAN_DIR/bin/sdkman-init.sh"
fi

unfunction _dotfiles_path_prepend
