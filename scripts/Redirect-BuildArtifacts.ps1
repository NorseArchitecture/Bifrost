#!/usr/bin/env pwsh
#
# Redirect-BuildArtifacts.ps1
#
# Bare-metal Windows/Visual Studio builds share this exact file tree with the devcontainer
# (docker-compose.yml binds the host NorseArchitecture folder straight into the container),
# often over a ReFS Dev Drive the devcontainer only reaches through the WSL/Windows file
# bridge. The devcontainer already redirects its own .NET bin/obj and every realm's npm
# node_modules off that shared tree, onto container-native disk (NORSE_BUILD_ARTIFACTS_DIR
# in devcontainer.json, root Directory.Build.props, postCreateCommand's
# npm-node-modules-redirect step). Bare-metal Windows has no equivalent unless this script
# runs once: without it, Windows-built bin/obj (win-x64 RIDs, Windows paths baked into
# obj/project.assets.json) and Windows-native npm node_modules land directly in the shared
# tree and corrupt the next container-side build/install until every bin/obj/node_modules
# folder is cleaned out by hand.
#
# Sets NORSE_BUILD_ARTIFACTS_DIR as a persistent user environment variable -- Visual Studio
# inherits it at launch, so restart VS (and any open terminals) afterward -- and symlinks
# every top-level realm's node_modules into the same target. Run once per Windows machine;
# re-running is a harmless no-op. Creating the symlinks needs either an elevated shell or
# Windows Developer Mode (Settings > Privacy & security > For developers) enabled.
#
# Usage:
#   pwsh scripts/Redirect-BuildArtifacts.ps1
#   pwsh scripts/Redirect-BuildArtifacts.ps1 -ArtifactsDir D:\tmp\norse-artifacts

param(
	[string]$ArtifactsDir = (Join-Path (Split-Path $PSScriptRoot -Qualifier) 'tmp\norse-artifacts')
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path $PSScriptRoot

Write-Host "Setting NORSE_BUILD_ARTIFACTS_DIR = $ArtifactsDir (User scope)..."
[Environment]::SetEnvironmentVariable('NORSE_BUILD_ARTIFACTS_DIR', $ArtifactsDir, 'User')

Get-ChildItem -Path $RepoRoot -Filter 'package.json' -Recurse -Depth 1 | ForEach-Object {
	$RealmDir = $_.Directory
	$Link = Join-Path $RealmDir.FullName 'node_modules'
	$Target = Join-Path $ArtifactsDir "$($RealmDir.Name)\node_modules"

	New-Item -ItemType Directory -Path (Split-Path $Target) -Force | Out-Null

	$Existing = Get-Item -Path $Link -Force -ErrorAction SilentlyContinue
	if ($Existing -and $Existing.LinkType -eq 'SymbolicLink') {
		Write-Host "$($RealmDir.Name): node_modules already redirected, skipping."
		return
	}
	if ($Existing) {
		Write-Host "$($RealmDir.Name): moving existing node_modules to $Target..."
		if (Test-Path $Target) { Remove-Item -Recurse -Force $Target }
		Move-Item -Path $Link -Destination $Target
	} else {
		New-Item -ItemType Directory -Path $Target -Force | Out-Null
	}

	New-Item -ItemType SymbolicLink -Path $Link -Target $Target -Force | Out-Null
	Write-Host "$($RealmDir.Name): node_modules -> $Target" -ForegroundColor Green
}

Write-Host 'Done. Restart Visual Studio (and any open terminals) to pick up NORSE_BUILD_ARTIFACTS_DIR.' -ForegroundColor Green
