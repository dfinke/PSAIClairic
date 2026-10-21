#Requires -Version 7.2
<#
.SYNOPSIS
Installs PSAIClairic for the current user from this checkout.
.DESCRIPTION
Copies only manifest-listed module files, excluding Git metadata, tests,
publishing scripts, credentials, and local notes. Existing matching files are updated;
unrelated destination files are preserved. FullPath overrides the module's
version directory. Supports WhatIf and Confirm.
.EXAMPLE
./InstallModule.ps1 -WhatIf
.EXAMPLE
./InstallModule.ps1 -FullPath ./work/module-install/PSAIClairic/0.2.0
#>
[CmdletBinding(SupportsShouldProcess)]
param([string]$FullPath)

$ErrorActionPreference = 'Stop'
$manifestPath = Join-Path $PSScriptRoot 'PSAIClairic.psd1'
$manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
$data = Import-PowerShellDataFile -LiteralPath $manifestPath

if ([string]::IsNullOrWhiteSpace($FullPath)) {
    $moduleRoot = if ($IsWindows) {
        Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'PowerShell/Modules'
    } else {
        Join-Path $HOME '.local/share/powershell/Modules'
    }
    $FullPath = Join-Path $moduleRoot "PSAIClairic/$($manifest.Version)"
}
$destination = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($FullPath)
$source = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd([IO.Path]::DirectorySeparatorChar)
$comparison = if ($IsWindows) { [StringComparison]::OrdinalIgnoreCase } else { [StringComparison]::Ordinal }
if ($destination.Equals($source, $comparison)) { throw 'Installation destination must differ from the source checkout.' }

# Check all package inputs before writing any destination files.
foreach ($relative in $data.FileList) {
    if (-not (Test-Path -LiteralPath (Join-Path $PSScriptRoot $relative) -PathType Leaf)) {
        throw "Module package file is missing: $relative"
    }
}
if ($PSCmdlet.ShouldProcess($destination, "Install PSAIClairic $($manifest.Version)")) {
    foreach ($relative in $data.FileList) {
        $targetFile = Join-Path $destination $relative
        New-Item -ItemType Directory -Path (Split-Path $targetFile -Parent) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $PSScriptRoot $relative) -Destination $targetFile -Force
    }
    Test-ModuleManifest -Path (Join-Path $destination 'PSAIClairic.psd1') -ErrorAction Stop | Out-Null
    Write-Host "Installed PSAIClairic $($manifest.Version) to $destination"
    Get-Item -LiteralPath $destination
}
