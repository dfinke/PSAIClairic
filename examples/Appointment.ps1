Import-Module (Join-Path $PSScriptRoot '../PSAIClairic.psd1') -Force

# Six scalar types: extraction, computation, and a deliberately missing value.
$fields = [ordered]@{
    customer       = New-ClairicField -Type text -Instructions 'Customer name'
    appointment    = New-ClairicField -Type date -Instructions 'Date of the service visit'
    start_time     = New-ClairicField -Type time -Instructions 'Scheduled start time in 24-hour format'
    confirmed_at   = New-ClairicField -Type datetime -Instructions 'Confirmation timestamp in UTC'
    visit_minutes  = New-ClairicField -Type duration -Unit minutes -Integer -Instructions 'Elapsed time between the scheduled start and end'
    labor_total    = New-ClairicField -Type number -Unit USD -Decimals 2 -Instructions 'Visit duration in hours multiplied by hourly labor rate; exclude parts'
    technician     = New-ClairicField -Type text -NullThreshold 0.5 -Instructions 'Assigned technician name; null when not stated'
}

$state = @'
Customer: Morgan Chen.
Service visit: December 4, from 09:15 to 10:45, all times UTC.
Confirmation recorded at 2026-11-30T16:20:00Z.
Labor is $120 per hour. Parts will be invoiced separately.
No technician has been assigned yet.
'@

# Checkable results: 2026-12-04, 09:15, 90 minutes, $180 labor, null technician.
$state
''
Invoke-Clairic -State $state -Fields $fields -ReferenceDate '2026-12-01' |
    ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys
