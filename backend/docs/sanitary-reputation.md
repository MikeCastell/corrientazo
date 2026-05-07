---
title: "CORRIENTAZO — Sistema Sanitario y Reputación"
version: "1.0"
last_updated: "2026-05-07"
---

## Objetivo
Construir confianza mediante:
- verificación de cocineros por niveles,
- evidencias y checklist,
- reportes con severidad,
- suspensiones,
- y un sistema de reputación que impacte en ranking y habilitación de modos (recogida/domicilio).

## Modelo mental (producto -> backend)
1. Cocinero se registra y queda `is_active=false`.
2. Realiza checklist/evidencias (niveles).
3. Admin aprueba o rechaza (con trazabilidad).
4. Cocinero obtiene badge sanitario (materializado) y reputación.
5. Los clientes reportan incidentes.
6. Reportes severos disparan suspensión y/o re-verificación obligatoria.

## Diseño del sanitario (niveles + checklist)
### Entidades Prisma (base)
- `sanitary_levels`
  - Define checklist y reglas por nivel (versionado vía JSON).
- `sanitary_checks`
  - Evidencias del cocinero para un nivel (estado PENDING/APPROVED/REJECTED).

### Progresión de niveles (reglas)
Recomendación:
- Nivel 0: verificación identidad/ubicación (fuera del checklist, o como checklist mínimo).
- Nivel 1..N: cada nivel agrega controles más exigentes.

Reglas operacionales:
- Un cocinero puede tener varias `sanitary_checks` (historial).
- `cook_profiles.sanitary_level_id` apunta al nivel actual aprobado.

### Checklist en `sanitary_levels`
- Guardar checklist como `checklist_json`:
  - lista de ítems,
  - tipo de evidencia requerida (foto/check),
  - rangos permitidos,
  - reglas condicionales.
- Guardar evidencias del cocinero en `sanitary_checks.evidence_urls_json`.

## Reportes (incidentes) y severidad
### Entidad Prisma
- `reports`
  - liga reporter (cliente), cook, y opcionalmente order/sanitary_check.

### Flujo
1. Cliente reporta desde el módulo de “Soporte / Reportar”.
2. Se valida:
   - que el pedido existe y pertenece al cliente,
   - que el tipo de reporte es válido,
   - severidad inicial basada en categoría.
3. Admin revisa el caso:
   - status pasa a `UNDER_REVIEW` y luego `RESOLVED`.

### Severidad y acciones
Tabla de referencia (aplicada en código, no en DB):
- Severidad 1-2:
  - warning + capacitación in-app
  - sin suspensión (o suspensión corta opcional)
- Severidad 3-4:
  - suspensión temporal
  - o re-verificación obligatoria del nivel mínimo
- Severidad 5:
  - suspensión extendida y posible revocación de habilitación delivery

## Suspensiones (operación)
### Entidad Prisma
- `suspensions`
  - `status`, `started_at`, `ends_at`, `reason_type/reason_text`.

Reglas:
- Si hay suspensión `ACTIVE`:
  - `cook_profiles.is_active=false` o al menos bloquear `delivery_enabled`.
- Si termina:
  - se re-evalúa nivel y/o se obliga a un nuevo `sanitary_check` según severidad.

## Reputación (ranking + habilitación)
### Entidad Prisma
- `cook_reputation_snapshots`

### Inputs a reputación
- `reviews.rating` (promedio y conteo)
- `reports` (tasa por 100 pedidos, tipo y severidad)
- historial de `sanitary_checks`

### Materialización para performance
Para miles de consultas (feed “hoy cerca de ti”), se recomienda:
- mantener `cook_reputation_snapshots` actualizados por un job periódico,
- o por eventos (cuando:
  - se crea una review,
  - se resuelve un reporte,
  - se aprueba un sanitario).

### Impacto en marketplace
1. Ranking del feed hiperlocal:
   - combina distancia + disponibilidad + reputación.
2. Habilitación de domicilio:
   - cocineros con reputación sanitaria insuficiente deben quedar solo pickup.

## Trazabilidad (audit y compliance)
Para cada acción relevante:
- crear timeline de cambios (por ejemplo en orders o sanitary events).
- al menos:
  - creación de sanitary_check,
  - aprobación/rechazo (admin),
  - creación y resolución de reportes,
  - activación/fin de suspensión.

En la implementación real, se recomienda usar el `domain_event_outbox` para notificar:
- `sanitary.update` a users,
- desbloqueos de modalidad (delivery/pickup),
- cambios de reputación a modo “future ranking”.

---
Fin del documento.

