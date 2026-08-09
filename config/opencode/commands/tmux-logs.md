---
description: Inject recent output from a tmux pane. Usage: /tmux-logs <pane-target>
---

Recent output from tmux pane target `$ARGUMENTS`:

!`if [ -z "${TMUX:-}" ]; then printf 'Not currently running inside tmux.\n'; elif [ -z "$ARGUMENTS" ]; then printf 'No pane target supplied. Usage: /tmux-logs <pane-target>\n'; else tmux capture-pane -p -S -200 -t "$ARGUMENTS"; fi`

Review this output. If there are errors or warnings, explain them and suggest fixes.
