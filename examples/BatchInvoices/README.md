# Extract a batch of invoices

Read a JSON array of invoice text, send each invoice to Clairic, and collect the extracted details in a PowerShell array. The six fictional invoices are in [invoices.json](invoices.json).

Run the [demo script](ExtractInvoices.ps1) from the project root:

```powershell
$invoiceDetails = @(./examples/BatchInvoices/ExtractInvoices.ps1)
$invoiceDetails
```

The script finds `invoices.json` beside itself, so it works from any current directory. Set your Cloudflare credentials before running it. A progress bar shows the current invoice, total count, and remaining invoices. It clears when processing finishes or fails. The script returns objects directly, so you can also pipe its output into other commands.

## Walkthrough

With your Cloudflare credentials set, run from this folder:

```powershell
Import-Module ../../PSAIClairic.psd1 -Force

$fields = [ordered]@{
    invoice_number = New-ClairicField -Type text -Instructions 'Invoice number'
    vendor         = New-ClairicField -Type text -Instructions 'Full vendor name'
    invoice_date   = New-ClairicField -Type date -Instructions 'Invoice issue date'
    due_date       = New-ClairicField -Type date -Instructions 'Issue date plus the net payment days'
    total          = New-ClairicField -Type number -Decimals 2 -Unit USD -Instructions 'Total amount due including shipping'
    po_number      = New-ClairicField -Type text -Instructions 'Purchase order number; null if not provided'
}

# Get-Content is PowerShell's cat command. -Raw reads the complete JSON file.
$invoices = Get-Content ./invoices.json -Raw | ConvertFrom-Json

$invoiceDetails = @(
    foreach ($invoice in $invoices) {
        Invoke-Clairic -State $invoice -Fields $fields |
            ConvertFrom-ClairicAnswer -FieldOrder $fields.Keys
    }
)

$invoiceDetails
```

`$invoiceDetails` is an array of six `PSCustomObject` results, one per invoice, in input order. Each object has the same ordered fields. Missing purchase order numbers should be null. The loop makes **six sequential API requests**, not a single batch API request.

To see the entire array as JSON:

```powershell
ConvertTo-Json -InputObject $invoiceDetails -Depth 5
```

Or keep working with the objects:

```powershell
$invoiceDetails.Count
$invoiceDetails | Where-Object total -GT 200
$invoiceDetails | Measure-Object total -Sum
```

The source facts give these checkable targets; actual model responses must be verified:

| Invoice | Vendor | Due date | Total (USD) | PO number |
| --- | --- | --- | --- | --- |
| INV-1001 | Northwind Supply | 2026-10-31 | 1080.00 | PO-7001 |
| INV-1002 | Alpine Office | 2026-10-18 | 205.00 | null |
| INV-1003 | Cedar Coffee | 2026-10-12 | 162.00 | PO-7003 |
| INV-1004 | Harbor Design | 2026-11-07 | 480.00 | null |
| INV-1005 | Maple Hardware | 2026-10-24 | 96.00 | PO-7005 |
| INV-1006 | Summit Support | 2026-10-22 | 350.00 | null |

The expected sum is USD 2,373.00. The value-only projection omits confidence and other response metadata; keep the full `Invoke-Clairic` response if you need that information.
