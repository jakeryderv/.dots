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
    echo "usage: manai <command> [-- question]" >&2
    return 2
  fi

  # Split on -- : left side is command, right side is question
  local cmd=""
  local question_parts=()
  local seen_separator=false

  for arg in "$@"; do
    if [ "$arg" = "--" ]; then
      seen_separator=true
    elif $seen_separator; then
      question_parts+=("$arg")
    elif [ -z "$cmd" ]; then
      cmd="$arg"
    else
      # No separator, treat remaining args as question (backwards compat)
      question_parts+=("$arg")
    fi
  done

  if [ -z "$cmd" ]; then
    echo "manai: no command specified" >&2
    return 2
  fi

  if ! man -w "$cmd" >/dev/null 2>&1; then
    echo "manai: no man page found for '$cmd'" >&2
    return 1
  fi

  # MANAI_PREPEND / MANAI_APPEND: static text to wrap the prompt
  local prepend="${MANAI_PREPEND:-You are a Unix expert providing help based on provided manpage.}"
  local append="${MANAI_APPEND:-Be concise and straight to the point, always format outputs nicely and in strict universal markdown syntax.}"

  local prompt="${question_parts[*]:-Explain and show common usage.}"
  local full_prompt="${prepend:+$prepend }${prompt}${append:+ $append}"

  man "$cmd" | col -bx \
    | llm "$full_prompt" \
    | _llm_render
}

######################################################################
# helpai — explain command help using llm
######################################################################

helpai() {
  if [ -z "$1" ]; then
    echo "usage: helpai <command> [subcommand...] [-- question]" >&2
    return 2
  fi

  # Split on -- : left side is command, right side is question
  local cmd_parts=()
  local question_parts=()
  local seen_separator=false

  for arg in "$@"; do
    if [ "$arg" = "--" ]; then
      seen_separator=true
    elif $seen_separator; then
      question_parts+=("$arg")
    else
      cmd_parts+=("$arg")
    fi
  done

  if [ ${#cmd_parts[@]} -eq 0 ]; then
    echo "helpai: no command specified" >&2
    return 2
  fi

  if ! command -v "${cmd_parts[0]}" >/dev/null 2>&1; then
    echo "helpai: command not found: '${cmd_parts[0]}'" >&2
    return 1
  fi

  # Try --help first, fall back to -h (capture both stdout and stderr)
  local help_text
  help_text=$("${cmd_parts[@]}" --help 2>&1) || help_text=$("${cmd_parts[@]}" -h 2>&1)

  if [ -z "$help_text" ]; then
    echo "helpai: no help output from '${cmd_parts[*]}'" >&2
    return 1
  fi

  local prepend="${HELPAI_PREPEND:-You are a Unix expert providing help based on command help output.}"
  local append="${HELPAI_APPEND:-Be concise and straight to the point, always format outputs nicely and in strict universal markdown syntax.}"

  local prompt="${question_parts[*]:-Explain and show common usage.}"
  local full_prompt="${prepend:+$prepend }${prompt}${append:+ $append}"

  echo "$help_text" \
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

  llm "You are a Unix/Linux command-line expert. Respond with the best single command or short pipeline.
	Rules:
		- prefer POSIX or GNU coreutils
		- no long prose
		- no emojis
		- no safety disclamers
		- no alternatives unless requested
		- assume bash
		- output must be copy-paste runnable

	prompt: how to $*" \
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

  llm "Summarize the following text concisely. Output only the summary, no preamble." < /dev/stdin \
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

######################################################################
# chunkask — ask a question across a large file via chunking
######################################################################

# Default chunk size (bytes)
export CHUNKASK_SIZE=40000

chunkask() {
  if [ $# -lt 2 ]; then
    echo "usage: chunkask <file> <question>" >&2
    return 2
  fi

  local file="$1"
  shift
  local question="$*"

  if [ ! -f "$file" ]; then
    echo "chunkask: file not found: $file" >&2
    return 1
  fi

  local size="${CHUNKASK_SIZE:-40000}"
  local tmpdir
  tmpdir=$(mktemp -d)

  split -b "$size" "$file" "$tmpdir/chunk_"

  # Ask the question of each chunk
  local answers="$tmpdir/answers.txt"
  > "$answers"

  for chunk in "$tmpdir"/chunk_*; do
    llm "Given this excerpt, answer the question: $question" < "$chunk" >> "$answers"
    echo -e "\n---\n" >> "$answers"
  done

  # Reduce step
  llm "Combine the following partial answers into a single coherent answer to the question: $question" \
    < "$answers" \
    | _llm_render

  rm -rf "$tmpdir"
}


######################################################################
# llmq - ask good model ml questions
######################################################################

llmq() {
	llm -m qwen2.5-coder:14b \
	--no-stream \
	--system "You are an expert machine learning researcher. Be precise, technical, and concise." \
	"$@" | _llm_render
}

