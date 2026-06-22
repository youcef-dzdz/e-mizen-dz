import type { Metadata } from "next";
import "./globals.css";

// Layout racine minimal (Phase 0.1). La gestion i18n/[locale] + RTL arabe
// arrive plus tard en Phase 0 — ici on pose seulement la coquille HTML.
export const metadata: Metadata = {
  title: "E-Mizen DZ",
  description: "Plateforme LegalTech algérienne — marketplace avocats, ERP cabinet, assistant IA.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  // lang="fr" par défaut — le switch FR/AR/EN + dir RTL sera géré en Phase 0 i18n.
  return (
    <html lang="fr">
      <body>{children}</body>
    </html>
  );
}
