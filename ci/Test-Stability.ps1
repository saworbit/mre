<#
.SYNOPSIS
    Automated stability regression tests for Reapbot.

.DESCRIPTION
    Runs QuakeSpasm with bot stress tests, captures output, and provides analysis.

.EXAMPLE
    .\ci\Test-Stability.ps1
    .\ci\Test-Stability.ps1 -SpDuration 30 -MpDuration 60
#>

param(
    [int]$SpDuration = 60,
    [int]$MpDuration = 120,
    [int]$OverflowDuration = 30,
    [string]$QuakePath = "",
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$script:TestsPassed = 0
$script:TestsFailed = 0
$script:TestResults = @()
$script:Insights = @()

# Resolve paths
$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $QuakePath) {
    $QuakePath = Join-Path $RepoRoot "launch\quake-spasm"
}
$QuakeExe = Join-Path $QuakePath "quakespasm.exe"
$MreFolder = Join-Path $QuakePath "mre"
$TestLogDir = Join-Path $RepoRoot "ci\logs"

# Ensure log directory exists
if (-not (Test-Path $TestLogDir)) {
    New-Item -ItemType Directory -Path $TestLogDir -Force | Out-Null
}

# Possible log locations (QuakeSpasm may write here)
$LogLocations = @(
    (Join-Path $QuakePath "qconsole.log"),
    (Join-Path $MreFolder "qconsole.log"),
    (Join-Path $QuakePath "id1\qconsole.log")
)

# Error patterns to detect (CRITICAL = test failure)
$ErrorPatterns = @(
    @{ Pattern = "runaway loop"; Severity = "CRITICAL"; Desc = "Infinite loop in QuakeC code" }
    @{ Pattern = "stack overflow"; Severity = "CRITICAL"; Desc = "Recursive call exceeded stack" }
    @{ Pattern = "edict overflow"; Severity = "CRITICAL"; Desc = "Too many entities spawned" }
    @{ Pattern = "no free edicts"; Severity = "CRITICAL"; Desc = "Entity limit reached" }
    @{ Pattern = "PROGS.DAT system vars"; Severity = "CRITICAL"; Desc = "QuakeC globals corrupted" }
    @{ Pattern = "Host_Error"; Severity = "CRITICAL"; Desc = "Engine host error" }
    @{ Pattern = "Sys_Error"; Severity = "CRITICAL"; Desc = "System-level error" }
    @{ Pattern = "FATAL"; Severity = "CRITICAL"; Desc = "Fatal error occurred" }
    @{ Pattern = "SV_TouchLinks"; Severity = "CRITICAL"; Desc = "Entity touch chain error" }
)

# Warning patterns (notable but not failures)
$WarningPatterns = @(
    @{ Pattern = "sv_aim is deprecated"; Severity = "WARN"; Desc = "Expected once per map" }
    @{ Pattern = "Couldn't spawn"; Severity = "WARN"; Desc = "Bot spawn blocked (may be expected)" }
    @{ Pattern = "no spawn point"; Severity = "WARN"; Desc = "Missing info_player_deathmatch" }
    @{ Pattern = "illegible"; Severity = "WARN"; Desc = "Asset loading issue" }
    @{ Pattern = "weapon\.mdl"; Severity = "INFO"; Desc = "Weapon model loaded" }
    @{ Pattern = "player\.mdl"; Severity = "INFO"; Desc = "Player model loaded" }
)

# Performance/behavior patterns to track
$MetricPatterns = @(
    @{ Pattern = "Bot added"; Count = 0; Desc = "Bots successfully spawned" }
    @{ Pattern = "impulse 100"; Count = 0; Desc = "Bot add commands received" }
    @{ Pattern = "waypoint"; Count = 0; Desc = "Waypoint operations" }
    @{ Pattern = "target"; Count = 0; Desc = "Target acquisitions" }
)

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor Cyan
    Write-Host "  $Title" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor Cyan
}

