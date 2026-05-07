@echo off
setlocal

REM CORRIENTAZO - One click dev (Windows + Emulador)
REM - Intenta lanzar el emulador
REM - Levanta backend (Docker)
REM - Arranca Flutter run en emulador con API_BASE_URL=10.0.2.2

chcp 65001 >nul

set SCRIPT_DIR=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%START_DEV_EMULATOR.ps1"

echo.
echo Listo.
pause

