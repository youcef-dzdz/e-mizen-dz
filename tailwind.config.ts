import type { Config } from "tailwindcss";

// Source de vérité visuelle: uidesign.md §3 (palette) + §11 (mapping).
// Règle 8: aucune couleur/spacing/shadow hardcodé ailleurs — uniquement ces tokens.
const config: Config = {
  content: [
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        // Palette de marque (uidesign.md §3) — noms conservés tels quels.
        espresso: "#3B1E03", // boutons, liens, accents principaux
        or: "#C4902A", // "DZ", citations de loi, éléments premium
        creme: "#FAF9F7", // fond de page par défaut
        beige: "#F2EDE6", // fond sidebar
        blanc: "#FFFFFF", // cards, modals, inputs
        ink: "#1A1A1A", // texte principal — jamais #000 pur (uidesign §13.2)

        // Surfaces spéciales chat + disclaimer (uidesign.md §3)
        "bubble-user": "#EDE8DF", // bulle utilisateur
        "bubble-ai": "#FFFFFF", // bulle IA
        disclaimer: "#FFFBEB", // fond disclaimer juridique

        // Gris chauds uniquement — jamais de gris froids (uidesign §13.3)
        warm: {
          secondary: "#6B6660", // texte secondaire
          tertiary: "#9A9490", // texte tertiaire
          disabled: "#C9C3BB", // texte/élément désactivé
          border: "#E8E3DC", // bordures
          sand: "#D9C9B8", // illustrations empty state / bordure loading
        },

        // Couleurs sémantiques (uidesign §3) — DEFAULT = accent, light = fond clair
        success: {
          DEFAULT: "#2A7A4B",
          light: "#D1FAF0",
          dark: "#047857", // texte badge "Vérifié" (uidesign A7)
          bg: "#F0FDF4", // fond input succès (uidesign A2)
        },
        warning: {
          DEFAULT: "#B45309",
          light: "#FEF3E2",
        },
        error: {
          DEFAULT: "#B91C1C",
          light: "#FEE2E2",
        },
        info: {
          DEFAULT: "#3B1E03", // tons espresso (uidesign §3)
          light: "#F0E8DF",
        },
      },
      fontFamily: {
        // Latin FR/EN. Fichiers de police chargés en Phase 0 (layout/i18n).
        sans: ["Inter", "system-ui", "sans-serif"],
        // Arabe AR — appliqué via dir="rtl" + font-arabic (uidesign §4)
        arabic: ["Noto Sans Arabic", "sans-serif"],
      },
      borderRadius: {
        // uidesign.md §6
        badge: "6px",
        btn: "8px",
        card: "10px",
        modal: "14px",
      },
      boxShadow: {
        // uidesign.md §7 — ombres chaudes, jamais d'ombre noire dure
        card: "0 1px 2px rgba(59, 30, 3, 0.04)",
        "card-hover": "0 4px 12px rgba(59, 30, 3, 0.08)",
        modal: "0 12px 32px rgba(26, 26, 26, 0.18)",
        focus: "0 0 0 3px rgba(59, 30, 3, 0.20)",
      },
    },
  },
  plugins: [],
};

export default config;
