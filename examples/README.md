# Clairic examples

Run these scripts with PowerShell 7.2 or later. Set `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_AUTH_TOKEN` in your session first. Each script makes one live request and prints its source text followed by ordered results.

| Script | Field types and behavior |
| --- | --- |
| `Invoice.ps1` | Text, date, number, text list, estimate; invoice extraction and arithmetic |
| `Appointment.ps1` | Text, date, time, datetime, duration, number; year anchoring, elapsed time, labor cost, and a missing technician |
| `Lists.ps1` | List of text, numbers, and dates; an empty list when no phone numbers are present |
| `Estimates.ps1` | Numeric and date estimates, logarithmic scale, quantiles, and middle 80% prediction intervals |
| `Forecast.ps1` | Seven daily steps and four weekly steps; prints nested per-step distributions |

From the project root:

```powershell
.\examples\Appointment.ps1
.\examples\Lists.ps1
.\examples\Estimates.ps1
.\examples\Forecast.ps1
```

Together these exercise all nine field types: `text`, `number`, `date`, `time`, `datetime`, `duration`, `list`, `estimate`, and `forecast`.

Appointment facts provide checkable targets: December 4 resolves to 2026-12-04, the visit is 90 minutes, labor is USD 180, and the technician is missing. List targets are the three names, three amounts, three dates, and an empty phone list. Model formatting and accuracy still require checking. Estimates and forecasts have no fixed expected answer: supplied history informs uncertain predictions, and bounds restrict the requested output range.

`ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys` projects values into a `PSCustomObject`. Estimates and forecasts also retain `$result` so you can inspect uncertainty metadata. To retain the variables after a script finishes, dot-source it (for example, `. .\examples\Estimates.ps1`). No preview switches are added to these examples.
