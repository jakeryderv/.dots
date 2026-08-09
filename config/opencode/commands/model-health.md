---
description: Audit all model assignments (defaults, council, workflow) — availability + benchmarks, suggest fixes
---
Configured model availability (defaults plus every agent assignment):

!`openai_models="$(opencode models openai)"; openrouter_models="$(opencode models openrouter)"; { python3 -c 'import json, pathlib; config=json.loads(pathlib.Path.home().joinpath(".config/opencode/opencode.json").read_text()); print(config["model"]); print(config["small_model"])'; sed -n 's/^model:[[:space:]]*//p' "$HOME"/.config/opencode/agents/*.md; } | sort -u | while IFS= read -r model; do case "$model" in openai/*) catalog="$openai_models" ;; openrouter/*) catalog="$openrouter_models" ;; *) catalog="" ;; esac; if printf '%s\n' "$catalog" | grep -Fxq "$model"; then printf 'available\t%s\n' "$model"; else printf 'missing\t%s\n' "$model"; fi; done`

Audit every model assignment in this opencode config. Assignments live in two places:
- `~/.config/opencode/opencode.json` → `model` and `small_model` (the **defaults**)
- `~/.config/opencode/agents/*.md` → each agent's `model:` line

Group the assignments and apply the RIGHT check to each group. Do not mix providers:
the suggested replacement for a default must come from openai; for any agent it must
come from openrouter. The availability report above is filtered to configured models.

1. **Defaults** (`model`, `small_model` in opencode.json) — sourced from **openai**.
   - Use the availability report above (✓ available / ✗ gone).
   - These are deliberate tier choices (flagship driver / cheap small model), NOT
     benchmark picks. Only flag a swap if the current model is unavailable, or a
     clearly-newer *same-tier* openai model exists. Do not chase leaderboards here.

2. **Council seats** (`agents/council-*.md`) — sourced from **openrouter**.
   - Use the availability report above (✓ / ✗ e.g. suspended).
   - Use web search for current Artificial Analysis rankings (artificialanalysis.ai)
     per seat's domain: code, cli/terminal, vision (image+video), reasoning/math,
     general intelligence. Suggest a swap ONLY if the new leader is also present in
     the openrouter list above.

3. **Workflow agents** (every other `agents/*.md` — e.g. plan, fixer, tdd, review,
   explore, librarian, config-tuner) — sourced from **openrouter**.
   - These intentionally use floating `~vendor/...-latest` aliases (tier/role picks,
     not benchmark picks). Only verify the alias still resolves in the availability
     report. Do NOT suggest benchmark-leader swaps here.

4. Print ONE table: `item | group | current model | available? | verdict (keep / swap → <model>)`.

5. If you recommend any changes, summarize them and ASK me to confirm. On my
   confirmation, delegate the edits to `@config-tuner` (it edits the files,
   validates JSON, and shows a diff). Do NOT edit any files yourself.
