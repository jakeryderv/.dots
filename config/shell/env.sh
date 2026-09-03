# shellcheck shell=sh
# Environment: PATH, EDITOR, pager. Sourced by every interactive shell from
# its rc file, first, so everything after it sees the same PATH. POSIX sh on
# purpose -- no bash-isms -- so bash and zsh read one file.

# ~/.local/bin and the npm global prefix, guarded against duplication when a
# subshell re-sources this. Node comes from flake.nix, whose store path is
# read-only, so `npm install -g` needs the writable prefix ~/.npmrc names.
case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) export PATH="$HOME/.local/bin:$PATH" ;;
esac
case ":$PATH:" in
*":$HOME/.npm-global/bin:"*) ;;
*) export PATH="$HOME/.npm-global/bin:$PATH" ;;
esac

# ls colors
if [ -x /usr/bin/dircolors ]; then
    if [ -r "$HOME/.dircolors" ]; then
        eval "$(dircolors -b "$HOME/.dircolors")"
    else
        eval "$(dircolors -b)"
    fi
fi

if [ -n "$SSH_CONNECTION" ]; then
    export EDITOR='vim'
else
    export EDITOR='nvim'
fi

# Pi agent defaults: keep provider prompt caches warm across sessions, and do
# not index the whole home directory when Pi starts there.
export PI_CACHE_RETENTION=long
export FFF_ENABLE_HOME_SCAN=0

# man pages in the editor when there is one; otherwise colour less itself.
if command -v nvim >/dev/null 2>&1; then
    export MANPAGER='nvim +Man!'
elif command -v vim >/dev/null 2>&1; then
    export MANPAGER='vim -M -c "runtime! ftplugin/man.vim" -c MANPAGER -'
else
    export LESS='-R'
    LESS_TERMCAP_md=$(printf '\033[1;36m') && export LESS_TERMCAP_md
    LESS_TERMCAP_us=$(printf '\033[1;32m') && export LESS_TERMCAP_us
    LESS_TERMCAP_so=$(printf '\033[1;44;37m') && export LESS_TERMCAP_so
    LESS_TERMCAP_me=$(printf '\033[0m') && export LESS_TERMCAP_me
    LESS_TERMCAP_ue=$(printf '\033[0m') && export LESS_TERMCAP_ue
    LESS_TERMCAP_se=$(printf '\033[0m') && export LESS_TERMCAP_se
fi
