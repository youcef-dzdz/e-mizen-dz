# STATUS.md — État du Projet E-Mizen DZ

> Mis à jour à chaque fin de session. Lu en premier à chaque session (Étape 1).
> Ne jamais résumer ou tronquer — toujours ajouter, jamais écraser.

---

## Dernière Session
Date: 2026-06-24 (Session 007 suite)
Ce qui a été fait: Formulaire signup CÂBLÉ sur signUp() et vérifié de bout en bout. Flux complet testé en réel : page signup → signUp() → auth.users → trigger 004 → public.users (role=citoyen) → email de confirmation reçu → compte confirmé. UX : panneau succès clair, bloc erreur traduit, trigger gère le profil (create-profile PAS appelé).
Prochaine tâche: masquer la réception du retour de confirmation — construire la route /auth/callback (le lien de confirmation revient actuellement sur /fr#access_token sans handler dédié)
Résumé point (reprise): signup loop 100% fonctionnel et vérifié. Compte test confirmé en base (youcef.mokhtari). Reste pour finir Phase 0.3 : route callback (confirmation/OAuth) + page login.

---

## Phase Courante
**Phase 0 — Foundation & Setup** · Statut: 🔵 En cours · Progression: ~95% (0.1 scaffolding + 0.2 ✅ complète + 0.3 Auth Foundation ~95% — signup loop câblé & vérifié de bout en bout ; reste route /auth/callback puis page login)
**Phase 0.2 ✅ complète:** migrations 001–003 + wilaya seed exécutés sur Supabase le 2026-06-24, vérifiés (wilaya=69, 59–69=11).
**Phase 0.3 — Auth Foundation 🔵 en cours (Session 007):** pgvector activé (vector 0.8.0) · @supabase/ssr + next-intl v4 installés · src/lib/supabase/server-session.ts ajouté (client SSR cookie/session, anon, respecte RLS — server.ts service_role INCHANGÉ) · squelette i18n complet (routing.ts + request.ts + plugin next.config.mjs + stubs fr/ar/en common + restructure app/[locale] avec dir RTL + NextIntlClientProvider) · middleware fusionné src/middleware.ts (next-intl v4 + refresh session Supabase, un seul fichier, ordre correct) · **migration 004_handle_new_user.sql (trigger AFTER INSERT auth.users → profil public.users auto-créé, role=citoyen forcé) exécutée + testée · formulaire signup UI + validation client (tokens uidesign, FR/AR RTL vérifiés)**. Prochaine immédiate: câbler SignupForm sur auth.ts signUp() (le trigger gère le profil — PAS d'appel à create-profile). **Mise à jour (Session 007 suite): SignupForm câblé sur signUp() et flux signup vérifié de bout en bout en réel (page → auth.users → trigger 004 → public.users role=citoyen → email confirmé). Prochaine immédiate: route /auth/callback (handler confirmation/OAuth) puis page login.**
Numérotation migrations (ordre dépendance FK, verrouillé): 001 wilaya · 002 specialites · 003 users. (Ancien "001 users / 002 wilaya / 025 specialites" corrigé Session 002 — users.wilaya_id réfère wilaya.)
> Wilaya count corrigé 58→69 le 2026-06-23 (loi n° 26-06 du 04/04/2026 — 11 nouvelles wilayas n°59-69, ex-wilayas déléguées). Période transitoire jusqu'au 31/12/2026.

---

## État des Phases
| Phase | Nom | Statut |
|---|---|---|
| 0 | Foundation & Setup | 🔵 En cours (0.1 fait · 0.2 ✅ migrations 001–003 + seed wilayas exécutés/vérifiés 2026-06-24) |
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
- [x] Supabase project accessible — ref `rwasjhplhbobrwqerzks` (migrations 001–003 + seed exécutés 2026-06-24)
- [ ] Vercel deployment actif — [URL à remplir]
- [ ] Variables .env.local présentes et complètes
- [x] `npm run dev` démarre sans erreur (HTTP 200, landing rendu — Session 001)
- [ ] /api/health retourne 200 (route pas encore créée)
- [ ] Supabase Auth fonctionne (test login)
- [ ] pgvector activée (Phase 6+ uniquement)

Statut actuel: 🔵 Scaffolding OK (build 0 erreur, dev 200) — Supabase project créé (ref `rwasjhplhbobrwqerzks`), migrations 001–003 + seed exécutés 2026-06-24

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
- [ ] **[AVANT Phase 1] Seed specialites** — table créée (002) mais 0 lignes. Avocat_specialites (Phase 1) en dépend. Liste des spécialités juridiques à définir.
- [ ] **[AVANT Phase 2 — Haversine] Vérifier coordonnées chef-lieu wilayas 49–69** (21 lignes ⚠️ VERIF dans seed.sql) contre Google Maps. Seedées non vérifiées le 2026-06-24.
- ✅ **[Phase 0.3 — Auth] Client de session SSR — RÉSOLU (Session 005, formulation antérieure imprécise).** L'ancienne dette disait « réécrire server.ts avec @supabase/ssr » — c'était imprécis. server.ts (clé service_role, bypass RLS) reste INCHANGÉ par design : il n'a jamais eu vocation à porter les sessions. La gestion de session a été ajoutée dans un fichier NOUVEAU `src/lib/supabase/server-session.ts` (@supabase/ssr, clé anon, lecture/écriture cookies, respecte RLS). Les deux clients coexistent : server.ts = privilégié serveur, server-session.ts = session utilisateur.
- [ ] **[Phase 0.3 — i18n] Fichiers de messages = stubs (namespace `common` uniquement).** messages/fr.json, ar.json, en.json ne contiennent que le namespace `common` (Session 005). Les traductions complètes sont à fournir par composant UI au fur et à mesure des phases ; Rule 4 impose le trio fr/ar/en en lockstep (clé manquante dans un fichier = build bloquant, clé déclarée jamais référencée = à supprimer).
- **[Phase 0.2 / Phase 1 — users & cabinets] RBAC-ready :** le design des tables users / cabinets doit rester compatible RBAC dès maintenant (cabinet_id déjà présent par entité — Rule 16). Le système RBAC de Phase 3 (membership multi-collaborateurs + rôles secrétaire/collaborateur) doit pouvoir s'ajouter de façon **additive** (nouvelles tables membership/permissions), sans réécrire la fondation users/cabinets. Ne pas verrouiller un schéma users mono-utilisateur qui forcerait une migration de fondation plus tard.
- **[Phase 0.3 — Auth] Création du profil users = service_role serveur uniquement.** La table users n'a AUCUNE policy INSERT côté client (volontaire — empêche un signup malveillant de choisir role='admin'). Donc le flux signup DOIT créer la ligne public.users via une route serveur (service_role), jamais côté client, et DOIT forcer role='citoyen' pour les inscriptions publiques. Si oublié en Phase 0.3 → le signup échoue silencieusement.
- [ ] **[AVANT fin Phase 1] Route create-profile — devenir fallback :** le trigger 004 est désormais l'ACTEUR PRINCIPAL de création de profil (atomique). La route /api/auth/create-profile fait maintenant double emploi (insert dupliqué → erreur PK si appelée). DÉCISION : la garder comme filet de sécurité défensif (defense-in-depth entreprise) mais la convertir en upsert idempotent « ne rien écraser sur conflit » AVANT fin Phase 1 — OU la supprimer. Tant que non convertie : le formulaire ne l'appelle PAS (le trigger suffit). Code orphelin temporaire.
- [ ] **[Phase error-hardening] Route create-profile — code erreur :** retourne 500 générique sur toute erreur d'insert ; « ligne déjà existante » devrait être un 409. À affiner dans la passe error-hardening.
- [ ] **[Quand logger.ts existe] Route create-profile — logging :** échec d'insert non journalisé (TODO logger.ts dans le code). À brancher quand logger.ts existe.
- [ ] **[Phase 0.3 / Phase 1 — Auth] Signup — orphelins :** un auth.users peut exister sans ligne public.users si le client ferme l'onglet entre auth.signUp() et l'appel à create-profile. À détecter au premier login + réparer. Faible criticité MVP.
- [ ] **[Phase 0.3 — Auth] Détection "email déjà utilisé" non vérifiée :** SignupForm mappe error.status===422 / regex vers errors.emailTaken, MAIS Supabase masque par défaut les emails déjà inscrits (fake success, anti-énumération T08) — ce code peut ne jamais se déclencher. À tester explicitement et ajuster si besoin.
- [ ] **[Phase 0.3 — Auth] Pas de libellé "chargement" signup :** bouton réutilise le label submit pendant isLoading (désactivé). Ajouter clé i18n auth.signup.submitting (3 locales) pour un retour visuel clair pendant l'appel réseau.

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
Nom produit: E-Mizen DZ (définitif). Ancien projet de référence: LegalBot DZ — **base de code différente, zéro héritage**. Repository: https://github.com/youcef-dzdz/e-mizen-dz (créé Session 001). Supabase: créé (ref `rwasjhplhbobrwqerzks`, migrations + seed exécutés 2026-06-24). Vercel: à créer.

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

### Session 003 — Phase 0.2 Seed Wilayas
Date: 2026-06-23 · Phase: 0 (Foundation) · Tâche: supabase/seed.sql — 69 wilayas (DATA ONLY)
Fait: seed.sql avec 69 INSERT (id, code, nom_fr, nom_ar, lat, long ; actif/created_at = défauts). 1-58 officiel 2019 + 59-69 loi 26-06 (verrouillés). Coords chef-lieu ; incertaines marquées ⚠️ VERIF (tout 49-69 + mineures, 55 lignes flaggées).
Décisions: columns = exactement celles de migration 001 · code = matricule 2 chiffres · 14 grandes villes non flaggées, reste flaggé pour spot-check honnête (pas de faux-confiant).
Build: N/A (SQL data) · Seed: ⏳ PAS exécuté · Spécialités: ⏳ tâche séparée
Prochaine session: vérif coords flaggées → seed spécialités → exécution migrations+seed → Phase 0.3 auth

### Session 004 — Phase 0.2 Exécution migrations + seed
Date: 2026-06-24 · Phase: 0 (Foundation) · Tâche: exécuter migrations 001–003 + wilaya seed sur Supabase, vérifier
Fait: migrations 001–003 + seed wilayas exécutés sur Supabase (ref `rwasjhplhbobrwqerzks`), vérifiés (wilaya=69, 59–69=11). Phase 0.2 ✅ complète.
Dette logguée: (1) seed specialites manquant — bloque avocat_specialites Phase 1 ; (2) coords wilayas 49–69 (21 lignes ⚠️ VERIF) à vérifier avant Phase 2 Haversine.
Prochaine session: activer pgvector → Phase 0.3 Auth

### Session 005 — Phase 0.3 Auth Foundation (pgvector + session SSR + i18n)
Date: 2026-06-24 · Phase: 0.3 (Auth Foundation) · Tâche: pgvector + client de session SSR + squelette i18n (étapes a→d)
Fait: pgvector activé (vector 0.8.0) · @supabase/ssr + next-intl v4 installés · server-session.ts (client SSR cookie/session, anon, RLS ; server.ts service_role inchangé) · squelette i18n (routing.ts + request.ts + plugin next.config.mjs + stubs fr/ar/en common + restructure app/[locale] dir RTL + NextIntlClientProvider)
Décisions: server.ts NON réécrit (session = fichier séparé server-session.ts) · messages = stubs common (dette i18n logguée) · root layout thin, [locale]/layout possède `<html lang dir>` + provider
Build: ✅ 0 erreur · app sert /fr /ar /en
Prochaine session: middleware fusionné (next-intl v4 + refresh session Supabase dans un seul middleware.ts, bon ordre)

### Session 006 — Middleware fusionné
Date: 2026-06-24 · Phase: 0.3 Auth Foundation
Fait: src/middleware.ts — next-intl v4 + refresh session Supabase, un seul fichier, ordre correct · build 0 erreur · runtime vérifié (détection navigateur Chrome→/en Opera→/fr, /ar RTL)
Décisions: détection de langue navigateur gardée ACTIVE (pas de force /fr) — meilleure UX trilingue algérienne · warning Edge Runtime process.version = cosmétique, ignoré
Build: 0 erreur · Commit: 668f24c · Prochaine session: pages auth (login/signup/callback)

### Session 007 — Trigger profil + formulaire signup
Date: 2026-06-24 · Phase: 0.3 Auth Foundation
Fait: migration 004 trigger handle_new_user (SECURITY DEFINER, role citoyen forcé, AFTER INSERT auth.users) testé OK · formulaire signup UI + validation client (tokens uidesign, FR/AR RTL vérifiés)
Décisions: création profil = TRIGGER atomique (choix entreprise, pas frontend multi-étapes) · create-profile devient fallback idempotent futur · langue de travail session = arabe (pédagogie)
Build: 0 erreur · Prochaine session: câbler signUp() au formulaire

### Session 007 (suite) — Signup loop câblé & vérifié
Date: 2026-06-24 · Phase: 0.3 Auth Foundation
Fait: SignupForm câblé sur signUp() · flux signup complet testé en réel (page→auth.users→trigger→users role=citoyen→email confirmé) · UX succès/erreur traduite
Décisions: trigger gère le profil (create-profile non appelé) · compte test youcef.mokhtari gardé pour tester login
Build: 0 erreur · Prochaine session: route /auth/callback puis page login

[Sessions suivantes ajoutées ici par l'agent]
