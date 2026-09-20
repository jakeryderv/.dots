# shellcheck shell=sh
# Environment: PATH, EDITOR, pager. Sourced by every interactive shell from
# its rc file, first, so everything after it sees the same PATH. POSIX sh on
# purpose -- no bash-isms -- so bash and zsh read one file.

# User-installed executables, guarded against duplication in subshells.
case ":$PATH:" in
*":$HOME/.local/bin:"*) ;;
*) export PATH="$HOME/.local/bin:$PATH" ;;
esac

# Upstream language managers and their installed commands.
for runtime_bin in "${CARGO_HOME:-$HOME/.cargo}/bin" "${BUN_INSTALL:-$HOME/.bun}/bin"; do
    case ":$PATH:" in
    *":$runtime_bin:"*) ;;
    *) export PATH="$runtime_bin:$PATH" ;;
    esac
done
unset runtime_bin
# Binaries produced by go install; the Go runtime itself is in ~/.local/bin.
case ":$PATH:" in
*":$HOME/go/bin:"*) ;;
*) export PATH="$PATH:$HOME/go/bin" ;;
esac

# nvm owns Node, npm and each Node version's global packages. Do not set an
# npm prefix or add the retired ~/.npm-global/bin; nvm selects the active bin.
# Version switching is explicit (`nvm use`), with no directory-change hook.
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$NVM_DIR/nvm.sh"
fi

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
