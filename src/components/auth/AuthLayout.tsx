import Image from 'next/image'
import { getTranslations } from 'next-intl/server'

// Cadre partagé des 4 pages auth (login / signup / forgot / reset) — DRY.
// POURQUOI Server Component async (pas de 'use client') : purement présentationnel ;
// getTranslations lit la tagline côté serveur sans transformer le composant en client.
// Le <main> + centrage vivent ici, les pages ne font que l'envelopper.
export default async function AuthLayout({ children }: { children: React.ReactNode }) {
  const t = await getTranslations('common')

  return (
    <main className="min-h-screen bg-creme flex flex-col items-center justify-center p-4">
      {/* Bloc vertical centré : logo → wordmark → tagline → formulaire. */}
      <div className="flex flex-col items-center">
        {/*
          width/height = dimensions réelles du fichier (518×713) : next/image
          les exige pour réserver l'espace et éviter le layout shift (saut de
          mise en page au chargement). h-16 (64px) + w-auto : affichage contraint,
          ratio préservé. priority : logo au-dessus de la ligne de flottaison.
        */}
        <Image
          src="/images/logo/e-mizen-dz.png"
          alt="E-Mizen DZ"
          width={518}
          height={713}
          priority
          className="h-16 w-auto mb-2"
        />
        {/* Wordmark : nom de marque fixe, jamais traduit. "DZ" en or (token premium). */}
        <p className="text-espresso text-xl font-medium mb-1">
          E-Mizen <span className="text-or">DZ</span>
        </p>
        {/* Tagline : identité de marque traduite (common.tagline), gris chaud secondaire. */}
        <p className="text-warm-secondary text-sm text-center mb-5">{t('tagline')}</p>
        {children}
      </div>
    </main>
  )
}
