import { createSupabaseSessionClient } from '@/lib/supabase/server-session'
import { createSupabaseServerClient } from '@/lib/supabase/server'

// Route serveur : crée la ligne public.users après le signup.
// POURQUOI une route serveur : la table users n'a AUCUNE policy INSERT côté client
// (003_users.sql) — la création du profil passe obligatoirement par service_role,
// qui bypasse RLS (Rule 11). C'est la SEULE place autorisée à écrire role.

export async function POST(request: Request) {
  // Marque la requête comme utilisée (pas de body lu : l'identité ne vient JAMAIS
  // du client — voir plus bas). Référencé pour la signature du handler.
  void request

  // 1. Identité depuis la SESSION vérifiée, jamais depuis le body de la requête.
  //    POURQUOI : le client ne doit jamais pouvoir déclarer qui il est (T01/T03) —
  //    getUser() revalide le token côté serveur Supabase, c'est la seule source sûre.
  const session = await createSupabaseSessionClient()
  const {
    data: { user },
  } = await session.auth.getUser()

  // Pas d'utilisateur authentifié → 401 générique, aucun détail (Rule 1).
  if (!user) {
    return Response.json({ error: 'unauthorized' }, { status: 401 })
  }

  // 2. Insertion via service_role (bypass RLS). Client paramétré Supabase,
  //    zéro concaténation SQL (Rule 14).
  const admin = createSupabaseServerClient()
  const { error } = await admin.from('users').insert({
    // id + email viennent de la session vérifiée, JAMAIS du body (T01/T03).
    id: user.id,
    email: user.email,
    // POURQUOI hardcodé : empêche l'escalade de privilège ; le client ne doit
    // jamais pouvoir choisir son rôle (T01/T03). locale/created_at/updated_at
    // prennent leurs valeurs par défaut côté base (003_users.sql).
    role: 'citoyen',
  })

  // En cas d'échec (ex. ligne déjà existante), message générique — jamais l'erreur
  // Postgres brute (Rule 1). TODO logger.ts : journaliser error côté serveur.
  // Pas de cleanup d'orphelin ni de retry ici (dette logguée séparément).
  if (error) {
    return Response.json({ error: 'profile_creation_failed' }, { status: 500 })
  }

  return Response.json({ ok: true }, { status: 201 })
}
