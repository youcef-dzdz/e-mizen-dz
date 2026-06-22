import { createClient } from "@supabase/supabase-js";

// Client Supabase navigateur (Phase 0.1) — clé anon UNIQUEMENT.
// POURQUOI: la clé anon est sûre côté client, c'est RLS qui protège les données
// (uidesign/CLAUDE §6). Jamais de service_role ici (Règle 11).

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

// Échec explicite à la configuration plutôt qu'une erreur opaque au runtime.
if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    "Configuration Supabase manquante: NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY.",
  );
}

// Instance unique réutilisée côté navigateur.
export const supabaseBrowser = createClient(supabaseUrl, supabaseAnonKey);
