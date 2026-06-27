import { getTranslations } from 'next-intl/server'
import AuthLayout from '@/components/auth/AuthLayout'
import SignupForm from '@/components/auth/SignupForm'

// Titre d'onglet traduit par locale. POURQUOI params est une Promise + await :
// Next.js 14 passe params en async ; getTranslations résout le titre par locale.
export async function generateMetadata({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params
  const t = await getTranslations({ locale, namespace: 'auth' })
  return { title: t('signup.pageTitle') }
}

// Page d'inscription — Server Component fin (Rule 7 : un seul composant page par
// fichier). POURQUOI minimal : la page ne fait qu'envelopper ; le cadre + centrage
// vivent dans <AuthLayout />, toute la logique dans <SignupForm /> (composant client).
export default function SignupPage() {
  return (
    <AuthLayout>
      <SignupForm />
    </AuthLayout>
  )
}
