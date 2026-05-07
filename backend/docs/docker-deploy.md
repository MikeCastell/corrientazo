---
title: "CORRIENTAZO — Docker & Deployment (VPS Ubuntu)"
version: "1.0"
last_updated: "2026-05-07"
---

## Objetivo
Permitir un despliegue profesional y repetible en un VPS Ubuntu usando Docker:
- API NestJS
- Worker BullMQ
- PostgreSQL
- Redis
- Nginx reverse proxy con TLS y soporte websockets

## Layout propuesto (backend/)
```text
backend/
  Dockerfile.api
  Dockerfile.worker
  docker-compose.yml
  .env.example
  docker/nginx/nginx.conf
  src/...
  prisma/...
```

## Servicios (docker-compose)
### `api`
- Construido con `Dockerfile.api`.
- Expone puertos internos (ej. 3000).
- Conecta a PostgreSQL y Redis.
- Mantiene sesiones stateless (JWT).

### `worker`
- Construido con `Dockerfile.worker`.
- Corre workers BullMQ (colas: notifications, payments reconciliation, etc).

### `postgres`
- Imagen oficial Postgres.
- Volumen persistente.
- Recomendación: habilitar backups automáticos fuera de este repo.

### `redis`
- Imagen oficial Redis.

### `nginx`
- Reverse proxy con TLS.
- Enrutado:
  - `/api` -> api:3000
  - Websockets -> mismo upstream (header upgrade)

## Dockerfiles (multi-stage)
### API
- stage build: instalar dependencias, compilar TS.
- stage runtime: copiar build y `node_modules` product.
- configurar `NODE_ENV=production`.

### Worker
- similar a API, pero el entrypoint ejecuta “worker mode”.

## Variables de entorno (ejemplo)
Archivo: `.env.example`.
Campos mínimos:
- `DATABASE_URL`
- `REDIS_URL`
- `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`
- `JWT_ACCESS_TTL_SECONDS`, `JWT_REFRESH_TTL_SECONDS`
- `SOCKETIO_PORT` o `PORT`
- `FCM_PRIVATE_KEY` / `FCM_API_KEY` (futuro)
- `APNS_*` (futuro)
- `NEQUI_API_KEY` / `NEQUI_WEBHOOK_SECRET`
- `DAVIPLATA_API_KEY` / `DAVIPLATA_WEBHOOK_SECRET`
- `ADMIN_BOOTSTRAP_KEY` (si aplica)

## Nginx (websockets + headers)
Puntos críticos:
- soportar `Upgrade` y `Connection` para websockets.
- reenviar `X-Forwarded-Proto` y `X-Forwarded-For`.
- limitar body size para upload de evidencias (fotos sanitarias).

---
Fin del documento.

