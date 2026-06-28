#!/usr/bin/env pwsh
#
# sync-the-realms.ps1
#
# Brings every submodule to the tip of master in parallel, then pulls Bifrost.
# Keeps submodules on a real branch — no detached HEAD.
#
# Usage:
#   pwsh scripts/sync-the-realms.ps1

param(
	[int]$ThrottleLimit = 5
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path $PSScriptRoot

Write-Host 'Syncing realms...'

$Paths = git -C $Root submodule status |
	ForEach-Object { ($_.Trim() -split '\s+')[1] }

$Results = $Paths | ForEach-Object -Parallel {
	$Name = $_
	$Path = Join-Path $using:Root $Name

	git -C $Path fetch origin --quiet 2>&1 | Out-Null
	$Ok = $LASTEXITCODE -eq 0
	git -C $Path checkout master --quiet 2>&1 | Out-Null
	$Ok = $Ok -and $LASTEXITCODE -eq 0
	git -C $Path pull --ff-only --quiet 2>&1 | Out-Null
	$Ok = $Ok -and $LASTEXITCODE -eq 0

	[pscustomobject]@{ Name = $Name; Ok = $Ok }
} -ThrottleLimit $ThrottleLimit

foreach ($Result in $Results | Sort-Object Name) {
	if ($Result.Ok) {
		Write-Host "    $($Result.Name)"
	} else {
		Write-Warning "    FAILED: $($Result.Name)"
	}
}

$Failures = @($Results | Where-Object { -not $_.Ok })
if ($Failures.Count -gt 0) {
	Write-Error "Failed to sync: $($Failures.Name -join ', ')"
	exit 1
}

Write-Host 'Pulling Bifrost...'
git -C $Root pull --ff-only --quiet
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host 'Done.'
