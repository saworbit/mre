@echo off
setlocal

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "MAXPLAYERS=%~1"
set "MAPNAME=%~2"

if "%MAXPLAYERS%"=="" set "MAXPLAYERS=8"
if "%MAPNAME%"=="" set "MAPNAME=dm4"

set "FTE_EXE=%ROOT%\\..\\fteqw_win64\\fteqw64.exe"
set "QS_EXE=%ROOT%\\quakespasm.exe"
if exist "%QS_EXE%" (
  for %%A in ("%QS_EXE%") do set "QS_SIZE=%%~zA"
)
if not exist "%QS_EXE%" (
  set "QS_SIZE="
)
if "%QS_SIZE%"=="0" (
  set "QS_SIZE="
)
if "%QS_SIZE%"=="" (
  if exist "%ROOT%\\quakespasm-sdl12.exe" (
    set "QS_EXE=%ROOT%\\quakespasm-sdl12.exe"
  ) else (
    echo ERROR: quakespasm.exe not found or is empty in %ROOT%
    echo If you are on 32-bit, run from .\\win32 instead.
    exit /b 1
  )
)

if not exist "%ROOT%\\id1\\PAK0.PAK" (
  echo ERROR: id1\\PAK0.PAK not found in %ROOT%id1
  echo Copy the Steam id1 pack files into %ROOT%id1 and try again.
  exit /b 1
)

if not exist "%ROOT%\\mre\\progs.dat" (
  echo ERROR: mre\\progs.dat not found in %ROOT%mre
  echo Build or copy the v2 progs.dat and try again.
  exit /b 1
)

echo Launching Reapbot v2...
echo Maxplayers: %MAXPLAYERS%  Map: %MAPNAME%
echo.

set "PROGS_VER="
for /f %%V in ('powershell -NoProfile -Command "$p='%ROOT%\\mre\\progs.dat'; if (Test-Path $p) { $b=Get-Content -Encoding Byte -TotalCount 4 $p; if ($b.Length -ge 4) { [BitConverter]::ToInt32($b,0) } }"') do set "PROGS_VER=%%V"

if "%PROGS_VER%"=="6" (
  "%QS_EXE%" -basedir "%ROOT%" -game mre -listen %MAXPLAYERS% +maxplayers %MAXPLAYERS% +deathmatch 1 +map %MAPNAME%
) else if exist "%FTE_EXE%" (
  echo Using FTEQW (required for FTE progs.dat)...
  "%FTE_EXE%" -basedir "%ROOT%" -game mre -condebug +developer 1 -listen %MAXPLAYERS% +maxplayers %MAXPLAYERS% +deathmatch 1 +map %MAPNAME%
) else (
  "%QS_EXE%" -basedir "%ROOT%" -game mre -listen %MAXPLAYERS% +maxplayers %MAXPLAYERS% +deathmatch 1 +map %MAPNAME%
)

endlocal
