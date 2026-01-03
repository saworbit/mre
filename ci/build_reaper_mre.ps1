$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$srcDir = Join-Path $repoRoot "reaper_mre"
$compiler = Join-Path $repoRoot "tools\\fteqcc_win64\\fteqcc64.exe"
$outputDir = Join-Path $repoRoot "ci\\reaper_mre"
$outputFile = Join-Path $outputDir "progs.dat"

if (!(Test-Path -Path $compiler)) {
    throw "Missing compiler: $compiler"
}

if (!(Test-Path -Path $srcDir)) {
    throw "Missing source directory: $srcDir"
}

if (!(Test-Path -Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

# Compile from the source directory so relative includes and progs.src resolve correctly.
Push-Location $srcDir
try {
    & $compiler -O3 progs.src
} finally {
    Pop-Location
}

$built = Join-Path $srcDir "progs.dat"
if (!(Test-Path -Path $built)) {
    throw "Build failed: $built not found"
}

# Basic sanity check to catch partial or empty outputs in CI.
$minBytes = 200000
$size = (Get-Item -Path $built).Length
if ($size -lt $minBytes) {
    throw "Build failed: progs.dat too small ($size bytes)"
}

# Publish the artifact into the CI folder for downstream steps.
Copy-Item -Path $built -Destination $outputFile -Force
Write-Host "Built $outputFile ($size bytes)"
