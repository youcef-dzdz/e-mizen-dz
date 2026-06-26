import ForgotPasswordForm from '@/components/auth/ForgotPasswordForm'

// Page mot de passe oublié — Server Component fin (Rule 7).
// POURQUOI minimal : mise en page uniquement, logique dans <ForgotPasswordForm />.
export default function ForgotPasswordPage() {
  return (
    <main className="min-h-screen bg-creme flex items-center justify-center p-4">
      <ForgotPasswordForm />
    </main>
  )
}
