# STATUS.md — État du Projet E-Mizen DZ

> Mis à jour à chaque fin de session. Lu en premier à chaque session (Étape 1).
> Ne jamais résumer ou tronquer — toujours ajouter, jamais écraser.

---

## Dernière Session
Date: 2026-06-29 (Session 012)
Ce qui a été fait: UI inscription avocat COMPLÈTE construite, buildée (0 erreur) et testée en réel. Pièces : (3a) validators isValidNom + isValidTelephoneDZ + extension signUp(metadata optionnel) — commit 5849419 ; (3b) WilayaSelect (fetch 69 wilayas actives depuis la table, affichage code+nom selon locale) + service wilaya + type Wilaya + i18n — commit d6e3ec5 ; (3c-1) composant TextField réutilisable — commit 679b600 ; (3c-2) AvocatSignupForm (8 champs, validation client, signUp options.data={intent:'avocat',...}) + page signup-avocat + i18n FR/AR/EN — commit 7fe4ba8 ; fix largeur stable AuthLayout — commit a3644c0. VALIDATION RÉELLE : signUp avocat testé → trigger 011 a bien écrit la ligne pending_avocat_registrations (Benali/Sofiane/wilaya 27/cabinet, vérifié en base) ✅ ; email de confirmation reçu ✅ ; email_confirmed_at rempli ✅ ; formulaire FR/AR/EN + RTL arabe + 69 wilayas affichées ✅ ; validation champs (email/password/nom invalides bloquent, téléphone vide accepté, bouton gelé tant qu'invalide) ✅.
Prochaine tâche: (1) diagnostiquer auth_error=1 au clic du lien de confirmation (le code arrive au callback mais exchangeCodeForSession échoue — piste : mismatch locale fr/en dans emailRedirectTo, OU code_verifier PKCE perdu entre contextes) ; (2) pièce 4 — logique de promotion post-confirmation (route serveur lit pending → register_avocat → supprime pending, idempotente).
Résumé point (reprise): Backbone serveur (009+010+011) + UI inscription avocat (3a/3b/3c) COMPLETS et validés en réel (trigger 011 écrit le pending, confirmé en base). L'avocat reste citoyen avec une ligne pending tant que la pièce 4 (promotion) n'est pas construite — comportement attendu. Reste Phase 1 : fix auth_error=1, promotion, upload documents, profil public, paramètres cabinet.

---

## Phase Courante
**Phase 1 — Avocat Profile & Cabinet** · Statut: 🔵 DÉMARRÉE · **SCHÉMA Phase 1 COMPLET (Session 010)** : les 4 tables migrées + RLS + tests négatifs vérifiés sur Supabase — 005_cabinets, 006_avocats (enum avocat_statut, RLS T03 stricte + anti-auto-vérification), 007_avocat_specialites (jointure N:N, PK composite), 008_disponibilites (récurrent hebdo, 2 CHECK, soft delete). Couche GRANT/REVOKE explicite (least privilege) appliquée suite au changement de défaut Supabase (30 mai 2026). ⚠️ **Phase 1 PAS terminée — seule sa fondation données est posée.** La partie applicative + UI reste à faire : inscription avocat (email only, upload documents bucket privé, statut en_attente), profil public /marketplace/[avocatId], paramètres cabinet.
**Backbone serveur inscription avocat (migrations 009 + 010 + 011) FAIT et testé (Session 011)** : (009) slugify + register_avocat (atomique, SECURITY DEFINER, service_role-only) + trigger garde-fou role ; (010) table pending_avocat_registrations (registre serveur pur, RLS refus total client) ; (011) trigger défensif handle_new_avocat_pending (metadata → pending, ne fait jamais échouer signUp). Reste applicatif Phase 1 : UI inscription avocat (signUp options.data), logique de promotion post-confirmation (route serveur lit pending + appelle register_avocat), upload documents, profil public, paramètres cabinet.
**UI inscription avocat (Session 012) FAITE, buildée (0 erreur) et testée en réel** : validators (isValidNom + isValidTelephoneDZ) + signUp(metadata optionnel) · WilayaSelect (69 wilayas actives fetchées depuis la table, affichage code+nom selon locale) + service wilaya + type Wilaya · TextField réutilisable · AvocatSignupForm (8 champs, validation client, signUp options.data={intent:'avocat',...}) + page signup-avocat + i18n FR/AR/EN lockstep + RTL · fix largeur stable AuthLayout. VALIDÉ EN RÉEL : trigger 011 écrit le pending (confirmé en base), email de confirmation reçu, email_confirmed_at rempli, 3 langues + RTL + 69 wilayas OK. Reste Phase 1 : **fix auth_error=1 au lien de confirmation** (bloquant avant promotion), logique de promotion post-confirmation, upload documents, profil public, paramètres cabinet.
**Phase 0.3 — Auth Foundation** · Statut: ✅ TERMINÉE (100%) · Finition UI auth faite (Session 009 suite) : AuthLayout partagé + LanguageSwitcher global + titres navigateur traduits + boutons affinés py-3 sur les 4 formulaires. Phase 0.3 close à 100 % sur **tous les niveaux** (logic + UI + i18n + RTL testés FR/AR). · Prochaine : Phase 1 (Avocat Profile & Cabinet).
**Phase 0 — Foundation & Setup** · Statut: 🔵 En cours · Progression: ~98% (0.1 scaffolding + 0.2 ✅ complète + 0.3 Auth Foundation ✅ TERMINÉE — vérifiée E2E, password reset complet inclus)
**Phase 0.2 ✅ complète:** migrations 001–003 + wilaya seed exécutés sur Supabase le 2026-06-24, vérifiés (wilaya=69, 59–69=11).
**Phase 0.3 — Auth Foundation 🔵 en cours (Session 007):** pgvector activé (vector 0.8.0) · @supabase/ssr + next-intl v4 installés · src/lib/supabase/server-session.ts ajouté (client SSR cookie/session, anon, respecte RLS — server.ts service_role INCHANGÉ) · squelette i18n complet (routing.ts + request.ts + plugin next.config.mjs + stubs fr/ar/en common + restructure app/[locale] avec dir RTL + NextIntlClientProvider) · middleware fusionné src/middleware.ts (next-intl v4 + refresh session Supabase, un seul fichier, ordre correct) · **migration 004_handle_new_user.sql (trigger AFTER INSERT auth.users → profil public.users auto-créé, role=citoyen forcé) exécutée + testée · formulaire signup UI + validation client (tokens uidesign, FR/AR RTL vérifiés)**. Prochaine immédiate: câbler SignupForm sur auth.ts signUp() (le trigger gère le profil — PAS d'appel à create-profile). **Mise à jour (Session 007 suite): SignupForm câblé sur signUp() et flux signup vérifié de bout en bout en réel (page → auth.users → trigger 004 → public.users role=citoyen → email confirmé). Prochaine immédiate: route /auth/callback (handler confirmation/OAuth) puis page login.**
Numérotation migrations (ordre dépendance FK, verrouillé): 001 wilaya · 002 specialites · 003 users. (Ancien "001 users / 002 wilaya / 025 specialites" corrigé Session 002 — users.wilaya_id réfère wilaya.)
> Wilaya count corrigé 58→69 le 2026-06-23 (loi n° 26-06 du 04/04/2026 — 11 nouvelles wilayas n°59-69, ex-wilayas déléguées). Période transitoire jusqu'au 31/12/2026.

---

## État des Phases
| Phase | Nom | Statut |
|---|---|---|
| 0 | Foundation & Setup | 🔵 En cours (0.1 fait · 0.2 ✅ migrations 001–003 + seed wilayas exécutés/vérifiés 2026-06-24 · 0.3 Auth Foundation ✅ TERMINÉE — vérifiée E2E, password reset complet) |
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
**Table pending_avocat_registrations — in-scope Phase 1, approuvée fondateur (2026-06-28) :** 28e table, ajoutée au scope par décision explicite du fondateur. POURQUOI : implémente le flux d'inscription avocat de niveau entreprise (pending registration). À l'inscription, les données avocat/cabinet (nom, prenom, telephone, wilaya_id, cabinet_nom) sont stockées côté serveur (service_role) dans cette table ; le compte reste citoyen non confirmé. La promotion en avocat (rpc register_avocat, migration 009) — qui crée le cabinet + la ligne avocats — n'est déclenchée qu'APRÈS confirmation email vérifiée, au premier accès authentifié (logique de promotion idempotente). BÉNÉFICE : aucune donnée orpheline (pas de cabinet créé pour un email jamais confirmé), identité toujours server-authoritative (jamais via user_metadata manipulable par le client), un seul pattern d'auth (confirmation email obligatoire pour tous, y compris avocat). Le total passe de 27 à 28 tables. RLS : aucun accès client (lecture ou écriture) — service_role uniquement. PK = user_id (un seul pending par compte). Hard delete après promotion réussie (enregistrement transitoire, exception Rule 10 documentée comme les tables de jointure).

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
- ✅ **[AVANT Phase 1] Seed specialites — RÉSOLUE (Session 009).** Catalogue de 20 spécialités juridiques algériennes + « autre » (id=99) ajouté à seed.sql, exécuté sur Supabase, count=21 vérifié. Commit `0f72f64` poussé. Décision « avocat généraliste » = option B (select-all UI, à implémenter Phase 1), PAS un row dans specialites.
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
- 🟢 **[Phase 1 — GRANT/REVOKE] REVOKE des privilèges non nécessaire — vérifié.** Le nouveau défaut Supabase ne grant plus SELECT/INSERT/UPDATE/DELETE par défaut (changement 30 mai 2026), donc aucun REVOKE préalable n'est requis. Le hardening REVOKE complet des rôles est déjà couvert par la couche GRANT explicite (least privilege) ajoutée aux 4 tables (001/002/003/005).
- [ ] **[Phase 1 — barreau]** La colonne avocats.barreau est en texte libre. À normaliser en table de référence (FK) quand la liste officielle UNOA des barreaux algériens sera obtenue. Texte temporaire = dette consciente, pas oubli.
- [ ] **[Passe sécurité avant déploiement] npm audit — 5 vulnérabilités (1 moderate, 4 high) :** signalées après install (probablement transitives, dans des sous-dépendances dev). NE PAS lancer `npm audit fix --force` (breaking changes, risque de casser un build qui marche). À auditer dans une passe sécurité dédiée avant déploiement (checklist SECURITY.md). Vérifier `npm audit` en détail à ce moment-là.
- [ ] **[Phase 7 — QA] Garde-fou trg_guard_user_role (verrou role, migration 009) :** actif en base comme défense en profondeur, mais sa validation négative (un authenticated ne peut pas changer son role) n'a PAS pu être testée de façon concluante dans le SQL Editor (set local role ne reproduit pas fidèlement le contexte de rôle d'une session app). À valider en E2E via l'app en Phase 7.
- [ ] **[Phase 1 / MVP] Compte de test register_avocat = UUID fixe 22349d59-75a3-4bbb-accc-8ff240747796** (créé manuellement via Dashboard Auth). Acceptable MVP ; en entreprise réelle, seed de test automatisé via l'API Auth en CI (post-graduation).
- [ ] **[Leçon outil] Supabase SQL Editor :** avec une sélection active, le bouton devient « Run selected » et n'exécute QUE la portion surlignée → les fixtures/nettoyage en tête de fichier sont sautés. Toujours Ctrl+A (ou désélectionner) avant Run pour exécuter le fichier entier.
- [ ] **[Phase 7 — QA] Validation COMPORTEMENTALE du trigger 011 (handle_new_avocat_pending) :** les tests actuels sont STRUCTURELS (existence fonction + trigger actif) car un INSERT auth.users est impossible dans le SQL Editor. À valider en E2E via l'app : signUp avocat → 1 pending créé ; signUp citoyen → aucun pending ; metadata corrompu (wilaya non numérique, champ manquant, FK invalide) → aucun pending MAIS signUp réussit (principe défensif).
- [ ] **[Phase 1 — promotion] Logique de promotion post-confirmation à construire :** au premier accès authentifié confirmé, une route serveur doit lire pending_avocat_registrations, appeler register_avocat (009), puis supprimer le pending. Doit être idempotente (rejouable sans double-inscription) et robuste (si l'onglet est fermé après confirmation, la promotion se complète au prochain accès).
- [ ] **[Phase 1 — BLOQUANT avant promotion] auth_error=1 au clic du lien de confirmation email :** le terminal montre que le code arrive au callback (/[locale]/auth/callback?code=...) mais exchangeCodeForSession échoue → redirige vers /[locale]?auth_error=1. email_confirmed_at est pourtant rempli (la confirmation côté Supabase réussit), mais la session locale ne s'établit pas. Pistes à investiguer : (a) mismatch de locale — signUp depuis /fr mais lien de confirmation ouvert/redirigé en /en (observé dans les logs) ; (b) code_verifier PKCE perdu entre le contexte de signUp et l'ouverture du lien. À diagnostiquer proprement (lire callback route + emailRedirectTo) avant la pièce promotion.
- [ ] **[Phase 1 / avant tests intensifs + production] SMTP — rate limit Supabase par défaut « sending emails » = 2 emails/h** (SMTP de dev, non modifiable sur le plan actuel) — bloque les tests d'inscription répétés (« Une erreur est survenue » au-delà de 2/h). En entreprise réelle : remplacer par un SMTP dédié = Resend (déjà dans le stack) dans Supabase Auth → SMTP settings, ce qui lève la limite et la rend configurable. À configurer avant les tests E2E intensifs (Phase 7) et avant production.
- [ ] **[Phase 1 — UX mineur, non bloquant] Validation onBlur affiche « invalide » sur un champ requis laissé vide** (ex. email vide → « Adresse email invalide »). Acceptable MVP, mais l'idéal entreprise = message « champ requis » distinct de « format invalide ». Polish optionnel.

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

### Session 007 (fin) — Route callback + emailRedirectTo
Date: 2026-06-24 · Phase: 0.3 Auth Foundation
Fait: route /auth/callback (échange PKCE, anti open-redirect) · Redirect URL Dashboard ajoutée · signUp emailRedirectTo localisé · build 0 erreur
Décisions: flow PKCE (code query) au lieu d'implicite (hash) · callback ne rend pas d'UI (redirige seulement) · messaging page destination = étape suivante
Build: 0 erreur · NON testé end-to-end · Prochaine session: tester boucle confirmation complète (email neuf) puis page login

### Session 008 — Noyau auth vérifié E2E + améliorations UX
Date: 2026-06-26 · Phase: 0.3 Auth Foundation
Fait: chaîne signup→trigger→callback PKCE→login→session cookie vérifiée en réel (cookie sb- confirmé) · fix client.ts createBrowserClient · show/hide + confirm password + loading state · lucide-react ajouté · crise git (validation.ts untracked) résolue
Décisions: createBrowserClient obligatoire en SSR (cookies pas localStorage) · git status après CHAQUE commit (leçon: validation.ts perdu) · MFA/CAPTCHA/social = Future Building
Build: 0 erreur · Prochaine session: password reset OU Phase 1

### Session 008 (suite) — Password reset complet + auth clôturée
Date: 2026-06-26 · Phase: 0.3 Auth Foundation → TERMINÉE
Fait: flow reset complet (forgot + callback type=recovery + reset-password + updatePassword + lien login) vérifié E2E en réel · auth 100% fonctionnelle
Décisions: lien reset = usage unique (un clic, sinon auth_error=1 normal) · le code callback gérait déjà recovery correctement, l'échec initial = lien déjà consommé · MFA/social/resend = Future Building
Build: 0 erreur · Prochaine session: Phase 1 — Avocat Profile & Cabinet

### Session 009 — Seed specialites
Date: 2026-06-26 · Phase: 0.3→1 transition
Fait: catalogue specialites (20 spécialités juridiques algériennes + « autre » id=99) ajouté à seed.sql, exécuté sur Supabase, count=21 vérifié. Décision « avocat généraliste » = option B (select-all UI) — à implémenter Phase 1, PAS un row dans specialites.
Build: N/A (SQL data) · Commit: 0f72f64 poussé
Prochaine session: Phase 1 — table cabinets (migration + RLS + tests négatifs)

### Session 009 (suite) — Table cabinets + couche GRANT/REVOKE
Date: 2026-06-27 · Phase: 1 (Avocat Profile & Cabinet)
Fait: migration 005_cabinets (tenant root, uuid PK, wilaya_id FK, soft delete, trigger updated_at réutilisé, RLS SELECT public + écriture service_role) + tests négatifs RLS vérifiés sur Supabase (4 ops, Success). GAP plateforme corrigé : Supabase ne grant plus par défaut (changement 30 mai 2026) → couche GRANT/REVOKE explicite (least privilege) ajoutée aux 4 tables (001 wilaya, 002 specialites, 003 users, 005 cabinets) + appliquée manuellement sur la base.
Décisions: avocat↔cabinet = 1:1, FK dans avocats.cabinet_id · statut/Barreau/vérification = sur avocats (pas cabinets) · verifie_jus_qu_a = colonne schema-ready Phase avocats, logique périodique = Future Building · généraliste = option B (select-all UI).
Build: N/A (SQL) · Commit: 7bf8c4e poussé
Prochaine session: migration avocats (statut enum, numéro Barreau, verifie_jusqu_a, cabinet_id FK)

### Session 009 (suite) — Finition UI pages auth
Date: 2026-06-27 · Phase: 0.3 (clôture définitive UI) → 1
Fait: AuthLayout partagé (logo + wordmark "E-Mizen DZ" DZ en or + tagline traduite) · LanguageSwitcher global (FR·AR·EN, RTL-safe, helpers createNavigation dans routing.ts) · titres navigateur traduits par locale (generateMetadata + getTranslations) · espacements resserrés + bouton affiné (py-3) sur les 4 formulaires · clé common.tagline + 4 clés auth.*.pageTitle (3 locales lockstep). Testé visuellement les 4 pages × FR/AR, RTL arabe vérifié propre (labels à droite, œil à gauche, miroir auto via classes logiques).
Build: 0 erreur · Commit: 3a80718 poussé
Prochaine session: Phase 1 — migration avocats (statut enum, n° Barreau, verifie_jusqu_a, cabinet_id FK)

### Session 010 — Schéma Phase 1 complet (4 tables)
Date: 2026-06-27 · Phase: 1 (Avocat Profile & Cabinet)
Fait: les 4 tables du schéma Phase 1 migrées + RLS + tests négatifs vérifiés sur Supabase : 005_cabinets, 006_avocats (enum avocat_statut 4 valeurs, RLS T03 stricte : public voit verifie only + owner voit sa ligne, anti-auto-vérification testée), 007_avocat_specialites (jointure N:N, PK composite, hard delete justifié), 008_disponibilites (récurrent hebdo ISO 8601, 2 CHECK, soft delete). Décisions clés : avocat.id = PK partagée users.id (extension 1:1) · barreau = texte (dette : normaliser en table UNOA plus tard) · pratique_generale booléen (option C) · tests idempotents via ON CONFLICT (leçon : begin/rollback non fiable dans SQL Editor + auth.users non nettoyable).
Commits: 7bf8c4e (cabinets), 538b4f6 (avocats), 7c6349f (avocat_specialites), e5a79fe (disponibilites) — tous poussés
Prochaine session: Phase 1 partie applicative — inscription avocat (email only, upload documents bucket privé, statut en_attente) + profil public /marketplace/[avocatId] + paramètres cabinet.

### Session 011 — Backbone serveur inscription avocat (migration 009)
Date: 2026-06-28 · Phase: 1 (Avocat Profile & Cabinet)
Fait: migration 009 (slugify + register_avocat atomique SECURITY DEFINER service_role-only + trigger garde-fou role) construite, testée Supabase, poussée. Tests négatifs TEST 2/3/4 ✅ (execute refusé, happy path, double-inscription bloquée). Fichier de test self-cleaning.
Décisions: garde-fou role validé en Phase 7 (SQL Editor non fiable pour le contexte de rôle) · compte test UUID fixe via Dashboard Auth · TEST 1 retiré du fichier (non concluant dans l'éditeur), trigger gardé en base.
Commit: 65a2a49 poussé · Prochaine session: route API /api/auth/register-avocat (signUp → register_avocat)

### Session 011 (suite) — Backbone serveur inscription avocat (009+010+011)
Date: 2026-06-28 · Phase: 1 (Avocat Profile & Cabinet)
Fait: flux inscription avocat entreprise (option C pending registration). 009 register_avocat + garde-fou role · 010 table pending (registre serveur pur, RLS refus total client) · 011 trigger défensif metadata→pending (jamais d'échec signUp). Tests : 009 happy/double/execute ✅, 010 négatifs RLS ✅, 011 structurels ✅.
Décisions: 28e table pending approuvée fondateur · option C (trigger lit metadata, données véloces non sensibles, role jamais via metadata) · trigger 011 séparé de 004 (responsabilité unique) · validation comportementale 011 + garde-fou 009 reportées Phase 7 E2E.
Commits: 65a2a49 (009), c97e172 (010), 9380a58 (011) poussés · Prochaine session: UI inscription avocat (signUp options.data + validation + i18n + RTL).

### Session 012 — UI inscription avocat complète (3a→3c) + validation réelle
Date: 2026-06-29 · Phase: 1 (Avocat Profile & Cabinet)
Fait: UI inscription avocat complète — validators (nom/telephone DZ) + signUp(metadata) · WilayaSelect (69 wilayas depuis la base, code+nom) + service/type · TextField réutilisable · AvocatSignupForm (8 champs) + page + i18n FR/AR/EN · fix largeur AuthLayout. Buildé 0 erreur. TESTÉ EN RÉEL : trigger 011 écrit le pending (vérifié base), email reçu, confirmation OK, RTL+3 langues+69 wilayas OK.
Décisions: composants séparés du citoyen (testé, non refactoré) · WilayaSelect autonome (pas de Select générique, YAGNI) · TextField extrait (DRY, Rule 3) · wilaya fetchée depuis la base (source unique) · code+nom affichés (matricule utile).
Bugs ouverts: auth_error=1 au lien de confirmation (callback exchangeCodeForSession échoue — locale mismatch ou PKCE) · rate limit email Supabase 2/h (→ Resend SMTP).
Commits: 5849419, d6e3ec5, 679b600, 7fe4ba8, a3644c0 poussés · Prochaine session: fix auth_error=1 puis pièce 4 (promotion post-confirmation).

[Sessions suivantes ajoutées ici par l'agent]
