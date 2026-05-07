@echo off
setlocal

REM CORRIENTAZO - Dev start (Emulador Android)
REM - Levanta backend (Docker)
REM - Arranca Flutter en el emulador con API_BASE_URL=10.0.2.2

chcp 65001 >nul
set SCRIPT_DIR=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%dev_emulator_start.ps1"

echo.
echo Listo.
pause
