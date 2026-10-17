Set-StrictMode -Version 2.0

function Get-DefaultSource {
    param([Parameter(Mandatory)][string]$Name)
    if ($Name -ceq 'winget') {
        return [pscustomobject]@{
            Name = 'winget'; Argument = 'https://cdn.winget.microsoft.com/cache'
            Identifier = 'Microsoft.Winget.Source_8wekyb3d8bbwe'; Type = 'Microsoft.PreIndexed.Package'
        }
    }
    if ($Name -ceq 'msstore') {
        return [pscustomobject]@{
            Name = 'msstore'; Argument = 'https://storeedgefd.dsx.mp.microsoft.com/v9.0'
            Identifier = 'StoreEdgeFD'; Type = 'Microsoft.Rest'
        }
    }
    throw "Unsupported source '$Name'. Phase 1 supports the default winget and msstore sources."
}

function Get-AppPlan {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$ManifestPath, [string[]]$PackageId)

    $seen = @{}
    $plan = @()
    foreach ($path in $ManifestPath) {
        $document = Get-Content -LiteralPath $path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if (-not $document.PSObject.Properties['Sources'] -or @($document.Sources).Count -eq 0) {
            throw "No Sources in $path. Use the WinGet package-list schema."
        }
        foreach ($source in $document.Sources) {
            $details = $source.SourceDetails
            $expected = Get-DefaultSource $details.Name
            if ($details.Identifier -cne $expected.Identifier -or
                $details.Argument -cne $expected.Argument -or $details.Type -cne $expected.Type) {
                throw "Source '$($details.Name)' in $path does not match Microsoft's default source."
            }
            if (@($source.Packages).Count -eq 0) { throw "No packages in $path." }
            foreach ($package in $source.Packages) {
                # Reject fields we do not implement instead of silently ignoring installer overrides.
                foreach ($property in $package.PSObject.Properties.Name) {
                    if ($property -notin @('PackageIdentifier', 'Version', 'Scope')) {
                        throw "Unsupported package field '$property' in $path."
                    }
                }
                $id = $package.PackageIdentifier
                if ($id -isnot [string] -or $id -cnotmatch '^[A-Za-z0-9][A-Za-z0-9._+-]*$') {
                    throw "Invalid PackageIdentifier in $path."
                }
                $version = $null
                $scope = $null
                if ($package.PSObject.Properties['Version']) {
                    if ($package.Version -isnot [string] -or $package.Version -notmatch '^\S+$' -or
                        $package.Version.StartsWith('-')) { throw "Invalid Version for $id." }
                    $version = $package.Version
                }
                if ($package.PSObject.Properties['Scope']) {
                    if ($package.Scope -cnotin @('user', 'machine')) { throw "Invalid Scope for $id." }
                    $scope = $package.Scope
                }
                $entry = [pscustomobject]@{ Id = $id; Source = $details.Name; Version = $version; Scope = $scope }
                if ($seen.ContainsKey($id)) {
                    $previous = $seen[$id]
                    if ($previous.Id -cne $id -or $previous.Source -cne $entry.Source -or
                        $previous.Version -cne $version -or $previous.Scope -cne $scope) {
                        throw "Conflicting duplicate package $id."
                    }
                    continue
                }
                $seen[$id] = $entry
                $plan += $entry
            }
        }
    }
    foreach ($id in $PackageId) {
        if ($id -cnotin $plan.Id) { throw "Package '$id' is not in the selected lists. Check -IncludeGaming and the exact ID." }
    }
    if ($PackageId) { $plan = @($plan | Where-Object { $_.Id -cin $PackageId }) }
    if ($plan.Count -eq 0) { throw 'The selected app plan is empty.' }
    return $plan
}

function Invoke-WinGetCommand {
    param([Parameter(Mandatory)][string]$Executable, [Parameter(Mandatory)][string[]]$Arguments)
    # Windows PowerShell 5.1 treats redirected stderr as ErrorRecord objects.
    # Inspect the native exit code, not PowerShell's native-error preference.
    $ErrorActionPreference = 'Continue'
    $PSNativeCommandUseErrorActionPreference = $false
    $global:LASTEXITCODE = $null
    $lines = @(& $Executable @Arguments 2>&1 | ForEach-Object {
        $line = $_.ToString()
        Write-Host $line
        $line
    })
    $code = $global:LASTEXITCODE
    return [pscustomobject]@{ ExitCode = $code; Output = ($lines -join [Environment]::NewLine) }
}

