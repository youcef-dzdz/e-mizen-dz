import SignupForm from '@/components/auth/SignupForm'

// Page d'inscription — Server Component fin (Rule 7 : un seul composant page par
// fichier). POURQUOI minimal : la page ne fait que la mise en page ; toute la logique
// vit dans <SignupForm /> (composant client). Centrage vertical sur fond crème.
export default function SignupPage() {
  return (
    <main className="min-h-screen bg-creme flex items-center justify-center p-4">
      <SignupForm />
    </main>
  )
}
