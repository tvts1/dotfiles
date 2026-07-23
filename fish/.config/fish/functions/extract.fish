function extract
    if test (count $argv) -ne 1
        echo "Usage: extract <archive>" >&2
        return 2
    end

    set -l archive $argv[1]

    if not test -e "$archive"
        echo "extract: file not found: $archive" >&2
        return 1
    end

    if not test -f "$archive"
        echo "extract: not a regular file: $archive" >&2
        return 1
    end

    switch (string lower -- "$archive")
        case "*.tar.bz2" "*.tbz2"
            type -q tar; or begin
                echo "extract: tar is required for $archive" >&2
                return 127
            end
            tar xjf "$archive"

        case "*.tar.gz" "*.tgz"
            type -q tar; or begin
                echo "extract: tar is required for $archive" >&2
                return 127
            end
            tar xzf "$archive"

        case "*.bz2"
            type -q bunzip2; or begin
                echo "extract: bunzip2 is required for $archive" >&2
                return 127
            end
            bunzip2 "$archive"

        case "*.rar"
            type -q unrar; or begin
                echo "extract: unrar is required for $archive" >&2
                return 127
            end
            unrar x "$archive"

        case "*.gz"
            type -q gunzip; or begin
                echo "extract: gunzip is required for $archive" >&2
                return 127
            end
            gunzip "$archive"

        case "*.tar"
            type -q tar; or begin
                echo "extract: tar is required for $archive" >&2
                return 127
            end
            tar xf "$archive"

        case "*.zip"
            type -q unzip; or begin
                echo "extract: unzip is required for $archive" >&2
                return 127
            end
            unzip "$archive"

        case "*.7z"
            type -q 7z; or begin
                echo "extract: 7z is required for $archive" >&2
                return 127
            end
            7z x "$archive"

        case "*"
            echo "extract: unsupported archive: $archive" >&2
            return 1
    end
end
