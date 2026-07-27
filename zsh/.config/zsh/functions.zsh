# Extract common archive formats into the current directory.
extract() {
  if (( $# != 1 )); then
    print -u2 "Usage: extract <archive>"
    return 2
  fi

  local archive="$1"
  local extractor
  local -a extract_command

  if [[ ! -e "$archive" ]]; then
    print -u2 "extract: file not found: $archive"
    return 1
  fi

  if [[ ! -f "$archive" ]]; then
    print -u2 "extract: not a regular file: $archive"
    return 1
  fi

  case "${archive:l}" in
    *.tar.bz2|*.tbz2) extractor=tar; extract_command=(tar -xjf "$archive") ;;
    *.tar.gz|*.tgz)   extractor=tar; extract_command=(tar -xzf "$archive") ;;
    *.bz2)            extractor=bunzip2; extract_command=(bunzip2 "$archive") ;;
    *.rar)            extractor=unrar; extract_command=(unrar x "$archive") ;;
    *.gz)             extractor=gunzip; extract_command=(gunzip "$archive") ;;
    *.tar)            extractor=tar; extract_command=(tar -xf "$archive") ;;
    *.zip)            extractor=unzip; extract_command=(unzip "$archive") ;;
    *.7z)             extractor=7z; extract_command=(7z x "$archive") ;;
    *)
      print -u2 "extract: unsupported archive: $archive"
      return 1
      ;;
  esac

  if ! command -v "$extractor" >/dev/null 2>&1; then
    print -u2 "extract: required command not found: $extractor"
    return 127
  fi

  command "${extract_command[@]}"
}
