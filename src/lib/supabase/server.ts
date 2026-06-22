import { createClient } from "@supabase/supabase-js";

// Client Supabase serveur (Phase 0.1) — clé service_role.
// ⛔ SERVEUR UNIQUEMENT (Règle 11): service_role bypasse RLS entièrement.
// Une fuite côté navigateur = chaque utilisateur lit chaque ligne. Faille P0.
// Importer ce fichier seulement dans: API routes, lib serveur, edge functions.

// Garde-fou: si jamais ce module est chargé dans un bundle navigateur, on coupe net.
if (typeof window !== "undefined") {
  throw new Error(
    "lib/supabase/server.ts importé côté client — interdit (Règle 11, service_role).",
  );
}

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

// Échec explicite à la configuration plutôt qu'une erreur opaque au runtime.
if (!supabaseUrl || !serviceRoleKey) {
  throw new Error(
    "Configuration Supabase serveur manquante: NEXT_PUBLIC_SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY.",
  );
}

// Crée un client serveur frais à l'appel. Pas de session persistée: ce client
// agit en service_role, il ne doit jamais hériter d'une session utilisateur.
export function createSupabaseServerClient() {
  return createClient(supabaseUrl!, serviceRoleKey!, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}
