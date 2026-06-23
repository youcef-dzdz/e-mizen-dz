# STATUS.md — État du Projet E-Mizen DZ

> Mis à jour à chaque fin de session. Lu en premier à chaque session (Étape 1).
> Ne jamais résumer ou tronquer — toujours ajouter, jamais écraser.

---

## Dernière Session
Date: 2026-06-23 (Session 002)
Ce qui a été fait: Phase 0.2 (partie 1) — migrations fondation STRUCTURE SEULE en ordre de dépendance FK : 001 wilaya, 002 specialites, 003 users (ENUMs user_role/user_locale, trigger updated_at, FK wilaya_id, soft delete). RLS activée + policies sur les 3 tables. Tests négatifs RLS écrits (tests/rls/*.test.sql). AUCUN seed, migrations PAS encore exécutées (revue d'abord).
Prochaine tâche: revue fondateur du SQL → puis tâche de seed SÉPARÉE (69 wilayas + spécialités) → puis exécution des migrations sur Supabase → Phase 0.3 auth.
Résumé point (reprise): renumérotation dépendance-FK appliquée (wilaya/specialites avant users). Pas de test runner JS → tests RLS en .test.sql (set role anon/authenticated + ROLLBACK, zéro seed persisté). specialites.slug UNIQUE = index, pas de doublon. users : pas de policy INSERT/DELETE client (signup via service_role ; soft delete only).

---

## Phase Courante
**Phase 0 — Foundation & Setup** · Statut: 🔵 En cours · Progression: ~25% (0.1 scaffolding + 0.2 structure migrations fondation)
Prochaine tâche immédiate: revue SQL → tâche de seed SÉPARÉE (69 wilayas + spécialités) → exécuter 001/002/003 sur Supabase (+ activer pgvector) → Phase 0.3 auth
Numérotation migrations (ordre dépendance FK, verrouillé): 001 wilaya · 002 specialites · 003 users. (Ancien "001 users / 002 wilaya / 025 specialites" corrigé Session 002 — users.wilaya_id réfère wilaya.)
> Wilaya count corrigé 58→69 le 2026-06-23 (loi n° 26-06 du 04/04/2026 — 11 nouvelles wilayas n°59-69, ex-wilayas déléguées). Période transitoire jusqu'au 31/12/2026.

---

## État des Phases
| Phase | Nom | Statut |
|---|---|---|
| 0 | Foundation & Setup | 🔵 En cours (0.1 fait · 0.2 structure migrations fondation) |
| 1 | Avocat Profile & Cabinet | ⏳ À commencer |
| 2 | Marketplace Public | ⏳ À commencer |
| 3 | ERP Cabinet | ⏳ À commencer |
| 4 | Portail Client | ⏳ À commencer |
| 5 | Admin Panel | ⏳ À commencer |
| 6 | Assistant IA | ⏳ À commencer |
| 7 | Intégration + QA + Demo | ⏳ À commencer |

---

## Checklist Environnement
À vérifier en début de session si environnement non confirmé:
- [ ] Supabase project accessible — [URL dashboard à remplir]
- [ ] Vercel deployment actif — [URL à remplir]
- [ ] Variables .env.local présentes et complètes
- [x] `npm run dev` démarre sans erreur (HTTP 200, landing rendu — Session 001)
- [ ] /api/health retourne 200 (route pas encore créée)
- [ ] Supabase Auth fonctionne (test login)
- [ ] pgvector activée (Phase 6+ uniquement)

Statut actuel: 🔵 Scaffolding OK (build 0 erreur, dev 200) — Supabase pas encore créé (Phase 0.2)

---

## Décisions Verrouillées
**Stack:** Next.js 14 + TS + Tailwind · **Supabase Auth (PAS Clerk — définitif)** · Supabase (PostgreSQL + RLS + Storage + pgvector) · Groq llama-3.3-70b-versatile · @xenova/transformers (multilingual-e5-base, 768 dim) · Resend · Vercel · next-intl (FR+AR+EN, pas de dz.json).
**Architecture:** pas de backend séparé (API routes Next.js) · services/ = Supabase uniquement · lib/ = clients externes · RTL Arabic via useRTL + RTLProvider.
**Modèle utilisateur:** Visiteur / Citoyen (role immuable) / Client (état métier, jamais un rôle) / Avocat / Admin (+ admin_roles).
**Auth methods:** Email+Password, Google OAuth, Magic Link · Avocat = email uniquement.
**Tables:** 27 — voir docs/PHASES.md pour l'ordre de migration.
**Compétiteur:** avocatalgerien.com (annuaire WordPress, pas de vérification/ERP/IA) — avantage intact.
**RBAC cabinet — in-scope Phase 3 (2026-06-23):** le RBAC multi-collaborateurs (rôles secrétaire + collaborateur, membership par cabinet, permissions par rôle) est désormais une feature approuvée, requise par l'encadreur. Build + démo live attendus en Phase 3. N'est plus une feature hors scope.

---

## Fichiers MD — Statut
| Fichier | Emplacement | Statut |
|---|---|---|
| CLAUDE.md | racine | ✅ Complet |
| FIX.md | racine | ✅ Complet |
| uidesign.md | racine | ✅ Complet |
| README.md | racine | ✅ Complet |
| .env.example / .gitignore | racine | ✅ Complet |
| docs/PHASES.md | docs/ | ✅ Complet |
| docs/STATUS.md | docs/ | ✅ Complet |
| docs/SECURITY.md | docs/ | ✅ Complet |
| docs/RAG.md | docs/ | ✅ Complet |
| docs/CODEMAP.md | docs/ | ✅ Template vide |
| docs/REPORT.md | docs/ | ✅ Template |
| docs/PAGINATION.md | docs/ | ✅ Complet |
| .claude/settings.json + commands + rules | .claude/ | ✅ Complet |

---

## Bugs Connus
Aucun — projet non commencé.

---

## À Faire Avant Phase 6 (Assistant IA)
- [ ] Trouver PDFs **Arabic** des 5 codes (Code Civil, Pénal, Procédure Civile, Procédure Pénale, Code de la Famille). Source: avocatalgerien.com § Codes & Lois
- [ ] Code de la Famille: FR disponible ✅ — AR manquant
- [ ] Schema legal_chunks: deux lignes par article (FR + AR), colonne langue + un seul embedding
- [ ] Articles abrogés → actif=false dès l'ingestion · Articles "bis" → chunks séparés
- [ ] Vérifier zéro corruption d'ordre des mots après ingestion

---

## Dette Technique Connue (à traiter dans la phase indiquée)
- **[Phase 0.3 — Auth] src/lib/supabase/server.ts** : actuellement basé sur @supabase/supabase-js (suffisant pour le scaffolding, pas pour les sessions). À réécrire avec @supabase/ssr (gestion cookies) AU MOMENT de construire le flux auth — pas avant, car non testable sans login. Le prompt Phase 0.3 doit installer @supabase/ssr et remplacer ce client.
- **[Phase 0.2 / Phase 1 — users & cabinets] RBAC-ready :** le design des tables users / cabinets doit rester compatible RBAC dès maintenant (cabinet_id déjà présent par entité — Rule 16). Le système RBAC de Phase 3 (membership multi-collaborateurs + rôles secrétaire/collaborateur) doit pouvoir s'ajouter de façon **additive** (nouvelles tables membership/permissions), sans réécrire la fondation users/cabinets. Ne pas verrouiller un schéma users mono-utilisateur qui forcerait une migration de fondation plus tard.

---

## Future Building — Backlog
| # | Feature | Effort | Dépendances | Priorité |
|---|---|---|---|---|
| 1 | Graphify MCP | Faible | Phase 2+ | Moyenne |
| 2 | Impersonation admin | Moyen | Phase 5 | Faible |
| 3 | Notifications WebSockets | Élevé | Phase 4 | Haute |
| 4 | Facturation Stripe | Très élevé | RBAC cabinet (Phase 3) | Moyenne |
| 5 | OCR documents | Moyen | Phase 3 | Moyenne |
| 6 | Notaires / Huissiers | Très élevé | Phase 2 | Haute |
| 7 | Application mobile | Très élevé | MVP complet | Haute |
| 8 | Migration FastAPI + LangGraph | Très élevé | MVP complet | Faible |

> Cabinet Pro / RBAC multi-collaborateurs retiré du backlog le 2026-06-23 — désormais in-scope Phase 3 (requis encadreur). Voir § Décisions Verrouillées.

---

## Renommage et Historique
Nom produit: E-Mizen DZ (définitif). Ancien projet de référence: LegalBot DZ — **base de code différente, zéro héritage**. Repository: https://github.com/youcef-dzdz/e-mizen-dz (créé Session 001). Vercel / Supabase: à créer.

---

## Notes Fondateur
[Section libre — le fondateur écrit ici, l'agent lit mais ne modifie jamais.]

---

## Journal des Sessions
> 5 lignes max par session. Scannable en 30 secondes.

### Session 000 — Initialisation
Date: [première session] · Phase: pré-code (design & architecture)
Fait: conception complète CLAUDE.md + tous les docs · stack verrouillée · 27 tables · 8 phases
Décisions: Supabase Auth au lieu de Clerk · Admin avant IA · RTL Arabic · Darija = chat IA uniquement
Build: N/A — aucun code · Prochaine session: Phase 0.1 Project Setup

### Session 001 — Phase 0.1 Project Setup
Date: 2026-06-22 · Phase: 0 (Foundation) · Tâche: scaffolding + git init
Fait: Next.js 14.2.35 + TS + Tailwind (tokens uidesign.md), structure §7 (.gitkeep), src/lib/supabase/{client,server}.ts, src/lib/logger.ts, layout + landing placeholder
Décisions: scaffolding manuel (pas create-next-app, dossier non-vide) · next.config.mjs au lieu de .ts (Next 14 ne lit pas .ts) — approuvé fondateur
Build: ✅ 0 erreur · dev: ✅ HTTP 200 · git: ✅ commit poussé origin/main · .env.local: ✅ jamais traqué
Prochaine session: Phase 0.2 — Supabase + pgvector + migrations 001/002/025

### Session 002 — Phase 0.2 Migrations Fondation (structure)
Date: 2026-06-23 · Phase: 0 (Foundation) · Tâche: migrations 001 wilaya / 002 specialites / 003 users — STRUCTURE seule
Fait: 3 migrations (ENUMs user_role/user_locale, FK wilaya_id, trigger updated_at, soft delete users) · RLS + policies (SELECT public wilaya/specialites ; SELECT/UPDATE own users, pas de DELETE) · 6 fichiers + 3 tests négatifs tests/rls/*.test.sql
Décisions: renumérotation ordre dépendance FK (wilaya/specialites avant users) · tests en .test.sql (pas de runner JS, package.json hors scope) · slug UNIQUE = index · users sans INSERT/DELETE client
Build: N/A (SQL only, pas de build Next) · Migrations: ⏳ PAS exécutées (revue d'abord) · Seed: ⏳ tâche séparée (aucun seed dans cette tâche)
Prochaine session: revue SQL → seed (69 wilayas + spécialités) → exécution migrations → Phase 0.3 auth

[Sessions suivantes ajoutées ici par l'agent]
