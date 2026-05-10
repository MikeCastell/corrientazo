import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from "@nestjs/common";
import { ConfigService } from "@nestjs/config";

/**
 * Sugerencia de texto con modelo multimodal (Gemini).
 * Requiere GEMINI_API_KEY en el servidor (Google AI Studio).
 */
@Injectable()
export class CookAiService {
  constructor(private readonly config: ConfigService) {}

  async describeMealImage(imageBuffer: Buffer, mimeType: string): Promise<string> {
    const key = this.config.get<string>("GEMINI_API_KEY")?.trim();
    if (!key) {
      throw new ServiceUnavailableException(
        "La sugerencia por foto no está configurada en el servidor (GEMINI_API_KEY).",
      );
    }

    const safeMime =
      /^image\/(jpeg|png|webp|gif|heic|heif)$/i.test(mimeType) ? mimeType : "image/jpeg";

    const model = "gemini-1.5-flash";
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${encodeURIComponent(key)}`;

    const prompt =
      "Eres un asistente para una app de comida casera en Colombia. " +
      "Describe el plato de la foto en 2 o 3 frases en español, tono cercano y apetitoso. " +
      "No inventes ingredientes que no se vean con claridad. No menciones precios ni marcas. " +
      "Si la imagen no muestra comida, responde exactamente: No parece un plato de comida. " +
      "Máximo 450 caracteres.";

    const body = {
      contents: [
        {
          parts: [
            { text: prompt },
            {
              inline_data: {
                mime_type: safeMime,
                data: imageBuffer.toString("base64"),
              },
            },
          ],
        },
      ],
      generationConfig: {
        maxOutputTokens: 512,
        temperature: 0.35,
      },
    };

    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    });

    const rawText = await res.text();
    if (!res.ok) {
      // eslint-disable-next-line no-console
      console.error("[cook-ai] Gemini HTTP error", res.status, rawText.slice(0, 500));
      throw new BadRequestException(
        "No pudimos analizar la imagen ahora. Revisa la foto o inténtalo más tarde.",
      );
    }

    let json: unknown;
    try {
      json = JSON.parse(rawText) as Record<string, unknown>;
    } catch {
      throw new BadRequestException("Respuesta inválida del servicio de IA.");
    }

    const candidates = (json as { candidates?: unknown }).candidates;
    const first = Array.isArray(candidates) ? candidates[0] : undefined;
    const parts = (first as { content?: { parts?: unknown } } | undefined)?.content?.parts;
    const textPart = Array.isArray(parts) ? parts[0] : undefined;
    const text = (textPart as { text?: unknown } | undefined)?.text;

    if (typeof text !== "string" || !text.trim()) {
      throw new BadRequestException("No se generó una descripción para esta imagen.");
    }

    return text.trim().slice(0, 600);
  }
}
