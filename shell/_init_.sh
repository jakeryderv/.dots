#!/usr/bin/env bash
# Loader — source bash config modules in a defined order.
#
# Add the following to ~/.bashrc:
#
# if [ -f "$HOME/.dots/shell/_init_.sh" ]; then
#     source "$HOME/.dots/shell/_init_.sh"
# fi
#

# Directory where this script resides (portable even if moved)
BASH_CONFIG_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Order matters: env/options first, then functions, then things that may
# reference them (aliases, keybinds). `local` is last so a machine-specific
# file can override anything above it, and is the only module allowed to be
# absent -- a missing tracked module means the shell would start degraded
# (no aliases, exports, functions), so it warns instead of skipping silently.
bash_modules=(
    exports     # PATH, EDITOR, LS_COLORS
    options     # history + shopt
    completions # bash-completion + readline bindings
    functions   # shell functions
    aliases     # aliases
    keybinds    # readline keybindings (may reference functions)
    llm         # llm helper functions
    local       # machine-specific, git-ignored (optional)
)

for module in "${bash_modules[@]}"; do
    config_file="$BASH_CONFIG_DIR/$module.sh"
    if [ -r "$config_file" ]; then
        # shellcheck disable=SC1090 # module paths are assembled from the fixed list above
        source "$config_file"
    elif [ "$module" != local ]; then
        printf 'dots: missing shell module: %s\n' "$config_file" >&2
    fi
done

# Clean up so these don't clutter the environment
unset BASH_CONFIG_DIR bash_modules module config_file
