#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Wires lyze/posh-git-sh (the bash port of posh-git) into ~/.bashrc, same
# tool and same PS1 shape as buvinghausen/buvinghausen's update-tools.sh,
# adapted for the container: scoped to /workspaces/** instead of ~/code/**
# since that's this environment's equivalent code root, and no SDKMAN splice
# is needed here. bash stays the default terminal -- this only changes its
# prompt inside /workspaces. ~/.bashrc isn't persisted across rebuilds (see
# docker-compose.yml), so this re-runs, replay-safe, on every container
# create, same as the other postCreateCommand steps beside it.
# ---------------------------------------------------------------------------
set -euo pipefail

curl -fsSL -o ~/.posh-git-sh https://raw.githubusercontent.com/lyze/posh-git-sh/master/git-prompt.sh

MARKER="# posh-git-sh -- only active inside /workspaces/**"
if ! grep -qF "$MARKER" ~/.bashrc 2>/dev/null; then
  cat >>~/.bashrc <<'EOF'

# posh-git-sh -- only active inside /workspaces/**
source ~/.posh-git-sh

_update_prompt() {
    case "$PWD" in
        /workspaces/*)
            PROMPT_COMMAND='__posh_git_ps1 "\u@\h:\w " "\\\$ ";'
            ;;
        *)
            PROMPT_COMMAND=''
            PS1='\u@\h:\w\$ '
            ;;
    esac
}

cd() {
    builtin cd "$@" || return
    _update_prompt
}

_update_prompt
EOF
  echo "configure-posh-git-sh: wired into ~/.bashrc"
fi
