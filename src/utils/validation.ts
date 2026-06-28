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

// Validation nom / prénom (inscription avocat). POURQUOI volontairement permissif :
// l'objectif n'est PAS de prouver qu'un nom est « réel » (impossible et inutile — un
// humain vérifie l'avocat au Phase 5 avant activation), mais de bloquer le vide et
// l'aberrant (chaîne numérique pure, espaces seuls). On accepte donc largement :
// lettres (accents FR + caractères arabes), espaces, tirets, apostrophes — de quoi
// couvrir « Mohamed », « Aït-Saïd », « N'Diaye », « بن علي ». POURQUOI une longueur
// max de 100 : garde-fou contre l'input aberrant / abus, aligné sur la colonne DB.
// La regex reste lisible exprès : pas de classe Unicode exotique, juste les plages utiles.
export function isValidNom(value: string): boolean {
  const trimmed = value.trim()
  // POURQUOI tester le trim : « "   " » a une longueur > 0 mais ne contient QUE des
  // espaces — on le refuse via la borne min sur la chaîne nettoyée.
  if (trimmed.length < 2 || trimmed.length > 100) {
    return false
  }
  // Plages autorisées : lettres latines de base, lettres accentuées FR courantes
  // (À-ÿ couvre é, è, à, ç, ï…), bloc arabe de base (؀-ۿ), plus espace,
  // tiret et apostrophe (droite et typographique). Au moins un caractère requis par
  // la borne min ci-dessus, donc une valeur purement numérique est refusée ici.
  return /^[A-Za-zÀ-ÿ؀-ۿ\s'’-]+$/.test(trimmed)
}

// Validation téléphone algérien (source : docs/SECURITY.md § tableau validation).
// POURQUOI ce format : un numéro algérien s'écrit soit en international « +213 » suivi
// de 9 chiffres, soit en national « 0 » suivi de 9 chiffres (10 caractères avec le 0).
// La regex reflète exactement les deux formes acceptées.
// IMPORTANT — POURQUOI cette fonction ne traite PAS le cas vide : le téléphone est
// OPTIONNEL à l'inscription (colonne nullable, migration 010). Cette fonction pure teste
// UNIQUEMENT le FORMAT d'une valeur non vide ; elle renvoie donc false sur "" (le vide
// n'a pas de format valide). C'est à l'APPELANT (le formulaire) de décider que « vide =
// acceptable » et de n'appeler ce validateur que sur une valeur effectivement saisie.
// On ne rend volontairement pas « vide = valide » ici pour garder le validateur honnête
// et réutilisable côté back (Rule 20), où le sens de « optionnel » peut différer.
export function isValidTelephoneDZ(value: string): boolean {
  return /^(\+213|0)[0-9]{9}$/.test(value)
}