function Write-TestResult {
    param([string]$TestName, [bool]$Passed, [string]$Message = "")

    if ($Passed) {
        Write-Host "[PASS] " -ForegroundColor Green -NoNewline
        Write-Host $TestName
        $script:TestsPassed++
    } else {
        Write-Host "[FAIL] " -ForegroundColor Red -NoNewline
        Write-Host "$TestName - $Message"
        $script:TestsFailed++
    }

    $script:TestResults += @{ Name = $TestName; Passed = $Passed; Message = $Message; Timestamp = (Get-Date).ToString("o") }
}

function Add-Insight {
    param([string]$Category, [string]$Message, [string]$Severity = "INFO")
    $script:Insights += @{ Category = $Category; Message = $Message; Severity = $Severity }

    $color = switch ($Severity) {
        "CRITICAL" { "Red" }
        "WARN" { "Yellow" }
        "GOOD" { "Green" }
        default { "Gray" }
    }
    Write-Host "  [$Severity] " -ForegroundColor $color -NoNewline
    Write-Host "$Category : $Message"
}

function Clear-AllLogs {
    foreach ($loc in $LogLocations) {
        if (Test-Path $loc) {
            Remove-Item $loc -Force -ErrorAction SilentlyContinue
        }
    }
}

function Find-ConsoleLog {
    foreach ($loc in $LogLocations) {
        if (Test-Path $loc) {
            return $loc
        }
    }
    return $null
}

