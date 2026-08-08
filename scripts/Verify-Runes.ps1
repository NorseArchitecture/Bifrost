#!/usr/bin/env pwsh
#
# Verify-Runes.ps1 — evaluated-state assertions for the MSBuild estate.
# Green builds are necessary, not sufficient: this harness asserts what the
# evaluation actually produced, per the verification matrix in
# ../Glitnir/docs/Platform/specs/2026-08-07-msbuild-estate-consolidation-design.md §4.
param(
	[ValidateSet('baseline', 'post-aggregation', 'post-hoist', 'final')]
	[string]$Phase = 'baseline'
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
$Failures = [System.Collections.Generic.List[string]]::new()

function Get-Evaluated {
	param([string]$Project, [string[]]$Items = @(), [string[]]$Properties = @(), [string[]]$Props = @())
	$MsbuildArgs = @($Project)
	$Items      | ForEach-Object { $MsbuildArgs += "-getItem:$_" }
	$Properties | ForEach-Object { $MsbuildArgs += "-getProperty:$_" }
	# A lone -getProperty with no -getItem alongside it drops MSBuild into its
	# raw single-value shortcut (prints just the value, e.g. "false") instead
	# of the documented JSON envelope. Force JSON mode with a harmless second
	# property whenever that exact shape would otherwise trigger it.
	if ($Items.Count -eq 0 -and $Properties.Count -eq 1) { $MsbuildArgs += '-getProperty:MSBuildProjectFile' }
	$Props      | ForEach-Object { $MsbuildArgs += "-p:$_" }
	$Raw = dotnet msbuild @MsbuildArgs 2>&1 | Out-String
	if ($Raw -notmatch '(?s)(\{.*\})') { throw "No JSON in msbuild output for ${Project}: $Raw" }
	$Matches[1] | ConvertFrom-Json
}

function Assert-Items {
	param([string]$Label, [object]$Evaluated, [string]$ItemType, [string]$PathSuffix, [switch]$Absent, [string]$MetadataName, [string]$MetadataValue)
	$Hits = @($Evaluated.Items.$ItemType | Where-Object {
		$Match = ($_.Identity -replace '\\', '/').EndsWith($PathSuffix)
		if ($Match -and $MetadataName) { $Match = $_.$MetadataName -eq $MetadataValue }
		$Match
	})
	$Ok = $Absent ?
		($Hits.Count -eq 0) :
		($Hits.Count -eq 1)
	if (-not $Ok) { $Failures.Add("$Label — expected $($Absent ? '0' : '1') of '$PathSuffix' in @($ItemType), found $($Hits.Count)") }
}

function Assert-Property {
	param([string]$Label, [object]$Evaluated, [string]$Name, [string]$Expected)
	$Actual = $Evaluated.Properties.$Name
	if ($Actual -ne $Expected) { $Failures.Add("$Label — $Name expected '$Expected', got '$Actual'") }
}

# -p:_ParentTargets=__standalone__ cannot simulate "no Bifröst ancestor" any
# longer: it's an MSBuild global property, immune to reassignment by any
# in-project PropertyGroup for the rest of the build. Since Task 4/5, the
# group-level src/tests/gen Directory.Build.targets files each declare their
# OWN hop-1 _ParentTargets (pointing at the realm-root file) and gate their
# own <Import> on Exists($(_ParentTargets)) — the override poisons that hop
# too, so the realm-root file never gets imported at all and the fallback
# logic living there never runs. The only correct simulation of "no Bifröst
# ancestor" is the genuine one: physically remove Bifröst's own root
# Directory.Build.targets for the duration of the query.
function Invoke-WithBifrostRootHidden {
	param([scriptblock]$ScriptBlock)
	$RootTargets = "$Root/Directory.Build.targets"
	$HiddenTargets = "$RootTargets.verify-runes-hidden"
	if (Test-Path -LiteralPath $HiddenTargets) {
		throw "Stale hidden file '$HiddenTargets' found — a prior run of this harness likely crashed mid-operation. Manually restore it to '$RootTargets' (or verify $RootTargets already exists and delete the stale hidden copy) before re-running."
	}
	Move-Item -LiteralPath $RootTargets -Destination $HiddenTargets
	try {
		& $ScriptBlock
	} finally {
		Move-Item -LiteralPath $HiddenTargets -Destination $RootTargets
	}
}

# ---- Anchor projects -------------------------------------------------------
$MidgardBackend = "$Root/Midgard/src/Infrastructure.Backend/Infrastructure.Backend.csproj"
$MidgardServer  = "$Root/Midgard/src/Infrastructure.Web.Server/Infrastructure.Web.Server.csproj"
$YggWebServer   = "$Root/Yggdrasil/src/Hosting.Web.Server/Hosting.Web.Server.csproj"

# ---- BASELINE: true today, true forever ------------------------------------
# Workspace mode: NorseRef -> ProjectReference; platform analyzers attach.
$E = Get-Evaluated $MidgardBackend -Items ProjectReference, PackageReference
Assert-Items 'workspace: platform law attaches'   $E ProjectReference 'Svartalfheim/gen/Architecture.Analyzers/Architecture.Analyzers.csproj' -MetadataName OutputItemType -MetadataValue Analyzer
Assert-Items 'workspace: primitives law attaches' $E ProjectReference 'Svartalfheim/gen/Primitives.Analyzers/Primitives.Analyzers.csproj' -MetadataName OutputItemType -MetadataValue Analyzer
# Workspace package mode: same graph, package lens, no ProjectReference emission for NorseRef.
$E = Get-Evaluated $MidgardBackend -Items PackageReference -Props 'UseProjectReferences=false'
$NorsePkgs = @($E.Items.PackageReference | Where-Object Identity -like 'Norse.*')
if ($NorsePkgs.Count -eq 0) { $Failures.Add('package mode: no Norse.* PackageReference emitted for a NorseRef consumer') }
# Analyzer packages track the stable wildcard, not the prerelease one — same
# exception the post-hoist standalone-fallback assertion already carves out
# for Norse.Architecture.Analyzers below.
$NorsePkgs | Where-Object { $_.Version -ne '*-*' -and $_.Identity -ne 'Norse.Architecture.Analyzers' } | ForEach-Object { $Failures.Add("package mode: $($_.Identity) version '$($_.Version)' != '*-*'") }
# CPM realm, package mode: Version metadata must be absent (NU1008 law).
$E = Get-Evaluated $YggWebServer -Items PackageReference -Props 'UseProjectReferences=false'
@($E.Items.PackageReference | Where-Object Identity -like 'Norse.*') | Where-Object { $_.Version } | ForEach-Object {
	$Failures.Add("CPM package mode: $($_.Identity) carries Version '$($_.Version)' — NU1008") }
# Packaging identity: src evaluates packable, Yggdrasil hosts do not.
$E = Get-Evaluated $MidgardBackend -Properties IsPackable, OutputType
Assert-Property 'src identity' $E IsPackable 'true'
Assert-Property 'src identity' $E OutputType 'Library'
$E = Get-Evaluated $YggWebServer -Properties IsPackable
Assert-Property 'ygg host identity' $E IsPackable 'false'

# ---- GAP (fails on baseline; passes from post-aggregation on) --------------
# NORSE080: Yggdrasil consumes Midgard by NorseRef but never sees the realm analyzer.
if ($Phase -ne 'baseline') {
	$E = Get-Evaluated $YggWebServer -Items ProjectReference
	Assert-Items 'workspace: realm law crosses realms' $E ProjectReference 'Midgard/gen/Infrastructure.Web.Grpc.Analyzers/Infrastructure.Web.Grpc.Analyzers.csproj' -MetadataName OutputItemType -MetadataValue Analyzer
	# No double-attach anywhere: every analyzer-shaped ProjectReference identity is unique.
	$E = Get-Evaluated $MidgardServer -Items ProjectReference
	$AnalyzerRefs = @($E.Items.ProjectReference | Where-Object OutputItemType -eq 'Analyzer' | ForEach-Object { ($_.FullPath ?? $_.Identity) -replace '\\', '/' })
	$Dupes = $AnalyzerRefs | Group-Object | Where-Object Count -gt 1
	$Dupes | ForEach-Object { $Failures.Add("double-attach: $($_.Name) appears $($_.Count)x") }
}

# ---- POST-HOIST (Task 4 onward) --------------------------------------------
if ($Phase -in 'post-hoist', 'final') {
	# Standalone simulation: fallback emits stable-wildcard packages, not project refs.
	# "Standalone" here means physically no Bifröst ancestor — see
	# Invoke-WithBifrostRootHidden above for why the property-override
	# technique this used to use is unsound.
	Invoke-WithBifrostRootHidden {
		$E = Get-Evaluated $MidgardBackend -Items ProjectReference, PackageReference -Props 'UseProjectReferences=false'
		$NorsePkgs = @($E.Items.PackageReference | Where-Object Identity -like 'Norse.*')
		if ($NorsePkgs.Count -eq 0) { $Failures.Add('standalone fallback: no Norse.* PackageReference emitted — assertion vacuous') }
		$NorsePkgs | Where-Object { $_.Version -ne '*' -and $_.Identity -ne 'Norse.Architecture.Analyzers' } | ForEach-Object {
			$Failures.Add("standalone fallback: $($_.Identity) version '$($_.Version)' != '*'") }
		# Standalone realm-internal attach: Midgard's own manifest still delivers NORSE080.
		Assert-Items 'standalone: realm law attaches realm-internally' $E ProjectReference 'Midgard/gen/Infrastructure.Web.Grpc.Analyzers/Infrastructure.Web.Grpc.Analyzers.csproj' -MetadataName OutputItemType -MetadataValue Analyzer
	}
}

# ---- FINAL: the-runes.md ch. 5's duplicate-identity doctrine, enforced for real -------
# "duplicate analyzer project paths and duplicate analyzer assembly filenames are
# convicted as build-verification failures, not review hopes" (ch. 5) — that sentence
# described an aspiration until now; this is the standing check that makes it true.
if ($Phase -eq 'final') {
	$AnalyzerDeclarations = foreach ($ManifestFile in Get-ChildItem -Path "$Root/*/Directory.Analyzers.props") {
		$ManifestDir = $ManifestFile.DirectoryName
		$Xml = [xml](Get-Content -LiteralPath $ManifestFile.FullName -Raw)
		foreach ($Analyzer in (Select-Xml -Xml $Xml -XPath '//NorseRealmAnalyzer').Node) {
			$FullPath = [System.IO.Path]::GetFullPath(($Analyzer.Include -replace [regex]::Escape('$(MSBuildThisFileDirectory)'), "$ManifestDir/"))
			$AssemblyName = "Norse.$([System.IO.Path]::GetFileNameWithoutExtension($FullPath)).dll"
			[pscustomobject]@{ Manifest = $ManifestFile.FullName; FullPath = $FullPath; AssemblyName = $AssemblyName }
		}
	}
	$AnalyzerDeclarations | Group-Object FullPath | Where-Object Count -gt 1 | ForEach-Object {
		$Failures.Add("duplicate analyzer project path: '$($_.Name)' declared in $($_.Group.Manifest -join ', ')") }
	$AnalyzerDeclarations | Group-Object AssemblyName | Where-Object Count -gt 1 | ForEach-Object {
		$Failures.Add("duplicate analyzer assembly filename: '$($_.Name)' declared in $($_.Group.Manifest -join ', ')") }
}

if ($Failures.Count) {
	$Failures | ForEach-Object { Write-Host "FAIL: $_" -ForegroundColor Red }
	exit 1
}
Write-Host "Verify-Runes [$Phase]: all assertions green." -ForegroundColor Green
