@echo off
REM Replicable para cualquier usuario - usa %~dp0 (carpeta del script)
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0wallhaven-random.ps1" %*
pause
