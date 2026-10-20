BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '../PSAIClairic.psd1') -Force
}

Describe 'Ordered answer projection' {
    BeforeEach {
        $result = [pscustomobject]@{ answers = [pscustomobject][ordered]@{
            contacts = [pscustomobject]@{ value = @('Dana', 'Priya') }
            total = [pscustomobject]@{ value = 1080 }
            po = [pscustomobject]@{ value = $null }
        } }
    }
    It 'orders requested fields and appends remaining answers' {
        $values = $result | ConvertFrom-ClairicAnswer -FieldOrder total,po
        ($values.PSObject.Properties.Name -join ',') | Should -Be 'total,po,contacts'
        $values.total | Should -Be 1080
        $values.po | Should -BeNullOrEmpty
        $values.contacts.Count | Should -Be 2
    }
    It 'preserves response order when no field order is supplied' {
        $values = $result | ConvertFrom-ClairicAnswer
        ($values.PSObject.Properties.Name -join ',') | Should -Be 'contacts,total,po'
    }
    It 'rejects a requested field that is absent' {
        { $result | ConvertFrom-ClairicAnswer -FieldOrder absent } | Should -Throw '*does not exist*'
    }
    It 'processes multiple responses through the pipeline' {
        $values = @($result, $result) | ConvertFrom-ClairicAnswer -FieldOrder total
        $values.Count | Should -Be 2
        $values[0].total | Should -Be 1080
        $values[1].total | Should -Be 1080
    }
}
