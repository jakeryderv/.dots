---
description: Inject current tmux session + pane overview as context
---

Current tmux session and panes:

Session: !`tmux display-message -p '#{session_name}'`

Panes:
!`tmux list-panes -F '#{pane_index}: #{pane_current_command} (#{pane_title})#{?pane_active, [active],}'`

Use the above as context for what is currently running in my terminal.
