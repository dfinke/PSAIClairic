Set-StrictMode -Version Latest

function New-ClairicField {
    <#
    .SYNOPSIS
    Creates a typed Clairic field definition.
    .EXAMPLE
    New-ClairicField -Type number -Unit USD -Decimals 2 -Instructions 'Total including shipping'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('text','number','date','time','datetime','duration','list','estimate','forecast')][string]$Type,
        [string]$Instructions,
        [string]$Unit,
        [switch]$Integer,
        [ValidateRange(0,6)][int]$Decimals,
        [ValidateSet('text','number','date')][string]$Items,
        [object]$Min,
        [object]$Max,
        [object]$Step,
        [ValidateSet('linear','log')][string]$Scale,
        [ValidateRange(0.0000000001,1)][double]$NullThreshold,
        [ValidateRange(1,64)][int]$Horizon,
        [ValidateSet('step','minute','hour','day','week','month','quarter','year')][string]$Interval
    )
    $field = @{ type = $Type.ToLowerInvariant() }
    $names = @{ Instructions='instructions'; Unit='unit'; Integer='integer'; Decimals='decimals'; Items='items'; Min='min'; Max='max'; Step='step'; Scale='scale'; NullThreshold='null_threshold'; Horizon='horizon'; Interval='interval' }
    foreach ($name in $names.Keys) {
        if ($PSBoundParameters.ContainsKey($name)) {
            $value = $PSBoundParameters[$name]
            if ($name -eq 'Integer') { $value = [bool]$value }
            $field[$names[$name]] = $value
        }
    }
    Assert-ClairicField -Name field -Field $field
    return $field
}

