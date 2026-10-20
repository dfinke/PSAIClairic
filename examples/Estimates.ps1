Import-Module (Join-Path $PSScriptRoot '../PSAIClairic.psd1') -Force

# Numeric, ISO-date, and logarithmic estimates. These predict unknown outcomes.
$fields = [ordered]@{
    days_to_pay = New-ClairicField -Type estimate -Min 0 -Max 90 -Step 1 -Instructions 'Days after the current invoice issue date until it is paid'
    payment_date = New-ClairicField -Type estimate -Min '2026-10-21' -Max '2027-01-18' -Step 1 -Instructions 'Predicted payment date for the current invoice'
    repair_cost = New-ClairicField -Type estimate -Min 10 -Max 10000 -Scale log -Unit USD -Instructions 'Predicted total repair cost for the described equipment fault'
}

$state = @'
As of 2026-10-20, customer Northwind has an unpaid $1,080 invoice issued today,
with net-30 terms. Its six previous invoices were paid 25, 28, 30, 30, 32,
and 35 days after issue. The customer reports no dispute or payment hold.

Separately, a warehouse label printer has intermittent paper feed failures.
Previous similar repairs cost $85, $120, $150, $190, and $260.
A rare controller replacement can cost $1,500. No diagnosis has been made.
'@

$state
''
$result = Invoke-Clairic -State $state -Fields $fields -ReferenceDate '2026-10-20' -IncludeQuantiles
$result | ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys

# Retain uncertainty rather than treating the predicted value as a known fact.
# Each answer also contains the 99 percentiles requested with IncludeQuantiles.
foreach ($name in $fields.Keys) {
    $answer = $result.answers.$name
    [pscustomobject][ordered]@{
        Field  = $name
        Median = $answer.median
        P10    = $answer.p10
        P90    = $answer.p90
    }
}
