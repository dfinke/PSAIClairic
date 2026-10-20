param(
    [Parameter(Mandatory, Position = 0)]
    [ValidateCount(1, 4)]
    [string[]]$ImagePath,

    [string]$State = 'Read these images as one receipt. Extract the requested fields from visible receipt content; do not invent missing information.'
)

Import-Module (Join-Path $PSScriptRoot '../PSAIClairic.psd1') -Force

# Pass local PNG, JPEG, or WebP files. Images are embedded in the request.
# Amounts use the receipt's currency, which is extracted separately.
$fields = [ordered]@{
    vendor        = New-ClairicField -Type text -Instructions 'Merchant name printed on the receipt'
    receipt_date  = New-ClairicField -Type date -Instructions 'Receipt transaction date'
    total         = New-ClairicField -Type number -Decimals 2 -Instructions 'Final receipt total including tax; exclude cash tendered and change'
    tax           = New-ClairicField -Type number -Decimals 2 -Instructions 'Tax amount explicitly printed on the receipt; null if absent'
    currency      = New-ClairicField -Type text -Instructions 'Currency code, name, or symbol explicitly printed on the receipt; null if absent'
    items         = New-ClairicField -Type list -Items text -Instructions 'Purchased item descriptions in receipt order; exclude totals, tax, payment details, and headers'
}

Invoke-Clairic -ImagePath $ImagePath -State $State -Fields $fields |
    ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys
