@echo off
setlocal

REM Use UTF-8 for correct accents
chcp 65001 >nul

REM CORRIENTAZO Closed Alpha helper (Windows)
REM Runs the PowerShell script that:
REM - detects LAN IP
REM - starts backend docker compose
REM - builds release APK with API_BASE_URL=http://<LAN_IP>:3000

set SCRIPT_DIR=%~dp0
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%alpha_phone_setup.ps1"

echo.
echo Listo.
pause