function Assert-ClairicField {
    param([string]$Name, [object]$Field)
    if ($Name -cnotmatch '^[A-Za-z_][A-Za-z0-9_.\-]{0,63}$') { throw "Invalid field name '$Name'. Use 1-64 letters, digits, underscores, dots or hyphens; start with a letter or underscore." }
    if ($Field -isnot [System.Collections.IDictionary]) { throw "Field '$Name' must be a hashtable or dictionary." }
    # Use the vendored official schema for both helpers and caller-supplied fields.
    $fieldSchema = $script:InputSchema.properties.fields.additionalProperties | ConvertTo-Json -Depth 50
    $json = ConvertTo-Json -InputObject $Field -Depth 50 -Compress
    if (-not (Test-Json -Json $json -Schema $fieldSchema -ErrorAction SilentlyContinue)) { throw "Field '$Name' does not match the Clairic field schema." }
    $type = $Field['type']
    if ($type -eq 'list' -and -not $Field.Contains('items')) { throw "List field '$Name' requires items." }
    if ($type -in @('estimate','forecast')) {
        foreach ($key in @('min','max')) {
            if (-not $Field.Contains($key) -or $null -eq $Field[$key]) { throw "Field '$Name' requires $key." }
        }
        $lower = 0.0; $upper = 0.0
        $numeric = [double]::TryParse([string]$Field['min'], [Globalization.NumberStyles]::Float, [cultureinfo]::InvariantCulture, [ref]$lower) -and
            [double]::TryParse([string]$Field['max'], [Globalization.NumberStyles]::Float, [cultureinfo]::InvariantCulture, [ref]$upper)
        if ($numeric) {
            if (-not [double]::IsFinite($lower) -or -not [double]::IsFinite($upper) -or $lower -ge $upper) { throw "Field '$Name' requires finite min < max." }
            if ($Field['scale'] -eq 'log' -and $lower -le 0) { throw "Log field '$Name' requires min > 0." }
        } else {
            $dateMin = [datetime]::MinValue; $dateMax = [datetime]::MinValue
            if (-not [datetime]::TryParseExact([string]$Field['min'],'yyyy-MM-dd',[cultureinfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$dateMin) -or
                -not [datetime]::TryParseExact([string]$Field['max'],'yyyy-MM-dd',[cultureinfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$dateMax) -or $dateMin -ge $dateMax) { throw "Field '$Name' requires numeric bounds or ISO dates with min < max." }
        }
        if ($Field.Contains('step') -and $Field['step'] -notin @('month','year')) {
            $stepValue = 0.0
            if (-not [double]::TryParse([string]$Field['step'], [Globalization.NumberStyles]::Float, [cultureinfo]::InvariantCulture, [ref]$stepValue) -or -not [double]::IsFinite($stepValue) -or $stepValue -le 0) { throw "Field '$Name' requires a positive step, 'month', or 'year'." }
        }
    }
}

function Invoke-Clairic {
    <#
    .SYNOPSIS
    Sends a typed extraction request to Cloudflare Workers AI Clairic.
    .DESCRIPTION
    Uses CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_AUTH_TOKEN by default. Returns the
    complete result including uncertainty and usage metadata. PreviewRequest
    builds the JSON without credentials or a network request.
    .EXAMPLE
    Invoke-Clairic -State 'Invoice A123. Total USD 10.' -Fields @{ total = @{ type='number'; unit='USD' } }
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)][AllowEmptyString()][string]$State = '',
        [Parameter(Mandatory)][System.Collections.IDictionary]$Fields,
        [string[]]$ImagePath,
        [string]$ReferenceDate,
        [switch]$IncludeQuantiles,
        [switch]$ReturnStateText,
        [string]$AccountId = $env:CLOUDFLARE_ACCOUNT_ID,
        [string]$ApiToken = $env:CLOUDFLARE_AUTH_TOKEN,
        [ValidateRange(1,1800)][int]$TimeoutSec = 120,
        [switch]$PreviewRequest
    )
    process {
        if ($Fields.Count -eq 0) { throw 'At least one field is required.' }
        foreach ($name in $Fields.Keys) { Assert-ClairicField -Name $name -Field $Fields[$name] }
        $body = @{ model='clairic'; state=$State; fields=$Fields }
        if ($PSBoundParameters.ContainsKey('ReferenceDate')) {
            $parsedDate = [datetime]::MinValue
            if (-not [datetime]::TryParseExact($ReferenceDate,'yyyy-MM-dd',[cultureinfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$parsedDate)) { throw 'ReferenceDate must be an ISO date (yyyy-MM-dd).' }
            $body.reference_date = $ReferenceDate
        }
        if ($IncludeQuantiles -or $ReturnStateText) { $body.options = @{ include_quantiles=[bool]$IncludeQuantiles; return_state_text=[bool]$ReturnStateText } }
        if ($ImagePath -and $ImagePath.Count -gt 4) { throw 'At most four images are allowed.' }
        $images = @(); $totalBytes = 0L
        foreach ($path in $ImagePath) {
            $file = Get-Item -LiteralPath $path -ErrorAction Stop
            if ($file.PSIsContainer -or $file.Length -gt 4MB) { throw 'Each image must be a file no larger than 4 MiB.' }
            $contentType = switch ($file.Extension.ToLowerInvariant()) {
                '.png' { 'image/png' }; '.jpg' { 'image/jpeg' }; '.jpeg' { 'image/jpeg' }; '.webp' { 'image/webp' }
                default { throw 'Only PNG, JPEG and WebP image files are supported.' }
            }
            $bytes = [IO.File]::ReadAllBytes($file.FullName)
            $totalBytes += $bytes.Length
            if ($totalBytes -gt 8MB) { throw 'Combined decoded images exceed 8 MiB.' }
            $images += @{ content_type=$contentType; base64=[Convert]::ToBase64String($bytes) }
        }
        if ($images.Count) { $body.images = $images }
        if ([string]::IsNullOrWhiteSpace($State) -and $images.Count -eq 0) { throw 'Provide non-empty State or at least one image.' }
        $json = ConvertTo-Json -InputObject $body -Depth 50 -Compress
        $requestBytes = [Text.Encoding]::UTF8.GetBytes($json)
        if ($requestBytes.Length -gt 16MB) { throw 'Request body exceeds 16 MiB.' }
        if ($PreviewRequest) { return $json }
        if ($AccountId -cnotmatch '^[a-fA-F0-9]{32}$') { throw 'Set CLOUDFLARE_ACCOUNT_ID or supply a 32-character hexadecimal AccountId.' }
        if ([string]::IsNullOrWhiteSpace($ApiToken)) { throw 'Set CLOUDFLARE_AUTH_TOKEN or supply ApiToken.' }
        $uri = "https://api.cloudflare.com/client/v4/accounts/$AccountId/ai/run/@cf/cloudflare/clairic"
        try {
            $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{ Authorization="Bearer $ApiToken" } -ContentType 'application/json; charset=utf-8' -Body $requestBytes -TimeoutSec $TimeoutSec -ErrorAction Stop
        } catch {
            # Do not include request headers, response bodies or credentials in errors.
            $status = $null
            if ($_.Exception.PSObject.Properties['Response'] -and $_.Exception.Response) { $status = [int]$_.Exception.Response.StatusCode }
            $message = if ($status) { "Clairic HTTP request failed (status $status). Check Cloudflare permissions, quota and request fields." } else { 'Clairic request failed. Check connectivity and timeout settings.' }
            throw [InvalidOperationException]::new($message)
        }
        if ($null -eq $response) { throw 'Cloudflare returned an empty response.' }
        if ($response.PSObject.Properties['success']) {
            if (-not $response.success) { throw 'Cloudflare reported an unsuccessful Clairic request.' }
            if (-not $response.PSObject.Properties['result']) { throw 'Cloudflare response is missing result.' }
            $response = $response.result
        }
        if ($null -eq $response -or -not $response.PSObject.Properties['answers']) { throw 'Clairic response is missing answers.' }
        if ($response.PSObject.Properties['truncated'] -and $response.truncated) { Write-Warning 'Clairic truncated the input. Review results before use.' }
        return $response
    }
}

function ConvertFrom-ClairicAnswer {
    <#
    .SYNOPSIS
    Projects a Clairic result into an object containing field values only.
    .DESCRIPTION
    Explicit convenience projection. Discards confidence, spans and usage; keep
    the original response when evaluating uncertainty. Preserves null values.
    FieldOrder places named fields first; remaining fields retain response order.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)][psobject]$InputObject,
        [string[]]$FieldOrder
    )
    process {
        if (-not $InputObject.PSObject.Properties['answers']) { throw 'Input must be a Clairic result containing answers.' }
        $values = [ordered]@{}
        foreach ($name in $FieldOrder) {
            $property = $InputObject.answers.PSObject.Properties[$name]
            if ($null -eq $property) { throw "Answer field '$name' does not exist." }
            $values[$name] = $property.Value.value
        }
        foreach ($property in $InputObject.answers.PSObject.Properties) {
            if (-not $values.Contains($property.Name)) { $values[$property.Name] = $property.Value.value }
        }
        [pscustomobject]$values
    }
}

$script:InputSchema = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'schemas/schema-input.json') -Raw | ConvertFrom-Json
Export-ModuleMember -Function New-ClairicField, Invoke-Clairic, ConvertFrom-ClairicAnswer