function Assert-WinGetPrerequisites {
    param([Parameter(Mandatory)][scriptblock]$Runner, [string[]]$Source = @('winget'))
    $versionResult = & $Runner @('--version')
    if ($versionResult.ExitCode -ne 0 -or $versionResult.Output.Trim() -notmatch '^v?(\d+\.\d+\.\d+)(?:[-+].*)?$') {
        throw 'Could not read WinGet version. Repair or update App Installer, then run winget --info.'
    }
    $version = $Matches[1]
    if ([version]$version -lt [version]'1.6.2631') {
        throw "WinGet $version is too old. Update App Installer to get WinGet 1.6.2631 or newer."
    }
    foreach ($name in ($Source | Select-Object -Unique)) {
        $expected = Get-DefaultSource $name
        $sourceResult = & $Runner @('source', 'export', '--name', $name, '--disable-interactivity')
        if ($sourceResult.ExitCode -ne 0) {
            throw "Could not inspect the $name source. Run winget source list --name $name and resolve the reported source error."
        }
        $actual = $sourceResult.Output | ConvertFrom-Json -ErrorAction Stop
        if ($actual.Name -cne $expected.Name -or $actual.Arg -cne $expected.Argument -or
            $actual.Identifier -cne $expected.Identifier -or $actual.Type -cne $expected.Type) {
            throw "The source named $name does not match Microsoft's default source. Inspect winget source list --name $name."
        }
    }
    return $version
}

function Get-InstallOutcome {
    param([Parameter(Mandatory)][long]$ExitCode)
    # HRESULTs can arrive signed or unsigned. Values are from AppInstallerErrors.h.
    $hex = '0x{0:X8}' -f ($ExitCode -band 4294967295L)
    $status = 'failed'
    $restart = $false
    $stop = $false
    switch ($hex) {
        '0x00000000' { $status = 'installed' }
        '0x8A150061' { $status = 'already-installed' }
        '0x8A15010D' { $status = 'already-installed' }
        '0x8A150109' { $status = 'restart-required'; $restart = $true; $stop = $true }
        '0x8A15010A' { $status = 'retry-after-restart'; $restart = $true; $stop = $true }
        '0x8A15010B' { $status = 'unexpected-restart'; $restart = $true; $stop = $true }
        '0x8A15010C' { $status = 'cancelled'; $stop = $true }
        '0x8A150005' { $status = 'cancelled'; $stop = $true }
    }
    return [pscustomobject]@{ Status = $status; Hex = $hex; RestartRequired = $restart; Stop = $stop }
}

function Save-InstallReport {
    param($Report, [string]$Path)
    $Report.UpdatedAt = [DateTime]::UtcNow.ToString('o')
    $temporary = "$Path.tmp"
    $Report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $temporary -Encoding UTF8 -ErrorAction Stop
    Move-Item -LiteralPath $temporary -Destination $Path -Force -ErrorAction Stop
}

