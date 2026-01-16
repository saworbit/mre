@echo off
REM Quick launcher for stability tests
REM Usage: test_stability.bat [--quick]

setlocal
cd /d "%~dp0.."

if "%1"=="--quick" (
    echo Running QUICK stability tests (reduced duration)...
    powershell -ExecutionPolicy Bypass -File ci\Test-Stability.ps1 -SpDuration 30 -MpDuration 60 -OverflowDuration 15
) else (
    echo Running FULL stability tests...
    powershell -ExecutionPolicy Bypass -File ci\Test-Stability.ps1
)

endlocal
