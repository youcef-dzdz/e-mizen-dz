import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

// Client Supabase serveur "session" (Phase 0.3) — clé anon UNIQUEMENT.
// POURQUOI: ce client lit la session de l'utilisateur connecté depuis les cookies
// et agit EN TANT QUE cet utilisateur — donc RLS s'applique pleinement (Règle 11).
// À distinguer de server.ts (service_role, bypasse RLS) et de client.ts (navigateur).
// Usage: Server Components, route handlers et middleware (lecture de l'utilisateur).

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

// Échec explicite à la configuration plutôt qu'une erreur opaque au runtime.
if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    "Configuration Supabase session manquante: NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY.",
  );
}

// Crée un client serveur frais à l'appel, branché sur le cookie store de la requête.
// POURQUOI async + await cookies(): le pattern officiel @supabase/ssr (App Router
// Next.js 14) lit/écrit la session via les cookies de la requête courante.
export async function createSupabaseSessionClient() {
  const cookieStore = await cookies();

  return createServerClient(supabaseUrl!, supabaseAnonKey!, {
    cookies: {
      get(name: string) {
        return cookieStore.get(name)?.value;
      },
      set(name: string, value: string, options) {
        // POURQUOI try/catch: écrire un cookie depuis un Server Component lève une
        // erreur (les headers sont déjà figés). On l'absorbe — c'est le middleware
        // qui rafraîchit réellement la session. Sans ce catch, chaque rendu casse.
        try {
          cookieStore.set({ name, value, ...options });
        } catch {
          // Ignoré volontairement: refresh géré par le middleware.
        }
      },
      remove(name: string, options) {
        // POURQUOI try/catch: même contrainte que set() côté Server Component.
        try {
          cookieStore.set({ name, value: "", ...options });
        } catch {
          // Ignoré volontairement: refresh géré par le middleware.
        }
      },
    },
  });
}
