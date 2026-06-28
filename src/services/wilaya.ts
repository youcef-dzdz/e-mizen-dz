import { supabaseBrowser } from '@/lib/supabase/client'

// Service wilaya — moitié CLIENT (Rule 9 : tout appel Supabase vit dans services/).
// POURQUOI client anon (supabaseBrowser) et JAMAIS service_role (Rule 11) : la table
// wilaya est en SELECT public (policy RLS wilaya_select_public using(true)) — un
// Visiteur non authentifié doit pouvoir lister les wilayas, la clé anon suffit et
// service_role bypasserait RLS pour rien. On renvoie le résultat brut { data, error }
// pour que la UI décide du message (Rule 1) — aucune interprétation métier ici.

// Liste des wilayas actives pour le sélecteur d'inscription.
// POURQUOI eq('actif', true) : masquer les wilayas inactives (période transitoire de
// la loi 26-06) sans les supprimer — on n'affiche que celles réellement sélectionnables.
// POURQUOI order('id') : présenter les wilayas dans l'ordre officiel (1 → 69), repère
// connu des utilisateurs algériens, plutôt qu'un ordre alphabétique dépendant de la langue.
// POURQUOI select('id, code, nom_fr, nom_ar') : on ne tire que les colonnes utiles au
// menu (cf. type Wilaya) — pas de latitude/longitude inutiles au rendu.
// POURQUOI la forme paramétrée .from().select() : zéro concaténation SQL (Rule 14),
// aucune entrée utilisateur n'est injectée dans la requête.
export async function getWilayas() {
  return supabaseBrowser
    .from('wilaya')
    .select('id, code, nom_fr, nom_ar')
    .eq('actif', true)
    .order('id')
}
