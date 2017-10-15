@echo off
echo Fetches any newer Copypasta related files from the Data directory

setlocal ENABLEEXTENSIONS
set KEY_NAME=HKLM\Software\WOW6432Node\Bethesda Softworks\Fallout4
set VALUE_NAME=Installed Path
set repoPath=%~dp0Data

for /F "usebackq tokens=3*" %%a in (`reg query "%KEY_NAME%" /v "%VALUE_NAME%" 2^>nul ^| find "%VALUE_NAME%"`) do (
  set dataPath=%%b\Data
)

REM Format Paths to not have a '\' at the end
if "%repoPath:~-1%"=="\" (
  set repoPath=%repoPath:~0,-1%
)
if "%dataPath:~-1%"=="\" (
  set dataPath=%dataPath:~0,-1%
)
if not defined dataPath (
   echo Installation path not found.
   goto :eof
)

for /F "usebackq delims=" %%b in (files.txt) do (
  if "%%~xb"=="" (
    echo D | xcopy "%dataPath%\%%~b." "%repoPath%\%%~b" /C /D /S /I /Y
  ) else (
    echo F | xcopy "%dataPath%\%%~b" "%repoPath%\%%~b" /C /D /S /I /Y
  )
)
pause
