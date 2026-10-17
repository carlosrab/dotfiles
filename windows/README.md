# Windows applications

Install selected native Windows apps using WinGet and PowerShell. This setup is
independent of the Mac's Nix, Home Manager, and Homebrew configuration.

## App lists

| List | Apps |
|---|---|
| `apps/desktop.json` (default) | 1Password, Chrome, Google Drive, Obsidian, Synology Drive, Mullvad VPN, Claude desktop, Claude Code CLI, Codex CLI, ChatGPT desktop (including Codex desktop functionality) |
| `apps/gaming.json` (optional) | Steam, Epic Games Launcher |

These are editable defaults. Review the list before running it. Both files use
the [native WinGet import schema](https://learn.microsoft.com/en-us/windows/package-manager/winget/import).
The wrapper installs each exact ID separately to retain per-app exit codes,
verification output, and a report that survives partial failures.

The AI tools use these distinct packages:

| App | Exact ID | Source |
|---|---|---|
| Claude desktop | `Anthropic.Claude` | `winget` |
| Claude Code CLI (`claude`) | `Anthropic.ClaudeCode` | `winget` |
| Codex CLI (`codex`) | `OpenAI.Codex` | `winget` |
| ChatGPT desktop / Codex desktop experience | `9PLM9XGG6VKS` | `msstore` |

OpenAI's [current Windows desktop instructions](https://learn.chatgpt.com/docs/windows/windows-app)
use the last ID for ChatGPT, including the native Codex agent. The older Store
ID `9NT1R1C2HH7J` is listed as ChatGPT Classic and is not included here. These
names and IDs were checked on 2026-09-22; verify them on the PC before installing.
The CLI packages are native Windows binaries; Node.js and WSL are not bootstrap
prerequisites. WinGet also installs dependencies declared by package manifests
(the current Codex CLI package declares ripgrep and the Visual C++ runtime).

## Prerequisites and getting the files

Use native Windows 11 with internet access and Windows PowerShell 5.1 or
PowerShell 7. Run as your normal Windows user; individual installers may request
administrator approval through UAC.

Check WinGet:

```powershell
winget --version
winget source list --name winget
winget source list --name msstore
```

Use WinGet 1.6.2631 or newer. If it is missing or outdated, install/update
[App Installer](https://aka.ms/getwinget), reopen PowerShell, and check again.
The script checks the default URL, identifier, and type of each source used by
the selected apps: `winget` and, for ChatGPT, `msstore`. A filtered pilot using
only `winget` does not require `msstore`. It does not add or reset sources.

If Git is available, clone this repository into your user directory. To install
Git first, run `winget install --id Git.Git --exact --source winget`, then reopen
PowerShell so Git is on PATH.

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\code" | Out-Null
git clone https://github.com/carlosrab/dotfiles.git "$env:USERPROFILE\code\dotfiles"
Set-Location "$env:USERPROFILE\code\dotfiles"
```

If you already have the repository, use that checkout. Alternatively, download
the repository ZIP from GitHub's Code menu, extract it, and open PowerShell in
the extracted root. A ZIP snapshot works without Git. Use the branch or snapshot
that actually contains this Windows directory; an unpublished local change is
not available from the default GitHub branch.

If Windows blocks a reviewed local script, allow it for this PowerShell session
only, and unblock the downloaded files if necessary:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
Get-ChildItem .\windows -Recurse -File | Unblock-File
```

An organization policy may override the process setting. This setup does not
change machine-wide execution policy.

## Preview and install

From the repository root:

```powershell
# Preview desktop apps; no WinGet execution, network requests, or log creation.
.\windows\bootstrap.ps1 -Preview

# Preview desktop apps plus the optional launchers.
.\windows\bootstrap.ps1 -Preview -IncludeGaming

# Pilot one selected app, then inspect its result and launch it.
.\windows\bootstrap.ps1 -PackageId Obsidian.Obsidian -AcceptAgreements

# Install the desktop list.
.\windows\bootstrap.ps1 -AcceptAgreements

# Or install the desktop list plus launchers.
.\windows\bootstrap.ps1 -IncludeGaming -AcceptAgreements
```

`-PackageId` accepts one or more exact IDs from the selected lists, for example
`-PackageId Obsidian.Obsidian,Synology.DriveClient`. To select a launcher alone,
also use `-IncludeGaming`. Unknown IDs fail before installation.

`-AcceptAgreements` passes WinGet's package and source agreement acceptance
options; use it when you accept those terms. Without it, packages that require
unaccepted agreements fail with a recorded explanation. Commands are
noninteractive and installers run silently, although UAC can still appear.

Preview displays the local selection; it does not prove availability in the live
catalog. To inspect a package on the PC, use:

```powershell
winget show --id Obsidian.Obsidian --exact --source winget
winget show --id 9PLM9XGG6VKS --exact --source msstore
```

## Repeat runs, failures, and results

Every installation uses `--no-upgrade`. Existing installations recognized by
WinGet are retained; new applications use the latest applicable version unless
the list explicitly requests a version. Removing an entry does not uninstall
the app. The script does not change Windows preferences or initiate a restart.
An app's own updater can still update it independently.

Each real run writes a unique directory below
`$env:LOCALAPPDATA\dotfiles\logs`. Override the parent with `-LogDirectory` if
needed. The directory contains:

- `result.json`: selected apps, input-file hashes, WinGet/PowerShell versions,
  per-app status and exit codes, and an overall result. It is saved before work
  and after each app, so an interrupted run retains `running`/`pending` entries.
- `<PackageId>.install.txt`: WinGet's installation output.
- `<PackageId>.inventory.txt`: exact-ID `winget list` output, including the
  installed version when WinGet can identify it. Localized tables are retained
  as text rather than parsed into a potentially incorrect version value.

`installed` and `already-installed` require a successful inventory query.
`verification-failed` means the installation returned success or already-installed
but the subsequent query could not verify it. Check its logs before retrying.
Installer success does not establish that the app launches correctly; check that
on the desktop.

Inspect the most recent receipt:

```powershell
$receipt = Get-ChildItem "$env:LOCALAPPDATA\dotfiles\logs\*\result.json" |
    Sort-Object LastWriteTime -Descending | Select-Object -First 1
$report = Get-Content -Raw $receipt.FullName | ConvertFrom-Json
$report.Packages | Format-Table Id, Status, InstallExitHex
```

| Script exit code | Meaning |
|---|---|
| `0` | All selected apps were installed or already present, with successful inventory queries; also used for a successful preview. |
| `1` | A prerequisite, installation, verification, or cancellation needs attention. Read the console/receipt. A restart needed *before* installation also returns 1. |
| `3010` | An installer needs a restart to finish. Remaining apps stay pending. Restart Windows yourself, then rerun. |

Read `$LASTEXITCODE` immediately after running the script. A failure is not hidden
by later successful installations or restart requests. The script continues past
ordinary package failures but stops scheduling on cancellation or restart
requests. Resolve the reported issue and rerun the same command; completed apps
will be skipped. `winget --logs` opens WinGet's diagnostic log directory when its
captured output is insufficient.

Keep these local logs out of Git. Review a receipt before sharing it, since
installer output and local paths can contain machine-specific information.

## Updating the list and applications

Edit the selected JSON file to add or remove package IDs. Confirm each ID with
`winget search` and `winget show`. Phase 1 supports the default `winget` and `msstore` sources
and these package fields only: `PackageIdentifier`, optional `Version`, and
optional `Scope` (`user` or `machine`). Unsupported fields and conflicting
duplicates fail instead of being silently ignored. Identical duplicates are
installed once.

Keep each package under the matching `SourceDetails` block. The same ID in
different sources is rejected as ambiguous. The numeric Store ID is intentional;
do not replace it with a similarly named community package.

Adding `Version` requests that version for a new installation; `--no-upgrade`
still leaves an existing installation alone, even if its version differs. App
lists are not a lockfile or a guarantee that old installers remain available.

Upgrades are a separate, explicit operation. For example:

```powershell
winget upgrade --id Obsidian.Obsidian --exact --source winget
```

There is no bulk upgrade or removal operation in this bootstrap. The JSON lists
can also be passed directly to `winget import --import-file <path> --no-upgrade`,
but that bypasses the wrapper's source checks and per-app receipts.

## Validation

Run the offline behavioral tests with either Windows PowerShell 5.1 or PowerShell 7:

```powershell
.\windows\tests\Run-Tests.ps1
```

They use simulated WinGet responses and exercise package selection, repeat runs,
partial failures, source checks, native exit-code handling, cancellation, restart
handling, and preview. They do not install applications. A Windows workflow runs
them with both PowerShell versions when this change is pushed to GitHub.

Live validation is separate: confirm prerequisites, preview, install a pilot
app, run the selected list twice, launch representative apps, and retain the
result receipts. Phase 1 is complete only after this Windows validation.

## Manual follow-up

Sign in to apps and select sync folders, the Obsidian vault, and game libraries.
After installation, reopen PowerShell to refresh PATH, then check the CLIs:

```powershell
claude --version
codex --version
```

Launch ChatGPT from Start and check its chat and Codex/project workflows. Launch
`claude` and `codex` separately to complete sign-in when ready. This installer does
not copy account credentials or agent configuration from the Mac. Git is useful
for repository work and the desktop review panel; install it when needed using
the command above. Additional language runtimes depend on the projects you use.

WinGet installations of Claude Code require explicit upgrades; see
[Anthropic's setup instructions](https://code.claude.com/docs/en/setup).
Use `winget upgrade --id Anthropic.ClaudeCode --exact --source winget` or
`winget upgrade --id OpenAI.Codex --exact --source winget` when an upgrade is wanted.

The gaming list installs launchers; games and mods are managed in those launchers.
Driver setup and hardware validation remain part of the PC build checklist.
Personal file configuration, Windows settings, chezmoi, DSC, and WSL are later work.

## References

- [WinGet install options](https://learn.microsoft.com/en-us/windows/package-manager/winget/install)
- [WinGet source configuration](https://learn.microsoft.com/en-us/windows/package-manager/winget/source)
- [WinGet error codes](https://github.com/microsoft/winget-cli/blob/master/src/AppInstallerSharedLib/Public/AppInstallerErrors.h)
- [Claude Code package](https://github.com/microsoft/winget-pkgs/tree/master/manifests/a/Anthropic/ClaudeCode)
- [Codex CLI package](https://github.com/microsoft/winget-pkgs/tree/master/manifests/o/OpenAI/Codex)
- [ChatGPT Store listing](https://apps.microsoft.com/detail/9plm9xgg6vks)
