---
title: "CORRIENTAZO — NestJS Project Structure"
version: "1.0"
last_updated: "2026-05-07"
---

## Objetivo
Este documento define una estructura de proyecto NestJS pensada para:
- modularidad de dominio,
- claridad operacional (production-ready),
- escalabilidad (multi-instancia + colas + realtime),
- onboarding de nuevos desarrolladores.

Se asume una app separada en el directorio `backend/` (Node/NestJS) y un frontend independiente.

## Principios de estructura
1. **Un módulo por dominio** (o por subdominio fuerte).
2. **Capas estrictas** dentro de cada módulo:
   - `controller` solo orquesta y valida inputs.
   - `service` contiene lógica de negocio (casos de uso).
   - `repository` encapsula Prisma (queries y persistencia).
   - `gateway` / `processor` entrega eventos (socket o colas).
3. **Cero lógica de persistencia en Services**: si interactúa con DB, usa repository.
4. **Evitar acoplamiento entre módulos**:
   - usar interfaces o eventos del dominio,
   - preferir un `DomainEventBus` o outbox.
5. **Convención sobre configuración**:
   - naming consistente para endpoints, DTOs y eventos.

## Árbol recomendado (backend/)
```text
backend/
  src/
    main.ts
    app.module.ts
    config/
      env.ts
      env.validation.ts
      config.module.ts
    database/
      prisma/
        prisma.module.ts
        prisma.service.ts
      transactions/
        transaction-runner.ts
    common/
      decorators/
        current-user.decorator.ts
      guards/
        jwt-auth.guard.ts
        roles.guard.ts
      interceptors/
        correlation-id.interceptor.ts
        timing.interceptor.ts
      filters/
        http-exception.filter.ts
      errors/
        domain-errors.ts
        error-codes.ts
      logging/
        logger.module.ts
        request-logger.ts
      validation/
        dto-validation.pipe.ts
    realtime/
      realtime.module.ts
      sockets/
        orders-tracking.gateway.ts
        user-notifications.gateway.ts
      socket-events/
        orders.events.ts
        notifications.events.ts
    queues/
      queues.module.ts
      processors/
        notifications.processor.ts
        payments-reconciliation.processor.ts
      queues.constants.ts
      queue-events/
        notifications.events.ts
    auth/
      auth.module.ts
      auth.controller.ts
      auth.service.ts
      jwt/
        jwt.strategy.ts
        token-pair.service.ts
      refresh-tokens/
        refresh-tokens.repository.ts
    users/
      users.module.ts
      users.controller.ts
      users.service.ts
      users.repository.ts
      addresses/
        addresses.repository.ts
        addresses.service.ts
    cooks/
      cooks.module.ts
      cooks.controller.ts
      cooks.service.ts
      cooks.repository.ts
      cooks.verification/
        verification.service.ts
    sanitary/
      sanitary.module.ts
      sanitary.controller.ts
      levels/
      sanitary-checks/
      reports/
      suspensions/
    meals/
      meals.module.ts
      meals.controller.ts
      meals.service.ts
      meals.repository.ts
      publications/
        publications.repository.ts
    orders/
      orders.module.ts
      orders.controller.ts
      orders.service.ts
      orders.repository.ts
      domain/
        order-status.ts
        order-state-machine.ts
        order-events.ts
      dto/
        create-order.dto.ts
        update-order-status.dto.ts
    payments/
      payments.module.ts
      payments.controller.ts
      payments.service.ts
      providers/
        payment-provider.interface.ts
        nequi.provider.ts
        daviplata.provider.ts
      webhooks/
        webhooks.controller.ts
        payment-webhook.service.ts
      reconciliation/
        payments-reconciliation.service.ts
      dto/
        start-payment.dto.ts
    reviews/
      reviews.module.ts
      reviews.controller.ts
      reviews.service.ts
      reviews.repository.ts
    notifications/
      notifications.module.ts
      notifications.service.ts
      notifications.repository.ts
      templates/
        notification-templates.ts
    admin/
      admin.module.ts
      admin.controller.ts
      admin.service.ts
  prisma/
    schema.prisma
  docs/
    (documentación)
  docker/
    nginx/
      nginx.conf
```

## Convenciones de naming
- Archivos TypeScript:
  - `kebab-case.ts` para utilidades (ej. `transaction-runner.ts`),
  - `PascalCase` para clases/exports.
- DTOs:
  - ubicados en `*/dto/`.
- Repositories:
  - `*.repository.ts` y métodos con nombres de intención:
    - `findById(...)`, `reserveStockAndCreateOrder(...)`, etc.
- Eventos internos:
  - `*.events.ts` en `domain/`, `realtime/socket-events/` y `queues/queue-events/`.

## Convención de estructura por módulo
Ejemplo: `orders/`
```text
orders/
  orders.module.ts
  orders.controller.ts
  orders.service.ts
  orders.repository.ts
  domain/
    order-status.ts
    order-state-machine.ts
    order-events.ts
  dto/
    create-order.dto.ts
    update-order-status.dto.ts
```

## Capa de dominio vs infraestructura
- `orders/domain/*` contiene:
  - enums,
  - máquina de estados (transiciones válidas),
  - contratos de eventos.
- `orders/*repository.ts` contiene:
  - Prisma queries,
  - serialización de datos.
- `orders.service.ts`:
  - usa state machine + repositories + transacciones.

## Cómo se conectan módulos (sin acoplar)
1. Los services llaman repositories.
2. Las transiciones de estado generan eventos de dominio.
3. Los eventos se registran en un outbox transaccional.
4. Un worker consume outbox y ejecuta:
   - notificaciones,
   - emisión realtime,
   - reconciliación de pagos.

## Contratos de Socket.io (convención)
- `event names` en kebab:
  - `order.status.updated`
  - `order.eta.updated`
  - `notification.new`
- rooms:
  - `order:{orderId}`
  - `user:{userId}`

## Convenciones de seguridad
- Todos los endpoints protegidos:
  - `JwtAuthGuard`.
- Las acciones de cocinero y administrador usan guards extra:
  - `CookEnabledGuard`, `RolesGuard`.

---
Fin del documento.

