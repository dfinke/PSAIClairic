BeforeAll {
    $sourceRoot = Split-Path $PSScriptRoot -Parent
    $script:manifestData = Import-PowerShellDataFile (Join-Path $sourceRoot 'PSAIClairic.psd1')
    $script:installed = & (Join-Path $sourceRoot 'InstallModule.ps1') -FullPath (Join-Path $TestDrive 'Modules/PSAIClairic/0.2.0')
    $script:fixture = Join-Path $TestDrive 'publisher'
    foreach ($relative in $manifestData.FileList) {
        $target = Join-Path $fixture $relative
        New-Item -ItemType Directory -Path (Split-Path $target -Parent) -Force | Out-Null
        Copy-Item -LiteralPath (Join-Path $sourceRoot $relative) -Destination $target
    }
    Copy-Item -LiteralPath (Join-Path $sourceRoot 'PublishToGallery.ps1') -Destination $fixture
    $script:installMarker = Join-Path $fixture 'install-called.txt'
    $installerStub = @'
[CmdletBinding(SupportsShouldProcess)]
param()
Set-Content -LiteralPath '{0}' -Value called
Get-Item -LiteralPath '{1}'
'@ -f $installMarker.Replace("'", "''"), $installed.FullName.Replace("'", "''")
    Set-Content -LiteralPath (Join-Path $fixture 'InstallModule.ps1') -Value $installerStub
}

Describe 'Gallery package boundaries' {
    BeforeEach {
        if (Test-Path -LiteralPath $installMarker) { Remove-Item -LiteralPath $installMarker }
        Mock Get-Module { [pscustomobject]@{ Version=[version]'0.2.0'; ModuleBase=$installed.FullName } } -ParameterFilter { $ListAvailable -and $Name -eq 'PSAIClairic' }
        Mock Publish-Module {}
    }
    It 'installs exactly the manifest-listed files, including example images' {
        $actual = @(Get-ChildItem -LiteralPath $installed.FullName -Recurse -File -Force |
            ForEach-Object { [IO.Path]::GetRelativePath($installed.FullName, $_.FullName).Replace('\', '/') } | Sort-Object)
        ($actual -join ',') | Should -Be (($manifestData.FileList | Sort-Object) -join ',')
        Test-Path -LiteralPath (Join-Path $installed.FullName 'VideoScript.md') | Should -BeFalse
        Test-Path -LiteralPath (Join-Path $installed.FullName 'examples/receipt.png') | Should -BeTrue
    }
    It 'publishes the installed version and excludes unrelated local files' {
        Set-Content -LiteralPath (Join-Path $installed.FullName 'VideoScript.md') -Value 'local only'
        try {
            & (Join-Path $fixture 'PublishToGallery.ps1') -NuGetApiKey 'test-placeholder'
            Should -Invoke Publish-Module -Times 1 -Exactly -ParameterFilter {
                $Name -eq 'PSAIClairic' -and $RequiredVersion -eq '0.2.0' -and
                $Repository -eq 'PSGallery' -and $Exclude -contains 'VideoScript.md'
            }
            Test-Path -LiteralPath $installMarker | Should -BeTrue
            Test-Path -LiteralPath (Join-Path $installed.FullName 'VideoScript.md') | Should -BeTrue
        } finally {
            Remove-Item -LiteralPath (Join-Path $installed.FullName 'VideoScript.md')
        }
    }
    It 'does not install or publish with WhatIf' {
        & (Join-Path $fixture 'PublishToGallery.ps1') -NuGetApiKey 'test-placeholder' -WhatIf
        Test-Path -LiteralPath $installMarker | Should -BeFalse
        Should -Invoke Publish-Module -Times 0
    }
    It 'refuses to publish a different module resolved through PSModulePath' {
        Mock Get-Module { [pscustomobject]@{ Version=[version]'0.2.0'; ModuleBase='different-folder' } } -ParameterFilter { $ListAvailable -and $Name -eq 'PSAIClairic' }
        { & (Join-Path $fixture 'PublishToGallery.ps1') -NuGetApiKey 'test-placeholder' } | Should -Throw '*module-path ordering*'
        Should -Invoke Publish-Module -Times 0
    }
}
