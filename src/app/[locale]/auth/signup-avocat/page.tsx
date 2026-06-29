import { getTranslations } from 'next-intl/server'
import AuthLayout from '@/components/auth/AuthLayout'
import AvocatSignupForm from '@/components/auth/AvocatSignupForm'

// Titre d'onglet traduit par locale. POURQUOI params Promise + await : Next.js 14 passe
// params en async ; getTranslations résout le titre par locale.
export async function generateMetadata({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params
  const t = await getTranslations({ locale, namespace: 'auth' })
  return { title: t('signupAvocat.pageTitle') }
}

// Page d'inscription avocat — Server Component fin (Rule 7 : un seul composant page par
// fichier). POURQUOI minimal : la page ne fait qu'envelopper ; le cadre + centrage vivent
// dans <AuthLayout />, toute la logique dans <AvocatSignupForm /> (composant client).
export default function SignupAvocatPage() {
  return (
    <AuthLayout>
      <AvocatSignupForm />
    </AuthLayout>
  )
}
