@echo off
setlocal

REM CORRIENTAZO - One click dev (Windows)
REM - Emulador (API_BASE_URL=10.0.2.2)
REM - Celular (API_BASE_URL=http://LAN_IP:3000)

chcp 65001 >nul

set SCRIPT_DIR=%~dp0

echo.
echo === CORRIENTAZO - Modo de ejecucion ===
echo 1) Emulador (si hay 2+ AVD abiertos, abre 1 ventana Flutter por emulador)
echo 2) Celular (misma red WiFi)
echo.
choice /C 12 /N /M "Elige 1 o 2: "

if errorlevel 2 goto PHONE
goto EMULATOR

:EMULATOR
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%SCRIPT_DIR%START_DEV_EMULATOR.ps1" -Target emulator
goto END

:PHONE
powershell -NoProfile -ExecutionPolicy Bypass -NoExit -File "%SCRIPT_DIR%START_DEV_EMULATOR.ps1" -Target phone
goto END

:END
echo.
echo Listo.
pause

