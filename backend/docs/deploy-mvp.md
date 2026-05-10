# Deploy MVP (Docker Compose) — CORRIENTAZO backend

Objetivo: **no volver a arrancar un contenedor con `dist` viejo** y poder verificar en segundos qué build está corriendo.

## Qué garantiza el Dockerfile

- El **`dist`** solo viene de la stage **`builder`** tras **`npm run build`** en contexto limpio (no se copia `dist/` desde tu disco).
- Cambiar cualquier archivo del repo invalida la capa **`COPY . .`** → nuevo build del código.
- **`APP_GIT_COMMIT` / `APP_BUILD_TIME`**: se inyectan en la imagen si los pasás al build (útil para `/api/v1/version`).

## Regla de oro

Después de cambiar rutas o código Nest:

```powershell
cd backend
docker compose build api --no-cache
docker compose up -d api
```

`--no-cache` solo cuando quieras forzar (tras cambios sospechosos o deps); un build normal suele bastar si cambió el código fuente.

## Metadatos en build (recomendado)

PowerShell **antes** de `docker compose build`:

```powershell
$env:GIT_COMMIT = (git rev-parse --short HEAD)
$env:BUILD_TIME = (Get-Date).ToUniversalTime().ToString("o")
docker compose build api
docker compose up -d api
```

En Git Bash / macOS / Linux:

```bash
export GIT_COMMIT=$(git rev-parse --short HEAD)
export BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
docker compose build api && docker compose up -d api
```

## Checklist rápido

1. **Reconstruir** la imagen del API (`build api`; usar `--no-cache` si dudás).
2. **Levantar** `docker compose up -d api`.
3. **`GET /api/v1/healthz`** → `{"ok":true}`.
4. **`GET /api/v1/version`** → `version`, `git`, `builtAt` coherentes con lo que acabás de deployar.
5. **Smoke del endpoint nuevo** (ej. cancelación con JWT): debe responder **401/403/422**, pero **no** `Cannot POST …` (eso es 404 = ruta no desplegada).
6. **Flutter**: misma base URL que probaste con `curl` (`API_BASE_URL` / pantalla debug si la tenés).

## Healthcheck

Compose usa **`curl` dentro de la imagen** contra **`127.0.0.1`** y **`start_period: 90s`** para no marcar `unhealthy` mientras Nest arranca.

## Cuándo sospechar de imagen vieja

- `Cannot POST /api/v1/...` en rutas que **sí existen en el repo**.
- **`/api/v1/version`** muestra `git: unknown` y un `builtAt` viejo **después** de un deploy que creías nuevo → rebuild sin cache y volver a subir el contenedor.
