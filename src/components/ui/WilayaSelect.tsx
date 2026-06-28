'use client'

import { useEffect, useState } from 'react'
import { useTranslations, useLocale } from 'next-intl'
import { getWilayas } from '@/services/wilaya'
import type { Wilaya } from '@/types/wilaya'

// Sélecteur de wilaya réutilisable — menu déroulant natif des wilayas actives.
// POURQUOI 'use client' : charge la liste au montage (useEffect) et pilote un <select>
// contrôlé. POURQUOI un <select> natif (et pas une lib externe) : accessible, léger,
// déjà compatible RTL via dir="rtl" du layout locale — pas de dépendance ajoutée (YAGNI).
// POURQUOI composant autonome dédié (pas un Select générique) : un seul usage aujourd'hui
// (inscription avocat), on n'abstrait pas prématurément.
// POURQUOI classes logiques (text-start, pe-*) et tokens uniquement : le miroir RTL arabe
// est automatique (dir du layout) et aucune couleur n'est en dur (Rule 8).

type WilayaSelectProps = {
  // Valeur contrôlée : id de la wilaya sélectionnée, ou null si rien n'est choisi.
  value: number | null
  // Remonte le nouvel id (ou null si l'utilisateur revient sur le placeholder).
  onChange: (id: number | null) => void
  // Clé/texte d'erreur de validation fourni par le parent (ex. champ requis) — pilote
  // seulement la bordure ici ; le message est affiché par le formulaire appelant.
  error?: string | null
  // id HTML optionnel pour lier un <label> externe ; défaut stable sinon.
  id?: string
}

export default function WilayaSelect({
  value,
  onChange,
  error,
  id = 'wilaya',
}: WilayaSelectProps) {
  const t = useTranslations('wilaya')
  // Locale courante : choisit la colonne d'affichage (arabe → nom_ar, sinon nom_fr).
  const locale = useLocale()

  const [wilayas, setWilayas] = useState<Wilaya[]>([])
  // loading : vrai pendant le fetch initial → on désactive le select et on affiche un
  // libellé de chargement. fetchError : vrai si le SELECT a échoué → message générique
  // traduit, JAMAIS l'erreur brute Supabase (Rule 1).
  const [loading, setLoading] = useState(true)
  const [fetchError, setFetchError] = useState(false)

  useEffect(() => {
    // POURQUOI un flag isMounted : le composant peut être démonté avant la fin du fetch
    // (navigation rapide) — on évite alors un setState sur un composant démonté.
    let isMounted = true

    async function loadWilayas() {
      setLoading(true)
      setFetchError(false)
      const { data, error: loadError } = await getWilayas()
      if (!isMounted) return

      if (loadError || !data) {
        // On ne logge ni n'affiche le détail Supabase : seule la UI générique parle (Rule 1).
        setFetchError(true)
        setWilayas([])
      } else {
        setWilayas(data as Wilaya[])
      }
      setLoading(false)
    }

    loadWilayas()
    return () => {
      isMounted = false
    }
  }, [])

  // Conversion de la valeur string du <select> natif vers number | null. Le placeholder
  // a une value vide ('') → on remonte null ; sinon on parse l'id numérique.
  function handleChange(event: React.ChangeEvent<HTMLSelectElement>) {
    const raw = event.target.value
    onChange(raw === '' ? null : Number(raw))
  }

  // Libellé d'affichage d'une wilaya : matricule + nom selon la locale active (arabe
  // vs latin). POURQUOI préfixer le code (ex. "31 - Oran") : le matricule est un repère
  // officiel connu des Algériens (carte d'identité, plaques) — il lève l'ambiguïté entre
  // wilayas homonymes et rend la colonne code utile (cohérence type/SELECT/affichage).
  // POURQUOI le séparateur " - " : neutre en LTR comme en RTL, sans caractère directionnel.
  function displayName(w: Wilaya): string {
    const nom = locale === 'ar' ? w.nom_ar : w.nom_fr
    return `${w.code} - ${nom}`
  }

  return (
    <div>
      <label htmlFor={id} className="block text-start text-ink mb-2">
        {t('label')}
      </label>

      <select
        id={id}
        // En chargement, le select est inerte : pas de choix possible avant d'avoir les données.
        disabled={loading}
        // value contrôlé : '' force l'affichage du placeholder tant que rien n'est choisi.
        value={value === null ? '' : String(value)}
        onChange={handleChange}
        // pe-4 (padding-inline-end) et text-start : place et alignement logiques, corrects
        // en LTR comme en RTL arabe. Bordure error si le parent signale une erreur, sinon
        // bordure chaude par défaut. disabled:* atténue visuellement l'état chargement.
        className={`w-full bg-blanc rounded-btn p-4 pe-4 text-start border focus:outline-none focus:shadow-focus disabled:bg-beige disabled:text-warm-disabled disabled:cursor-not-allowed ${
          error ? 'border-error' : 'border-warm-border'
        }`}
      >
        {/* Option placeholder : value vide → mappée sur null par handleChange. Libellé
            dépend de l'état (chargement vs prêt) pour informer l'utilisateur. */}
        <option value="">{loading ? t('loading') : t('placeholder')}</option>

        {/* Une option par wilaya active, dans l'ordre officiel renvoyé par le service. */}
        {wilayas.map((w) => (
          <option key={w.id} value={w.id}>
            {displayName(w)}
          </option>
        ))}
      </select>

      {/* Erreur de CHARGEMENT (réseau/RLS) : message générique traduit, jamais le détail. */}
      {fetchError && (
        <p className="text-error text-sm text-start mt-2">{t('loadError')}</p>
      )}
    </div>
  )
}
