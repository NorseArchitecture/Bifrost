#!/usr/bin/env pwsh
#
# Redirect-BuildArtifacts.ps1
#
# Bare-metal Windows/Visual Studio builds share this exact file tree with the devcontainer
# (docker-compose.yml binds the host NorseArchitecture folder straight into the container),
# often over a ReFS Dev Drive the devcontainer only reaches through the WSL/Windows file
# bridge. The devcontainer already redirects its own .NET bin/obj onto container-native disk
# (NORSE_BUILD_ARTIFACTS_DIR in devcontainer.json, root Directory.Build.props). Bare-metal
# Windows has no equivalent unless this script runs once: without it, Windows-built bin/obj
# (win-x64 RIDs, Windows paths baked into obj/project.assets.json) land directly in the
# shared tree and corrupt the next container-side build until every bin/obj folder is
# cleaned out by hand.
#
# npm's node_modules gets the same treatment, but not via this script: a symlink/junction
# back into the repo doesn't work for node_modules -- one OS's reparse point is unreadable
# to the other over the 9p-bridged mount, and npm's own reify step actively fights a symlink
# there (lstat() sees a non-directory, decides it's junk, deletes it, and reifies a fresh
# node_modules back onto the shared tree). Realms that need npm packages at build time (see
# Naglfar's DesignSystem.Tokens.csproj) install straight into NORSE_BUILD_ARTIFACTS_DIR and
# use a Node module customization hook to resolve against it, keyed off this same env var --
# no reparse point involved on either OS.
#
# Sets NORSE_BUILD_ARTIFACTS_DIR as a persistent user environment variable -- Visual Studio
# inherits it at launch, so restart VS (and any open terminals) afterward. Run once per
# Windows machine; re-running is a harmless no-op.
#
# Usage:
#   pwsh scripts/Redirect-BuildArtifacts.ps1
#   pwsh scripts/Redirect-BuildArtifacts.ps1 -ArtifactsDir D:\tmp\norse-artifacts

param(
	[string]$ArtifactsDir = (Join-Path (Split-Path $PSScriptRoot -Qualifier) 'tmp\norse-artifacts')
)

$ErrorActionPreference = 'Stop'

Write-Host "Setting NORSE_BUILD_ARTIFACTS_DIR = $ArtifactsDir (User scope)..."
[Environment]::SetEnvironmentVariable('NORSE_BUILD_ARTIFACTS_DIR', $ArtifactsDir, 'User')

Write-Host 'Done. Restart Visual Studio (and any open terminals) to pick up NORSE_BUILD_ARTIFACTS_DIR.' -ForegroundColor Green
