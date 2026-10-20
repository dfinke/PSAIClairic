#Requires -Version 7.2
<#
.SYNOPSIS
Publishes this module to PowerShell Gallery when explicitly run.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$NuGetApiKey
)

$ErrorActionPreference = 'Stop'
$manifest = Test-ModuleManifest -Path (Join-Path $PSScriptRoot 'PSAIClairic.psd1') -ErrorAction Stop
if ($PSCmdlet.ShouldProcess('PSGallery', "Publish PSAIClairic $($manifest.Version)")) {
    Publish-Module -Path $PSScriptRoot -NuGetApiKey $NuGetApiKey -Repository PSGallery -ErrorAction Stop
}
