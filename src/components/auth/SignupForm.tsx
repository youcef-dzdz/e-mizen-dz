'use client'

import { useState } from 'react'
import { useTranslations } from 'next-intl'
import { isValidEmail, isStrongPassword } from '@/utils/validation'

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

  // Validité dérivée : sert à (dé)activer le bouton sans dupliquer la logique.
  const formValid = isValidEmail(email) && isStrongPassword(password)

  function validateEmail() {
    setEmailError(isValidEmail(email) ? null : 'errors.emailInvalid')
  }

  function validatePassword() {
    setPasswordError(isStrongPassword(password) ? null : 'errors.passwordWeak')
  }

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    // Revalidation complète au submit (le client n'est jamais la source de vérité,
    // mais ici c'est l'UX : on affiche toutes les erreurs d'un coup).
    validateEmail()
    validatePassword()
    if (!formValid) return

    // TODO étape 2 — brancher auth.ts signUp() + create-profile.
    console.log('signup ready', email)
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

      {/* Bouton primaire : désactivé tant que le formulaire n'est pas valide. */}
      <button
        type="submit"
        disabled={!formValid}
        className={`w-full rounded-btn p-4 font-medium ${
          formValid
            ? 'bg-espresso text-creme'
            : 'bg-beige text-warm-disabled cursor-not-allowed'
        }`}
      >
        {t('signup.submit')}
      </button>
    </form>
  )
}
