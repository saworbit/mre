$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$srcDir = Join-Path $repoRoot "mre"
$defaultCompiler = Join-Path $repoRoot "tools\\fteqcc_win64\\fteqcc64.exe"
$outputDir = Join-Path $repoRoot "ci\\mre"
$outputFile = Join-Path $outputDir "progs.dat"
$built = Join-Path $repoRoot "progs.dat"
$launchDir = Join-Path $repoRoot "launch\\quake-spasm\\mre"
$launchFile = Join-Path $launchDir "progs.dat"

function Resolve-CompilerPath {
    param(
        [string]$Preferred
    )

    if (![string]::IsNullOrWhiteSpace($Preferred)) {
        if (!(Test-Path -Path $Preferred)) {
            throw "Missing compiler at FTEQCC path: $Preferred"
        }
        return (Resolve-Path $Preferred).Path
    }

    if (Test-Path -Path $defaultCompiler) {
        return (Resolve-Path $defaultCompiler).Path
    }

    $toolsDir = Join-Path $repoRoot "tools"
    $fteDir = Join-Path $toolsDir "fteqcc_win64"
    $downloadZip = Join-Path $fteDir "fteqw-win64.zip"

    Write-Host "Compiler not found; downloading fteqcc from fte-team/fteqw releases..."
    New-Item -ItemType Directory -Path $fteDir -Force | Out-Null

    try {
        $headers = @{ "User-Agent" = "reapbot-ci" }
        $release = Invoke-WebRequest -Uri "https://api.github.com/repos/fte-team/fteqw/releases/latest" -Headers $headers -UseBasicParsing | ConvertFrom-Json
        $asset = $release.assets | Where-Object { $_.name -like "fteqw-win64-*.zip" } | Select-Object -First 1
        if (-not $asset) {
            throw "Unable to locate fteqw-win64 zip asset in latest release."
        }

        Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $downloadZip
        Expand-Archive -Path $downloadZip -DestinationPath $fteDir -Force
        Remove-Item -Path $downloadZip -Force
    } catch {
        throw "Failed to download fteqcc. Set FTEQCC to a local fteqcc64.exe path. Details: $($_.Exception.Message)"
    }

    $foundCompiler = Get-ChildItem -Path $fteDir -Filter "fteqcc64.exe" -Recurse -File | Select-Object -First 1
    if (-not $foundCompiler) {
        throw "Download completed but fteqcc64.exe was not found under $fteDir"
    }

    return $foundCompiler.FullName
}

$compiler = Resolve-CompilerPath -Preferred $env:FTEQCC

if (!(Test-Path -Path $srcDir)) {
    throw "Missing source directory: $srcDir"
}

if (!(Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}
if (!(Test-Path -Path $launchDir)) {
    New-Item -ItemType Directory -Path $launchDir | Out-Null
}

$startTime = Get-Date
Push-Location $srcDir
try {
    & $compiler -O3 progs.src
    if ($LASTEXITCODE -ne 0) {
        throw "Compiler failed with exit code $LASTEXITCODE"
    }
} finally {
    Pop-Location
}

if (!(Test-Path -Path $built)) {
    throw "Build failed: $built not found"
}

# Basic sanity check to catch partial or empty outputs in CI.
$minBytes = 200000
$builtItem = Get-Item -Path $built
$size = $builtItem.Length
if ($builtItem.LastWriteTime -lt $startTime) {
    throw "Build failed: progs.dat not updated (last write $($builtItem.LastWriteTime))"
}
if ($size -lt $minBytes) {
    throw "Build failed: progs.dat too small ($size bytes)"
}

Copy-Item -Path $built -Destination $outputFile -Force
Write-Host "Built $outputFile ($size bytes)"
Copy-Item -Path $built -Destination $launchFile -Force
Write-Host "Deployed $launchFile"
