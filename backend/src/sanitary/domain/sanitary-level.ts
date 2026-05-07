export type SanitaryLevelNumber = number;

export type SanitaryChecklistJson = unknown; // definido por diseño (items, evidencia requerida)
export type EvidenceRulesJson = unknown; // reglas avanzadas (condiciones)

export interface SanitaryLevelPolicy {
  levelNumber: SanitaryLevelNumber;
  name: string;
  checklist: SanitaryChecklistJson;
  evidenceRules?: EvidenceRulesJson;
}

