import { supabaseBrowser } from '@/lib/supabase/client'

// Service d'authentification — moitié CLIENT uniquement (Rule 9 : tout appel
// Supabase vit dans services/). Clé anon via supabaseBrowser — JAMAIS service_role
// ici (Rule 11). On NE capture PAS les erreurs : on renvoie le résultat brut de
// Supabase ({ data, error }) pour que la couche UI décide du message (Rule 1).

// Connexion email + mot de passe.
// POURQUOI renvoyer le résultat tel quel : la UI branche sur error pour afficher
// un message générique traduit ; ce service ne fait aucune interprétation métier.
export async function signIn(email: string, password: string) {
  return supabaseBrowser.auth.signInWithPassword({ email, password })
}

// Déconnexion de la session navigateur courante.
export async function signOut() {
  return supabaseBrowser.auth.signOut()
}

// Inscription email + mot de passe.
// POURQUOI ce commentaire est critique : ceci crée UNIQUEMENT l'entrée auth.users.
// La ligne dans la table users (role='citoyen' forcé) est créée séparément par une
// route serveur (service_role) — JAMAIS ici (Rule 11). Confirmation email
// obligatoire avant premier login (déjà activé côté Supabase).
export async function signUp(email: string, password: string, locale: string) {
  return supabaseBrowser.auth.signUp({
    email,
    password,
    options: {
      // POURQUOI emailRedirectTo : indique à Supabase de renvoyer l'utilisateur vers
      // notre route callback localisée après confirmation — déclenche le flow PKCE
      // (code en query) au lieu du flow implicite (token en hash) non géré côté serveur.
      // POURQUOI window.location.origin : l'URL doit être absolue ET correspondre à
      // l'origine réelle (localhost en dev, domaine en prod) — pas de valeur en dur.
      emailRedirectTo: `${window.location.origin}/${locale}/auth/callback`,
    },
  })
}

// Demande de réinitialisation de mot de passe par email.
// POURQUOI redirectTo vers /auth/callback?type=recovery : Supabase renvoie l'utilisateur
// vers notre callback avec un code PKCE ; le param type=recovery dira au callback de
// rediriger vers la page "nouveau mot de passe" (et pas l'accueil).
// POURQUOI window.location.origin : URL absolue, origine réelle (localhost/prod).
export async function resetPasswordForEmail(email: string, locale: string) {
  return supabaseBrowser.auth.resetPasswordForEmail(email, {
    redirectTo: `${window.location.origin}/${locale}/auth/callback?type=recovery`,
  })
}

// Mise à jour du mot de passe du compte authentifié.
// POURQUOI updateUser : l'utilisateur arrive ici APRÈS l'échange du code recovery
// (callback), donc il a une session valide ; updateUser change le mot de passe du
// compte authentifié. Pas besoin de l'ancien mot de passe (le lien email prouve
// l'identité). Renvoie le résultat brut (Rule 1).
export async function updatePassword(newPassword: string) {
  return supabaseBrowser.auth.updateUser({ password: newPassword })
}
