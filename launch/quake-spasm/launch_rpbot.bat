@echo off
setlocal

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "MAXPLAYERS=%~1"
set "MAPNAME=%~2"

if "%MAXPLAYERS%"=="" set "MAXPLAYERS=8"
if "%MAPNAME%"=="" set "MAPNAME=dm4"

if not exist "%ROOT%\\quakespasm.exe" (
  echo ERROR: quakespasm.exe not found in %ROOT%
  echo If you are on 32-bit, run from .\win32 instead.
  exit /b 1
)

if not exist "%ROOT%\\id1\\PAK0.PAK" (
  echo ERROR: id1\\PAK0.PAK not found in %ROOT%id1
  echo Copy the Steam id1 pack files into %ROOT%id1 and try again.
  exit /b 1
)

echo Launching Reaper Bot...
echo Maxplayers: %MAXPLAYERS%  Map: %MAPNAME%
echo.

"%ROOT%\\quakespasm.exe" -basedir "%ROOT%" -game RPBOT -listen %MAXPLAYERS% +maxplayers %MAXPLAYERS% +deathmatch 1 +map %MAPNAME%

endlocal