function Analyze-Output {
    param([string]$TestName, [string]$StdOut, [string]$StdErr, [int]$Duration, [int]$ActualDuration, [bool]$CrashedEarly)

    Write-Host ""
    Write-Host "  --- Analysis ---" -ForegroundColor Magenta

    $errors = @()
    $warnings = @()
    $metrics = @{}

    # Combine all output for analysis
    $allOutput = "$StdOut`n$StdErr"

    # Also check for engine log file
    $logPath = Find-ConsoleLog
    if ($logPath) {
        $logContent = Get-Content $logPath -Raw -ErrorAction SilentlyContinue
        if ($logContent) {
            $allOutput += "`n$logContent"
            Add-Insight -Category "Log" -Message "Found console log at $logPath" -Severity "INFO"
        }
    }

    $outputLines = $allOutput.Split("`n").Count
    $outputSize = $allOutput.Length

    # Check for critical errors
    foreach ($pattern in $ErrorPatterns) {
        $matches = [regex]::Matches($allOutput, $pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($matches.Count -gt 0) {
            $errors += @{ Pattern = $pattern.Pattern; Count = $matches.Count; Desc = $pattern.Desc }
            Add-Insight -Category "Error" -Message "$($pattern.Desc) - found $($matches.Count)x" -Severity "CRITICAL"
        }
    }

    # Check for warnings
    foreach ($pattern in $WarningPatterns) {
        $matches = [regex]::Matches($allOutput, $pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        if ($matches.Count -gt 0) {
            $warnings += @{ Pattern = $pattern.Pattern; Count = $matches.Count; Desc = $pattern.Desc }
            if ($pattern.Severity -eq "WARN") {
                Add-Insight -Category "Warning" -Message "$($pattern.Desc) - found $($matches.Count)x" -Severity "WARN"
            }
        }
    }

    # Collect metrics
    foreach ($pattern in $MetricPatterns) {
        $matches = [regex]::Matches($allOutput, $pattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $metrics[$pattern.Desc] = $matches.Count
    }

    # Process survival analysis
    if ($CrashedEarly) {
        $survivalPct = [math]::Round(($ActualDuration / $Duration) * 100)
        Add-Insight -Category "Stability" -Message "Process crashed at ${ActualDuration}s (${survivalPct}% of target)" -Severity "CRITICAL"
        $errors += @{ Pattern = "EARLY_EXIT"; Count = 1; Desc = "Process terminated early" }
    } else {
        Add-Insight -Category "Stability" -Message "Process survived full ${Duration}s duration" -Severity "GOOD"
    }

    # Output analysis
    if ($outputSize -gt 0) {
        Add-Insight -Category "Output" -Message "Captured $outputLines lines ($outputSize bytes)" -Severity "INFO"
    } else {
        Add-Insight -Category "Output" -Message "No console output captured (QuakeSpasm may need -developer 1)" -Severity "WARN"
    }

    # Recommendations based on findings
    Write-Host ""
    Write-Host "  --- Recommendations ---" -ForegroundColor Magenta

    if ($errors.Count -eq 0 -and -not $CrashedEarly) {
        Write-Host "  [OK] " -ForegroundColor Green -NoNewline
        Write-Host "No issues detected. Test passed."
    }

    if ($errors | Where-Object { $_.Pattern -match "edict" }) {
        Write-Host "  [FIX] " -ForegroundColor Yellow -NoNewline
        Write-Host "Reduce entity count or increase SP waypoint cap in botspawn.qc"
    }

    if ($errors | Where-Object { $_.Pattern -match "runaway" }) {
        Write-Host "  [FIX] " -ForegroundColor Yellow -NoNewline
        Write-Host "Check for infinite loops in bot AI - likely in route cache or goal selection"
    }

    if ($errors | Where-Object { $_.Pattern -match "stack" }) {
        Write-Host "  [FIX] " -ForegroundColor Yellow -NoNewline
        Write-Host "Deep recursion detected - add cycle detection or iteration limits"
    }

    if ($outputSize -eq 0) {
        Write-Host "  [TIP] " -ForegroundColor Cyan -NoNewline
        Write-Host "For more detailed logs, run QuakeSpasm manually with: -developer 1 +developer 1"
    }

    return @{
        Errors = $errors
        Warnings = $warnings
        Metrics = $metrics
        OutputSize = $outputSize
        CrashedEarly = $CrashedEarly
    }
}

function Run-QuakeTest {
    param(
        [string]$TestName,
        [string]$ConfigFile,
        [string]$Map,
        [int]$MaxPlayers,
        [int]$Duration,
        [switch]$Singleplayer
    )

    Write-Host ""
    Write-Host "Running: $TestName" -ForegroundColor Yellow
    Write-Host "  Config: $ConfigFile | Map: $Map | Duration: ${Duration}s"

    Clear-AllLogs

    # Prepare log files for this test
    $testSlug = $TestName -replace '[^a-zA-Z0-9]', '_'
    $stdOutLog = Join-Path $TestLogDir "${testSlug}_stdout.log"
    $stdErrLog = Join-Path $TestLogDir "${testSlug}_stderr.log"

    # Build arguments - add developer mode for more output
    $argList = @(
        "-basedir", $QuakePath,
        "-game", "mre",
        "-condebug",
        "+developer", "1"
    )

    if ($Singleplayer) {
        $argList += @("+map", $Map)
    } else {
        $argList += @("-listen", $MaxPlayers, "+maxplayers", $MaxPlayers, "+deathmatch", "1", "+map", $Map)
    }

    $argList += @("+exec", $ConfigFile)

    Write-Host "  Command: quakespasm.exe $($argList -join ' ')" -ForegroundColor DarkGray

    try {
        # Start process with output redirection
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = $QuakeExe
        $psi.Arguments = $argList -join ' '
        $psi.UseShellExecute = $false
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.CreateNoWindow = $false
        $psi.WindowStyle = [System.Diagnostics.ProcessWindowStyle]::Minimized

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $psi

        # Capture output asynchronously
        $stdOutBuilder = New-Object System.Text.StringBuilder
        $stdErrBuilder = New-Object System.Text.StringBuilder

        $stdOutEvent = Register-ObjectEvent -InputObject $process -EventName OutputDataReceived -Action {
            if ($EventArgs.Data) { $Event.MessageData.AppendLine($EventArgs.Data) }
        } -MessageData $stdOutBuilder

        $stdErrEvent = Register-ObjectEvent -InputObject $process -EventName ErrorDataReceived -Action {
            if ($EventArgs.Data) { $Event.MessageData.AppendLine($EventArgs.Data) }
        } -MessageData $stdErrBuilder

        $process.Start() | Out-Null
        $process.BeginOutputReadLine()
        $process.BeginErrorReadLine()

        # Wait for test duration
        Write-Host "  Progress: " -NoNewline
        $elapsed = 0
        while ($elapsed -lt $Duration -and -not $process.HasExited) {
            Start-Sleep -Seconds 5
            $elapsed += 5
            $pct = [math]::Round(($elapsed / $Duration) * 100)
            Write-Host "$pct% " -NoNewline -ForegroundColor DarkGray
        }
        Write-Host ""

        $crashedEarly = $process.HasExited -and ($elapsed -lt ($Duration * 0.5))
        $actualDuration = $elapsed

        # Kill process if still running
        if (-not $process.HasExited) {
            # Give it a moment to flush output
            Start-Sleep -Milliseconds 500
            Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 1
        }

        # Unregister events
        Unregister-Event -SourceIdentifier $stdOutEvent.Name -ErrorAction SilentlyContinue
        Unregister-Event -SourceIdentifier $stdErrEvent.Name -ErrorAction SilentlyContinue

        # Get captured output
        $stdOut = $stdOutBuilder.ToString()
        $stdErr = $stdErrBuilder.ToString()

        # Save logs
        if ($stdOut) { $stdOut | Set-Content $stdOutLog -ErrorAction SilentlyContinue }
        if ($stdErr) { $stdErr | Set-Content $stdErrLog -ErrorAction SilentlyContinue }

        # Analyze results
        $analysis = Analyze-Output -TestName $TestName -StdOut $stdOut -StdErr $stdErr -Duration $Duration -ActualDuration $actualDuration -CrashedEarly $crashedEarly

        # Final verdict
        Write-Host ""
        if ($analysis.Errors.Count -eq 0) {
            Write-TestResult -TestName $TestName -Passed $true
        } else {
            $errorMsg = ($analysis.Errors | ForEach-Object { $_.Desc }) -join "; "
            Write-TestResult -TestName $TestName -Passed $false -Message $errorMsg
        }

    } catch {
        Write-Host "  Exception: $_" -ForegroundColor Red
        Write-TestResult -TestName $TestName -Passed $false -Message "Launch failed: $_"
    }
}

# =============================================================================
# MAIN
# =============================================================================

Write-Host ""
Write-Host "========================================================================" -ForegroundColor Magenta
Write-Host "           REAPBOT STABILITY REGRESSION TEST SUITE                      " -ForegroundColor Magenta
Write-Host "========================================================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "  Repository:  $RepoRoot"
Write-Host "  QuakeSpasm:  $QuakePath"
Write-Host "  Log Output:  $TestLogDir"
Write-Host "  Timestamp:   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host ""

# Verify prerequisites
if (-not (Test-Path $QuakeExe)) {
    Write-Host "ERROR: QuakeSpasm not found at $QuakeExe" -ForegroundColor Red
    Write-Host "       Download QuakeSpasm and place in launch/quake-spasm/" -ForegroundColor Yellow
    exit 1
}

$pakFile = Join-Path $QuakePath "id1\PAK0.PAK"
if (-not (Test-Path $pakFile)) {
    Write-Host "ERROR: id1\PAK0.PAK not found" -ForegroundColor Red
    Write-Host "       Copy Quake data files (PAK0.PAK, PAK1.PAK) to launch/quake-spasm/id1/" -ForegroundColor Yellow
    exit 1
}

$progsFile = Join-Path $MreFolder "progs.dat"
if (-not (Test-Path $progsFile)) {
    if ($SkipBuild) {
        Write-Host "ERROR: mre\progs.dat not found and -SkipBuild specified" -ForegroundColor Red
        exit 1
    }
    Write-Host "Building progs.dat..." -ForegroundColor Yellow
    $buildScript = Join-Path $RepoRoot "ci\build_mre.ps1"
    & $buildScript
}

Write-Host "Prerequisites OK" -ForegroundColor Green

# =============================================================================
# TEST 1: SP Edict Overflow
# =============================================================================
Write-Section "TEST 1: Singleplayer Edict Overflow"
Write-Host "  Purpose:  Verify SP waypoint cap prevents edict overflow crash"
Write-Host "  Scenario: Load e1m1 (high entity count), add 2 bots"
Write-Host "  Watch:    'edict overflow', 'no free edicts', early crash"
Run-QuakeTest -TestName "SP Edict Overflow" -ConfigFile "test_stability_sp.cfg" -Map "e1m1" -MaxPlayers 4 -Duration $SpDuration -Singleplayer

# =============================================================================
# TEST 2: MP Route Recursion
# =============================================================================
Write-Section "TEST 2: Multiplayer Route Recursion / Lockup"
Write-Host "  Purpose:  Verify route cache doesn't cause exponential recursion"
Write-Host "  Scenario: Host dm4 DM with 8 bots (high route complexity)"
Write-Host "  Watch:    'runaway loop', 'stack overflow', process hang"
Run-QuakeTest -TestName "MP Route Recursion" -ConfigFile "test_stability_mp.cfg" -Map "dm4" -MaxPlayers 8 -Duration $MpDuration

# =============================================================================
# TEST 3: Scoreboard Overflow
# =============================================================================
Write-Section "TEST 3: Scoreboard Overflow Guard"
Write-Host "  Purpose:  Verify bot add rejects gracefully at maxplayers"
Write-Host "  Scenario: Try adding 12 bots when maxplayers=8"
Write-Host "  Watch:    Crash on 9th bot, array overflow"
Run-QuakeTest -TestName "Scoreboard Overflow" -ConfigFile "test_stability_overflow.cfg" -Map "dm4" -MaxPlayers 8 -Duration $OverflowDuration

# =============================================================================
# SUMMARY & INSIGHTS
# =============================================================================
Write-Section "TEST SUMMARY"

Write-Host ""
Write-Host "  Results:" -ForegroundColor White
Write-Host "    Passed: $script:TestsPassed" -ForegroundColor Green
if ($script:TestsFailed -gt 0) {
    Write-Host "    Failed: $script:TestsFailed" -ForegroundColor Red
} else {
    Write-Host "    Failed: $script:TestsFailed" -ForegroundColor Green
}
Write-Host "    Total:  $($script:TestsPassed + $script:TestsFailed)"
Write-Host ""

# Aggregate insights
if ($script:Insights.Count -gt 0) {
    Write-Host "  Key Insights:" -ForegroundColor White
    $criticals = $script:Insights | Where-Object { $_.Severity -eq "CRITICAL" }
    $warnings = $script:Insights | Where-Object { $_.Severity -eq "WARN" }
    $goods = $script:Insights | Where-Object { $_.Severity -eq "GOOD" }

    if ($criticals.Count -gt 0) {
        Write-Host "    Critical Issues: $($criticals.Count)" -ForegroundColor Red
    }
    if ($warnings.Count -gt 0) {
        Write-Host "    Warnings: $($warnings.Count)" -ForegroundColor Yellow
    }
    if ($goods.Count -gt 0) {
        Write-Host "    Healthy Checks: $($goods.Count)" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "  Logs saved to: $TestLogDir" -ForegroundColor DarkGray

# Save JSON results
$resultsFile = Join-Path $RepoRoot "ci\stability-results.json"
@{
    Timestamp = (Get-Date).ToString("o")
    Passed = $script:TestsPassed
    Failed = $script:TestsFailed
    Tests = $script:TestResults
    Insights = $script:Insights
} | ConvertTo-Json -Depth 4 | Set-Content $resultsFile

Write-Host "  JSON results: $resultsFile" -ForegroundColor DarkGray

# Final verdict
Write-Host ""
if ($script:TestsFailed -gt 0) {
    Write-Host "  STABILITY TESTS FAILED - See insights above for remediation" -ForegroundColor Red
    Write-Host ""
    exit 1
} else {
    Write-Host "  ALL STABILITY TESTS PASSED" -ForegroundColor Green
    Write-Host ""
    exit 0
}
