'use client'

import { useState } from 'react'
import { useTranslations } from 'next-intl'
import { isValidEmail, isStrongPassword } from '@/utils/validation'
import { signUp } from '@/services/auth'

// Formulaire d'inscription — présentation + validation client uniquement.
// POURQUOI 'use client' : champs contrôlés (useState) + validation à la frappe/blur.
// Tous les libellés/erreurs viennent de next-intl (Rule 4) — jamais de chaîne en dur.
// POURQUOI classes logiques (text-start, ms-/me-) et pas left/right : le miroir RTL
// arabe est géré par dir="rtl" du layout locale (Phase 0) — le composant se reflète
// automatiquement sans code spécifique à la direction.
export default function SignupForm() {
  const t = useTranslations('auth')

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  // Erreurs par champ : null = pas encore validé / valide. La clé i18n est stockée
  // pour afficher le message traduit sous le champ concerné.
  const [emailError, setEmailError] = useState<string | null>(null)
  const [passwordError, setPasswordError] = useState<string | null>(null)

  // État du flux asynchrone d'inscription. isLoading bloque le double-submit ;
  // submitStatus pilote l'affichage (panneau succès / bloc erreur) ; submitErrorKey
  // stocke UNIQUEMENT une clé i18n connue (jamais le message brut Supabase, Rule 1).
  const [isLoading, setIsLoading] = useState(false)
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle')
  const [submitErrorKey, setSubmitErrorKey] = useState<string | null>(null)

  // Validité dérivée : sert à (dé)activer le bouton sans dupliquer la logique.
  const formValid = isValidEmail(email) && isStrongPassword(password)

  function validateEmail() {
    setEmailError(isValidEmail(email) ? null : 'errors.emailInvalid')
  }

  function validatePassword() {
    setPasswordError(isStrongPassword(password) ? null : 'errors.passwordWeak')
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    // Revalidation complète au submit (le client n'est jamais la source de vérité,
    // mais ici c'est l'UX : on affiche toutes les erreurs d'un coup).
    validateEmail()
    validatePassword()
    if (!formValid) return

    // On verrouille le formulaire et on repart d'un état propre avant l'appel réseau.
    setIsLoading(true)
    setSubmitStatus('idle')
    setSubmitErrorKey(null)

    try {
      // signUp crée UNIQUEMENT l'entrée auth.users ; la ligne users (role citoyen)
      // est créée par le trigger DB côté serveur — on N'appelle PAS create-profile ici.
      const { error } = await signUp(email, password)

      if (error) {
        // POURQUOI ne pas exposer error.message brut — Rule 1, message générique
        // traduit ; on mappe seulement les cas connus vers une clé i18n.
        const alreadyRegistered =
          error.status === 422 ||
          /already\s*(registered|exists)|user_already_exists/i.test(error.message)
        setSubmitErrorKey(alreadyRegistered ? 'errors.emailTaken' : 'errors.generic')
        setSubmitStatus('error')
      } else {
        // Succès : on vide les champs et on bascule sur le panneau de confirmation.
        setSubmitStatus('success')
        setEmail('')
        setPassword('')
      }
    } finally {
      setIsLoading(false)
    }
  }

  // Succès : on remplace tout le formulaire par un panneau de confirmation clair.
  // POURQUOI cacher les champs : l'utilisateur doit comprendre sans ambiguïté que le
  // compte est créé et qu'il doit vérifier son email (exigence UX clé).
  if (submitStatus === 'success') {
    return (
      <div className="w-full max-w-md bg-success-light rounded-card shadow-card border border-success p-6">
        <h1 className="text-success text-2xl font-semibold text-start mb-2">
          {t('signup.title')}
        </h1>
        <p className="text-success text-start">{t('signup.success')}</p>
      </div>
    )
  }

  return (
    <form
      onSubmit={handleSubmit}
      noValidate
      className="w-full max-w-md bg-blanc rounded-card shadow-card border border-warm-border p-6"
    >
      <h1 className="text-espresso text-2xl font-semibold text-start mb-6">
        {t('signup.title')}
      </h1>

      {/* Champ email */}
      <div className="mb-4">
        <label
          htmlFor="email"
          className="block text-start text-ink mb-2"
        >
          {t('signup.emailLabel')}
        </label>
        <input
          id="email"
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          onBlur={validateEmail}
          className={`w-full bg-blanc rounded-btn p-4 text-start border focus:outline-none focus:shadow-focus ${
            emailError ? 'border-error' : 'border-warm-border'
          }`}
        />
        {emailError && (
          <p className="text-error text-sm text-start mt-2">{t(emailError)}</p>
        )}
      </div>

      {/* Champ mot de passe */}
      <div className="mb-6">
        <label
          htmlFor="password"
          className="block text-start text-ink mb-2"
        >
          {t('signup.passwordLabel')}
        </label>
        <input
          id="password"
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          onBlur={validatePassword}
          className={`w-full bg-blanc rounded-btn p-4 text-start border focus:outline-none focus:shadow-focus ${
            passwordError ? 'border-error' : 'border-warm-border'
          }`}
        />
        {passwordError && (
          <p className="text-error text-sm text-start mt-2">{t(passwordError)}</p>
        )}
      </div>

      {/* Bloc erreur : message générique traduit issu d'une clé i18n connue (Rule 1). */}
      {submitStatus === 'error' && submitErrorKey && (
        <div className="bg-error-light rounded-btn p-4 mb-4">
          <p className="text-error text-sm text-start">{t(submitErrorKey)}</p>
        </div>
      )}

      {/* Bouton primaire : désactivé tant que le formulaire n'est pas valide OU pendant
          l'appel réseau. Pas de clé "chargement" en i18n → on réutilise le libellé submit
          (jamais de chaîne en dur, Rule 4). */}
      <button
        type="submit"
        disabled={!formValid || isLoading}
        className={`w-full rounded-btn p-4 font-medium ${
          formValid && !isLoading
            ? 'bg-espresso text-creme'
            : 'bg-beige text-warm-disabled cursor-not-allowed'
        }`}
      >
        {t('signup.submit')}
      </button>
    </form>
  )
}
