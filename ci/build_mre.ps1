$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$srcDir = Join-Path $repoRoot "mre"
$compiler = Join-Path $repoRoot "tools\\fteqcc_win64\\fteqcc64.exe"
$outputDir = Join-Path $repoRoot "ci\\mre"
$outputFile = Join-Path $outputDir "progs.dat"
$built = Join-Path $repoRoot "progs.dat"

if (!(Test-Path -Path $compiler)) {
    throw "Missing compiler: $compiler"
}

if (!(Test-Path -Path $srcDir)) {
    throw "Missing source directory: $srcDir"
}

if (!(Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
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
