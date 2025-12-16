######################################################################
# `manai` - pipes manpage into llm to get summaries or ask questions
######################################################################

export MANAI_RENDERER=glow
#export MANAI_RENDERER=batcat

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

  case "$MANAI_RENDERER" in
    glow)
      if command -v glow >/dev/null 2>&1; then
        renderer=(glow)
      else
        renderer=(cat)
      fi
      ;;
    batcat)
      if command -v batcat >/dev/null 2>&1; then
        renderer=(batcat --language markdown --paging=never)
      else
        renderer=(cat)
      fi
      ;;
    *)
      renderer=(cat)
      ;;
  esac

  man "$cmd" | col -bx \
    | llm "${*:-Explain this command and show common usage.}" \
    | "${renderer[@]}"
}

####################################################################
# `why` - get insight on errors
####################################################################

why() {
  llm "Explain what went wrong and how to fix it" < /dev/stdin
}

####################################################################
# `howto` - get commands to do stuff
####################################################################

howto() {
  llm "Show the correct command to: $*"
}

####################################################################
# `summarize` - get summaries
####################################################################

summarize() {
  llm "Summarize this concisely" < /dev/stdin
}

####################################################################
# `ask` - general purpose ai help
####################################################################

ask() {
  llm "$*" < /dev/stdin
}

