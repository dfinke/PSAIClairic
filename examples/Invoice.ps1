Import-Module (Join-Path $PSScriptRoot '../PSAIClairic.psd1') -Force

$fields = [ordered]@{
    invoice_number = New-ClairicField -Type text
    due_date       = New-ClairicField -Type date -Instructions 'Issue date plus the net payment days'
    days_to_pay    = New-ClairicField -Type estimate -Min 0 -Max 120 -Step 1 -Instructions 'Days after issue until this invoice is paid'
    total          = New-ClairicField -Type number -Decimals 2 -Unit USD -Instructions 'Amount due including shipping'
    po_number      = New-ClairicField -Type text -Instructions 'Purchase order number'
    contacts       = New-ClairicField -Type list -Items text    
}


$state = @'
Invoice INV-2291 from Northwind Supply, issued 2026-09-02, net 30. 
4 pallets at $250.00 each, shipping $80.00.
Contact: Dana Ruiz, Priya Shah.
'@

$state
''
Invoke-Clairic -State $state -Fields $fields |
ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys