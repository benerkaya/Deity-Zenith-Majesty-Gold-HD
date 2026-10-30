@echo off
rem Status Deity Zenith for Majesty Gold HD
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install_DeityZenith.ps1" -Action Status %*
echo.
pause
