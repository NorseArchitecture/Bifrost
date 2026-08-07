#!/usr/bin/env pwsh
#
# summarize-the-branches.ps1
#
# Reports, for Bifrost and every submodule, the current branch, its parity with origin
# (ahead/behind, or a detached HEAD), and any other branches origin is carrying beyond the
# expected default (an in-flight feature fork, or a stray one worth cleaning up). Run it
# after sync-the-realms.ps1 to confirm every realm landed clean with nothing forgotten on
# the remote.
#
# Usage:
#   pwsh scripts/summarize-the-branches.ps1
#   pwsh scripts/summarize-the-branches.ps1 -NoFetch
#   pwsh scripts/summarize-the-branches.ps1 -DefaultBranch main

param(
	[switch]$NoFetch,
	[string]$DefaultBranch = 'master',
	[int]$ThrottleLimit = 5
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path $PSScriptRoot

$SubmodulePaths = git -C $Root submodule status |
	ForEach-Object { ($_.Trim() -split '\s+')[1] }

$Repos = @([pscustomobject]@{ Name = 'Bifrost'; Path = $Root }) +
	@($SubmodulePaths | ForEach-Object { [pscustomobject]@{ Name = $_; Path = (Join-Path $Root $_) } })

$Summaries = $Repos | ForEach-Object -Parallel {
	$Name = $_.Name
	$Path = $_.Path
	$DefaultBranch = $using:DefaultBranch

	if (-not $using:NoFetch) {
		git -C $Path fetch origin --quiet --prune 2>&1 | Out-Null
	}

	$Branch = (git -C $Path rev-parse --abbrev-ref HEAD 2>$null).Trim()
	$Detached = $Branch -eq 'HEAD'

	$Ahead = 0
	$Behind = 0
	$Upstream = $null
	if (-not $Detached) {
		$UpstreamRef = git -C $Path rev-parse --abbrev-ref --symbolic-full-name '@{u}' 2>$null
		if ($LASTEXITCODE -eq 0 -and $UpstreamRef) {
			$Upstream = $UpstreamRef.Trim()
			$Counts = (git -C $Path rev-list --left-right --count "$Upstream...HEAD" 2>$null).Trim() -split '\s+'
			if ($Counts.Count -eq 2) {
				$Behind = [int]$Counts[0]
				$Ahead = [int]$Counts[1]
			}
		}
	}

	# git's short-name algorithm collapses the origin/HEAD symref down to the bare string "origin" on
	# some versions rather than "origin/HEAD" -- match on the "origin/" prefix explicitly rather than
	# excluding "origin/HEAD" by name, so that alias can't slip through as a phantom branch.
	$OtherBranches = @(git -C $Path branch -r --format='%(refname:short)' 2>$null |
		Where-Object { $_ -like 'origin/*' -and $_ -ne "origin/$DefaultBranch" } |
		ForEach-Object { $_ -replace '^origin/', '' })

	[pscustomobject]@{
		Name          = $Name
		Branch        = $Branch
		Detached      = $Detached
		Upstream      = $Upstream
		Ahead         = $Ahead
		Behind        = $Behind
		OtherBranches = $OtherBranches
	}
} -ThrottleLimit $ThrottleLimit

$Ordered = @($Summaries | Where-Object { $_.Name -eq 'Bifrost' }) +
	@($Summaries | Where-Object { $_.Name -ne 'Bifrost' } | Sort-Object Name)

$Ordered |
	ForEach-Object {
		$Status =
			if ($_.Detached) { 'DETACHED HEAD' }
			elseif (-not $_.Upstream) { 'no upstream' }
			elseif ($_.Ahead -eq 0 -and $_.Behind -eq 0) { 'up to date' }
			elseif ($_.Ahead -gt 0 -and $_.Behind -gt 0) { "ahead $($_.Ahead), behind $($_.Behind)" }
			elseif ($_.Ahead -gt 0) { "ahead $($_.Ahead)" }
			else { "behind $($_.Behind)" }

		[pscustomobject]@{
			Repository    = $_.Name
			Branch        = $_.Branch
			Status        = $Status
			OtherBranches = if ($_.OtherBranches.Count -gt 0) { $_.OtherBranches -join ', ' } else { '-' }
		}
	} |
	Format-Table -AutoSize -Wrap

$OffDefault = @($Ordered | Where-Object { -not $_.Detached -and $_.Branch -ne $DefaultBranch })
$Detached = @($Ordered | Where-Object { $_.Detached })
$NotSynced = @($Ordered | Where-Object { -not $_.Detached -and ($_.Ahead -gt 0 -or $_.Behind -gt 0 -or -not $_.Upstream) })
$WithOtherBranches = @($Ordered | Where-Object { $_.OtherBranches.Count -gt 0 })

if ($Detached.Count -gt 0) {
	Write-Warning "Detached HEAD: $($Detached.Name -join ', ')"
}
if ($OffDefault.Count -gt 0) {
	Write-Warning "Off $($DefaultBranch): $($OffDefault.Name -join ', ')"
}
if ($NotSynced.Count -gt 0) {
	Write-Warning "Not in sync with origin: $($NotSynced.Name -join ', ')"
}
if ($WithOtherBranches.Count -gt 0) {
	Write-Host "Carrying other origin branches: $($WithOtherBranches.Name -join ', ')"
}
if ($Detached.Count -eq 0 -and $OffDefault.Count -eq 0 -and $NotSynced.Count -eq 0 -and $WithOtherBranches.Count -eq 0) {
	Write-Host 'All clean.'
}
