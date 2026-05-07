/**
 * Reputación sanitaria + calidad (materialización para ranking).
 *
 * Responsable:
 * - recalcular `cook_reputation_snapshots` a partir de reviews y reports,
 * - aplicar impacto de sanciones y niveles sanitarios.
 *
 * Implementación real:
 * - consulta DB (Prisma) con agregaciones,
 * - calcula scores (promedios y tasas),
 * - materializa snapshot con timestamps.
 */
export class CookReputationService {
  async recalculateForCook(cookProfileId: string): Promise<void> {
    // TODO: usar Prisma y agregaciones para:
    // - avg ratings + count,
    // - tasa de reports por severidad,
    // - score sanitario (por sanitary_checks aprobados/recientes),
    // - actualizar cook_reputation_snapshots y opcionalmente ranking cache.
    void cookProfileId;
  }
}

