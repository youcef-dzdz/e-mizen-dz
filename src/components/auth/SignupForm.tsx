'use client'

import { useState } from 'react'
import { useTranslations, useLocale } from 'next-intl'
import { Eye, EyeOff, Loader2 } from 'lucide-react'
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
  // Locale courante (FR/AR/EN) — passée à signUp pour construire l'URL de callback
  // localisée (emailRedirectTo) afin que la confirmation revienne dans la bonne langue.
  const locale = useLocale()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  // POURQUOI confirmer le mot de passe : une faute de frappe invisible (champ masqué)
  // enfermerait l'utilisateur hors de son compte dès la première connexion. La
  // double-saisie force la cohérence avant la création du compte.
  const [confirmPassword, setConfirmPassword] = useState('')
  // Erreurs par champ : null = pas encore validé / valide. La clé i18n est stockée
  // pour afficher le message traduit sous le champ concerné.
  const [emailError, setEmailError] = useState<string | null>(null)
  const [passwordError, setPasswordError] = useState<string | null>(null)
  const [confirmError, setConfirmError] = useState<string | null>(null)
  // Bascule affichage du mot de passe (pure UX) — n'altère ni la valeur ni la validation.
  const [showPassword, setShowPassword] = useState(false)
  // POURQUOI son propre showConfirmPassword : la bascule du champ confirmation est
  // indépendante de celle du mot de passe — révéler l'un ne doit jamais révéler l'autre.
  const [showConfirmPassword, setShowConfirmPassword] = useState(false)

  // État du flux asynchrone d'inscription. isLoading bloque le double-submit ;
  // submitStatus pilote l'affichage (panneau succès / bloc erreur) ; submitErrorKey
  // stocke UNIQUEMENT une clé i18n connue (jamais le message brut Supabase, Rule 1).
  const [isLoading, setIsLoading] = useState(false)
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle')
  const [submitErrorKey, setSubmitErrorKey] = useState<string | null>(null)

  // Validité dérivée : sert à (dé)activer le bouton sans dupliquer la logique.
  // La confirmation doit être non vide ET identique au mot de passe — le bouton reste
  // bloqué tant que les deux saisies ne concordent pas.
  const formValid =
    isValidEmail(email) &&
    isStrongPassword(password) &&
    confirmPassword.length > 0 &&
    confirmPassword === password

  function validateEmail() {
    setEmailError(isValidEmail(email) ? null : 'errors.emailInvalid')
  }

  function validatePassword() {
    setPasswordError(isStrongPassword(password) ? null : 'errors.passwordWeak')
  }

  // Erreur de concordance affichée seulement si la confirmation est saisie : on ne
  // crie pas « ça ne correspond pas » sur un champ encore vide.
  function validateConfirm() {
    setConfirmError(
      confirmPassword.length > 0 && confirmPassword !== password
        ? 'errors.passwordMismatch'
        : null
    )
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    // Revalidation complète au submit (le client n'est jamais la source de vérité,
    // mais ici c'est l'UX : on affiche toutes les erreurs d'un coup).
    validateEmail()
    validatePassword()
    validateConfirm()
    if (!formValid) return

    // On verrouille le formulaire et on repart d'un état propre avant l'appel réseau.
    setIsLoading(true)
    setSubmitStatus('idle')
    setSubmitErrorKey(null)

    try {
      // signUp crée UNIQUEMENT l'entrée auth.users ; la ligne users (role citoyen)
      // est créée par le trigger DB côté serveur — on N'appelle PAS create-profile ici.
      const { error } = await signUp(email, password, locale)

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
        setConfirmPassword('')
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
        {/* Conteneur relatif : ancre le bouton œil À L'INTÉRIEUR du champ. */}
        <div className="relative">
          <input
            id="password"
            type={showPassword ? 'text' : 'password'}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            onBlur={validatePassword}
            // pe-12 (padding-inline-end) et pas pr-12 : réserve la place de l'icône du
            // bon côté en LTR comme en RTL arabe — le texte ne passe jamais sous l'œil.
            className={`w-full bg-blanc rounded-btn p-4 pe-12 text-start border focus:outline-none focus:shadow-focus ${
              passwordError ? 'border-error' : 'border-warm-border'
            }`}
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
        {passwordError && (
          <p className="text-error text-sm text-start mt-2">{t(passwordError)}</p>
        )}
      </div>

      {/* Champ confirmation du mot de passe — miroir exact du champ ci-dessus, avec sa
          propre bascule d'affichage (showConfirmPassword) indépendante. */}
      <div className="mb-6">
        <label
          htmlFor="confirmPassword"
          className="block text-start text-ink mb-2"
        >
          {t('signup.confirmPasswordLabel')}
        </label>
        {/* Conteneur relatif : ancre le bouton œil À L'INTÉRIEUR du champ. */}
        <div className="relative">
          <input
            id="confirmPassword"
            type={showConfirmPassword ? 'text' : 'password'}
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            onBlur={validateConfirm}
            // pe-12 (padding-inline-end) et pas pr-12 : réserve la place de l'icône du
            // bon côté en LTR comme en RTL arabe — le texte ne passe jamais sous l'œil.
            className={`w-full bg-blanc rounded-btn p-4 pe-12 text-start border focus:outline-none focus:shadow-focus ${
              confirmError ? 'border-error' : 'border-warm-border'
            }`}
          />
          {/* type="button" obligatoire : sans lui, un <button> dans un <form> soumet
              le formulaire à chaque clic sur l'œil. end-0 (et pas right-0) : l'icône se
              place à la fin logique, donc à gauche en arabe RTL — miroir automatique. */}
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

      {/* Bloc erreur : message générique traduit issu d'une clé i18n connue (Rule 1). */}
      {submitStatus === 'error' && submitErrorKey && (
        <div className="bg-error-light rounded-btn p-4 mb-4">
          <p className="text-error text-sm text-start">{t(submitErrorKey)}</p>
        </div>
      )}

      {/* Bouton primaire : désactivé tant que le formulaire n'est pas valide OU pendant
          l'appel réseau. POURQUOI un libellé "patientez" + spinner pendant isLoading :
          l'utilisateur voit que l'action est en cours, ne re-clique pas et n'est pas
          perdu pendant la latence réseau. inline-flex/gap-2 aligne spinner et libellé. */}
      <button
        type="submit"
        disabled={!formValid || isLoading}
        className={`w-full inline-flex items-center justify-center gap-2 rounded-btn py-3 font-medium ${
          formValid && !isLoading
            ? 'bg-espresso text-creme'
            : 'bg-beige text-warm-disabled cursor-not-allowed'
        }`}
      >
        {isLoading && <Loader2 size={18} className="animate-spin" />}
        {isLoading ? t('submitting') : t('signup.submit')}
      </button>
    </form>
  )
}
