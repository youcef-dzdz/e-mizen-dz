import { getTranslations } from 'next-intl/server'
import AuthLayout from '@/components/auth/AuthLayout'
import LoginForm from '@/components/auth/LoginForm'

// Titre d'onglet traduit par locale. POURQUOI params est une Promise + await :
// Next.js 14 (app router récent) passe params en async. getTranslations (version
// serveur de next-intl) résout le titre selon la locale de l'URL.
export async function generateMetadata({ params }: { params: Promise<{ locale: string }> }) {
  const { locale } = await params
  const t = await getTranslations({ locale, namespace: 'auth' })
  return { title: t('signin.pageTitle') }
}

// Page de connexion — Server Component fin (Rule 7 : un seul composant page par
// fichier). POURQUOI minimal : la page ne fait qu'envelopper ; le cadre + centrage
// vivent dans <AuthLayout />, toute la logique dans <LoginForm /> (composant client).
export default function LoginPage() {
  return (
    <AuthLayout>
      <LoginForm />
    </AuthLayout>
  )
}
