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
    # Best effort: launch first listed emulator id if available
    $lines = $emulators -split "`r?`n"
    $ids = @()
    foreach ($line in $lines) {
      if ($line -match "^\s*([^\s]+)\s+") {
        $id = $Matches[1]
        if ($id -and $id -ne "Id" -and $id -ne "-----") { $ids += $id }
      }
    }
    if ($ids.Count -gt 0) {
      $emuId = $ids[0]
      Write-Host "Intentando abrir emulador: $emuId"
      flutter emulators --launch $emuId | Out-Host
      Start-Sleep -Seconds 3
    } else {
      Write-Host "No detecté emuladores automáticamente. Ábrelo manualmente si hace falta." -ForegroundColor Yellow
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
Push-Location $mobileRoot
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
Pop-Location

