@{
    RootModule = 'PSAIClairic.psm1'
    ModuleVersion = '0.2.0'
    GUID = '761113bd-65b6-441b-b030-156de27b0dce'
    Author = 'Doug Finke'
    Copyright = '(c) 2026 Doug Finke. All rights reserved.'
    Description = 'Turn text and images into typed PowerShell objects with Cloudflare Clairic: extraction, computation, estimates, forecasts, and uncertainty metadata.'
    PowerShellVersion = '7.2'
    CompatiblePSEditions = @('Core')
    FunctionsToExport = @('New-ClairicField', 'Invoke-Clairic', 'ConvertFrom-ClairicAnswer')
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    FileList = @(
        'PSAIClairic.psd1'
        'PSAIClairic.psm1'
        'schemas/schema-input.json'
        'schemas/schema-output.json'
        'examples/Invoice.ps1'
        'examples/Appointment.ps1'
        'examples/Lists.ps1'
        'examples/Estimates.ps1'
        'examples/Forecast.ps1'
        'examples/ReceiptImage.ps1'
        'examples/receipt.png'
        'examples/BatchInvoices/ExtractInvoices.ps1'
        'examples/BatchInvoices/invoices.json'
        'examples/BatchInvoices/README.md'
        'examples/README.md'
        'assets/psaiclairic-icon.png'
        'README.md'
        'CHANGELOG.md'
        'LICENSE'
    )
    PrivateData = @{
        PSData = @{
            Tags = @('Cloudflare', 'WorkersAI', 'Clairic', 'AI', 'Extraction', 'Forecasting')
            ProjectUri = 'https://github.com/dfinke/PSAIClairic'
            LicenseUri = 'https://github.com/dfinke/PSAIClairic/blob/main/LICENSE'
            ReleaseNotes = '0.2.0: Typed extraction, computation, estimates and forecasts; ordered PowerShell objects; examples for all nine types and receipt images; documented vision limitations; MIT license; package-only installation and publishing. See CHANGELOG.md.'
        }
    }
}
