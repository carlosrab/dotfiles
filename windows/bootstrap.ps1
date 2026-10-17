#Requires -Version 5.1
<#
.SYNOPSIS
Install selected Windows apps without upgrading existing installations.
.EXAMPLE
.\windows\bootstrap.ps1 -Preview -IncludeGaming
.EXAMPLE
.\windows\bootstrap.ps1 -PackageId Obsidian.Obsidian -AcceptAgreements
#>
[CmdletBinding()]
param(
    [switch]$Preview,
    [switch]$IncludeGaming,
    [string[]]$PackageId,
    [switch]$AcceptAgreements,
    [string]$LogDirectory
)

$ErrorActionPreference = 'Stop'
try {
    Import-Module (Join-Path $PSScriptRoot 'Bootstrap.psm1') -Force
    $manifests = @((Join-Path $PSScriptRoot 'apps/desktop.json'))
    if ($IncludeGaming) { $manifests += Join-Path $PSScriptRoot 'apps/gaming.json' }
    $plan = @(Get-AppPlan -ManifestPath $manifests -PackageId $PackageId)
    Write-Host 'Selected apps (existing installations will not be upgraded):'
    $plan | Format-Table Id, Source, Version, Scope -AutoSize | Out-Host
    if ($Preview) {
        Write-Host 'Preview only: no WinGet commands were run, no availability checks were made, and no logs were created.'
        exit 0
    }
    if ($env:OS -ne 'Windows_NT') { throw 'Installation requires native Windows. Use -Preview on this platform.' }
    $command = Get-Command winget.exe -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $command) {
        throw 'WinGet was not found. Install or update App Installer from https://aka.ms/getwinget, reopen PowerShell, and run winget --info.'
    }
    $executable = $command.Source
    $runner = { param([string[]]$Arguments) Invoke-WinGetCommand -Executable $executable -Arguments $Arguments }.GetNewClosure()
    $winGetVersion = Assert-WinGetPrerequisites -Runner $runner -Source @($plan.Source | Select-Object -Unique)
    if ([string]::IsNullOrWhiteSpace($LogDirectory)) {
        if ([string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) { throw 'LOCALAPPDATA is unavailable. Supply -LogDirectory explicitly.' }
        $LogDirectory = Join-Path $env:LOCALAPPDATA 'dotfiles/logs'
    }
    $inputPaths = @($PSCommandPath, (Join-Path $PSScriptRoot 'Bootstrap.psm1')) + $manifests
    $inputFiles = @($inputPaths | ForEach-Object {
        [pscustomobject]@{ Name = $_.Substring($PSScriptRoot.Length + 1); SHA256 = (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash }
    })
    $result = Invoke-AppPlan -Plan $plan -Runner $runner -LogDirectory $LogDirectory -WinGetVersion $winGetVersion -InputFiles $inputFiles -AcceptAgreements:$AcceptAgreements
    if ($result.ExitCode -eq 3010) { Write-Host 'Restart Windows, then rerun this command to finish verification and any remaining apps.' }
    exit $result.ExitCode
}
catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
