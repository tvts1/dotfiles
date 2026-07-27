# Interactive Zsh configuration.

ZSH_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

[[ -r "$ZSH_CONFIG_DIR/environment.zsh" ]] &&
  source "$ZSH_CONFIG_DIR/environment.zsh"

[[ -r "$ZSH_CONFIG_DIR/aliases.zsh" ]] &&
  source "$ZSH_CONFIG_DIR/aliases.zsh"

[[ -r "$ZSH_CONFIG_DIR/functions.zsh" ]] &&
  source "$ZSH_CONFIG_DIR/functions.zsh"

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt INTERACTIVE_COMMENTS

autoload -Uz compinit
ZSH_COMPDUMP="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
mkdir -p -- "${ZSH_COMPDUMP:h}"
if [[ -f "$ZSH_COMPDUMP" ]]; then
  compinit -C -d "$ZSH_COMPDUMP"
else
  compinit -d "$ZSH_COMPDUMP"
fi
unset ZSH_COMPDUMP

bindkey -e

[[ -r "$ZSH_CONFIG_DIR/integrations.zsh" ]] &&
  source "$ZSH_CONFIG_DIR/integrations.zsh"

# Keep plugins last: zsh-syntax-highlighting must be sourced after widgets and
# prompt integrations have been initialized.
[[ -r "$ZSH_CONFIG_DIR/plugins.zsh" ]] &&
  source "$ZSH_CONFIG_DIR/plugins.zsh"
