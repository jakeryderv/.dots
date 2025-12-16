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

  # MANAI_PREPEND / MANAI_APPEND: static text to wrap the prompt
  local prepend="${MANAI_PREPEND:-You are a Unix expert providing answers/help based on provided manpage.}"
  local append="${MANAI_APPEND:-Be concise and straight to the point, always format outputs in strict universal markdown syntax.}"

  local prompt="${*:-Explain this command and show common usage.}"
  local full_prompt="${prepend:+$prepend }${prompt}${append:+ $append}"

  man "$cmd" | col -bx \
    | llm "$full_prompt" \
    | _llm_render
}

######################################################################
# why — explain errors
######################################################################

why() {
  if [ -t 0 ]; then
    echo "usage: why < stdin" >&2
    return 2
  fi

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
  if [ -t 0 ]; then
    echo "usage: summarize < stdin" >&2
    return 2
  fi

  llm "Summarize this concisely" < /dev/stdin \
    | _llm_render
}

######################################################################
# grepask — search then ask (targeted for large files)
######################################################################

# Context lines around each match (default: 20)
export GREPASK_CONTEXT=20

grepask() {
  if [ $# -lt 3 ]; then
    echo "usage: grepask <pattern> <file> <question>" >&2
    echo "  set GREPASK_CONTEXT to adjust context window (default: 20)" >&2
    return 2
  fi

  local pattern="$1"
  local file="$2"
  shift 2

  if [ ! -f "$file" ]; then
    echo "grepask: file not found: $file" >&2
    return 1
  fi

  local ctx="${GREPASK_CONTEXT:-20}"
  local total_lines=$(wc -l < "$file")
  local match_count=$(grep -c "$pattern" "$file" || echo 0)

  {
    echo "File: $file ($total_lines lines total)"
    echo "Pattern: $pattern ($match_count matches)"
    echo ""
    echo "=== Match locations ==="
    grep -n "$pattern" "$file"
    echo ""
    echo "=== Expanded context ($ctx lines around each match) ==="
    grep -n -B "$ctx" -A "$ctx" "$pattern" "$file"
  } | llm "$*" | _llm_render
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

