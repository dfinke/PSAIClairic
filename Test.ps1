# Requires Pester 5. Disables Pester's unused Windows registry fixture.
Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
$config = New-PesterConfiguration
$config.Run.Path = Join-Path $PSScriptRoot 'tests'
$config.Run.PassThru = $true
$config.TestRegistry.Enabled = $false
$config.Output.Verbosity = 'Detailed'
$result = Invoke-Pester -Configuration $config
if ($result.FailedCount -gt 0 -or $result.FailedContainersCount -gt 0) { throw 'PSAIClairic tests failed.' }
