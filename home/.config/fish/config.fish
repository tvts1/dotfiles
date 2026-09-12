# Ambiente comum ao terminal, login e ações gráficas (fish -c).
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx TERMINAL kitty
set -gx BROWSER firefox
if not set -q ASDF_DATA_DIR; or test -z "$ASDF_DATA_DIR"
    set -gx ASDF_DATA_DIR "$HOME/.asdf"
end

# Prioridade determinística, inclusive antes da criação dos shims.
# Instalações antigas ficam no disco, mas não participam deste PATH.
set -l clean_path
for entry in $PATH
    if string match -q "$HOME/.sdkman/*" -- "$entry"; or string match -q "$HOME/.volta/*" -- "$entry"
        continue
    end
    if set -q SDKMAN_DIR; and string match -q "$SDKMAN_DIR/*" -- "$entry"
        continue
    end
    if set -q VOLTA_HOME; and string match -q "$VOLTA_HOME/*" -- "$entry"
        continue
    end
    if not contains -- "$entry" "$ASDF_DATA_DIR/shims" "$HOME/.local/bin" $clean_path
        set -a clean_path "$entry"
    end
end
set -gx PATH "$ASDF_DATA_DIR/shims" "$HOME/.local/bin" $clean_path

# O hook oficial atualiza JAVA_HOME no prompt. Também resolvemos no startup
# e ao mudar de diretório, para fish -c, wrappers Maven e ações do Thunar.
function dotfiles_java_home --on-variable PWD
    set -gx JAVA_HOME
    set -gx JDK_HOME
    if command -q asdf
        set -l java_home (command asdf where java 2>/dev/null)
        if test -n "$java_home"; and test -x "$java_home/bin/java"
            set -gx JAVA_HOME "$java_home"
            set -gx JDK_HOME "$java_home"
        end
    end
end
dotfiles_java_home

if status is-interactive
    if command -q bat
        set -gx PAGER bat
        alias batcat bat
    else if command -q less
        set -gx PAGER less
    end
    if command -q locale; and locale -a | string match -riq '^en_US\.(utf8|UTF-8)$'
        set -gx LANG en_US.UTF-8
    end
    if command -q eza
        alias ls eza
        alias ll 'eza -lah --group-directories-first'
        alias la 'eza -a'
        alias tree 'eza --tree'
    end
    command -q rg; and alias rgrep rg
    if command -q nvim
        alias vim nvim
        alias vi nvim
    end
    alias c clear
    fish_default_key_bindings

    function extract --argument-names archive
        if test (count $argv) -ne 1; or not test -f "$archive"
            printf 'Uso: extract <arquivo existente>\n' >&2
            return 2
        end
        # Caminho absoluto impede nomes iniciados por hífen de virarem opções.
        set archive (path resolve -- "$archive")
        switch (string lower -- "$archive")
            case '*.tar.bz2' '*.tbz2'
                command tar -xjf "$archive"
            case '*.tar.gz' '*.tgz'
                command tar -xzf "$archive"
            case '*.bz2'
                command bunzip2 "$archive"
            case '*.rar'
                command unrar x "$archive"
            case '*.gz'
                command gunzip "$archive"
            case '*.tar'
                command tar -xf "$archive"
            case '*.zip'
                command unzip "$archive"
            case '*.7z'
                command 7z x "$archive"
            case '*'
                printf 'Formato não suportado: %s\n' "$archive" >&2
                return 1
        end
    end

    if test -n "$JAVA_HOME"; and test -r "$ASDF_DATA_DIR/plugins/java/set-java-home.fish"
        source "$ASDF_DATA_DIR/plugins/java/set-java-home.fish"
    end
    command -q fzf; and fzf --fish | source
    command -q zoxide; and zoxide init fish | source
    command -q starship; and starship init fish | source
end
