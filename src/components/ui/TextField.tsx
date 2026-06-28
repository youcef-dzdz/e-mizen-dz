'use client'

import { useState } from 'react'
import { Eye, EyeOff } from 'lucide-react'

// Champ de formulaire réutilisable : label + input + message d'erreur, avec bascule
// d'affichage du mot de passe optionnelle. POURQUOI extraire ce pattern : il est répété
// ~9 fois entre le formulaire citoyen et le futur formulaire avocat (6 champs) — DRY sans
// abstraction prématurée, et garde chaque formulaire sous le plafond de 300 lignes (Rule 3).
//
// POURQUOI le parent passe les TEXTES déjà traduits (label, error, libellés du bouton œil)
// et PAS des clés i18n : TextField est un composant de PRÉSENTATION pur — aucun appel à
// useTranslations, aucune dépendance à un namespace i18n. Le parent décide de la traduction
// et reste libre de réutiliser ce champ dans n'importe quel contexte (Rule 9 : pas d'effet
// de bord ici non plus, aucune donnée Supabase).
//
// POURQUOI classes logiques (text-start, pe-12, end-0) et tokens uniquement : le miroir RTL
// arabe est automatique via dir="rtl" du layout locale, et aucune couleur n'est en dur (Rule 8).

type TextFieldProps = {
  // Lie le <label> à l'<input> (accessibilité) — fourni par le parent.
  id: string
  // Libellé déjà traduit (le parent gère l'i18n).
  label: string
  value: string
  // Remonte la valeur string brute ; le parent gère état et validation.
  onChange: (value: string) => void
  onBlur?: () => void
  // Message d'erreur déjà traduit, affiché tel quel sous le champ (null = pas d'erreur).
  error?: string | null
  // type natif de l'input ; 'password' active la possibilité de bascule (voir ci-dessous).
  type?: 'text' | 'email' | 'tel' | 'password'
  // Quand true ET type='password', affiche le bouton œil pour révéler/masquer la saisie.
  showPasswordToggle?: boolean
  placeholder?: string
  autoComplete?: string
  // Libellés d'accessibilité du bouton œil (aria-label), traduits par le parent. Fallback
  // 'Show'/'Hide' si non fournis — valeur d'accessibilité minimale, jamais affichée à l'écran.
  showPasswordLabel?: string
  hidePasswordLabel?: string
}

export default function TextField({
  id,
  label,
  value,
  onChange,
  onBlur,
  error,
  type = 'text',
  showPasswordToggle = false,
  placeholder,
  autoComplete,
  showPasswordLabel = 'Show',
  hidePasswordLabel = 'Hide',
}: TextFieldProps) {
  // showPassword n'a de sens que pour un champ password avec bascule — sinon il reste inerte.
  const [showPassword, setShowPassword] = useState(false)

  // Le bouton œil n'apparaît que si la bascule est demandée ET que le champ est un password.
  const hasToggle = showPasswordToggle && type === 'password'

  // Type effectif de l'input : si la bascule est active et révélée, on affiche en clair ;
  // sinon on garde le type d'origine (password masqué, ou text/email/tel inchangés).
  const effectiveType = hasToggle && showPassword ? 'text' : type

  return (
    <div>
      <label htmlFor={id} className="block text-start text-ink mb-2">
        {label}
      </label>

      {/* Conteneur relatif : ancre le bouton œil À L'INTÉRIEUR du champ quand il y a bascule. */}
      <div className="relative">
        <input
          id={id}
          type={effectiveType}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onBlur={onBlur}
          placeholder={placeholder}
          autoComplete={autoComplete}
          // pe-12 (padding-inline-end) seulement avec bascule : réserve la place de l'icône
          // du bon côté en LTR comme en RTL arabe — le texte ne passe jamais sous l'œil.
          // Bordure error si message fourni, sinon bordure chaude par défaut.
          className={`w-full bg-blanc rounded-btn p-4 text-start border focus:outline-none focus:shadow-focus ${
            hasToggle ? 'pe-12' : ''
          } ${error ? 'border-error' : 'border-warm-border'}`}
        />

        {/* type="button" obligatoire : sans lui, un <button> dans un <form> soumet le
            formulaire à chaque clic sur l'œil. end-0 (et pas right-0) : l'icône se place à
            la fin logique, donc à gauche en arabe RTL — miroir automatique. */}
        {hasToggle && (
          <button
            type="button"
            onClick={() => setShowPassword((v) => !v)}
            aria-label={showPassword ? hidePasswordLabel : showPasswordLabel}
            className="absolute inset-y-0 end-0 flex items-center pe-4 text-warm-tertiary"
          >
            {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
          </button>
        )}
      </div>

      {/* Message d'erreur générique déjà traduit (Rule 1) — affiché tel quel sous le champ. */}
      {error && (
        <p className="text-error text-sm text-start mt-2">{error}</p>
      )}
    </div>
  )
}
