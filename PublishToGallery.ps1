#Requires -Version 7.2
<#
.SYNOPSIS
Installs the package files and publishes the installed module to PowerShell Gallery.
.DESCRIPTION
Uses InstallModule.ps1 to copy only manifest-listed files into PSModulePath.
Any remaining local files in the installed directory are excluded from the
Gallery package. WhatIf performs no installation or publication.
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$NuGetApiKey = $env:NuGetApiKey
)

$ErrorActionPreference = 'Stop'
$manifestPath = Join-Path $PSScriptRoot 'PSAIClairic.psd1'
$manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
$data = Import-PowerShellDataFile -LiteralPath $manifestPath
if ($PSCmdlet.ShouldProcess('PSGallery', "Install and publish PSAIClairic $($manifest.Version)")) {
    if ([string]::IsNullOrWhiteSpace($NuGetApiKey)) {
        throw 'Supply -NuGetApiKey or set the NuGetApiKey environment variable before publishing.'
    }
    $installed = & (Join-Path $PSScriptRoot 'InstallModule.ps1') -Confirm:$false
    if (-not $installed -or -not $installed.FullName) { throw 'Installation did not return a module directory.' }
    $resolved = Get-Module -ListAvailable -Name PSAIClairic |
        Where-Object Version -EQ $manifest.Version | Select-Object -First 1
    if (-not $resolved -or $resolved.ModuleBase -ne $installed.FullName) {
        throw 'The installed module is not the PSAIClairic version resolved through PSModulePath. Check module-path ordering before publishing.'
    }
    $packageFiles = @($data.FileList | ForEach-Object { $_.Replace('\', '/') })
    $excluded = @(Get-ChildItem -LiteralPath $installed.FullName -File -Recurse -Force |
        ForEach-Object { [IO.Path]::GetRelativePath($installed.FullName, $_.FullName).Replace('\', '/') } |
        Where-Object { $_ -notin $packageFiles })
    $publish = @{
        Name            = 'PSAIClairic'
        RequiredVersion = $manifest.Version.ToString()
        NuGetApiKey      = $NuGetApiKey
        Repository      = 'PSGallery'
        ErrorAction     = 'Stop'
    }
    if ($excluded.Count) { $publish.Exclude = $excluded }
    Publish-Module @publish
}
