import {getRequestConfig} from 'next-intl/server';
import {routing} from './routing';

// Configuration par requête consommée par le plugin next-intl côté serveur.
// POURQUOI: charge les bons messages selon la locale demandée, à chaque requête.
export default getRequestConfig(async ({requestLocale}) => {
  // requestLocale provient du segment [locale] de l'URL (résolu de façon asynchrone).
  let locale = await requestLocale;

  // POURQUOI le fallback: une locale absente ou non supportée (URL forgée, lien
  // obsolète) ne doit jamais casser le rendu — on retombe sur la langue par défaut.
  if (!locale || !routing.locales.includes(locale as (typeof routing.locales)[number])) {
    locale = routing.defaultLocale;
  }

  return {
    locale,
    // POURQUOI import dynamique par chemin: seul le fichier de la locale active est
    // chargé. Les messages vivent à la racine du projet (../../messages/).
    messages: (await import(`../../messages/${locale}.json`)).default
  };
});
