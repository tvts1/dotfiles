# Resolve packaged plugins from their verified Arch locations first. The
# pacman fallback keeps this portable if a future package changes its layout.
zsh_plugin_from_package() {
  local package="$1"
  local expected_name="$2"
  shift 2

  local plugin_file package_name candidate

  for candidate in "$@"; do
    if [[ -r "$candidate" ]]; then
      source "$candidate"
      return 0
    fi
  done

  command -v pacman >/dev/null 2>&1 || return 0
  pacman -Q "$package" >/dev/null 2>&1 || return 0

  while read -r package_name candidate; do
    if [[ "${candidate:t}" == "$expected_name" && -r "$candidate" ]]; then
      plugin_file="$candidate"
      break
    fi
  done < <(pacman -Ql "$package" 2>/dev/null)

  [[ -n "$plugin_file" ]] && source "$plugin_file"
}

zsh_plugin_from_package \
  zsh-autosuggestions \
  zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# This must remain the final plugin loaded.
zsh_plugin_from_package \
  zsh-syntax-highlighting \
  zsh-syntax-highlighting.zsh \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

unfunction zsh_plugin_from_package
