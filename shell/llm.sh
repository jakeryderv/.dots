#!/usr/bin/env bash
######################################################################
# Short names for `ai` (bin/ai)
######################################################################
#
# The helpers themselves live in bin/ai so nvim, tmux, cron, and scripts can
# reach them; this module only keeps the names muscle memory already knows.
# Set AI_RENDERER (glow | bat | cat) in local.sh to change how output is
# rendered -- see `ai -h` for the rest of the knobs.

alias manai='ai man'
alias howto='ai how'
alias summarize='ai sum'
alias grepask='ai grep'
alias chunkask='ai chunk'
alias llmq='ai ml'
alias codeai='ai code'
alias why='ai why'
alias ask='ai ask'

# helpai stays a function: `cmd --help` is captured by the shell that defines
# cmd, so this is the only form that can explain a shell function, alias, or
# builtin. `ai help -` takes the captured text on stdin.
helpai() {
    if [ $# -eq 0 ]; then
        echo "usage: helpai <command> [subcommand...] [-- question]" >&2
        return 2
    fi

    # Split on -- : left side is the command, right side is the question.
    local cmd_parts=() question_parts=() seen_separator=false arg
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

    # Try --help first, fall back to -h (capture both stdout and stderr).
    local help_text
    help_text=$("${cmd_parts[@]}" --help 2>&1) || help_text=$("${cmd_parts[@]}" -h 2>&1)

    if [ -z "$help_text" ]; then
        echo "helpai: no help output from '${cmd_parts[*]}'" >&2
        return 1
    fi

    if [ ${#question_parts[@]} -gt 0 ]; then
        printf '%s\n' "$help_text" | ai help - -- "${question_parts[@]}"
    else
        printf '%s\n' "$help_text" | ai help -
    fi
}
