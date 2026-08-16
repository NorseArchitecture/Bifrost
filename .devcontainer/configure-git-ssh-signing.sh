#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Wires up git identity plus SSH-based commit/tag signing (no GPG), using
# whichever key the forwarded SSH agent happens to be holding -- e.g.
# Bitwarden's bridge on WSL2/Fedora, or the native Windows agent. See
# buvinghausen/buvinghausen's ssh/GITHUB-SSH-SIGNING-SETUP.md for the
# one-key-every-device design this mirrors. /home/vscode isn't a persisted
# volume (see docker-compose.yml), so this re-runs on every container
# create, same as the other postCreateCommand steps beside it.
#
# GIT_USER_NAME/GIT_USER_EMAIL come from devcontainer.json's remoteEnv,
# forwarded from the host environment -- each contributor sets their own
# before the container starts. Unset means this script leaves git identity
# alone (and, since allowed_signers below is keyed off user.email, skips
# that too) rather than guessing or hard-coding a single contributor's info.
# ---------------------------------------------------------------------------
set -uo pipefail

if [ -n "${GIT_USER_NAME:-}" ]; then
  git config --global user.name "$GIT_USER_NAME"
fi
if [ -n "${GIT_USER_EMAIL:-}" ]; then
  git config --global user.email "$GIT_USER_EMAIL"
fi

KEY="$(ssh-add -L 2>/dev/null | head -1)"
if [ -z "$KEY" ]; then
  echo "configure-git-ssh-signing: no key loaded in the forwarded agent (SSH_AUTH_SOCK=${SSH_AUTH_SOCK:-unset}) -- skipping. Run 'ssh-add -l' on the host, then reopen/rebuild the container."
  exit 0
fi

git config --global gpg.format ssh
git config --global user.signingkey "$KEY"
git config --global commit.gpgsign true
git config --global tag.gpgsign true

mkdir -p ~/.ssh
chmod 700 ~/.ssh

EMAIL="$(git config --global user.email 2>/dev/null || true)"
if [ -n "$EMAIL" ]; then
  echo "$EMAIL $KEY" > ~/.ssh/allowed_signers
  git config --global gpg.ssh.allowedSignersFile ~/.ssh/allowed_signers
fi

# Non-interactive known_hosts entry so `ssh -T git@github.com` (verification step)
# doesn't hang on ssh-askpass, which this headless container doesn't have.
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null
sort -u -o ~/.ssh/known_hosts ~/.ssh/known_hosts 2>/dev/null || true

echo "configure-git-ssh-signing: signing configured with $(echo "$KEY" | awk '{print $NF}')"
