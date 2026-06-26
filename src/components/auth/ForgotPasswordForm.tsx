'use client'

import { useState } from 'react'
import Link from 'next/link'
import { useTranslations, useLocale } from 'next-intl'
import { Loader2 } from 'lucide-react'
import { isValidEmail } from '@/utils/validation'
import { resetPasswordForEmail } from '@/services/auth'

// Formulaire "mot de passe oublié" — envoie un lien de réinitialisation par email.
// POURQUOI anti-énumération (T08) : on affiche toujours le même message de succès,
// que l'email existe ou non — ne jamais révéler l'existence d'un compte.
export default function ForgotPasswordForm() {
  const t = useTranslations('auth')
  const locale = useLocale()

  const [email, setEmail] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle')
  const [submitError, setSubmitError] = useState<string | null>(null)

  const formValid = isValidEmail(email)

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!formValid) return

    setIsLoading(true)
    setSubmitError(null)
    setSubmitStatus('idle')

    try {
      const { error } = await resetPasswordForEmail(email, locale)

      if (error) {
        // POURQUOI message générique uniquement : anti-énumération (T08) — ne pas
        // distinguer "email inexistant" d'une autre erreur côté client.
        setSubmitError('errors.generic')
        setSubmitStatus('error')
      } else {
        setSubmitStatus('success')
      }
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <div className="w-full max-w-md bg-blanc rounded-card shadow-card border border-warm-border p-6">
      <h1 className="text-espresso text-2xl font-semibold text-start mb-2">
        {t('forgot.title')}
      </h1>
      <p className="text-warm-tertiary text-sm text-start mb-6">
        {t('forgot.description')}
      </p>

      {submitStatus === 'success' ? (
        <div className="bg-success-light rounded-btn p-4 mb-4">
          <p className="text-success text-sm text-start">{t('forgot.success')}</p>
        </div>
      ) : (
        <form onSubmit={handleSubmit} noValidate>
          <div className="mb-4">
            <label htmlFor="forgot-email" className="block text-start text-ink mb-2">
              {t('forgot.emailLabel')}
            </label>
            <input
              id="forgot-email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              className="w-full bg-blanc rounded-btn p-4 text-start border border-warm-border focus:outline-none focus:shadow-focus"
            />
          </div>

          {submitError && (
            <div className="bg-error-light rounded-btn p-4 mb-4">
              <p className="text-error text-sm text-start">{t(submitError)}</p>
            </div>
          )}

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
            {isLoading ? t('submitting') : t('forgot.submit')}
          </button>
        </form>
      )}

      <Link
        href={`/${locale}/auth/login`}
        className="block text-start text-espresso text-sm mt-4 underline"
      >
        {t('forgot.backToLogin')}
      </Link>
    </div>
  )
}
