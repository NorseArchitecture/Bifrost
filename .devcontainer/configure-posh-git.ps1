# ---------------------------------------------------------------------------
# Installs posh-git and imports it from the CurrentUserAllHosts profile, so it
# loads in any pwsh session regardless of host (plain terminal, VS Code's
# PowerShell extension, etc). ~/.local/share/powershell and
# ~/.config/powershell aren't persisted volumes (see docker-compose.yml), so
# this re-runs on every container create, same as the other
# postCreateCommand steps beside it.
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'

if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser | Out-Null
}

Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

if (-not (Get-Module -ListAvailable -Name posh-git)) {
    Install-Module -Name posh-git -Scope CurrentUser -Force -AllowClobber -Confirm:$false
}

$profilePath = $PROFILE.CurrentUserAllHosts
$profileDir = Split-Path $profilePath -Parent
if (-not (Test-Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
}
if (-not (Test-Path $profilePath) -or -not (Select-String -Path $profilePath -Pattern '^Import-Module posh-git$' -Quiet)) {
    Add-Content -Path $profilePath -Value "`nImport-Module posh-git"
}

Write-Host "configure-posh-git: posh-git installed and imported from $profilePath"
