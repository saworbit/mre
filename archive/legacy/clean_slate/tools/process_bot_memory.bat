@echo off
REM Bot Memory Manager - Windows Launcher
REM Runs the automated waypoint persistence pipeline

echo ========================================
echo   BOT MEMORY MANAGER
echo   Modern Reaper Enhancements - Phase 5
echo ========================================
echo.

REM Check if Python is available
where python >NUL 2>NUL
if errorlevel 1 (
    echo ERROR: Python not found in PATH
    echo Please install Python 3.7+ from python.org
    pause
    exit /b 1
)

REM Run auto-pipeline
echo Running automated pipeline...
echo.
python "%~dp0bot_memory_manager.py" auto

echo.
echo ========================================
echo   PIPELINE COMPLETE
echo ========================================
echo.
echo Next steps:
echo   1. Add generated .qc file to progs.src
echo   2. Add Load function to worldspawn
echo   3. Recompile with FTEQCC
echo.
pause
