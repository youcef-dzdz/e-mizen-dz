// logger.ts — point de journalisation central (Règle 13).
// POURQUOI: aucun console.error/console.log brut dans composants/pages/services.
// L'erreur réelle reste côté serveur (fuite de noms de tables/chemins interdite,
// Règle 1) ; l'utilisateur ne voit qu'un message générique traduit côté UI.

type LogLevel = "info" | "warn" | "error";

interface LogContext {
  // Métadonnées libres pour le diagnostic serveur (jamais affichées à l'utilisateur).
  [key: string]: unknown;
}

// En dev on écrit en console pour le confort ; en prod on évite le bruit et on
// branchera un transport (ex. Supabase activity_log) dans une phase ultérieure.
function emit(level: LogLevel, message: string, context?: LogContext): void {
  if (process.env.NODE_ENV === "production") {
    // Stub: en production le détail part vers le serveur uniquement.
    // TODO Phase ultérieure: persister vers activity_log / service de logs.
    return;
  }

  const payload = context ? { message, ...context } : { message };
  // Console réservée au logger (le reste du code passe par ici).
  // eslint-disable-next-line no-console
  console[level === "warn" ? "warn" : level === "error" ? "error" : "log"](
    `[${level.toUpperCase()}]`,
    payload,
  );
}

export const logger = {
  info: (message: string, context?: LogContext) => emit("info", message, context),
  warn: (message: string, context?: LogContext) => emit("warn", message, context),
  error: (message: string, context?: LogContext) => emit("error", message, context),
};
