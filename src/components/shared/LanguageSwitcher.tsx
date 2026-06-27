'use client';

// POURQUOI client: la sélection de langue est interactive (navigation au clic).
import {useLocale} from 'next-intl';
import {Link, usePathname} from '@/i18n/routing';

// POURQUOI codes en dur: 'FR'/'AR'/'EN' sont des codes de langue (comme un nom
// de marque), pas du texte traduisible — exception légitime à la Rule 4.
const LOCALES = [
  {code: 'fr', label: 'FR'},
  {code: 'ar', label: 'AR'},
  {code: 'en', label: 'EN'}
] as const;

export default function LanguageSwitcher() {
  // POURQUOI usePathname de '@/i18n/routing' (pas next/navigation): renvoie le
  // chemin SANS préfixe de locale, donc on rebascule la langue en gardant la page.
  const pathname = usePathname();
  const active = useLocale();

  return (
    <nav className="flex items-center gap-2 text-sm" aria-label="Langue">
      {LOCALES.map(({code, label}, index) => (
        <span key={code} className="flex items-center gap-2">
          {/* Séparateur '·' entre les langues, jamais avant la première. */}
          {index > 0 && <span className="text-warm-tertiary">·</span>}
          <Link
            href={pathname}
            locale={code}
            aria-current={code === active ? 'true' : undefined}
            className={
              code === active
                ? 'text-espresso font-semibold underline decoration-or'
                : 'text-warm-secondary hover:text-espresso'
            }
          >
            {label}
          </Link>
        </span>
      ))}
    </nav>
  );
}
