param(
    [Parameter(Position = 0)]
    [ValidateCount(1, 4)]
    [string[]]$ImagePath = @((Join-Path $PSScriptRoot 'receipt.png')),

    [string]$State = 'Read these images as one receipt. Inspect the entire receipt from the merchant heading through the final merchandise row before the subtotal. Copy complete visible names with their original spelling; do not abbreviate or summarize. Include every purchased item, including the last item before the subtotal. Do not invent missing or illegible information.'
)

Import-Module (Join-Path $PSScriptRoot '../PSAIClairic.psd1') -Force

# Pass local PNG, JPEG, or WebP files. Images are embedded in the request.
# Amounts use the receipt's currency, which is extracted separately.
$fields = [ordered]@{
    vendor        = New-ClairicField -Type text -Instructions 'Complete merchant or store name from the receipt heading, including every word in that name. Copy the full name exactly as printed, not just its first word. Exclude slogans and sample/demo labels.'
    receipt_date  = New-ClairicField -Type date -Instructions 'Receipt transaction date'
    total         = New-ClairicField -Type number -Decimals 2 -Instructions 'Final receipt total including tax; exclude cash tendered and change'
    tax           = New-ClairicField -Type number -Decimals 2 -Instructions 'Tax amount explicitly printed on the receipt; null if absent'
    currency      = New-ClairicField -Type text -Instructions 'Currency code, name, or symbol explicitly printed on the receipt; null if absent'
    items         = New-ClairicField -Type list -Items text -Instructions 'Every purchased merchandise item description, one list entry per item row, in top-to-bottom receipt order. Copy each complete description exactly as printed, preserving all letters and words; do not shorten, paraphrase, merge rows, or omit the final item before the subtotal. Exclude quantities and prices from descriptions. Exclude headings, subtotal, tax, total, payment details, and footer text.'
}

Invoke-Clairic -ImagePath $ImagePath -State $State -Fields $fields |
    ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys
