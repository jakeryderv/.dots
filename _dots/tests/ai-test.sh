#!/usr/bin/env bash
#
# ai-test.sh - exercise bin/ai against a stub `llm`.
#
# The stub echoes the prompt it was given and the context it was piped, so the
# assertions are about what ai assembles, not about any model's answer. Nothing
# here reaches the network.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
AI="$REPO_ROOT/bin/ai"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

cat >"$TEST_ROOT/llm" <<'STUB'
#!/usr/bin/env bash
printf 'PROMPT:%s\n' "$*"
[ -t 0 ] || { printf 'CONTEXT:'; cat; }
STUB
chmod +x "$TEST_ROOT/llm"

export PATH="$TEST_ROOT:$PATH"
export AI_RENDERER=cat

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

assert_contains() {
    [[ "$1" == *"$2"* ]] || fail "$3"
}

# --- prompts reach llm intact ------------------------------------------------

out="$("$AI" how convert webm to mp4 </dev/null)"
assert_contains "$out" 'prompt: how to convert webm to mp4' 'how did not pass the intent through'

out="$(printf 'hello world\n' | "$AI" sum)"
assert_contains "$out" 'CONTEXT:hello world' 'sum did not forward stdin'

out="$(printf 'boom\n' | "$AI" why)"
assert_contains "$out" 'PROMPT:Explain what went wrong' 'why used the wrong prompt'

# --- context assembly --------------------------------------------------------

printf 'alpha\nTODO one\nbeta\nTODO two\n' >"$TEST_ROOT/notes.md"
out="$("$AI" grep TODO "$TEST_ROOT/notes.md" what is left </dev/null)"
assert_contains "$out" 'PROMPT:what is left' 'grep did not use the trailing words as the prompt'
assert_contains "$out" '(2 matches)' 'grep did not count matches'
assert_contains "$out" '2:TODO one' 'grep did not include numbered match locations'

# `help -` takes help text on stdin; that is how shell/llm.sh's helpai explains
# shell functions and builtins, which an external process cannot introspect.
out="$(printf 'Usage: foo [-x]\n' | "$AI" help - -- what is -x)"
assert_contains "$out" 'CONTEXT:Usage: foo [-x]' 'help - did not read stdin'
assert_contains "$out" 'what is -x' 'help - dropped the question'

# Two chunks in, one combined answer out.
printf 'line %s\n' {1..200} >"$TEST_ROOT/big.txt"
out="$(AI_CHUNK_SIZE=500 "$AI" chunk "$TEST_ROOT/big.txt" what is here </dev/null)"
assert_contains "$out" 'PROMPT:Combine the following partial answers' 'chunk skipped the reduce step'
assert_contains "$out" 'Given this excerpt' 'chunk did not map over the pieces'

# --- option handling ---------------------------------------------------------

out="$("$AI" -m gpt-4o ask hello </dev/null)"
assert_contains "$out" 'PROMPT:-m gpt-4o hello' '-m did not reach llm'

out="$("$AI" ml what is a transformer </dev/null)"
assert_contains "$out" 'qwen2.5-coder:14b' 'ml lost its default model'

# --- failure modes -----------------------------------------------------------

status=0
"$AI" man >/dev/null 2>&1 || status=$?
((status == 2)) || fail "missing argument should exit 2, got $status"

status=0
"$AI" bogus >/dev/null 2>&1 || status=$?
((status == 2)) || fail "unknown command should exit 2, got $status"

status=0
"$AI" chunk "$TEST_ROOT/nope.txt" question >/dev/null 2>&1 || status=$?
((status == 1)) || fail "missing file should exit 1, got $status"

echo 'ai tests passed'
