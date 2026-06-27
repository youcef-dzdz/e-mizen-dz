import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { NextIntlClientProvider } from "next-intl";
import { getMessages, setRequestLocale } from "next-intl/server";
import { routing } from "../../i18n/routing";
import LanguageSwitcher from "@/components/shared/LanguageSwitcher";
import "../globals.css";

// Métadonnées du produit. POURQUOI ici: le layout [locale] possède désormais
// la coquille <html>/<body>, donc c'est lui qui porte les métadonnées de page.
export const metadata: Metadata = {
  title: "E-Mizen DZ",
  description: "Plateforme LegalTech algérienne — marketplace avocats, ERP cabinet, assistant IA.",
};

// POURQUOI: pré-rend statiquement chaque locale (/fr, /ar, /en) au build,
// au lieu d'attendre une requête — performances et URLs indexables.
export function generateStaticParams() {
  return routing.locales.map((locale) => ({ locale }));
}

export default async function LocaleLayout({
  children,
  params,
}: Readonly<{
  children: React.ReactNode;
  params: { locale: string };
}>) {
  const { locale } = params;

  // POURQUOI: une locale absente de la liste blanche (ex: /es) ne doit jamais
  // rendre une page à moitié traduite — on renvoie un 404 propre.
  if (!routing.locales.includes(locale as (typeof routing.locales)[number])) {
    notFound();
  }

  // POURQUOI: requis par next-intl v4 pour activer le rendu statique — sans cet
  // appel, getMessages() bascule en rendu dynamique et casse generateStaticParams.
  setRequestLocale(locale);

  // Messages chargés côté serveur puis injectés au provider client.
  const messages = await getMessages();

  // POURQUOI dir=rtl seulement pour l'arabe: seul l'AR s'écrit de droite à gauche;
  // FR et EN restent en ltr. Le lang dynamique sert l'accessibilité et le SEO.
  return (
    <html lang={locale} dir={locale === "ar" ? "rtl" : "ltr"}>
      <body>
        <NextIntlClientProvider messages={messages}>
          {/* Switcher global en haut de page. POURQUOI ici (layout [locale]) et
              pas dans AuthLayout: élément transverse — codé une fois, présent sur
              tous les modules (DRY). justify-end + classes logiques (pas de right
              en dur) pour qu'en arabe (dir=rtl) il se reflète automatiquement. */}
          <div className="flex justify-end p-4">
            <LanguageSwitcher />
          </div>
          {children}
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
