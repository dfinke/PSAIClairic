#Requires -Version 7.2
Import-Module (Join-Path $PSScriptRoot '../../PSAIClairic.psd1') -Force

$fields = [ordered]@{
    invoice_number = New-ClairicField -Type text -Instructions 'Invoice number'
    vendor         = New-ClairicField -Type text -Instructions 'Full vendor name'
    invoice_date   = New-ClairicField -Type date -Instructions 'Invoice issue date'
    due_date       = New-ClairicField -Type date -Instructions 'Issue date plus the net payment days'
    total          = New-ClairicField -Type number -Decimals 2 -Unit USD -Instructions 'Total amount due including shipping'
    po_number      = New-ClairicField -Type text -Instructions 'Purchase order number; null if not provided'
}

$invoices = @(Get-Content (Join-Path $PSScriptRoot 'invoices.json') -Raw | ConvertFrom-Json)

$invoiceDetails = @(
    try {
        for ($index = 0; $index -lt $invoices.Count; $index++) {
            Write-Progress -Id 1 -Activity 'Extracting invoice details' `
                -Status "Invoice $($index + 1) of $($invoices.Count) - $($invoices.Count - $index - 1) remaining after this one" `
                -PercentComplete ([int](100 * $index / $invoices.Count))

            Invoke-Clairic -State $invoices[$index] -Fields $fields | ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys
        }
    }
    finally {
        Write-Progress -Id 1 -Activity 'Extracting invoice details' -Completed
    }
)

$invoiceDetails
