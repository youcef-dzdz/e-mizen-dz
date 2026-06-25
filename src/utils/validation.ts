// Validateurs purs réutilisés des DEUX côtés (Rule 20) : front pour l'UX (feedback
// instantané) ET back pour la sécurité (le client est contrôlé par l'attaquant, jamais
// de confiance). POURQUOI framework-agnostique, sans dépendance ni effet de bord :
// le même code doit tourner dans le navigateur, une route serveur et une edge function.

// POURQUOI cette regex (et pas la regex RFC 5322 complète) : la version complète est
// illisible et n'apporte rien en pratique — elle accepte des cas exotiques jamais
// rencontrés. On valide le format pragmatique « un@deux.tld » : pas d'espace, un seul @,
// un domaine avec au moins un point. La vraie preuve qu'un email existe = la
// confirmation par email (déjà exigée côté Supabase), pas la regex.
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

export function isValidEmail(email: string): boolean {
  return EMAIL_REGEX.test(email)
}

// Règle de force du mot de passe (source : docs/SECURITY.md) : longueur >= 8 ET
// au moins 1 majuscule ET au moins 1 chiffre. POURQUOI ces trois critères ensemble :
// barre minimale contre le brute-force / les mots de passe triviaux, sans imposer de
// caractères spéciaux (friction UX). Renvoie true uniquement si les trois sont remplis.
export function isStrongPassword(password: string): boolean {
  return (
    password.length >= 8 &&
    /[A-Z]/.test(password) &&
    /[0-9]/.test(password)
  )
}
