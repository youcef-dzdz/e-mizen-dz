import { getTranslations } from 'next-intl/server'
import AuthLayout from '@/components/auth/AuthLayout'
import ForgotPasswordForm from '@/components/auth/ForgotPasswordForm'

// Titre d'onglet traduit par locale. POURQUOI params est une Promise + await :
// Next.js 14 passe params en async ; getTranslations résout le titre par locale.
export async function generateMetadata({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params
  const t = await getTranslations({ locale, namespace: 'auth' })
  return { title: t('forgot.pageTitle') }
}

// Page mot de passe oublié — Server Component fin (Rule 7).
// POURQUOI minimal : enveloppe uniquement ; cadre + centrage dans <AuthLayout />,
// logique dans <ForgotPasswordForm /> (composant client).
export default function ForgotPasswordPage() {
  return (
    <AuthLayout>
      <ForgotPasswordForm />
    </AuthLayout>
  )
}
