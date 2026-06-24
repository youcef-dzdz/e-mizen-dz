import createNextIntlPlugin from 'next-intl/plugin';

// Pointe le plugin vers la config par requête (chargement des messages par locale).
const withNextIntl = createNextIntlPlugin('./src/i18n/request.ts');

/** @type {import('next').NextConfig} */
// Next.js 14 ne lit que .js/.mjs — config TypeScript réservée à Next 15+.
const nextConfig = {
  // Strict mode React: détecte les effets non idempotents tôt (qualité démo jury).
  reactStrictMode: true,
};

// POURQUOI envelopper: le plugin next-intl v4 injecte l'alias du fichier request.ts
// dans le build serveur — sans ce wrapper, getRequestConfig n'est jamais branché et
// les messages traduits ne sont pas résolus à l'exécution.
export default withNextIntl(nextConfig);
