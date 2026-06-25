import { createBrowserClient } from "@supabase/ssr";

// Client Supabase navigateur (Phase 0.1) — clé anon UNIQUEMENT.
// POURQUOI: la clé anon est sûre côté client, c'est RLS qui protège les données
// (uidesign/CLAUDE §6). Jamais de service_role ici (Règle 11).
//
// POURQUOI createBrowserClient (@supabase/ssr) et pas createClient (@supabase/supabase-js):
// en SSR Next.js la session doit vivre dans des COOKIES — lisibles côté serveur par
// le middleware et la route /callback — et non dans localStorage (navigateur seul,
// invisible au serveur). createBrowserClient utilise aussi le flow PKCE (code en
// query string) attendu par exchangeCodeForSession; createClient utilisait le flow
// implicite (token en hash) que le serveur ne peut pas traiter — d'où l'auth_error
// à la confirmation d'email. Les défauts @supabase/ssr (PKCE + cookies) sont corrects:
// ne pas reconfigurer flowType ni storage manuellement.

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;

// Échec explicite à la configuration plutôt qu'une erreur opaque au runtime.
if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error(
    "Configuration Supabase manquante: NEXT_PUBLIC_SUPABASE_URL / NEXT_PUBLIC_SUPABASE_ANON_KEY.",
  );
}

// Instance unique réutilisée côté navigateur.
export const supabaseBrowser = createBrowserClient(supabaseUrl, supabaseAnonKey);
