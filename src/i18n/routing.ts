import {defineRouting} from 'next-intl/routing';
import {createNavigation} from 'next-intl/navigation';

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

// Helpers de navigation conscients de la locale (next-intl v4).
// POURQUOI: createNavigation génère Link/usePathname/useRouter qui gèrent
// automatiquement le préfixe /fr,/ar,/en — y compris avec query params,
// ce qui rend la recherche (Phase 2) robuste sans bricoler les URLs à la main.
export const {Link, redirect, usePathname, useRouter, getPathname} =
  createNavigation(routing);
