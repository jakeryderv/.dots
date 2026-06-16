---
description: Audit all model assignments (defaults, council, workflow) — availability + benchmarks, suggest fixes
---
Models the **openai** provider can serve (OAuth — use ONLY for defaults):

!`opencode models openai`

Models the **openrouter** provider can serve (use ONLY for council + workflow agents):

!`opencode models openrouter`

Audit every model assignment in this opencode config. Assignments live in two places:
- `~/.config/opencode/opencode.json` → `model` and `small_model` (the **defaults**)
- `~/.config/opencode/agents/*.md` → each agent's `model:` line

Group the assignments and apply the RIGHT check to each group. Do not mix providers:
the suggested replacement for a default must come from the openai list above; for any
agent it must come from the openrouter list above.

1. **Defaults** (`model`, `small_model` in opencode.json) — sourced from **openai**.
   - Verify each is present in the openai list (✓ available / ✗ gone).
   - These are deliberate tier choices (flagship driver / cheap small model), NOT
     benchmark picks. Only flag a swap if the current model is unavailable, or a
     clearly-newer *same-tier* openai model exists. Do not chase leaderboards here.

2. **Council seats** (`agents/council-*.md`) — sourced from **openrouter**.
   - Verify each pinned model is present in the openrouter list (✓ / ✗ e.g. suspended).
   - Use web search for current Artificial Analysis rankings (artificialanalysis.ai)
     per seat's domain: code, cli/terminal, vision (image+video), reasoning/math,
     general intelligence. Suggest a swap ONLY if the new leader is also present in
     the openrouter list above.

3. **Workflow agents** (every other `agents/*.md` — e.g. plan, fixer, tdd, review,
   explore, librarian, config-tuner) — sourced from **openrouter**.
   - These intentionally use floating `~vendor/...-latest` aliases (tier/role picks,
     not benchmark picks). Only verify the alias still resolves / the model line is
     valid against the openrouter list. Do NOT suggest benchmark-leader swaps here.

4. Print ONE table: `item | group | current model | available? | verdict (keep / swap → <model>)`.

5. If you recommend any changes, summarize them and ASK me to confirm. On my
   confirmation, delegate the edits to `@config-tuner` (it edits the files,
   validates JSON, and shows a diff). Do NOT edit any files yourself.
