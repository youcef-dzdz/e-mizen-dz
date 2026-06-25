import LoginForm from '@/components/auth/LoginForm'

// Page de connexion — Server Component fin (Rule 7 : un seul composant page par
// fichier). POURQUOI minimal : la page ne fait que la mise en page ; toute la logique
// vit dans <LoginForm /> (composant client). Centrage vertical sur fond crème.
export default function LoginPage() {
  return (
    <main className="min-h-screen bg-creme flex items-center justify-center p-4">
      <LoginForm />
    </main>
  )
}
