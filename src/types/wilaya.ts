// Type Wilaya — forme minimale destinée au sélecteur (WilayaSelect).
// POURQUOI seulement ces 4 champs (et pas latitude/longitude/actif/created_at) : le
// menu déroulant n'a besoin que de l'identifiant (id = valeur soumise), du code
// administratif et des deux noms d'affichage (FR/AR selon la locale). latitude et
// longitude servent la recherche Haversine (Phase 2), actif et created_at sont des
// métadonnées de gestion — les inclure ici sur-chargerait le type sans usage côté UI.
// Le SELECT du service ne demande d'ailleurs que ces 4 colonnes, ce qui garde la forme
// du type et la requête alignées.
export interface Wilaya {
  id: number
  code: string
  nom_fr: string
  nom_ar: string
}
