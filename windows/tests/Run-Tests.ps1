#Requires -Version 5.1
# Offline behavioral tests: fake WinGet responses; never installs applications.
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../Bootstrap.psm1') -Force
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('dotfiles-windows-tests-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $testRoot
$script:Passed = 0

function Assert-True($Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Assert-Throws([scriptblock]$Action, [string]$Message) {
    $threw = $false
    try { & $Action | Out-Null } catch { $threw = $true }
    Assert-True $threw $Message
}
function Test-Case([string]$Name, [scriptblock]$Action) {
    & $Action
    $script:Passed++
    Write-Host "PASS: $Name"
}
function New-Manifest([object[]]$Packages, [string]$Source = 'winget') {
    $manifest = Get-Content -Raw (Join-Path $PSScriptRoot '../apps/desktop.json') | ConvertFrom-Json
    $manifest.Sources = @($manifest.Sources | Where-Object { $_.SourceDetails.Name -eq $Source })
    $manifest.Sources[0].Packages = $Packages
    $path = Join-Path $testRoot ([guid]::NewGuid().ToString('N') + '.json')
    $manifest | ConvertTo-Json -Depth 10 | Set-Content $path -Encoding UTF8
    return $path
}
function New-FakeRunner($State) {
    return {
        param([string[]]$Arguments)
        $State.Calls.Add($Arguments) | Out-Null
        $idIndex = [Array]::IndexOf($Arguments, '--id')
        $id = if ($idIndex -ge 0) { $Arguments[$idIndex + 1] } else { '' }
        switch ($Arguments[0]) {
            '--version' { return [pscustomobject]@{ ExitCode = 0; Output = 'v1.12.460' } }
            'source' {
                $name = $Arguments[[Array]::IndexOf($Arguments, '--name') + 1]
                if (-not $State.Sources.ContainsKey($name)) { return [pscustomobject]@{ ExitCode = 1; Output = 'Missing source' } }
                return [pscustomobject]@{ ExitCode = 0; Output = $State.Sources[$name] }
            }
            'install' {
                if ($State.Throws -eq $id) { throw 'Simulated command execution failure' }
                $code = if ($State.Codes.ContainsKey($id)) { $State.Codes[$id] }
                    elseif ($State.Installed.ContainsKey($id)) { -1978335135L } else { 0 }
                if ($code -eq 0) { $State.Installed[$id] = $true }
                return [pscustomobject]@{ ExitCode = $code; Output = "Installer output for $id" }
            }
            'list' {
                $code = if ($State.VerifyFailure -eq $id) { 1 } else { 0 }
                return [pscustomobject]@{ ExitCode = $code; Output = "Name Id Version`n$id $id 1.2.3" }
            }
            default { throw "Unexpected WinGet operation: $($Arguments -join ' ')" }
        }
    }.GetNewClosure()
}
function New-State {
    return @{
        Calls = [Collections.Generic.List[object]]::new(); Codes = @{}; Installed = @{}
        Throws = ''; VerifyFailure = ''
        Sources = @{
            winget = '{"Name":"winget","Arg":"https://cdn.winget.microsoft.com/cache","Identifier":"Microsoft.Winget.Source_8wekyb3d8bbwe","Type":"Microsoft.PreIndexed.Package"}'
            msstore = '{"Name":"msstore","Arg":"https://storeedgefd.dsx.mp.microsoft.com/v9.0","Identifier":"StoreEdgeFD","Type":"Microsoft.Rest"}'
        }
    }
}

try {
    $desktop = Join-Path $PSScriptRoot '../apps/desktop.json'
    $gaming = Join-Path $PSScriptRoot '../apps/gaming.json'
    $one = New-Manifest @(@{ PackageIdentifier = 'Test.First' })
    $two = New-Manifest @(@{ PackageIdentifier = 'Test.First' }, @{ PackageIdentifier = 'Test.Second' })
    $three = New-Manifest @(@{ PackageIdentifier = 'Test.First' }, @{ PackageIdentifier = 'Test.Second' }, @{ PackageIdentifier = 'Test.Third' })
    $plan = @(Get-AppPlan $two)

    Test-Case 'All PowerShell files parse' {
        foreach ($file in Get-ChildItem (Join-Path $PSScriptRoot '..') -Recurse -File | Where-Object { $_.Extension -in @('.ps1', '.psm1') }) {
            $tokens = $null; $parseErrors = $null
            $null = [Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$parseErrors)
            Assert-True ($parseErrors.Count -eq 0) "Parse errors in $($file.Name): $parseErrors"
        }
    }
    Test-Case 'Gaming is optional; exact package filter cannot broaden the selected list' {
        $desktopPlan = @(Get-AppPlan $desktop)
        $both = @(Get-AppPlan @($desktop, $gaming))
        Assert-True ('Valve.Steam' -notin $desktopPlan.Id) 'Steam leaked into the desktop list.'
        Assert-True ($both.Count -gt $desktopPlan.Count) 'Gaming selection added no apps.'
        $selected = @(Get-AppPlan @($desktop, $gaming) -PackageId 'Valve.Steam')
        Assert-True ($selected.Count -eq 1 -and $selected[0].Id -ceq 'Valve.Steam') 'Single-app selection changed.'
        Assert-Throws { Get-AppPlan $desktop -PackageId 'Valve.Steam' } 'Excluded gaming package was accepted.'
        Assert-Throws { Get-AppPlan $desktop -PackageId 'not-in-the-list' } 'Unknown package was accepted.'
    }
    Test-Case 'Duplicate entries are deduplicated; conflicting intent fails before installation' {
        Assert-True (@(Get-AppPlan @($two, $two)).Count -eq 2) 'Duplicate apps were scheduled twice.'
        $conflict = New-Manifest @(@{ PackageIdentifier = 'Test.First'; Scope = 'machine' })
        Assert-Throws { Get-AppPlan @($one, $conflict) } 'Conflicting scopes were accepted.'
    }
    Test-Case 'Malformed and unsupported manifest fields are rejected' {
        $bad = Join-Path $testRoot 'invalid.json'
        '{broken' | Set-Content $bad
        Assert-Throws { Get-AppPlan $bad } 'Malformed JSON was accepted.'
        $override = New-Manifest @(@{ PackageIdentifier = 'Test.First'; InitialOverrideArguments = '/unexpected' })
        Assert-Throws { Get-AppPlan $override } 'Unsupported installer override was ignored.'
        $invalidId = New-Manifest @(@{ PackageIdentifier = '--force' })
        Assert-Throws { Get-AppPlan $invalidId } 'Invalid package ID was accepted.'
        $empty = New-Manifest @()
        Assert-Throws { Get-AppPlan $empty } 'Empty package list was accepted.'
    }
    Test-Case 'Prerequisites accept supported WinGet and reject a mismatched source' {
        $state = New-State
        $runner = New-FakeRunner $state
        Assert-True ((Assert-WinGetPrerequisites $runner) -eq '1.12.460') 'Version check failed.'
        $state.Sources.winget = $state.Sources.winget.Replace('https://cdn.winget.microsoft.com/cache', 'https://example.invalid/cache')
        Assert-Throws { Assert-WinGetPrerequisites $runner } 'Mismatched source was accepted.'
        Assert-Throws { Assert-WinGetPrerequisites { param($Arguments) [pscustomobject]@{ ExitCode = 0; Output = 'v1.0.0' } } } 'Old WinGet was accepted.'
    }
    Test-Case 'Mixed-source plans preserve the Store source and reject ambiguous IDs' {
        $store = New-Manifest @(@{ PackageIdentifier = '9TESTSTOREID' }) -Source msstore
        $mixed = @(Get-AppPlan @($one, $store))
        Assert-True ($mixed.Count -eq 2 -and $mixed[1].Source -ceq 'msstore') 'Store source was lost.'
        $selected = @(Get-AppPlan @($one, $store) -PackageId '9TESTSTOREID')
        Assert-True ($selected.Count -eq 1 -and $selected[0].Source -ceq 'msstore') 'Store filter broadened the plan.'
        $conflict = New-Manifest @(@{ PackageIdentifier = 'Test.First' }) -Source msstore
        Assert-Throws { Get-AppPlan @($one, $conflict) } 'Duplicate ID across sources was accepted.'
    }
    Test-Case 'Manifest sources reject custom names and modified Store descriptors' {
        foreach ($field in @('Name', 'Argument', 'Identifier', 'Type')) {
            $store = New-Manifest @(@{ PackageIdentifier = '9TESTSTOREID' }) -Source msstore
            $data = Get-Content -Raw $store | ConvertFrom-Json
            $data.Sources[0].SourceDetails.$field = 'unexpected'
            $data | ConvertTo-Json -Depth 10 | Set-Content $store -Encoding UTF8
            Assert-Throws { Get-AppPlan $store } "Changed Store $field was accepted."
        }
    }
    Test-Case 'Prerequisites inspect only selected sources and reject missing or modified Store sources' {
        $state = New-State
        $runner = New-FakeRunner $state
        $mixed = @(Get-AppPlan $desktop)
        $null = Assert-WinGetPrerequisites $runner -Source $mixed.Source
        $queries = @($state.Calls | Where-Object { $_[0] -eq 'source' })
        Assert-True ($queries.Count -eq 2 -and 'winget' -in $queries[0] -and 'msstore' -in $queries[1]) 'Selected sources were not checked once each.'
        $state.Sources.Remove('msstore')
        $state.Calls.Clear()
        $pilot = @(Get-AppPlan $desktop -PackageId 'Obsidian.Obsidian')
        $null = Assert-WinGetPrerequisites $runner -Source $pilot.Source
        Assert-True ($state.Calls.Count -eq 2) 'Winget-only pilot inspected an unused source.'
        Assert-Throws { Assert-WinGetPrerequisites $runner -Source $mixed.Source } 'Missing selected Store source was accepted.'
        $state.Sources.msstore = (New-State).Sources.msstore.Replace('StoreEdgeFD', 'DifferentStore')
        Assert-Throws { Assert-WinGetPrerequisites $runner -Source msstore } 'Modified Store source was accepted.'
        $state.Sources.msstore = (New-State).Sources.msstore
        $state.Sources.Remove('winget')
        $null = Assert-WinGetPrerequisites $runner -Source msstore
    }
    Test-Case 'Store install and repeat-run inventory stay on the selected source' {
        $store = New-Manifest @(@{ PackageIdentifier = '9TESTSTOREID' }) -Source msstore
        $storePlan = @(Get-AppPlan $store)
        $state = New-State
        $runner = New-FakeRunner $state
        $first = Invoke-AppPlan $storePlan $runner $testRoot -AcceptAgreements
        $second = Invoke-AppPlan $storePlan $runner $testRoot -AcceptAgreements
        Assert-True ($first.ExitCode -eq 0 -and $second.ExitCode -eq 0 -and $second.Report.Packages[0].Status -eq 'already-installed') 'Store repeat run failed.'
        foreach ($call in $state.Calls) {
            Assert-True ($call[[Array]::IndexOf($call, '--source') + 1] -ceq 'msstore') 'Store package used another source.'
            Assert-True ('--exact' -in $call -and '--accept-source-agreements' -in $call) 'Store matching/agreement options were lost.'
            if ($call[0] -eq 'install') { Assert-True ('--no-upgrade' -in $call -and '--accept-package-agreements' -in $call) 'Store install flags changed.' }
        }
        $receipt = Get-Content -Raw $second.ReportPath | ConvertFrom-Json
        Assert-True ($receipt.Packages[0].Source -ceq 'msstore') 'Store source was lost in the receipt.'
    }
    Test-Case 'Installation and repeat run preserve exact selection and skip upgrades' {
        $state = New-State
        $runner = New-FakeRunner $state
        $first = Invoke-AppPlan $plan $runner $testRoot -AcceptAgreements
        Assert-True ($first.ExitCode -eq 0) 'First run failed.'
        Assert-True (@($first.Report.Packages | Where-Object Status -ne 'installed').Count -eq 0) 'First run status incorrect.'
        $second = Invoke-AppPlan $plan $runner $testRoot
        Assert-True ($second.ExitCode -eq 0) 'Repeat run failed.'
        Assert-True (@($second.Report.Packages | Where-Object Status -ne 'already-installed').Count -eq 0) 'Repeat run did not skip installed apps.'
        foreach ($call in $state.Calls) {
            Assert-True ($call[0] -in @('install', 'list')) 'Unexpected mutating command.'
            Assert-True ('--exact' -in $call -and '--source' -in $call) 'Package/source matching is ambiguous.'
            Assert-True ('--allow-reboot' -notin $call -and '--force' -notin $call) 'Unexpected force/reboot option.'
            if ($call[0] -eq 'install') { Assert-True ('--no-upgrade' -in $call) 'Upgrade protection is missing.' }
        }
        $lastInstall = @($state.Calls | Where-Object { $_[0] -eq 'install' })[-1]
        Assert-True ('--accept-package-agreements' -notin $lastInstall) 'Agreements were accepted without the flag.'
        $receipt = Get-Content -Raw $second.ReportPath | ConvertFrom-Json
        Assert-True ($receipt.State -eq 'completed' -and $receipt.Packages.Count -eq 2) 'Saved receipt does not match the completed run.'
        Assert-True ((Get-Content -Raw $receipt.Packages[0].InventoryLog) -match '1.2.3') 'Installed version output was lost.'
    }
    Test-Case 'A missing package fails the run while subsequent apps still install' {
        $state = New-State
        $state.Codes['Test.First'] = 2316632084L # 0x8A150014: no applications found
        $result = Invoke-AppPlan $plan (New-FakeRunner $state) $testRoot
        Assert-True ($result.ExitCode -eq 1 -and $result.Report.State -eq 'needs-attention') 'Missing package was reported as success.'
        Assert-True ($result.Report.Packages[1].Status -eq 'installed') 'A package failure prevented independent apps from installing.'
    }
    Test-Case 'Command exceptions remain failures and preserve the receipt' {
        $state = New-State; $state.Throws = 'Test.First'
        $result = Invoke-AppPlan $plan (New-FakeRunner $state) $testRoot
        Assert-True ($result.ExitCode -eq 1 -and $result.Report.Packages[0].Message -match 'Simulated') 'Command exception was lost.'
        Assert-True (Test-Path $result.ReportPath) 'No receipt after command failure.'
    }
    Test-Case 'Unverified installation cannot be reported as completed' {
        $state = New-State; $state.VerifyFailure = 'Test.First'
        $result = Invoke-AppPlan $plan (New-FakeRunner $state) $testRoot
        Assert-True ($result.ExitCode -eq 1 -and $result.Report.Packages[0].Status -eq 'verification-failed') 'Verification error was ignored.'
    }
    Test-Case 'Restart-to-finish stops scheduling and preserves pending apps for the next run' {
        $state = New-State; $state.Codes['Test.First'] = 2316632329L # 0x8A150109
        $result = Invoke-AppPlan $plan (New-FakeRunner $state) $testRoot
        Assert-True ($result.ExitCode -eq 3010 -and $result.Report.State -eq 'restart-required') 'Restart-to-finish was misclassified.'
        Assert-True ($result.Report.Packages[1].Status -eq 'pending' -and $state.Calls.Count -eq 1) 'Work continued after a restart request.'
    }
    Test-Case 'Restart-before-install is unfinished work, not a successful installation' {
        $state = New-State; $state.Codes['Test.First'] = 2316632330L # 0x8A15010A
        $result = Invoke-AppPlan $plan (New-FakeRunner $state) $testRoot
        Assert-True ($result.ExitCode -eq 1 -and $result.Report.Packages[0].Status -eq 'retry-after-restart') 'Restart-before-install was reported as success.'
    }
    Test-Case 'Cancellation stops further installation' {
        $state = New-State; $state.Codes['Test.First'] = 2316632332L # 0x8A15010C
        $result = Invoke-AppPlan $plan (New-FakeRunner $state) $testRoot
        Assert-True ($result.ExitCode -eq 1 -and $state.Calls.Count -eq 1) 'Cancellation was ignored.'
        Assert-True ($result.Report.Packages[1].Status -eq 'pending') 'Cancelled run lost pending app state.'
    }
    Test-Case 'A successful later app cannot hide an earlier failure before a restart' {
        $state = New-State; $state.Codes['Test.First'] = 1; $state.Codes['Test.Third'] = 2316632329L
        $result = Invoke-AppPlan @(Get-AppPlan $three) (New-FakeRunner $state) $testRoot
        Assert-True ($result.ExitCode -eq 1) 'Restart exit code hid an earlier failure.'
    }
    Test-Case 'Signed/unsigned HRESULTs agree; unknown errors remain failures' {
        # Force numeric expressions: Windows PowerShell 5.1 can treat bare L-suffixed arguments as strings.
        $signed = Get-InstallOutcome ([long]-1978335135)
        $unsigned = Get-InstallOutcome ([long]2316632161)
        Assert-True ($signed.Status -eq 'already-installed' -and $signed.Hex -eq $unsigned.Hex) 'HRESULT normalization failed.'
        Assert-True ((Get-InstallOutcome 42).Status -eq 'failed') 'Unknown error was reported as success.'
    }
    Test-Case 'Native stderr and exit code survive PowerShell error handling' {
        $hostExecutable = (Get-Process -Id $PID).Path
        # EncodedCommand preserves embedded quotes under Windows PowerShell's legacy native argument handling.
        $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('[Console]::Error.WriteLine("diagnostic"); Write-Output "output"; exit 42'))
        $result = Invoke-WinGetCommand $hostExecutable @('-NoProfile', '-OutputFormat', 'Text', '-EncodedCommand', $encodedCommand)
        Assert-True ($result.ExitCode -eq 42 -and $result.Output -match 'diagnostic' -and $result.Output -match 'output') 'Native error handling lost output or exit code.'
    }
    Test-Case 'Entry-point preview succeeds offline and creates no log directory' {
        $previewLogs = Join-Path $testRoot 'must-not-exist'
        $hostExecutable = (Get-Process -Id $PID).Path
        $entry = Join-Path $PSScriptRoot '../bootstrap.ps1'
        & $hostExecutable -NoProfile -File $entry -Preview -IncludeGaming -PackageId Valve.Steam -LogDirectory $previewLogs
        Assert-True ($LASTEXITCODE -eq 0 -and -not (Test-Path $previewLogs)) 'Preview failed or created logs.'
    }
    Test-Case 'A process that cannot start cannot reuse a previous successful exit code' {
        $global:LASTEXITCODE = 0
        Assert-Throws { Invoke-WinGetCommand (Join-Path $testRoot 'missing-winget.exe') @('--version') } 'A missing executable was accepted.'
        Assert-True ($null -eq $global:LASTEXITCODE) 'A missing executable retained a stale native exit code.'
    }
    Write-Host "$script:Passed tests passed. These tests simulate WinGet; live Windows validation is separate."
}
finally {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}
