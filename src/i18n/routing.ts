import {defineRouting} from 'next-intl/routing';

// Configuration centrale du routage i18n.
// POURQUOI: source de vérité unique des locales — réutilisée par request.ts,
// le middleware et les helpers de navigation, pour éviter toute divergence.
export const routing = defineRouting({
  // FR/AR/EN: les trois langues UI du produit (la darija reste cantonnée au chat IA).
  locales: ['fr', 'ar', 'en'],

  // POURQUOI 'fr': langue par défaut du marché algérien ciblé et du fallback métier.
  defaultLocale: 'fr',

  // POURQUOI 'always': préfixe de locale toujours présent dans l'URL (/fr, /ar, /en),
  // pour des URLs explicites, partageables et indexables sans ambiguïté de langue.
  localePrefix: 'always'
});
