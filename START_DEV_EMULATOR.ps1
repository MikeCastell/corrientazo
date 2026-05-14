param(
  [ValidateSet("emulator", "phone")]
  [string]$Target = "emulator"
)

$ErrorActionPreference = "Stop"

try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  $OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

function Title($t) {
  Write-Host ""
  Write-Host "=== $t ===" -ForegroundColor Cyan
}

$script:LanIp = $null

function Get-LanIPv4() {
  try {
    $candidates = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
      Where-Object {
        $_.IPAddress -and
        $_.IPAddress -notlike "127.*" -and
        $_.IPAddress -notlike "169.254.*"
      } |
      Sort-Object -Property InterfaceMetric |
      Select-Object -ExpandProperty IPAddress
    if ($candidates -and $candidates.Count -gt 0) { return $candidates[0] }
  } catch {}

  try {
    $raw = ipconfig 2>$null
    if ($raw) {
      $m = [regex]::Match($raw, "(?m)\\bIPv4[^:]*:\\s*([0-9]{1,3}(?:\\.[0-9]{1,3}){3})\\b")
      if ($m.Success) {
        $ip = $m.Groups[1].Value
        if ($ip -and -not ($ip -like "127.*") -and -not ($ip -like "169.254.*")) {
          return $ip
        }
      }
    }
  } catch {}

  return $null
}

function Test-CorrientazoApkZipOk {
  param([Parameter(Mandatory)][string]$ApkPath)
  if (-not (Test-Path -LiteralPath $ApkPath)) { return $false }
  try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop
    $z = [System.IO.Compression.ZipFile]::OpenRead($ApkPath)
    $z.Dispose()
    return $true
  } catch {
    return $false
  }
}

function Remove-CorrientazoBrokenDebugApk {
  param([Parameter(Mandatory)][string]$MobileRoot)
  # Flutter puede dejar APK en flutter-apk/; Gradle en apk/debug/. Cualquiera corrupto
  # (sin EOCD en el ZIP) rompe packageDebug / aapt / zipro.
  $candidates = @(
    (Join-Path $MobileRoot "build\app\outputs\flutter-apk\app-debug.apk"),
    (Join-Path $MobileRoot "build\app\outputs\apk\debug\app-debug.apk")
  )
  $bad = $false
  foreach ($apk in $candidates) {
    if (-not (Test-Path -LiteralPath $apk)) { continue }
    if (-not (Test-CorrientazoApkZipOk -ApkPath $apk)) {
      $bad = $true
      Write-Host ""
      Write-Host "APK debug corrupto o incompleto (ZIP sin EOCD): $apk" -ForegroundColor Yellow
      break
    }
  }
  if (-not $bad) { return }
  $outRoot = Join-Path $MobileRoot "build\app\outputs"
  Write-Host "Borrando build\app\outputs para empaquetado limpio (evita IncrementalSplitter + APK roto)." -ForegroundColor Yellow
  if (Test-Path -LiteralPath $outRoot) {
    Remove-Item -LiteralPath $outRoot -Recurse -Force -ErrorAction SilentlyContinue
  }
}

function Get-FlutterAndroidEmulatorIds {
  param([string]$MobileRoot)
  Push-Location $MobileRoot
  $raw = & flutter devices --machine 2>$null
  $exitCode = $LASTEXITCODE
  Pop-Location
  if ($exitCode -ne 0 -or [string]::IsNullOrWhiteSpace($raw)) {
    return @()
  }
  try {
    $devices = @($raw | ConvertFrom-Json)
    $list = [System.Collections.Generic.List[string]]::new()
    foreach ($d in $devices) {
      $id = [string]$d.id
      if ($id -match '^emulator-\d+$') {
        $list.Add($id)
      }
    }
    return ,@($list)
  } catch {
    return @()
  }
}

$workspaceRoot = (Resolve-Path $PSScriptRoot).Path
$mobileRoot = Join-Path $workspaceRoot "mobile"
$composeFile = Join-Path $workspaceRoot "backend\docker-compose.yml"

Title "CORRIENTAZO - Dev (1 clic)"
Write-Host "Workspace: $workspaceRoot"
Write-Host "Target:    $Target"

if ($Target -eq "emulator") {
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
} else {
  Title "0) Celular (alpha)"
  $script:LanIp = Get-LanIPv4
  if (-not $script:LanIp) {
    Write-Host "No pude detectar tu IP LAN automáticamente." -ForegroundColor Yellow
    Write-Host "Abre CMD y corre: ipconfig" -ForegroundColor Yellow
    Write-Host "Busca 'IPv4 Address' y úsala para el API_BASE_URL." -ForegroundColor Yellow
  } else {
    Write-Host "Tu IP LAN: $script:LanIp"
    Write-Host "API_BASE_URL sugerido: http://$script:LanIp`:3000"
  }
  Write-Host ""
  Write-Host "IMPORTANTE (celular):"
  Write-Host "- PC y celular en la MISMA red WiFi"
  Write-Host "- Backend debe quedar levantado (paso 1)"
  Write-Host "- Si conectas por USB, puedes usar hot reload igual que emulador"
}

Title "1) Backend (Docker)"
if (-not (Test-Path $composeFile)) {
  throw "No encontré docker-compose en: $composeFile"
}
Push-Location $workspaceRoot
docker compose -f $composeFile up -d | Out-Host
Pop-Location

