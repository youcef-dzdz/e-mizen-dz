// Layout racine volontairement minimal (Phase 0.3).
// POURQUOI thin: avec next-intl v4, c'est le layout [locale] qui possède
// <html lang>/<body> et dir RTL (le lang/dir dépend de la locale, inconnue ici).
// La racine ne fait que laisser passer les enfants — sinon on aurait deux <html>.
export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return children;
}
