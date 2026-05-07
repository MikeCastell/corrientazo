## CORRIENTAZO — Closed Alpha (Android)

### Requisitos
- Tener el backend corriendo y accesible desde el teléfono (**misma red Wi‑Fi**).
- Un Android con “Instalar apps desconocidas” habilitado (si aplica).

### IMPORTANTE (por qué te sale NetworkException)
- **`http://10.0.2.2:3000` SOLO sirve en emulador**.
- En un **teléfono real**, debes usar la IP local de tu PC: `http://TU_IP_LAN:3000`

### Backend que debe estar corriendo
- **API (NestJS)** en el puerto `3000`.
- En local, en tu PC: `http://<TU_IP_LAN>:3000`
  - Ejemplo típico: `http://192.168.1.12:3000`

### Paso a paso para que el teléfono conecte (sin programación)
1) **Conecta tu teléfono y tu PC a la misma Wi‑Fi**.

2) **Encuentra la IP de tu PC** (Windows):
   - Abre **CMD** (Símbolo del sistema).
   - Escribe: `ipconfig`
   - Busca “**IPv4 Address**” o “**Dirección IPv4**”. Ejemplo: `192.168.1.12`

3) **Enciende el backend** (si usas Docker):
   - En tu PC, en la carpeta `E:/CORRIENTAZO`:
   - Ejecuta:

```bash
docker compose -f backend/docker-compose.yml up -d
```

4) **Prueba desde el teléfono en el navegador**:
   - Abre Chrome en el teléfono y entra a:
   - `http://TU_IP_LAN:3000/api/v1/healthz`
   - Debe responder: `{"ok":true}`

Si NO abre:
- Revisa que el backend esté arriba (en tu PC) y que el puerto 3000 esté expuesto.
- En Windows Firewall, permite conexiones entrantes para Docker/Node en red privada.

### Si Chrome abre `healthz` pero la app NO conecta
Eso pasaba cuando el APK release no tenía permiso de Internet. Ya quedó corregido, pero si un tester reporta esto:
- Desinstalar CORRIENTAZO
- Instalar el APK más reciente

### Setup automático (recomendado)
En tu PC, corre (doble clic):
- `mobile/tools/closed-alpha/alpha_phone_setup.bat`

Ese script:
- Detecta tu IP LAN
- Levanta el backend con Docker
- Construye el APK release apuntando a tu IP (para teléfono real)
- Te deja el APK listo para compartir

---

## Dev rápido (emulador)
Si estás desarrollando en el emulador y no quieres repetir comandos al reiniciar el PC:
- Abre el emulador
- Doble clic en `mobile/tools/dev/dev_emulator_start.bat`

Eso levanta backend (Docker) y corre `flutter run` con `API_BASE_URL=http://10.0.2.2:3000`.

### Cómo construir el APK Release (para compartir)
Desde `E:/CORRIENTAZO/mobile`:

```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=http://TU_IP_LAN:3000
```

### Dónde queda el APK
`build/app/outputs/flutter-apk/app-release.apk`

### Cómo instalar en un Android
Opción A (manual):
- Copia `app-release.apk` al teléfono y ábrelo para instalar.

Opción B (ADB):

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

### Cambiar de entorno (local vs servidor)
La app lee la URL del backend desde `--dart-define=API_BASE_URL=...`.

Ejemplos:
- Emulador Android: `http://10.0.2.2:3000`
- Teléfono en tu Wi‑Fi: `http://192.168.1.12:3000`
- Servidor: `https://api.tudominio.com`

