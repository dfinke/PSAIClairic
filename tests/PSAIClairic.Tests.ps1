BeforeDiscovery {
    Import-Module (Join-Path $PSScriptRoot '../PSAIClairic.psd1') -Force
}
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../PSAIClairic.psd1') -Force
}

Describe 'Clairic request validation' {
    It 'creates all nine supported types' {
        foreach ($type in @('text','number','date','time','datetime','duration')) {
            (New-ClairicField -Type $type).type | Should -Be $type
        }
        (New-ClairicField -Type list -Items text).items | Should -Be text
        (New-ClairicField -Type estimate -Min 0 -Max 120 -Step 1).max | Should -Be 120
        (New-ClairicField -Type forecast -Min 0 -Max 100 -Horizon 4 -Interval week).horizon | Should -Be 4
    }
    It 'requires list items and estimate bounds' {
        { New-ClairicField -Type list } | Should -Throw '*requires items*'
        { New-ClairicField -Type estimate -Min 0 } | Should -Throw '*requires max*'
        { New-ClairicField -Type estimate -Min 10 -Max 1 } | Should -Throw '*min < max*'
        { New-ClairicField -Type estimate -Min 0 -Max 10 -Step 0 } | Should -Throw '*positive step*'
        { New-ClairicField -Type estimate -Min 0 -Max 10 -Scale log } | Should -Throw '*min > 0*'
    }
    It 'accepts ISO date estimate bounds' {
        (New-ClairicField -Type estimate -Min '2026-10-20' -Max '2026-12-01' -Step 1).min | Should -Be '2026-10-20'
    }
    It 'previews UTF-8 content and options without credentials' {
        $request = Invoke-Clairic -State 'Café: $12' -Fields @{ total = @{ type='number'; decimals=2 } } -ReferenceDate '2026-10-20' -IncludeQuantiles -ReturnStateText -PreviewRequest | ConvertFrom-Json
        $request.state | Should -Be 'Café: $12'
        $request.options.include_quantiles | Should -BeTrue
        $request.reference_date | Should -Be '2026-10-20'
    }
    It 'rejects missing input, empty fields, bad names, dates and direct schemas' {
        { Invoke-Clairic -Fields @{ x=@{ type='text' } } -PreviewRequest } | Should -Throw '*non-empty State*'
        { Invoke-Clairic -State x -Fields @{} -PreviewRequest } | Should -Throw '*At least one*'
        { Invoke-Clairic -State x -Fields @{ 'bad name'=@{ type='text' } } -PreviewRequest } | Should -Throw '*Invalid field name*'
        { Invoke-Clairic -State x -Fields @{ x=@{ type='unsupported' } } -PreviewRequest } | Should -Throw '*schema*'
        { Invoke-Clairic -State x -Fields @{ x=@{ type='number'; decimals=7 } } -PreviewRequest } | Should -Throw '*schema*'
        { Invoke-Clairic -State x -Fields @{ x=@{ type='text' } } -ReferenceDate '2026-02-30' -PreviewRequest } | Should -Throw '*ISO date*'
    }
    It 'encodes an image-only request' {
        $path = Join-Path $TestDrive 'pixel.png'
        [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+a/e8AAAAASUVORK5CYII='))
        $request = Invoke-Clairic -ImagePath $path -Fields @{ x=@{ type='number' } } -PreviewRequest | ConvertFrom-Json
        @($request.images).Count | Should -Be 1
        $request.images[0].content_type | Should -Be 'image/png'
    }
    It 'rejects excessive image count and unsupported formats' {
        { Invoke-Clairic -ImagePath @('1','2','3','4','5') -Fields @{ x=@{ type='text' } } -PreviewRequest } | Should -Throw '*four images*'
        $path = Join-Path $TestDrive 'image.gif'
        Set-Content $path 'GIF'
        { Invoke-Clairic -ImagePath $path -Fields @{ x=@{ type='text' } } -PreviewRequest } | Should -Throw '*PNG, JPEG and WebP*'
    }
}

Describe 'Clairic HTTP transport' {
    InModuleScope PSAIClairic {
        BeforeEach {
            $script:testArgs = @{ State='Invoice'; Fields=@{ total=@{ type='number' } }; AccountId=('a'*32); ApiToken='test-secret' }
            Mock Invoke-RestMethod {
                [pscustomobject]@{ success=$true; result=[pscustomobject]@{ answers=[pscustomobject]@{ total=[pscustomobject]@{ value=1080; confidence=0.99 }; po=[pscustomobject]@{ value=$null } }; truncated=$false; usage=[pscustomobject]@{ input_tokens=655 } } }
            }
        }
        It 'posts JSON bytes to the model endpoint and retains metadata' {
            $result = Invoke-Clairic @testArgs
            $result.answers.total.confidence | Should -Be 0.99
            $result.usage.input_tokens | Should -Be 655
            Should -Invoke Invoke-RestMethod -Times 1 -Exactly -ParameterFilter {
                $Method -eq 'Post' -and $Uri -eq "https://api.cloudflare.com/client/v4/accounts/$('a'*32)/ai/run/@cf/cloudflare/clairic" -and
                $Headers.Authorization -eq 'Bearer test-secret' -and $Body -is [byte[]] -and
                ([Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json).model -eq 'clairic'
            }
        }
        It 'preserves null when projecting values' {
            $values = Invoke-Clairic @testArgs | ConvertFrom-ClairicAnswer
            $values.total | Should -Be 1080
            $values.po | Should -BeNullOrEmpty
        }
        It 'supports a direct model response' {
            Mock Invoke-RestMethod { [pscustomobject]@{ answers=[pscustomobject]@{ x=[pscustomobject]@{ value=1 } } } }
            (Invoke-Clairic @testArgs).answers.x.value | Should -Be 1
        }
        It 'rejects an unsuccessful envelope' {
            Mock Invoke-RestMethod { [pscustomobject]@{ success=$false } }
            { Invoke-Clairic @testArgs } | Should -Throw '*unsuccessful*'
        }
        It 'does not leak credentials from transport errors' {
            Mock Invoke-RestMethod { throw 'test-secret' }
            { Invoke-Clairic @testArgs } | Should -Throw '*Check connectivity*'
            try { Invoke-Clairic @testArgs } catch { $_.Exception.Message | Should -Not -Match 'test-secret' }
        }
        It 'warns about truncation' {
            Mock Invoke-RestMethod { [pscustomobject]@{ answers=[pscustomobject]@{}; truncated=$true } }
            Invoke-Clairic @testArgs -WarningVariable warnings -WarningAction SilentlyContinue | Out-Null
            $warnings | Should -Match 'truncated'
        }
        It 'validates credentials before transport' {
            $testArgs.AccountId = '../bad'
            { Invoke-Clairic @testArgs } | Should -Throw '*AccountId*'
            Should -Invoke Invoke-RestMethod -Times 0
        }
    }
}
