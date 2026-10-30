@echo off
rem Install Deity Zenith for Majesty Gold HD
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install_DeityZenith.ps1" -Action Install %*
echo.
pause
