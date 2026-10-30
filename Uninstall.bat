@echo off
rem Uninstall Deity Zenith for Majesty Gold HD
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install_DeityZenith.ps1" -Action Uninstall %*
echo.
pause
