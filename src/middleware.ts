import { type NextRequest } from 'next/server'
import { createServerClient } from '@supabase/ssr'
import createIntlMiddleware from 'next-intl/middleware'
import { routing } from '@/i18n/routing'

// next-intl gère le routing de locale (redirection / rewrite fr/ar/en).
const intlMiddleware = createIntlMiddleware(routing)

export async function middleware(request: NextRequest) {
  // 1. next-intl d'abord : produit la réponse (avec redirect/rewrite de locale + ses cookies).
  const response = intlMiddleware(request)

  // 2. Client Supabase qui LIT les cookies de la requête et ÉCRIT sur la réponse next-intl.
  //    On utilise la clé anon (jamais service_role en middleware — Rule 11).
  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          // Sur la requête : pour que les Server Components de CE cycle voient le token rafraîchi.
          cookiesToSet.forEach(({ name, value }) =>
            request.cookies.set(name, value)
          )
          // Sur la réponse : pour que le navigateur reçoive le nouveau cookie (requête suivante).
          cookiesToSet.forEach(({ name, value, options }) =>
            response.cookies.set(name, value, options)
          )
        },
      },
    }
  )

  // 3. getUser() (pas getSession) : revalide le token côté serveur Supabase et déclenche
  //    le refresh si expiré → setAll réécrit les cookies. C'est ce qui maintient la session vivante.
  await supabase.auth.getUser()

  // 4. Retourner la réponse next-intl, qui porte maintenant les cookies d'auth rafraîchis.
  return response
}

export const config = {
  // Exclut api, les assets Next, et tout chemin avec extension de fichier.
  matcher: ['/((?!api|_next|_vercel|.*\\..*).*)'],
}
