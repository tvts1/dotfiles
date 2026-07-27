# Login-shell environment. Interactive settings belong in .zshrc.
ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

[[ -r "$ZSH_CONFIG_DIR/environment.zsh" ]] &&
  source "$ZSH_CONFIG_DIR/environment.zsh"