if ($Target -eq "emulator") {
  Title "2) Flutter (emulador)"
  Write-Host "Nota: Impeller no soporta render por software. No usamos --enable-software-rendering."
  Write-Host ""

  Remove-CorrientazoBrokenDebugApk -MobileRoot $mobileRoot

  $emuIds = Get-FlutterAndroidEmulatorIds $mobileRoot
  # Separate argv entries — a single string breaks dart-define parsing on some shells.
  $flutterEmuDefines = @(
    '--dart-define=API_BASE_URL=http://10.0.2.2:3000',
    '--dart-define=STARTUP_DEBUG=true'
  )

  if ($emuIds.Count -eq 0) {
    Write-Host "No detecté emuladores Android conectados." -ForegroundColor Yellow
    Write-Host "Abre uno o más AVD (Device Manager) y vuelve a ejecutar este script." -ForegroundColor Yellow
    Write-Host ""
    Push-Location $mobileRoot
    flutter devices | Out-Host
    Pop-Location
    Write-Host ""
    Write-Host "Intentando flutter run sin -d (elige dispositivo si hay varios)..."
    Push-Location $mobileRoot
    Remove-CorrientazoBrokenDebugApk -MobileRoot $mobileRoot
    & flutter run @flutterEmuDefines
    Pop-Location
  }
  elseif ($emuIds.Count -ge 2) {
    Write-Host "Se encontraron $($emuIds.Count) emuladores:" -ForegroundColor Green
    $emuIds | ForEach-Object { Write-Host "  - $_" }
    Write-Host ""
    Write-Host "Compilando UN solo APK (debug) antes de abrir varias ventanas..." -ForegroundColor Cyan
    Write-Host "Motivo: si varios 'flutter run' compilan a la vez, el mismo app-debug.apk se corrompe (zipro / aapt)." -ForegroundColor DarkGray
    Push-Location $mobileRoot
    & flutter build apk --debug @flutterEmuDefines
    if ($LASTEXITCODE -ne 0) {
      Pop-Location
      throw "flutter build apk --debug falló (exit $LASTEXITCODE)."
    }
    Pop-Location

    $apkPath = Join-Path $mobileRoot "build\app\outputs\flutter-apk\app-debug.apk"
    if (-not (Test-Path -LiteralPath $apkPath)) {
      throw "No encontré el APK tras el build: $apkPath"
    }
    if (-not (Test-CorrientazoApkZipOk -ApkPath $apkPath)) {
      throw "El APK generado no es un ZIP válido (sigue truncado). Prueba: cerrar otras ventanas Flutter/Gradle, ejecutar flutter clean, o revisar antivirus/disco."
    }

    Write-Host ""
    Write-Host "Abriendo UNA ventana de consola por emulador (mismo APK; sin carrera al escribir el .apk)." -ForegroundColor Cyan
    $mobileRootEsc = $mobileRoot.Replace("'", "''")
    $apkPathEsc = $apkPath.Replace("'", "''")
    foreach ($id in $emuIds) {
      $idEsc = $id.Replace("'", "''")
      Start-Process -FilePath "powershell.exe" `
        -WorkingDirectory $mobileRoot `
        -ArgumentList @(
          "-NoExit",
          "-NoProfile",
          "-ExecutionPolicy", "Bypass",
          "-Command",
          "`$Host.UI.RawUI.WindowTitle = 'CORRIENTAZO Flutter - $idEsc'; Set-Location '$mobileRootEsc'; & flutter run -d '$idEsc' --use-application-binary='$apkPathEsc' @('--dart-define=API_BASE_URL=http://10.0.2.2:3000','--dart-define=STARTUP_DEBUG=true')"
        )
    }
    Write-Host ""
    Write-Host "Listo: revisa las ventanas nuevas. Cada una tiene su propio 'r' / 'R' para hot reload." -ForegroundColor Green
  }
  else {
    $only = $emuIds[0]
    Write-Host "Un emulador conectado: $only" -ForegroundColor Green
    Push-Location $mobileRoot
    Remove-CorrientazoBrokenDebugApk -MobileRoot $mobileRoot
    & flutter run -d $only @flutterEmuDefines
    Pop-Location
  }
} else {
  Title "2) Flutter (celular)"
  $api = $null
  if ($script:LanIp) { $api = "http://$script:LanIp`:3000" }
  if (-not $api) {
    Write-Host "No tengo IP LAN detectada. Igual puedes correr Flutter, pero define API_BASE_URL manualmente." -ForegroundColor Yellow
    Write-Host "Ejemplo: flutter run -d <deviceId> --dart-define=API_BASE_URL=http://TU_IP:3000" -ForegroundColor Yellow
    return
  }

  Push-Location $mobileRoot
  Write-Host "Buscando dispositivos (flutter devices)..."
  flutter devices | Out-Host
  Write-Host ""
  Write-Host "Si tu celular aparece arriba, este comando lo corre con API_BASE_URL=$api"
  Write-Host ""
  Remove-CorrientazoBrokenDebugApk -MobileRoot $mobileRoot
  & flutter run @("--dart-define=API_BASE_URL=$api", '--dart-define=STARTUP_DEBUG=true')
  Pop-Location
}

