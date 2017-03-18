@echo off
echo Pushes any files in the Copypasta local repository to the Data directory

setlocal ENABLEEXTENSIONS
set KEY_NAME=HKLM\Software\WOW6432Node\Bethesda Softworks\Fallout4
set VALUE_NAME=Installed Path
set gitPath=%~dp0Data

for /F "usebackq tokens=3*" %%A IN (`reg query "%KEY_NAME%" /v "%VALUE_NAME%" 2^>nul ^| find "%VALUE_NAME%"`) do (
	set dataPath=%%B\Data
)

REM Format Paths to not have a '\' at the end
if "%gitPath:~-1%"=="\" (
	set gitPath=%gitPath:~0,-1%
)
if "%dataPath:~-1%"=="\" (
	set dataPath=%dataPath:~0,-1%
)

if defined dataPath (
	@echo off
	xcopy "%gitPath%" "%dataPath%" /D /-Y /S
) else (
	@echo off
	echo Installation Path not found.
)
pause
