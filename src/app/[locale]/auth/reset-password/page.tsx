import { getTranslations } from 'next-intl/server'
import AuthLayout from '@/components/auth/AuthLayout'
import ResetPasswordForm from '@/components/auth/ResetPasswordForm'

// Titre d'onglet traduit par locale. POURQUOI params est une Promise + await :
// Next.js 14 passe params en async ; getTranslations résout le titre par locale.
export async function generateMetadata({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params
  const t = await getTranslations({ locale, namespace: 'auth' })
  return { title: t('reset.pageTitle') }
}

// Page de réinitialisation du mot de passe — Server Component fin (Rule 7).
// POURQUOI minimal : enveloppe uniquement ; cadre + centrage dans <AuthLayout />,
// logique dans <ResetPasswordForm /> (composant client).
export default function ResetPasswordPage() {
  return (
    <AuthLayout>
      <ResetPasswordForm />
    </AuthLayout>
  )
}
