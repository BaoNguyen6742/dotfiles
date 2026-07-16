[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$ConfigDir = if ($env:PI_CODING_AGENT_DIR) {
    $env:PI_CODING_AGENT_DIR
} else {
    Join-Path $HOME ".pi/agent"
}
$Timestamp = Get-Date -Format "yyyyMMdd-HHmmss"

function Get-FileDigest {
    param([Parameter(Mandatory)] [string]$Path)

    $Sha256 = [System.Security.Cryptography.SHA256]::Create()
    $Stream = [System.IO.File]::OpenRead($Path)
    try {
        [Convert]::ToBase64String($Sha256.ComputeHash($Stream))
    } finally {
        $Stream.Dispose()
        $Sha256.Dispose()
    }
}

function Install-ConfigFile {
    param(
        [Parameter(Mandatory)] [string]$Source,
        [Parameter(Mandatory)] [string]$Destination
    )

    if (Test-Path -LiteralPath $Destination -PathType Leaf) {
        $sourceHash = Get-FileDigest -Path $Source
        $destinationHash = Get-FileDigest -Path $Destination
        if ($sourceHash -eq $destinationHash) {
            Write-Host "Unchanged: $Destination"
            return
        }
    }

    if ($DryRun) {
        if (Test-Path -LiteralPath $Destination) {
            Write-Host "Would back up: $Destination"
        }
        Write-Host "Would install: $Destination"
        return
    }

    $DestinationDir = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Force -Path $DestinationDir | Out-Null
    if (Test-Path -LiteralPath $Destination) {
        $Backup = "$Destination.bak-$Timestamp"
        $Suffix = 1
        while (Test-Path -LiteralPath $Backup) {
            $Backup = "$Destination.bak-$Timestamp-$Suffix"
            $Suffix++
        }
        Copy-Item -LiteralPath $Destination -Destination $Backup
        Write-Host "Backed up: $Backup"
    }
    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Host "Installed: $Destination"
}

Install-ConfigFile `
    -Source (Join-Path $ScriptDir "settings.json") `
    -Destination (Join-Path $ConfigDir "settings.json")

$ExtensionsDir = Join-Path $ScriptDir "extensions"
Get-ChildItem -LiteralPath $ExtensionsDir -File -Recurse | ForEach-Object {
    $RelativePath = $_.FullName.Substring($ExtensionsDir.Length).TrimStart([char]'/', [char]'\')
    Install-ConfigFile `
        -Source $_.FullName `
        -Destination (Join-Path (Join-Path $ConfigDir "extensions") $RelativePath)
}

if ($DryRun) {
    Write-Host "Dry run complete."
} else {
    Write-Host "Pi configuration installed. Restart Pi to apply settings changes."
}
