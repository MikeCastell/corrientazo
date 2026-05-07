$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

function Title($t) {
  Write-Host ""
  Write-Host "=== $t ===" -ForegroundColor Cyan
}

$workspaceRoot = (Resolve-Path $PSScriptRoot).Path
$mobileRoot = Join-Path $workspaceRoot "mobile"
$composeFile = Join-Path $workspaceRoot "backend\docker-compose.yml"

Title "CORRIENTAZO - Dev (1 clic)"
Write-Host "Workspace: $workspaceRoot"

Title "0) Emulador (opcional)"
try {
  Push-Location $mobileRoot
  $emulators = (flutter emulators) 2>$null
  if ($LASTEXITCODE -eq 0 -and $emulators) {
    # Best effort: the output is a table. We pick the first row that matches:
    # <Id> • <Name> • <Manufacturer> • <Platform>
    $lines = $emulators -split "`r?`n"
    $emuId = $null
    foreach ($line in $lines) {
      # Example:
      # Pixel_8 • Pixel 8 • Google • android
      if ($line -match "^\s*([A-Za-z0-9_\\-]+)\s*•\s*.+\s*•\s*.+\s*•\s*(android|ios)\s*$") {
        $emuId = $Matches[1]
        break
      }
      # Fallback: space-separated columns (some terminals strip the bullet)
      if (-not $emuId -and $line -match "^\s*([A-Za-z0-9_\\-]+)\s+.+\s+android\s*$") {
        $emuId = $Matches[1]
        break
      }
    }
    if ($emuId) {
      Write-Host "Intentando abrir emulador: $emuId"
      flutter emulators --launch $emuId | Out-Host
      Start-Sleep -Seconds 3
    } else {
      Write-Host "No pude detectar el ID del emulador automáticamente. Ábrelo manualmente." -ForegroundColor Yellow
    }
  } else {
    Write-Host "No pude listar emuladores. Ábrelo manualmente si hace falta." -ForegroundColor Yellow
  }
} catch {
  Write-Host "No pude lanzar el emulador automáticamente. Ábrelo manualmente." -ForegroundColor Yellow
} finally {
  try { Pop-Location } catch {}
}

Title "1) Backend (Docker)"
if (-not (Test-Path $composeFile)) {
  throw "No encontré docker-compose en: $composeFile"
}
Push-Location $workspaceRoot
docker compose -f $composeFile up -d | Out-Host
Pop-Location

Title "2) Flutter (emulador)"
Write-Host "Si tu emulador NO es emulator-5554, cambia el -d en este script."
Write-Host "Tip: si el emulador se cierra, usamos render por software (más estable)."
Push-Location $mobileRoot
flutter run -d emulator-5554 --enable-software-rendering --dart-define=API_BASE_URL=http://10.0.2.2:3000 --dart-define=STARTUP_DEBUG=true
Pop-Location

