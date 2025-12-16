######################################################################
# Renderer control for all llm-based functions
######################################################################

# Options: glow | batcat | cat
# glow recommended, looks the best
# if piping into other stuff - use cat
export MANAI_RENDERER=glow


_llm_render() {
  case "$MANAI_RENDERER" in
    glow)
      if command -v glow >/dev/null 2>&1; then
        glow
      else
        cat
      fi
      ;;
    batcat)
      if command -v batcat >/dev/null 2>&1; then
        batcat --language markdown --paging=never
      else
        cat
      fi
      ;;
    cat|"")
      cat
      ;;
    *)
      cat
      ;;
  esac
}

######################################################################
# manai — explain man pages using llm
######################################################################

manai() {
  if [ -z "$1" ]; then
    echo "usage: manai <command> [question]" >&2
    return 2
  fi

  cmd="$1"
  shift

  if ! man -w "$cmd" >/dev/null 2>&1; then
    echo "manai: no man page found for '$cmd'" >&2
    return 1
  fi

  man "$cmd" | col -bx \
    | llm "${*:-Explain this command and show common usage.}" \
    | _llm_render
}

######################################################################
# why — explain errors
######################################################################

why() {
  llm "Explain what went wrong and how to fix it" < /dev/stdin \
    | _llm_render
}

######################################################################
# howto — intent → command
######################################################################

howto() {
  if [ $# -eq 0 ]; then
    echo "usage: howto <description>" >&2
    return 2
  fi

  llm "Show the correct command to: $*" \
    | _llm_render
}

######################################################################
# summarize — compress text
######################################################################

summarize() {
  llm "Summarize this concisely" < /dev/stdin \
    | _llm_render
}

######################################################################
# ask — general reasoning
######################################################################

ask() {
  if [ $# -eq 0 ] && [ -t 0 ]; then
    echo "usage: ask <question> [< stdin]" >&2
    return 2
  fi

  llm "$*" < /dev/stdin \
    | _llm_render
}

