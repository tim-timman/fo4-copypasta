@echo off
setlocal ENABLEEXTENSIONS
set KEY_NAME=HKLM\Software\WOW6432Node\Bethesda Softworks\Fallout4
set VALUE_NAME=Installed Path
set repoPath=%~dp0Data

for /F "usebackq tokens=3*" %%A IN (`reg query "%KEY_NAME%" /v "%VALUE_NAME%" 2^>nul ^| find "%VALUE_NAME%"`) do (
  set dataPath=%%B\Data
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

set ppjPath=Scripts\Source\User\Copypasta.ppj
set scriptsPath=Scripts\Source\User\Copypasta\.

REM Copy the scripts and build project from repo to data
echo F | xcopy "%repoPath%\%ppjPath%" "%dataPath%\%ppjPath%" /C /D /S /I /Y
echo D | xcopy /exclude:files_to_exclude.txt "%repoPath%\%scriptsPath%" "%dataPath%\%scriptsPath%" /C /D /S /I /Y

REM Run the compiler
call "%dataPath%\..\Papyrus Compiler\PapyrusCompiler.exe" "%dataPath%\%ppjPath%"
pause
