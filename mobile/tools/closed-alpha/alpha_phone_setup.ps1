$ErrorActionPreference = "Stop"

# Make console output UTF-8 (avoid "telÃ©fono" issues)
try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

function Write-Title($t) {
  Write-Host ""
  Write-Host "=== $t ===" -ForegroundColor Cyan
}

function Get-LanIPv4 {
  # 1) Preferred: query Windows network stack (works on most machines)
  try {
    $ips = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction Stop |
      Where-Object {
        $_.IPAddress -and
        $_.IPAddress -ne "127.0.0.1" -and
        $_.IPAddress -notmatch "^169\\.254\\." -and
        $_.IPAddress -match "^(10\\.|192\\.168\\.|172\\.(1[6-9]|2[0-9]|3[0-1])\\.)"
      } |
      Sort-Object -Property InterfaceMetric |
      Select-Object -ExpandProperty IPAddress

    if ($ips -and $ips.Count -gt 0) { return $ips[0] }
  } catch {}

  # 2) Fallback: parse any IPv4 from ipconfig (language-agnostic)
  $text = (ipconfig | Out-String)
  $matches = [regex]::Matches($text, "\b((?:\d{1,3}\.){3}\d{1,3})\b")
  foreach ($m in $matches) {
    $ip = $m.Groups[1].Value
    if ($ip -eq "127.0.0.1") { continue }
    if ($ip.StartsWith("169.254.")) { continue }
    if ($ip -match "^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)") { return $ip }
  }

  throw "No pude detectar tu IP LAN automáticamente. Abre CMD, corre ipconfig y copia tu 'Dirección IPv4'."
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\\..")).Path
$mobileDir = $repoRoot
$workspaceRoot = (Resolve-Path (Join-Path $repoRoot "..")).Path
$composeFile = Join-Path $workspaceRoot "backend\\docker-compose.yml"

Write-Title "CORRIENTAZO Closed Alpha - Setup para telefono"

Write-Title "1) Detectando IP LAN"
$ip = Get-LanIPv4
Write-Host "IP detectada: $ip"
$baseUrl = "http://${ip}:3000"
Write-Host "API_BASE_URL (telefono): $baseUrl"

Write-Title "2) Levantando backend (Docker Compose)"
if (-not (Test-Path $composeFile)) {
  throw "No encontré docker-compose en: $composeFile"
}

Push-Location $workspaceRoot
docker compose -f $composeFile up -d | Out-Host
Pop-Location

Write-Title "3) Probando salud del backend"
$healthUrl = "$baseUrl/api/v1/healthz"
Write-Host "Probando: $healthUrl"
try {
  $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 10 -Uri $healthUrl
  Write-Host "OK: $($r.StatusCode) $($r.Content)" -ForegroundColor Green
} catch {
  Write-Host "NO pude confirmar health desde la PC." -ForegroundColor Yellow
  Write-Host "Aun así continuaré con el build. Si el teléfono no conecta, revisa firewall/red." -ForegroundColor Yellow
}

Write-Title "4) Construyendo APK release (apunta a tu IP LAN)"
Push-Location $mobileDir
flutter pub get | Out-Host
flutter analyze | Out-Host
flutter build apk --release --dart-define=API_BASE_URL=$baseUrl | Out-Host
Pop-Location

$apk = Join-Path $mobileDir "build\\app\\outputs\\flutter-apk\\app-release.apk"

Write-Title "5) Resultado"
if (Test-Path $apk) {
  $info = Get-Item $apk
  Write-Host "APK listo:" -ForegroundColor Green
  Write-Host "  $($info.FullName)"
  Write-Host ("  Tamaño: {0:N1} MB" -f ($info.Length / 1MB))
  Write-Host ""
  Write-Host "Instalación (opción A): copia el APK al teléfono e instálalo."
  Write-Host "Instalación (opción B - ADB): adb install -r `"$apk`""
  Write-Host ""
  Write-Host "IMPORTANTE: En el teléfono, prueba en Chrome:"
  Write-Host "  $healthUrl"
} else {
  throw "No encontré el APK en: $apk"
}

