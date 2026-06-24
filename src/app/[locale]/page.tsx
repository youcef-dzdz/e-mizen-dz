// Page d'accueil placeholder (Phase 0.1) — vérifie que le scaffolding + les
// tokens Tailwind rendent correctement. Le vrai landing arrive en Phase 0.
// Aucune couleur hardcodée: uniquement des tokens uidesign.md (Règle 8).
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 p-6">
      <h1 className="text-4xl font-bold text-espresso">
        E-Mizen <span className="text-or">DZ</span>
      </h1>
      <p className="text-warm-secondary">
        Plateforme LegalTech algérienne — scaffolding Phase 0.1 opérationnel.
      </p>
      <span className="rounded-badge bg-success-light px-3 py-1 text-sm text-success-dark">
        Build OK
      </span>
    </main>
  );
}
