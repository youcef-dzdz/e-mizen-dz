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
//
// POURQUOI le 4e paramètre metadata OPTIONNEL : c'est le SEUL point de création de
// compte de l'app. L'inscription avocat doit transmettre son intention + ses données
// descriptives (intent='avocat', nom, prenom, telephone, wilaya_id, cabinet_nom) à
// Supabase Auth ; Supabase les range dans auth.users.raw_user_meta_data, que le trigger
// 011 lit pour créer la ligne pending_avocat_registrations côté serveur. On évite ainsi
// un second point de création de compte.
// POURQUOI metadata est OPTIONNEL et placé en dernier : rétrocompatibilité totale — le
// SignupForm citoyen appelle toujours signUp(email, password, locale) à 3 arguments,
// metadata reste undefined, options.data n'est pas envoyé, comportement strictement
// inchangé pour le citoyen.
// SÉCURITÉ : role n'est JAMAIS passé dans metadata (il est forcé côté serveur, T01/T03) ;
// uniquement des données descriptives non sensibles. Le client est contrôlé par
// l'attaquant — le serveur ne fait jamais confiance à ces métadonnées pour un privilège.
export async function signUp(
  email: string,
  password: string,
  locale: string,
  metadata?: Record<string, unknown>,
) {
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
      // POURQUOI options.data = metadata : ces clés atterrissent dans raw_user_meta_data,
      // lues par le trigger 011. Si metadata est undefined (cas citoyen), data l'est aussi
      // → Supabase n'écrit aucune métadonnée, rétrocompatible.
      data: metadata,
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
