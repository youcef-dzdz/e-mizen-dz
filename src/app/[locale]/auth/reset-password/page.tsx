import ResetPasswordForm from '@/components/auth/ResetPasswordForm'

// Page de réinitialisation du mot de passe — Server Component fin (Rule 7).
// POURQUOI minimal : mise en page uniquement, logique dans <ResetPasswordForm />.
export default function ResetPasswordPage() {
  return (
    <main className="min-h-screen bg-creme flex items-center justify-center p-4">
      <ResetPasswordForm />
    </main>
  )
}
