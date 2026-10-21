<p align="center">
  <img src="assets/psaiclairic-icon.png" alt="PSAIClairic: documents transformed into typed values and forecasts" width="180">
</p>

# PSAIClairic

**Turn messy text into PowerShell objects—with the uncertainty still attached.**

An invoice arrives as a paragraph. A service visit hides dates, times, and costs in a note. A payment forecast needs more than a single guess. PSAIClairic turns those inputs into typed answers you can pipe, inspect, and use in your scripts.

Define what you need. Give Clairic the facts. Get PowerShell objects back.

```powershell
Import-Module PSAIClairic

$fields = [ordered]@{
    invoice_number = New-ClairicField -Type text
    total = New-ClairicField -Type number -Unit USD -Decimals 2 -Instructions 'Amount due including shipping'
    due_date = New-ClairicField -Type date -Instructions 'Issue date plus payment terms'
}

Invoke-Clairic -State 'Invoice INV-2291 issued 2026-09-02, net 30. 4 pallets at $250 each plus $80 shipping.' -Fields $fields |
    ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys
```

The facts in this example determine invoice `INV-2291`, total `1080`, and due date `2026-10-02`. Model answers still need checking.

## What you can do

- **Extract** names, amounts, dates, times, timestamps, durations, and lists from text or images.
- **Compute** values from supplied facts, such as invoice totals or elapsed time.
- **Estimate** unknown numbers or dates with prediction intervals and optional quantiles.
- **Forecast** a sequence of values with uncertainty for each step.
- **Keep control** with typed fields, bounds, precision, units, and explicit handling of missing information.

PowerShell 7.2 or later. No extra runtime modules. Powered by Cloudflare Workers AI's preview [Clairic model](https://developers.cloudflare.com/workers-ai/models/clairic/).

## Install

From PowerShell Gallery:

```powershell
Install-Module PSAIClairic -Scope CurrentUser
Import-Module PSAIClairic
```

The Gallery command is available after the first package is published. To use the public GitHub checkout before then, or develop the module locally, install from source below.

## Install from source

```powershell
git clone https://github.com/dfinke/PSAIClairic.git
Set-Location PSAIClairic
./InstallModule.ps1
Import-Module PSAIClairic
```

The installer copies only manifest-listed package files into your current user's versioned PowerShell module directory. Git metadata, tests, publishing scripts, credentials, and local notes are excluded. It does not require administrator access or remove unrelated files. Use `-WhatIf` to inspect the destination, or `-FullPath` to choose a module directory explicitly.

To work directly from the checkout:

```powershell
Import-Module ./PSAIClairic.psd1 -Force
```

## Connect to Cloudflare

Set these environment variables in your current session using your own account ID and a token with Workers AI Read permission:

```powershell
$env:CLOUDFLARE_ACCOUNT_ID = '<your 32-character account ID>'
$env:CLOUDFLARE_AUTH_TOKEN = '<your API token>'
```

`Invoke-Clairic` also accepts `-AccountId` and `-ApiToken`. Keep real tokens out of source files and commits. Live requests use your Cloudflare account and may incur charges. See Cloudflare's [REST setup guide](https://developers.cloudflare.com/workers-ai/get-started/rest-api/).

## Try the examples

Each example makes one live request and returns ordered results. Text examples also print their source text. Run from the checkout root after setting your credentials, or use the installed module folder:

```powershell
Set-Location (Get-Module PSAIClairic -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).ModuleBase
./examples/Invoice.ps1
```

| Example | What it exercises |
| --- | --- |
| `./examples/Invoice.ps1` | Invoice extraction, total calculation, due date, missing PO number, contacts, and payment estimate |
| `./examples/Appointment.ps1` | Text, number, date, time, datetime, duration, and a missing technician |
| `./examples/Lists.ps1` | Text, number, and date lists, including an empty-list case |
| `./examples/Estimates.ps1` | Numeric and date estimates, logarithmic scale, quantiles, and prediction intervals |
| `./examples/ReceiptImage.ps1` | Bundled sample receipt (or your own image): merchant, date, total, tax, currency, and items |
| `./examples/Forecast.ps1` | Daily and weekly forecasts with per-step distributions |

Together they cover **all nine field types**. See the [examples guide](examples/README.md) for expected facts and interpretation. Estimates and forecasts retain `$result` for uncertainty inspection; dot-source those scripts if you want their variables available afterward.

## Three commands, one pipeline

| Command | Purpose |
| --- | --- |
| `New-ClairicField` | Build a typed field definition with instructions and constraints |
| `Invoke-Clairic` | Send text and/or local images; return the full model result |
| `ConvertFrom-ClairicAnswer` | Project answer values into a `PSCustomObject`, optionally ordering fields |

### Define your fields

