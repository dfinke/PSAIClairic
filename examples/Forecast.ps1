Import-Module (Join-Path $PSScriptRoot '../PSAIClairic.psd1') -Force

# Two forecast intervals: seven daily steps and four weekly steps.
$fields = [ordered]@{
    daily_orders = New-ClairicField -Type forecast -Min 0 -Max 250 -Step 1 -Horizon 7 -Interval day -Unit orders -Instructions 'Daily order count for October 20 through October 26, 2026, in chronological order'
    weekly_balance = New-ClairicField -Type forecast -Min 0 -Max 5000 -Step 50 -Horizon 4 -Interval week -Unit USD -Instructions 'Unpaid balance on October 27, November 3, November 10, and November 17, 2026, in chronological order'
}

$state = @'
Forecast origin: 2026-10-20 at 00:00 UTC.
Daily orders, oldest first:
2026-10-06: 91; 2026-10-07: 98; 2026-10-08: 103; 2026-10-09: 112;
2026-10-10: 63; 2026-10-11: 57; 2026-10-12: 89; 2026-10-13: 95;
2026-10-14: 101; 2026-10-15: 108; 2026-10-16: 117; 2026-10-17: 67;
2026-10-18: 61; 2026-10-19: 94.
No promotions, closures, or stock shortages are planned in the next week.

The unpaid balance is $5,000 on October 20. A customer says it plans to pay
$1,000 per week, starting October 27. Previous payments have sometimes been
one week late. There will be no new invoices during this four-week forecast.
'@

$state
''
$result = Invoke-Clairic -State $state -Fields $fields -ReferenceDate '2026-10-20'
$result | ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys

# Forecast answers expose a distribution for each step, not just a point value.
# JSON keeps the nested step statistics visible in the console.
foreach ($name in $fields.Keys) {
    Write-Host "`n$name - per-step distributions"
    $result.answers.$name.steps | ConvertTo-Json -Depth 20
}
