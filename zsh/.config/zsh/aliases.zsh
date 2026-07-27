# Use enhanced interactive commands without changing POSIX command semantics.

if command -v eza >/dev/null 2>&1; then
  alias ls="eza"
  alias ll="eza -lah --group-directories-first"
  alias la="eza -a"
  alias tree="eza --tree"
fi

if command -v bat >/dev/null 2>&1; then
  alias batcat="bat"
fi

if command -v rg >/dev/null 2>&1; then
  alias rgrep="rg"
fi

if command -v nvim >/dev/null 2>&1; then
  alias vim="nvim"
  alias vi="nvim"
fi

alias c="clear"