Use `New-ClairicField` or nested hashtables. Field names start with a letter or underscore and contain up to 64 letters, digits, underscores, dots, or hyphens.

| Type | Example definition |
| --- | --- |
| `text` | `New-ClairicField -Type text -Instructions 'Customer name'` |
| `number` | `New-ClairicField -Type number -Unit USD -Decimals 2` |
| `date` | `New-ClairicField -Type date -Instructions 'Payment deadline'` |
| `time` | `New-ClairicField -Type time -Instructions 'Start time'` |
| `datetime` | `New-ClairicField -Type datetime -Instructions 'Timestamp in UTC'` |
| `duration` | `New-ClairicField -Type duration -Unit minutes -Integer` |
| `list` | `New-ClairicField -Type list -Items text` |
| `estimate` | `New-ClairicField -Type estimate -Min 0 -Max 120 -Step 1` |
| `forecast` | `New-ClairicField -Type forecast -Min 0 -Max 5000 -Horizon 4 -Interval week` |

List item types are `text`, `number`, and `date`. Estimates and forecasts require `Min` and `Max`; date estimates accept ISO date bounds. Other settings include `Instructions`, `Unit`, `Integer`, `Decimals` (0–6), `Step`, `Scale` (`linear`/`log`), `NullThreshold`, and forecast `Interval`. Use settings relevant to the field type. Logarithmic estimates require a positive minimum.

### Supply text or images

```powershell
# Read a whole document as one input.
Get-Content ./invoice.txt -Raw | Invoke-Clairic -Fields $fields

# Embed local images; remote image URLs are not accepted.
Invoke-Clairic -ImagePath ./invoice.png -Fields $fields -ReturnStateText

# Anchor dates that omit a year and request estimate quantiles.
Invoke-Clairic -State $state -Fields $fields -ReferenceDate '2026-10-20' -IncludeQuantiles
```

### Choose how much of the answer to keep

```powershell
$result = Invoke-Clairic -State $state -Fields $fields
$result.answers  # Values, source spans, confidence, or prediction statistics
$result.usage    # Token usage and pass count

# Value-only object, in your field-definition order.
$result | ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys
```

`FieldOrder` places named fields first and appends remaining answers in response order. Unknown names raise an error. Null values and arrays are preserved. The projection discards metadata, so keep the original result when assessing uncertainty.

## Interpreting results

Missing scalar facts can return `null`; missing list matches can return an empty list. Read `value` rather than an alternative `guess`. Extracted text includes character offsets into the source; `-ReturnStateText` requests the text those offsets index.

Estimates include statistics such as `median`, `p10`, and `p90`. The interval from p10 to p90 covers the middle 80% of the predicted distribution; it does not guarantee that the outcome falls there. Forecast answers include an estimate for each step. Typed output and confidence scores do not guarantee correctness. Check results against evidence before consequential actions.

## Limits and request behavior

- Up to four PNG, JPEG, or WebP files: 4 MiB each and 8 MiB total decoded.
- Maximum JSON request size: 16 MiB.
- Field validation uses the bundled official input schema plus checks for required list and estimate settings. Cloudflare performs additional semantic validation.
- Requests time out after 120 seconds by default; set `-TimeoutSec` to override.
- Requests are not automatically retried. Input truncation emits a warning.
- For local request inspection, the module supports `Invoke-Clairic ... -PreviewRequest`; it returns JSON without credentials or a network call.

Clairic is a preview service; availability, pricing, and behavior can change. Consult the [model reference](https://developers.cloudflare.com/workers-ai/models/clairic/) for current details. Bundled schemas were retrieved October 20, 2026.

## Publishing

Run from a source checkout with PowerShellGet installed and a PowerShell Gallery API key authorized to publish PSAIClairic:

```powershell
# Inspects the action without installing or publishing.
./PublishToGallery.ps1 -NuGetApiKey $NuGetApiKey -WhatIf

# Installs the package files, then publishes that installed version.
./PublishToGallery.ps1 -NuGetApiKey $NuGetApiKey
```

The helper runs `InstallModule.ps1`, verifies that the installed version resolves through `PSModulePath`, and publishes by module name and exact version. The installer copies only `FileList` entries; the publisher also excludes any installed files outside that list. This keeps Git files, tests, helper scripts, secrets, and local notes such as `VideoScript.md` out of the package. Unrelated installed files are preserved locally. The API key is supplied at runtime and must not be committed.

## Development

With Pester 5 installed:

```powershell
./Test.ps1
```

The tests mock network calls and incur no inference charges. Example requests have also been checked offline against the input schema and exercised with mocked responses across all nine types. Live permissions and prediction quality require authenticated integration testing.

See [CHANGELOG.md](CHANGELOG.md) for changes. This module is licensed under the [MIT License](LICENSE); Cloudflare's service and model terms apply separately.
