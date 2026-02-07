@echo off
setlocal

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "MAXPLAYERS=%~1"
set "MAPNAME=%~2"

if "%MAXPLAYERS%"=="" set "MAXPLAYERS=8"
if "%MAPNAME%"=="" set "MAPNAME=dm4"

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

"%QS_EXE%" -basedir "%ROOT%" -game mre -listen %MAXPLAYERS% +maxplayers %MAXPLAYERS% +deathmatch 1 +map %MAPNAME%

endlocal
