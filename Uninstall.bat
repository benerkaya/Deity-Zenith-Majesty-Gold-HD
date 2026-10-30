@echo off
rem Uninstall Deity for Majesty Gold HD
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install_Deity.ps1" -Action Uninstall %*
echo.
pause
