#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Manual update path for the Claude Code CLI, kept because DISABLE_AUTOUPDATER
# is set in .claude/settings.json: npm 12 blocks lifecycle scripts on global
# installs (see devcontainer.json's "claude-native-binary" postCreateCommand
# comment), so a bare `npm install -g @anthropic-ai/claude-code@latest` --
# and `claude update`, which goes through the same npm path -- silently skips
# the postinstall step that places the native binary, leaving `claude` dead
# with "claude native binary not installed" until that postinstall is rerun
# by hand. This script chains both steps so updating stays one command.
# ---------------------------------------------------------------------------
set -euo pipefail

npm install -g @anthropic-ai/claude-code@latest
sudo "$(command -v node)" "$(npm root -g)/@anthropic-ai/claude-code/install.cjs"

echo "update-claude: $(claude --version)"
