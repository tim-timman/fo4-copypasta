@echo off
echo Fetches any newer Copypasta related files from the Data directory

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
	xcopy "%dataPath%\meshes\Copypasta" "%gitPath%\meshes\Copypasta" /DYS
	xcopy "%dataPath%\Textures\Copypasta" "%gitPath%\Textures\Copypasta" /DYS
	xcopy "%dataPath%\Scripts\Copypasta_v2" "%gitPath%\Scripts\Copypasta_v2" /DYS
	xcopy "%dataPath%\Scripts\Source\User\Copypasta_v2" "%gitPath%\Scripts\Source\User\Copypasta_v2" /DYS
	echo F | xcopy "%dataPath%\Copypasta.esp" "%gitPath%\Copypasta.esp" /DY
	echo F | xcopy "%dataPath%\IPA.esp" "%gitPath%\IPA.esp" /DY
) else (
	@echo off
	echo Installation Path not found.
)
pause