function Invoke-AppPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$Plan,
        [Parameter(Mandatory)][scriptblock]$Runner,
        [Parameter(Mandatory)][string]$LogDirectory,
        [string]$WinGetVersion,
        [object[]]$InputFiles = @(),
        [switch]$AcceptAgreements
    )

    $runName = '{0}-{1}' -f [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'), [guid]::NewGuid().ToString('N').Substring(0, 8)
    $runDirectory = Join-Path $LogDirectory $runName
    $null = New-Item -ItemType Directory -Path $runDirectory -ErrorAction Stop
    $reportPath = Join-Path $runDirectory 'result.json'
    $rows = @($Plan | ForEach-Object {
        [pscustomobject][ordered]@{
            Id = $_.Id; Source = $_.Source; RequestedVersion = $_.Version; Scope = $_.Scope
            Status = 'pending'; InstallExitCode = $null; InstallExitHex = $null; VerifyExitCode = $null
            RestartRequired = $false; Message = ''; InstallLog = $null; InventoryLog = $null
        }
    })
    $report = [pscustomobject][ordered]@{
        SchemaVersion = 1; StartedAt = [DateTime]::UtcNow.ToString('o'); UpdatedAt = $null
        State = 'in-progress'; ExitCode = $null; WinGetVersion = $WinGetVersion
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        AcceptAgreements = [bool]$AcceptAgreements; InputFiles = $InputFiles; Packages = $rows
    }
    Save-InstallReport $report $reportPath
    Write-Host "Results: $reportPath"

    for ($index = 0; $index -lt $Plan.Count; $index++) {
        $package = $Plan[$index]
        $row = $rows[$index]
        $row.Status = 'running'
        Save-InstallReport $report $reportPath
        $arguments = @('install', '--id', $package.Id, '--exact', '--source', $package.Source,
            '--no-upgrade', '--silent', '--disable-interactivity')
        if ($package.Version) { $arguments += @('--version', $package.Version) }
        if ($package.Scope) { $arguments += @('--scope', $package.Scope) }
        if ($AcceptAgreements) { $arguments += @('--accept-source-agreements', '--accept-package-agreements') }
        $stop = $false
        try {
            Write-Host "Installing or checking $($package.Id)..."
            $result = & $Runner $arguments
            if ($null -eq $result.ExitCode) { throw 'WinGet did not return an exit code.' }
            $row.InstallExitCode = [long]$result.ExitCode
            $outcome = Get-InstallOutcome $row.InstallExitCode
            $row.InstallExitHex = $outcome.Hex
            $row.Status = $outcome.Status
            $row.RestartRequired = $outcome.RestartRequired
            $stop = $outcome.Stop
            $row.InstallLog = Join-Path $runDirectory "$($package.Id).install.txt"
            $result.Output | Set-Content -LiteralPath $row.InstallLog -Encoding UTF8 -ErrorAction Stop
            if ($row.Status -in @('installed', 'already-installed')) {
                # Keep the native, localized inventory output, including the installed version.
                # Do not parse human-readable tables to decide installation success.
                $verifyArguments = @('list', '--id', $package.Id, '--exact', '--source', $package.Source, '--disable-interactivity')
                if ($package.Scope) { $verifyArguments += @('--scope', $package.Scope) }
                if ($AcceptAgreements) { $verifyArguments += '--accept-source-agreements' }
                $inventory = & $Runner $verifyArguments
                $row.VerifyExitCode = $inventory.ExitCode
                $row.InventoryLog = Join-Path $runDirectory "$($package.Id).inventory.txt"
                $inventory.Output | Set-Content -LiteralPath $row.InventoryLog -Encoding UTF8 -ErrorAction Stop
                if ($null -eq $inventory.ExitCode -or $inventory.ExitCode -ne 0) {
                    $row.Message = "Install result was $($row.Status), but WinGet could not verify the installed app. Inspect the logs and rerun."
                    $row.Status = 'verification-failed'
                }
            }
            elseif ($row.RestartRequired) {
                $row.Message = 'Restart Windows yourself, then rerun the same command to finish and verify the selected apps.'
            }
            else {
                $row.Message = 'Inspect the install log. Resolve the error and rerun; completed apps will be skipped.'
                if ($outcome.Hex -in @('0x8A150041', '0x8A150046')) {
                    $row.Message = 'Agreements were not accepted. Review the terms and rerun with -AcceptAgreements if you accept them.'
                }
            }
        }
        catch {
            $row.Status = 'failed'
            $row.Message = $_.Exception.Message
        }
        Save-InstallReport $report $reportPath
        Write-Host "$($row.Id): $($row.Status)"
        if ($stop) { break }
    }

    $failures = @($rows | Where-Object { $_.Status -in @('failed', 'verification-failed', 'retry-after-restart', 'unexpected-restart', 'cancelled') })
    if ($failures.Count -gt 0) { $report.State = 'needs-attention'; $report.ExitCode = 1 }
    elseif (@($rows | Where-Object { $_.RestartRequired }).Count -gt 0) { $report.State = 'restart-required'; $report.ExitCode = 3010 }
    else { $report.State = 'completed'; $report.ExitCode = 0 }
    Save-InstallReport $report $reportPath
    $rows | Format-Table Id, Status, InstallExitHex -AutoSize | Out-Host
    Write-Host "Report: $reportPath"
    return [pscustomobject]@{ ExitCode = $report.ExitCode; ReportPath = $reportPath; Report = $report }
}

Export-ModuleMember -Function Get-AppPlan, Invoke-WinGetCommand, Assert-WinGetPrerequisites, Get-InstallOutcome, Invoke-AppPlan
