---
description: Inject recent output (scrollback) from a tmux pane. Usage: /tmux-logs <pane-index>
---

Recent output from tmux pane $ARGUMENTS:

!`tmux capture-pane -p -S -200 -t "$ARGUMENTS"`

Review this output. If there are errors or warnings, explain them and suggest fixes.
