import { ErrorCodes, ErrorCode } from "./error-codes";

export class DomainError extends Error {
  public readonly code: ErrorCode;
  public readonly statusCode: number;
  public readonly details?: Record<string, unknown>;

  constructor(args: {
    code: ErrorCode;
    message: string;
    statusCode: number;
    details?: Record<string, unknown>;
  }) {
    super(args.message);
    this.code = args.code;
    this.statusCode = args.statusCode;
    this.details = args.details;
  }
}

// Ejemplos de helpers (extendibles por dominio)
export class SoldOutError extends DomainError {
  constructor(details?: Record<string, unknown>) {
    super({
      code: ErrorCodes.ORDER_SOLD_OUT,
      message: "No hay cupos disponibles",
      statusCode: 409,
      details,
    });
  }
}

