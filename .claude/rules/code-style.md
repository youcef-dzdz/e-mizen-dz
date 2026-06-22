# code-style.md — Code Style & Structure Rules

These rules load on every coding turn. They are enforced at npm run build
and at code review. Violations block "done".

## R3 — Component size ceiling
- No component file exceeds 300 lines (lines = code only; imports + comments
  + blank lines excluded from the count).
- On exceed: extract sub-components into the same feature folder, never just
  trim comments to pass. A 400-line component is a missing abstraction.
- WHY: large components hide state and make blast-radius (FIX.md) unreadable.

## R4 — Translations before UI
- Before writing ANY UI component, the keys it uses must exist in all three:
  messages/fr.json, messages/ar.json, messages/en.json.
- Key naming: namespace.section.element (e.g. marketplace.search.placeholder).
- A key declared in one file but absent in another = build-blocking.
- A key declared but never referenced in code = dead key, remove it.
- WHY: a missing AR key ships a broken RTL screen straight to the jury demo.

## R5 — Definition of done
- npm run build returning 0 errors is the ONLY definition of done.
- Not "it renders", not "looks fine locally" — 0 build errors, every time.
- type-check + lint warnings are addressed before the task is closed.
- WHY: a green build is the single shared truth across founder, Vercel, jury.

## R6 — Check before create
- Before creating any component/service/hook, grep it + read docs/CODEMAP.md.
- If it exists: extend it. If similar exists: ask before forking.
- WHY: duplicate components drift apart and double the bug surface.

## R7 — One page component per file
- One default-exported page component per file. No two page components sharing
  a file. Shared pieces live in components/, imported in.
- WHY: keeps routing predictable and the file tree = the URL tree.

## R8 — Design tokens only (no hardcoded values)
- Colors, spacing, fonts come from uidesign.md tokens / Tailwind config only.
- FORBIDDEN: raw hex (#3B1E03), arbitrary Tailwind values (bg-[#...], p-[13px]),
  inline style colors.
- ALLOWED: token classes (bg-espresso, text-or, p-4 from the scale).
- Token source of truth: tailwind.config.ts (espresso/creme/or/beige) +
  uidesign.md.
- WHY: one hardcoded color breaks theming later and the brand audit now.

## R22 — Comments
- Comments in French only.
- Comment the WHY (intent, edge case, business rule), never the WHAT (the code
  already says what).
- Mandatory in: RLS policies, service functions (src/services/**), .env.example.
- WHY: future-you and the jury read intent, not restated syntax.
