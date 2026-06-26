'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useTranslations, useLocale } from 'next-intl'
import { Eye, EyeOff, Loader2 } from 'lucide-react'
import { isValidEmail } from '@/utils/validation'
import { signIn } from '@/services/auth'

// Formulaire de connexion — présentation + validation client uniquement.
// POURQUOI 'use client' : champs contrôlés (useState) + appel signIn navigateur.
// Tous les libellés/erreurs viennent de next-intl (Rule 4) — jamais de chaîne en dur.
// POURQUOI classes logiques (text-start) et pas left/right : le miroir RTL arabe est
// géré par dir="rtl" du layout locale (Phase 0) — le composant se reflète tout seul.
export default function LoginForm() {
  const t = useTranslations('auth')
  // Locale courante (FR/AR/EN) — sert à la redirection localisée après succès et au
  // lien d'inscription. POURQUOI useLocale et pas un parse manuel de l'URL : source
  // unique de vérité fournie par next-intl, alignée sur le middleware de routage.
  const locale = useLocale()
  const router = useRouter()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  // Bascule affichage du mot de passe (pure UX) — n'altère ni la valeur ni le flux auth.
  const [showPassword, setShowPassword] = useState(false)

  // État du flux asynchrone de connexion. isLoading bloque le double-submit ;
  // submitError stocke UNIQUEMENT une clé i18n connue (jamais le message brut
  // Supabase, Rule 1) ou null quand il n'y a pas d'erreur à afficher.
  const [isLoading, setIsLoading] = useState(false)
  const [submitError, setSubmitError] = useState<string | null>(null)

  // Validité dérivée pour (dé)activer le bouton. POURQUOI pas de isStrongPassword ici :
  // les mots de passe existants sont antérieurs à toute règle de force — on exige
  // seulement un email valide et un mot de passe non vide, jamais re-tester la force
  // au login (sinon on bloque des comptes légitimes créés avant la règle).
  const formValid = isValidEmail(email) && password.length > 0

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!formValid) return

    // On verrouille le formulaire et on repart d'un état d'erreur propre.
    setIsLoading(true)
    setSubmitError(null)

    try {
      const { error } = await signIn(email, password)

      if (error) {
        // POURQUOI ne pas exposer error.message brut — Rule 1 : message générique
        // traduit, jamais le détail Supabase. POURQUOI un message générique par défaut
        // (anti-énumération, T08) : ne pas révéler si l'email existe ou si c'est le
        // mot de passe qui est faux. Seuls deux cas connus ont un message UX utile :
        // email non confirmé (l'utilisateur doit agir) et identifiants invalides.
        const raw = `${error.message ?? ''}`.toLowerCase()
        if (raw.includes('email not confirmed') || raw.includes('email_not_confirmed')) {
          setSubmitError('errors.emailNotConfirmed')
        } else if (raw.includes('invalid login credentials') || error.status === 400) {
          setSubmitError('errors.invalidCredentials')
        } else {
          setSubmitError('errors.generic')
        }
      } else {
        // Succès : redirection vers l'accueil localisé.
        router.push(`/${locale}`)
        // POURQUOI router.refresh : signIn vient de poser le cookie de session ; le
        // middleware et les Server Components doivent re-lire ce cookie frais pour
        // rendre l'état authentifié. Sans refresh, le serveur garde l'ancienne session.
        router.refresh()
      }
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <form
      onSubmit={handleSubmit}
      noValidate
      className="w-full max-w-md bg-blanc rounded-card shadow-card border border-warm-border p-6"
    >
      <h1 className="text-espresso text-2xl font-semibold text-start mb-6">
        {t('signin.title')}
      </h1>

      {/* Champ email */}
      <div className="mb-4">
        <label htmlFor="email" className="block text-start text-ink mb-2">
          {t('signin.emailLabel')}
        </label>
        <input
          id="email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          className="w-full bg-blanc rounded-btn p-4 text-start border border-warm-border focus:outline-none focus:shadow-focus"
        />
      </div>

      {/* Champ mot de passe */}
      <div className="mb-6">
        <label htmlFor="password" className="block text-start text-ink mb-2">
          {t('signin.passwordLabel')}
        </label>
        {/* Conteneur relatif : ancre le bouton œil À L'INTÉRIEUR du champ. */}
        <div className="relative">
          <input
            id="password"
            type={showPassword ? 'text' : 'password'}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            // pe-12 (padding-inline-end) et pas pr-12 : réserve la place de l'icône du
            // bon côté en LTR comme en RTL arabe — le texte ne passe jamais sous l'œil.
            className="w-full bg-blanc rounded-btn p-4 pe-12 text-start border border-warm-border focus:outline-none focus:shadow-focus"
          />
          {/* type="button" obligatoire : sans lui, un <button> dans un <form> soumet
              le formulaire à chaque clic sur l'œil. end-0 (et pas right-0) : l'icône se
              place à la fin logique, donc à gauche en arabe RTL — miroir automatique. */}
          <button
            type="button"
            onClick={() => setShowPassword((v) => !v)}
            aria-label={showPassword ? 'Hide password' : 'Show password'}
            className="absolute inset-y-0 end-0 flex items-center pe-4 text-warm-tertiary"
          >
            {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
          </button>
        </div>
        <Link
          href={`/${locale}/auth/forgot-password`}
          className="block text-end text-espresso text-sm mt-2 underline"
        >
          {t('forgot.title')}
        </Link>
      </div>

      {/* Bloc erreur : message générique traduit issu d'une clé i18n connue (Rule 1). */}
      {submitError && (
        <div className="bg-error-light rounded-btn p-4 mb-4">
          <p className="text-error text-sm text-start">{t(submitError)}</p>
        </div>
      )}

      {/* Bouton primaire : désactivé tant qu'email invalide OU mot de passe vide OU
          pendant l'appel réseau. POURQUOI un libellé "patientez" + spinner pendant
          isLoading : l'utilisateur voit que l'action est en cours, ne re-clique pas et
          n'est pas perdu pendant la latence réseau. inline-flex/gap-2 aligne les deux. */}
      <button
        type="submit"
        disabled={!formValid || isLoading}
        className={`w-full inline-flex items-center justify-center gap-2 rounded-btn p-4 font-medium ${
          formValid && !isLoading
            ? 'bg-espresso text-creme'
            : 'bg-beige text-warm-disabled cursor-not-allowed'
        }`}
      >
        {isLoading && <Loader2 size={18} className="animate-spin" />}
        {isLoading ? t('submitting') : t('signin.submit')}
      </button>

      {/* Lien vers l'inscription — href localisé construit à partir de la locale courante. */}
      <Link
        href={`/${locale}/auth/signup`}
        className="block text-start text-espresso text-sm mt-4 underline"
      >
        {t('signin.noAccount')}
      </Link>
    </form>
  )
}
