$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

function Write-Title($t) {
  Write-Host ""
  Write-Host "=== $t ===" -ForegroundColor Cyan
}

$mobileToolsDev = (Resolve-Path $PSScriptRoot).Path
$mobileRoot = (Resolve-Path (Join-Path $mobileToolsDev "..\\..")).Path         # .../mobile
$workspaceRoot = (Resolve-Path (Join-Path $mobileRoot "..")).Path              # .../CORRIENTAZO
$composeFile = Join-Path $workspaceRoot "backend\\docker-compose.yml"

Write-Title "CORRIENTAZO Dev (Emulador)"
Write-Host "Workspace: $workspaceRoot"
Write-Host "Mobile:     $mobileRoot"

Write-Title "1) Levantando backend (Docker)"
if (-not (Test-Path $composeFile)) {
  throw "No encontre docker-compose en: $composeFile"
}
Push-Location $workspaceRoot
docker compose -f $composeFile up -d | Out-Host
Pop-Location

Write-Title "2) Arrancando Flutter (emulador)"
Write-Host "IMPORTANTE:"
Write-Host "- Abre tu emulador ANTES de correr este archivo."
Write-Host "- Si tienes varios dispositivos, corre 'flutter devices' y ajusta el -d."

Push-Location $mobileRoot
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://10.0.2.2:3000
Pop-Location

