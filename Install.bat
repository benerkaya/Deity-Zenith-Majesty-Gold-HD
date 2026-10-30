@echo off
rem Install Deity for Majesty Gold HD
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install_Deity.ps1" -Action Install %*
echo.
pause
