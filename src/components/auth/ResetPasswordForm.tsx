'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'
import { useTranslations, useLocale } from 'next-intl'
import { Eye, EyeOff, Loader2 } from 'lucide-react'
import { isStrongPassword } from '@/utils/validation'
import { updatePassword } from '@/services/auth'

// Formulaire de réinitialisation du mot de passe — l'utilisateur arrive ici avec une
// session recovery valide (posée par le callback après échange du code PKCE).
// POURQUOI anti-énumération maintenue : en cas d'erreur on affiche un message générique
// ou "lien expiré", jamais le détail Supabase.
export default function ResetPasswordForm() {
  const t = useTranslations('auth')
  const locale = useLocale()
  const router = useRouter()

  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [passwordError, setPasswordError] = useState<string | null>(null)
  const [confirmError, setConfirmError] = useState<string | null>(null)
  const [showPassword, setShowPassword] = useState(false)
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)

  const [isLoading, setIsLoading] = useState(false)
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle')
  const [submitError, setSubmitError] = useState<string | null>(null)

  const formValid =
    isStrongPassword(password) &&
    confirmPassword.length > 0 &&
    confirmPassword === password

  function validatePassword() {
    setPasswordError(isStrongPassword(password) ? null : 'errors.passwordWeak')
  }

  function validateConfirm() {
    setConfirmError(
      confirmPassword.length > 0 && confirmPassword !== password
        ? 'errors.passwordMismatch'
        : null
    )
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    validatePassword()
    validateConfirm()
    if (!formValid) return

    setIsLoading(true)
    setSubmitStatus('idle')
    setSubmitError(null)

    try {
      const { error } = await updatePassword(password)

      if (error) {
        // POURQUOI deux cas : si la session recovery a expiré ou n'existe pas,
        // l'utilisateur doit refaire la demande — sinon message générique (Rule 1).
        const raw = `${error.message ?? ''}`.toLowerCase()
        const sessionExpired =
          error.status === 401 ||
          error.status === 403 ||
          raw.includes('session') ||
          raw.includes('not authenticated') ||
          raw.includes('auth')
        setSubmitError(sessionExpired ? 'errors.resetLinkInvalid' : 'errors.generic')
        setSubmitStatus('error')
      } else {
        setSubmitStatus('success')
        // Redirection vers login après un court délai pour lire le message de succès.
        setTimeout(() => router.push(`/${locale}/auth/login`), 2000)
      }
    } finally {
      setIsLoading(false)
    }
  }

  if (submitStatus === 'success') {
    return (
      <div className="w-full max-w-md bg-success-light rounded-card shadow-card border border-success p-6">
        <h1 className="text-success text-2xl font-semibold text-start mb-2">
          {t('reset.title')}
        </h1>
        <p className="text-success text-start">{t('reset.success')}</p>
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
        {t('reset.title')}
      </h1>

      {/* Champ nouveau mot de passe */}
      <div className="mb-6">
        <label htmlFor="password" className="block text-start text-ink mb-2">
          {t('reset.passwordLabel')}
        </label>
        <div className="relative">
          <input
            id="password"
            type={showPassword ? 'text' : 'password'}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onBlur={validatePassword}
            className={`w-full bg-blanc rounded-btn p-4 pe-12 text-start border focus:outline-none focus:shadow-focus ${
              passwordError ? 'border-error' : 'border-warm-border'
            }`}
          />
          <button
            type="button"
            onClick={() => setShowPassword((v) => !v)}
            aria-label={showPassword ? 'Hide password' : 'Show password'}
            className="absolute inset-y-0 end-0 flex items-center pe-4 text-warm-tertiary"
          >
            {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
          </button>
        </div>
        {passwordError && (
          <p className="text-error text-sm text-start mt-2">{t(passwordError)}</p>
        )}
      </div>

      {/* Champ confirmation */}
      <div className="mb-6">
        <label htmlFor="confirmPassword" className="block text-start text-ink mb-2">
          {t('reset.confirmLabel')}
        </label>
        <div className="relative">
          <input
            id="confirmPassword"
            type={showConfirmPassword ? 'text' : 'password'}
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            onBlur={validateConfirm}
            className={`w-full bg-blanc rounded-btn p-4 pe-12 text-start border focus:outline-none focus:shadow-focus ${
              confirmError ? 'border-error' : 'border-warm-border'
            }`}
          />
          <button
            type="button"
            onClick={() => setShowConfirmPassword((v) => !v)}
            aria-label={showConfirmPassword ? 'Hide password' : 'Show password'}
            className="absolute inset-y-0 end-0 flex items-center pe-4 text-warm-tertiary"
          >
            {showConfirmPassword ? <EyeOff size={18} /> : <Eye size={18} />}
          </button>
        </div>
        {confirmError && (
          <p className="text-error text-sm text-start mt-2">{t(confirmError)}</p>
        )}
      </div>

      {submitStatus === 'error' && submitError && (
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
        {isLoading ? t('submitting') : t('reset.submit')}
      </button>
    </form>
  )
}
