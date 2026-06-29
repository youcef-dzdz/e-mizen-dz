'use client'

import { useState } from 'react'
import { useTranslations, useLocale } from 'next-intl'
import { Loader2 } from 'lucide-react'
import {
  isValidEmail,
  isStrongPassword,
  isValidNom,
  isValidTelephoneDZ,
} from '@/utils/validation'
import { signUp } from '@/services/auth'
import TextField from '@/components/ui/TextField'
import WilayaSelect from '@/components/ui/WilayaSelect'

// Formulaire d'inscription avocat — 8 champs, validation client (validation.ts) puis
// signUp avec options.data = { intent:'avocat', ... }. POURQUOI intent (et JAMAIS role) :
// le rôle avocat est forcé côté serveur après vérification admin (T01/T03) ; on ne
// transmet que l'intention + des données descriptives non sensibles, lues par le trigger
// 011 pour créer la ligne pending_avocat_registrations.
// POURQUOI réutiliser TextField + WilayaSelect : DRY, et garde ce fichier sous 300 lignes
// (Rule 3). On ne refactore pas le formulaire citoyen (testé).
export default function AvocatSignupForm() {
  const t = useTranslations('auth')
  // Locale courante — passée à signUp pour l'URL de callback localisée (emailRedirectTo).
  const locale = useLocale()

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [nom, setNom] = useState('')
  const [prenom, setPrenom] = useState('')
  // Téléphone OPTIONNEL : vide accepté (colonne nullable 010) — voir validateTelephone.
  const [telephone, setTelephone] = useState('')
  const [wilayaId, setWilayaId] = useState<number | null>(null)
  const [cabinetNom, setCabinetNom] = useState('')

  // Erreurs par champ : null = valide / pas encore validé ; sinon une clé i18n connue.
  const [emailError, setEmailError] = useState<string | null>(null)
  const [passwordError, setPasswordError] = useState<string | null>(null)
  const [confirmError, setConfirmError] = useState<string | null>(null)
  const [nomError, setNomError] = useState<string | null>(null)
  const [prenomError, setPrenomError] = useState<string | null>(null)
  const [telephoneError, setTelephoneError] = useState<string | null>(null)
  const [wilayaError, setWilayaError] = useState<string | null>(null)
  const [cabinetNomError, setCabinetNomError] = useState<string | null>(null)

  // État du flux asynchrone. submitErrorKey stocke UNIQUEMENT une clé i18n connue
  // (jamais le message brut Supabase, Rule 1).
  const [isLoading, setIsLoading] = useState(false)
  const [submitStatus, setSubmitStatus] = useState<'idle' | 'success' | 'error'>('idle')
  const [submitErrorKey, setSubmitErrorKey] = useState<string | null>(null)

  // Téléphone optionnel : vide => valide ; rempli => doit respecter le format DZ.
  const telephoneValid = telephone.trim() === '' || isValidTelephoneDZ(telephone.trim())

  // Validité globale dérivée : (dé)active le bouton sans dupliquer la logique de validation.
  const formValid =
    isValidEmail(email) &&
    isStrongPassword(password) &&
    confirmPassword.length > 0 &&
    confirmPassword === password &&
    isValidNom(nom) &&
    isValidNom(prenom) &&
    telephoneValid &&
    wilayaId !== null &&
    isValidNom(cabinetNom)

  function validateEmail() {
    setEmailError(isValidEmail(email) ? null : 'errors.emailInvalid')
  }
  function validatePassword() {
    setPasswordError(isStrongPassword(password) ? null : 'errors.passwordWeak')
  }
  // Erreur de concordance seulement si la confirmation est saisie : on ne crie pas
  // « ça ne correspond pas » sur un champ encore vide.
  function validateConfirm() {
    setConfirmError(
      confirmPassword.length > 0 && confirmPassword !== password
        ? 'errors.passwordMismatch'
        : null
    )
  }
  function validateNom() {
    setNomError(isValidNom(nom) ? null : 'errors.nomInvalid')
  }
  function validatePrenom() {
    setPrenomError(isValidNom(prenom) ? null : 'errors.prenomInvalid')
  }
  // POURQUOI ne contrôler que si non vide : le téléphone est facultatif — un champ vide
  // ne doit JAMAIS afficher d'erreur ; on ne vérifie le format que sur une saisie réelle.
  function validateTelephone() {
    setTelephoneError(telephoneValid ? null : 'errors.telephoneInvalid')
  }
  function validateWilaya() {
    setWilayaError(wilayaId !== null ? null : 'errors.wilayaRequired')
  }
  function validateCabinetNom() {
    setCabinetNomError(isValidNom(cabinetNom) ? null : 'errors.cabinetNomInvalid')
  }

  async function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault()
    // Revalidation complète au submit : on affiche toutes les erreurs d'un coup (UX).
    validateEmail()
    validatePassword()
    validateConfirm()
    validateNom()
    validatePrenom()
    validateTelephone()
    validateWilaya()
    validateCabinetNom()
    if (!formValid) return

    setIsLoading(true)
    setSubmitStatus('idle')
    setSubmitErrorKey(null)

    try {
      // options.data : intent + données descriptives → raw_user_meta_data, lues par le
      // trigger 011. role n'y figure JAMAIS (forcé serveur après vérif admin). telephone
      // vide => null (cohérent avec la colonne nullable 010).
      const { error } = await signUp(email, password, locale, {
        intent: 'avocat',
        nom: nom.trim(),
        prenom: prenom.trim(),
        telephone: telephone.trim() || null,
        wilaya_id: wilayaId,
        cabinet_nom: cabinetNom.trim(),
      })

      if (error) {
        // Rule 1 : jamais error.message brut — on mappe seulement les cas connus vers une clé.
        const alreadyRegistered =
          error.status === 422 ||
          /already\s*(registered|exists)|user_already_exists/i.test(error.message)
        setSubmitErrorKey(alreadyRegistered ? 'errors.emailTaken' : 'errors.generic')
        setSubmitStatus('error')
      } else {
        // Succès : on vide tout et on bascule sur le panneau de confirmation.
        setSubmitStatus('success')
        setEmail('')
        setPassword('')
        setConfirmPassword('')
        setNom('')
        setPrenom('')
        setTelephone('')
        setWilayaId(null)
        setCabinetNom('')
      }
    } finally {
      setIsLoading(false)
    }
  }

  // Succès : on remplace le formulaire par un panneau de confirmation clair (même UX que
  // le formulaire citoyen) — l'avocat doit comprendre qu'il doit confirmer son email.
  if (submitStatus === 'success') {
    return (
      <div className="w-full max-w-md bg-success-light rounded-card shadow-card border border-success p-6">
        <h1 className="text-success text-2xl font-semibold text-start mb-2">
          {t('signupAvocat.title')}
        </h1>
        <p className="text-success text-start">{t('signupAvocat.success')}</p>
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
        {t('signupAvocat.title')}
      </h1>

      <div className="mb-4">
        <TextField
          id="email"
          type="email"
          autoComplete="email"
          label={t('signupAvocat.emailLabel')}
          value={email}
          onChange={setEmail}
          onBlur={validateEmail}
          error={emailError ? t(emailError) : null}
        />
      </div>

      {/* Mot de passe + confirmation : bascule œil traduite (aria-label) via TextField. */}
      <div className="mb-4">
        <TextField
          id="password"
          type="password"
          autoComplete="new-password"
          showPasswordToggle
          showPasswordLabel={t('signupAvocat.showPassword')}
          hidePasswordLabel={t('signupAvocat.hidePassword')}
          label={t('signupAvocat.passwordLabel')}
          value={password}
          onChange={setPassword}
          onBlur={validatePassword}
          error={passwordError ? t(passwordError) : null}
        />
      </div>

      <div className="mb-4">
        <TextField
          id="confirmPassword"
          type="password"
          autoComplete="new-password"
          showPasswordToggle
          showPasswordLabel={t('signupAvocat.showPassword')}
          hidePasswordLabel={t('signupAvocat.hidePassword')}
          label={t('signupAvocat.confirmPasswordLabel')}
          value={confirmPassword}
          onChange={setConfirmPassword}
          onBlur={validateConfirm}
          error={confirmError ? t(confirmError) : null}
        />
      </div>

      <div className="mb-4">
        <TextField
          id="nom"
          label={t('signupAvocat.nomLabel')}
          value={nom}
          onChange={setNom}
          onBlur={validateNom}
          error={nomError ? t(nomError) : null}
        />
      </div>

      <div className="mb-4">
        <TextField
          id="prenom"
          label={t('signupAvocat.prenomLabel')}
          value={prenom}
          onChange={setPrenom}
          onBlur={validatePrenom}
          error={prenomError ? t(prenomError) : null}
        />
      </div>

      {/* Téléphone : type='tel' ; facultatif — pas d'erreur si laissé vide. */}
      <div className="mb-4">
        <TextField
          id="telephone"
          type="tel"
          autoComplete="tel"
          label={t('signupAvocat.telephoneLabel')}
          value={telephone}
          onChange={setTelephone}
          onBlur={validateTelephone}
          error={telephoneError ? t(telephoneError) : null}
        />
      </div>

      <div className="mb-4">
        <WilayaSelect
          id="wilaya"
          value={wilayaId}
          onChange={(id) => {
            setWilayaId(id)
            // Efface l'erreur « requis » dès qu'une wilaya est choisie (feedback immédiat).
            if (id !== null) setWilayaError(null)
          }}
          error={wilayaError ? t(wilayaError) : null}
        />
      </div>

      <div className="mb-6">
        <TextField
          id="cabinetNom"
          label={t('signupAvocat.cabinetNomLabel')}
          value={cabinetNom}
          onChange={setCabinetNom}
          onBlur={validateCabinetNom}
          error={cabinetNomError ? t(cabinetNomError) : null}
        />
      </div>

      {/* Bloc erreur submit : message générique traduit issu d'une clé i18n connue (Rule 1). */}
      {submitStatus === 'error' && submitErrorKey && (
        <div className="bg-error-light rounded-btn p-4 mb-4">
          <p className="text-error text-sm text-start">{t(submitErrorKey)}</p>
        </div>
      )}

      {/* Bouton désactivé tant que le formulaire n'est pas valide OU pendant l'appel réseau ;
          spinner + libellé « patientez » informent que l'action est en cours. */}
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
        {isLoading ? t('submitting') : t('signupAvocat.submit')}
      </button>
    </form>
  )
}
