#!/usr/bin/env pwsh
#
# Trust-DevCert.ps1
#
# Imports the devcontainer's ASP.NET Core HTTPS dev cert into Windows' CurrentUser\Root
# store, so Chrome/Edge/Brave stop showing the self-signed warning for the AppHost dashboard
# and every Aspire-forwarded site (https://localhost:5000, :5001, :5002, ...).
#
# Public certificate only — the private key never leaves the container, no password, no
# cleanup step. Run once per Windows machine; re-running is a harmless no-op. Only needs to
# run again if the norse-home Docker volume is ever deleted, since that forces the
# devcontainer to mint a brand-new cert (new fingerprint) on next rebuild.
#
# Usage:
#   pwsh scripts/Trust-DevCert.ps1

param(
	[string]$CertPath = (Join-Path (Split-Path $PSScriptRoot) '.devcontainer/certs/aspnetcore-dev.crt')
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $CertPath)) {
	throw "Cert not found at $CertPath — start the devcontainer at least once first (postCreateCommand's dev-cert-trust step generates it)."
}

Write-Host "Trusting $CertPath in CurrentUser\Root..."
Import-Certificate -FilePath $CertPath -CertStoreLocation Cert:\CurrentUser\Root | Out-Null

Write-Host 'Trusted. Restart your browser for it to pick up the change.' -ForegroundColor Green
