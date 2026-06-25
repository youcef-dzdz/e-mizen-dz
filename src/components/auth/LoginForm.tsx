'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useTranslations, useLocale } from 'next-intl'
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
        <input
          id="password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          className="w-full bg-blanc rounded-btn p-4 text-start border border-warm-border focus:outline-none focus:shadow-focus"
        />
      </div>

      {/* Bloc erreur : message générique traduit issu d'une clé i18n connue (Rule 1). */}
      {submitError && (
        <div className="bg-error-light rounded-btn p-4 mb-4">
          <p className="text-error text-sm text-start">{t(submitError)}</p>
        </div>
      )}

      {/* Bouton primaire : désactivé tant qu'email invalide OU mot de passe vide OU
          pendant l'appel réseau. Pas de clé "chargement" → on réutilise le libellé
          submit (jamais de chaîne en dur, Rule 4). */}
      <button
        type="submit"
        disabled={!formValid || isLoading}
        className={`w-full rounded-btn p-4 font-medium ${
          formValid && !isLoading
            ? 'bg-espresso text-creme'
            : 'bg-beige text-warm-disabled cursor-not-allowed'
        }`}
      >
        {t('signin.submit')}
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
