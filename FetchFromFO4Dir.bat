@echo off
echo Fetches any newer Copypasta related files from the Data directory
echo 
set dataPath=%ProgramFiles(x86)%\Steam\steamapps\common\Fallout 4\Data
set gitPath=%~dp0\Data
xcopy "%dataPath%\meshes\Copypasta" "%gitPath%\meshes\Copypasta" /DYS
xcopy "%dataPath%\Textures\Copypasta" "%gitPath%\Textures\Copypasta" /DYS
xcopy "%dataPath%\Scripts\Copypasta_v2" "%gitPath%\Scripts\Copypasta_v2" /DYS
xcopy "%dataPath%\Scripts\Source\User\Copypasta_v2" "%gitPath%\Scripts\Source\User\Copypasta_v2" /DYS
xcopy "%dataPath%\Copypasta.esp" "%gitPath%\Copypasta.esp" /DY
pause