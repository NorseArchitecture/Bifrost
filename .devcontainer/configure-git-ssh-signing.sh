#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Wires up SSH-based commit/tag signing (no GPG) using whichever key the
# forwarded SSH agent happens to be holding -- e.g. Bitwarden's bridge on
# WSL2/Fedora, or the native Windows agent. See buvinghausen/buvinghausen's
# ssh/GITHUB-SSH-SIGNING-SETUP.md for the one-key-every-device design this
# mirrors. /home/vscode isn't a persisted volume (see docker-compose.yml),
# so this re-runs on every container create, same as the other
# postCreateCommand steps beside it.
# ---------------------------------------------------------------------------
set -uo pipefail

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
