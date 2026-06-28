#!/usr/bin/env pwsh
#
# pull-the-images.ps1
#
# Pulls every Docker image used by the Bifrost local dev environment.

$images = docker images --format "{{.Repository}}:{{.Tag}}" | Where-Object { $_ -notmatch "<none>" }

foreach ($image in $images) {
	Write-Host "Pulling $image ..."
	docker pull $image
}
