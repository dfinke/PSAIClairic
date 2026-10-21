# Clairic examples

Run these scripts with PowerShell 7.2 or later. Set `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_AUTH_TOKEN` in your session first. Each standalone script makes one live request and returns ordered results. The BatchInvoices walkthrough makes one request per invoice. Text examples also print their source text.

| Script | Field types and behavior |
| --- | --- |
| [BatchInvoices](BatchInvoices/README.md) | Read six invoices from JSON, loop through Clairic, and collect an array of typed invoice details |
| `Invoice.ps1` | Text, date, number, text list, estimate; invoice extraction and arithmetic |
| `Appointment.ps1` | Text, date, time, datetime, duration, number; year anchoring, elapsed time, labor cost, and a missing technician |
| `Lists.ps1` | List of text, numbers, and dates; an empty list when no phone numbers are present |
| `Estimates.ps1` | Numeric and date estimates, logarithmic scale, quantiles, and middle 80% prediction intervals |
| `ReceiptImage.ps1` | Local receipt images: merchant, transaction date, total, tax, currency, and item descriptions |
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

## Receipt images

Run with the bundled fictional `receipt.png`, or supply your own local PNG, JPEG, or WebP image. Credentials are not bundled. The sample was created with the built-in image generation tool: a crisp, front-on fictional Northwind Market receipt with exact item text and checkable totals.

```powershell
# Uses receipt.png beside the script, regardless of your working directory.
.\examples\ReceiptImage.ps1

.\examples\ReceiptImage.ps1 -ImagePath 'D:\receipts\receipt.png'

# Multiple images must belong to the same receipt (for example, two halves).
.\examples\ReceiptImage.ps1 -ImagePath './receipt-top.jpg', './receipt-bottom.jpg'

# Optional text context accompanies the image.
.\examples\ReceiptImage.ps1 -State 'Read this receipt. The date format is day/month/year.'
```

Up to four images, 4 MiB each and 8 MiB combined decoded; remote URLs are not supported. Missing scalar facts may return null. Verify extracted amounts and dates against the original receipt.

The bundled sample contains these checkable facts:

| Field | Expected fact |
| --- | --- |
| Vendor | NORTHWIND MARKET |
| Receipt date | 2026-10-20 |
| Total | 23.76 |
| Tax | 1.76 |
| Currency | USD |
| Items | Coffee Beans; Sourdough Bread; Apples |

Item amounts are 12.00, 6.00, and 4.00; subtotal is 22.00. The sample is labeled fictional and not valid. These are verification targets rather than guaranteed outputs; observed live-run errors are documented below.

### Observed image extraction issue

Two user-reported live runs against the bundled `receipt.png` on October 20, 2026 returned correct dates, amounts, and currency, but incomplete or incorrect receipt text. Sharpening the instructions to request complete names and every merchandise row did not resolve the errors in the second run.

| Field | Printed on the receipt | Latest reported result |
| --- | --- | --- |
| Vendor | `NORTHWIND MARKET` | `NORTHW MARKET` |
| Bread description | `Sourdough Bread` | `Sdough Bread` |
| Final merchandise item | `Apples` | Missing from the items list |

The first run returned `NORTHWIND` for the vendor and had the same bread truncation and missing Apples. Both reported runs returned receipt date `2026-10-20`, total `23.76`, tax `1.76`, and currency `USD` correctly.

The example remains a direct image-to-typed-fields demonstration of Clairic's vision capability, with no separate OCR stage or hard-coded answer corrections. These observations concern this sample and these runs; the underlying cause has not been established. Valid typed output did not ensure accurate or complete text extraction. Compare results with the image and the expected-facts table above when evaluating this example.
