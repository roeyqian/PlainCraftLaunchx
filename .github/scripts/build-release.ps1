$ErrorActionPreference = 'Stop'
function Get-Sha256([string] $Path) {
    $stream = [IO.File]::OpenRead($Path)
    $hasher = [Security.Cryptography.SHA256]::Create()
    try {
        return [BitConverter]::ToString($hasher.ComputeHash($stream)).Replace('-', '')
    } finally {
        $hasher.Dispose()
        $stream.Dispose()
    }
}

$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$projectFile = Join-Path $projectRoot 'Plain Craft Launcher 2\Plain Craft Launcher 2.csproj'
$publishRoot = Join-Path $projectRoot 'Plain Craft Launcher 2\publish\one-click'
$buildId = (Get-Date -Format 'yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
$publishDir = Join-Path $publishRoot $buildId
$logPath = Join-Path $publishDir 'build.log'
$targetExe = Join-Path $projectRoot 'Plain Craft Launcher 2.exe'
$backupExe = $null

Push-Location -LiteralPath $projectRoot
try {
    if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
        throw 'The .NET SDK is required. Install the .NET 10 SDK and try again.'
    }
    New-Item -ItemType Directory -Path $publishDir -Force | Out-Null
    Write-Host 'Building Release x64, self-contained single-file EXE...'
    Write-Host "Build log: $logPath"
    & dotnet publish $projectFile -c Release -p:Platform=x64 -r win-x64 --self-contained true -p:PublishSingleFile=true "-p:IntermediateOutputPath=obj/one-click/$buildId/" -o $publishDir -v quiet *> $logPath
    if ($LASTEXITCODE -ne 0) {
        Get-Content -LiteralPath $logPath -Tail 30 | Out-Host
        throw "Build failed. See the full log: $logPath"
    }

    $publishedExe = Join-Path $publishDir 'Plain Craft Launcher 2.exe'
    if (-not (Test-Path -LiteralPath $publishedExe -PathType Leaf)) {
        throw 'Publish succeeded but the EXE is missing.'
    }
    $publishedHash = Get-Sha256 $publishedExe

    if (Test-Path -LiteralPath $targetExe) {
        # Read the entire existing binary before replacing it, then preserve a verified backup.
        $existingBytes = [IO.File]::ReadAllBytes($targetExe)
        if ($existingBytes.Length -lt 2 -or $existingBytes[0] -ne 0x4D -or $existingBytes[1] -ne 0x5A) {
            throw 'The existing target is not an EXE. Refusing to replace it.'
        }
        $existingBytes = $null
        $oldHash = Get-Sha256 $targetExe
        $backupDir = Join-Path $env:USERPROFILE ('.Config\.backup\PCL-build-' + $buildId)
        New-Item -ItemType Directory -Path $backupDir | Out-Null
        $backupExe = Join-Path $backupDir 'Plain Craft Launcher 2.exe'
        Copy-Item -LiteralPath $targetExe -Destination $backupExe
        if ((Get-Sha256 $backupExe) -ne $oldHash) {
            throw 'Backup verification failed. The target has not been replaced.'
        }
        Write-Host "Previous EXE backup: $backupExe"
    }

    # Stage on the same volume so an in-use EXE cannot be partially overwritten.
    $stagedExe = Join-Path $publishDir 'ready.exe'
    Copy-Item -LiteralPath $publishedExe -Destination $stagedExe
    if ((Get-Sha256 $stagedExe) -ne $publishedHash) {
        throw 'Staged EXE verification failed.'
    }
    if (Test-Path -LiteralPath $targetExe) {
        [IO.File]::Replace($stagedExe, $targetExe, [System.Management.Automation.Language.NullString]::Value)
    } else {
        [IO.File]::Move($stagedExe, $targetExe)
    }
    if ((Get-Sha256 $targetExe) -ne $publishedHash) {
        throw 'Output EXE verification failed. The published EXE and any backup are preserved.'
    }
    Write-Host "Success: $targetExe" -ForegroundColor Green
    Write-Host "SHA256: $publishedHash"
} catch {
    Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host 'If the EXE is running, close it before retrying.'
    exit 1
} finally {
    Pop-Location
}
exit 0
