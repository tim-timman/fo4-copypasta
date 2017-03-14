@echo off
echo Pushes the Copypasta files to the Data directory
echo 
set dataPath=%ProgramFiles(x86)%\Steam\steamapps\common\Fallout 4\Data
set gitPath=%~dp0\Data
xcopy "%gitPath%" "%dataPath%" /D /-Y /S
pause