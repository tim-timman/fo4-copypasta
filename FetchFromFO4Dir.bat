@echo off
echo Fetches any newer Copypasta related files from the Data directory

setlocal ENABLEEXTENSIONS
set KEY_NAME=HKLM\Software\WOW6432Node\Bethesda Softworks\Fallout4
set VALUE_NAME=Installed Path
set gitPath=%~dp0Data

for /F "usebackq tokens=3*" %%A IN (`reg query "%KEY_NAME%" /v "%VALUE_NAME%" 2^>nul ^| find "%VALUE_NAME%"`) do (
	set dataPath=%%B\Data
)

if defined dataPath (
	@echo off
	xcopy "%dataPath%\meshes\Copypasta" "%gitPath%\meshes\Copypasta" /DYS
	xcopy "%dataPath%\Textures\Copypasta" "%gitPath%\Textures\Copypasta" /DYS
	xcopy "%dataPath%\Scripts\Copypasta_v2" "%gitPath%\Scripts\Copypasta_v2" /DYS
	xcopy "%dataPath%\Scripts\Source\User\Copypasta_v2" "%gitPath%\Scripts\Source\User\Copypasta_v2" /DYS
	xcopy "%dataPath%\Copypasta.esp" "%gitPath%\Copypasta.esp" /DY
) else (
	@echo off
	echo Installation Path not found.
)
pause