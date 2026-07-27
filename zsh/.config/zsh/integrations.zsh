if command -v fzf >/dev/null 2>&1; then
  # Arch packages these files under /usr/share/fzf. Alternate layouts are
  # checked so the module stays harmless outside that exact package version.
  for fzf_completion in \
    /usr/share/fzf/completion.zsh \
    /usr/share/fzf/shell/completion.zsh; do
    if [[ -r "$fzf_completion" ]]; then
      source "$fzf_completion"
      break
    fi
  done
  unset fzf_completion

  for fzf_key_bindings in \
    /usr/share/fzf/key-bindings.zsh \
    /usr/share/fzf/shell/key-bindings.zsh \
    "$HOME/.fzf.zsh"; do
    if [[ -r "$fzf_key_bindings" ]]; then
      source "$fzf_key_bindings"
      break
    fi
  done
  unset fzf_key_bindings
fi

command -v zoxide >/dev/null 2>&1 &&
  eval "$(zoxide init zsh)"

command -v starship >/dev/null 2>&1 &&
  eval "$(starship init zsh)"
