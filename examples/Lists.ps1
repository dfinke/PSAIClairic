Import-Module (Join-Path $PSScriptRoot '../PSAIClairic.psd1') -Force

# All three supported list item types, plus an empty-list case.
$fields = [ordered]@{
    attendees       = New-ClairicField -Type list -Items text -Instructions 'Attendee names, in the order listed'
    invoice_amounts = New-ClairicField -Type list -Items number -Decimals 2 -Unit USD -Instructions 'The three invoice amounts, in the order listed; omit invoice identifiers'
    review_dates    = New-ClairicField -Type list -Items date -Instructions 'Review dates, in chronological order'
    phone_numbers   = New-ClairicField -Type list -Items text -Instructions 'Phone numbers explicitly present in the input; empty list if none'
}

$state = @'
Attendees: Dana Ruiz, Priya Shah, Morgan Chen.
Invoices: A101 is $125.50; A102 is $80.00; A103 is $249.99.
Reviews are scheduled for 2026-11-02, 2026-11-09, and 2026-11-16.
Contact details have not been supplied.
'@

$state
''
Invoke-Clairic -State $state -Fields $fields |
    ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys
