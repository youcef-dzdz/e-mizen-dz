# CODEMAP.md — Registre des Composants E-Mizen DZ

> Mis à jour après chaque création OU modification de composant (Rule 23). Document de référence pour la démo jury.

---

## Usage en démo jury
1. Le jury clique sur un bouton/feature → 2. Ouvrir ce fichier → 3. Trouver le composant par nom/module → 4. On a fichier + ligne + fonction + service + table + politique RLS + explication → 5. Ouvrir le fichier, aller à la ligne, expliquer.

## Template d'entrée
```
### [NomDuComposant]
| Champ | Valeur |
|---|---|
| Composant | src/components/[module]/[Nom].tsx → ligne N |
| Fonction principale | handleXxx() / fetchXxx() |
| Service appelé | src/services/xxx.ts → ligne N → xxxService() |
| API Route | src/app/api/xxx/route.ts (si applicable) |
| Table(s) Supabase | nom_table — colonnes concernées |
| Politique RLS | supabase/policies/xxx.sql → nom politique |
| Explication | Ce que ça fait en français simple (1-3 phrases) |
```

---

## Module: UI Primitives (src/components/ui/)
### WilayaSelect (Session 011 — Phase 1)
| Champ | Valeur |
|---|---|
| Composant | src/components/ui/WilayaSelect.tsx |
| Fonction principale | WilayaSelect() → loadWilayas() (useEffect) |
| Service appelé | src/services/wilaya.ts → getWilayas() |
| Table(s) Supabase | wilaya — id, code, nom_fr, nom_ar (filtre actif côté service) |
| Politique RLS | wilaya_select_public (SELECT anon+authenticated, voir 001) |
| Explication | Sélecteur `<select>` natif des 69 wilayas actives, chargées au montage. Affiche code + nom selon la locale (nom_ar en arabe, nom_fr sinon). Composant autonome dédié à l'inscription avocat (pas de Select générique, YAGNI). |

### TextField (Session 010 — Phase 1)
| Champ | Valeur |
|---|---|
| Composant | src/components/ui/TextField.tsx |
| Fonction principale | TextField() |
| Service appelé | Aucun — composant de présentation pur (aucun appel Supabase, aucun i18n interne) |
| Table(s) Supabase | Aucune |
| Politique RLS | N/A |
| Explication | Champ de formulaire réutilisable (label + input + message d'erreur), avec bascule optionnelle d'affichage du mot de passe. Extrait pour DRY entre SignupForm citoyen et AvocatSignupForm (Rule 3, plafond 300 lignes). Le parent fournit les textes déjà traduits. |

## Module: Marketplace (src/components/marketplace/)
*[Vide — à remplir en Phase 2]*

## Module: ERP Cabinet (src/components/cabinet/)
*[Vide — à remplir en Phase 3]*

## Module: Portail Client (src/components/portail/)
*[Vide — à remplir en Phase 4]*

## Module: Assistant IA (src/components/assistant/)
*[Vide — à remplir en Phase 6]*

## Module: Admin Panel (src/components/admin/)
*[Vide — à remplir en Phase 5]*

## Module: Shared (src/components/shared/)
*[Vide — à remplir en Phase 0]*

## Module: Auth (src/components/auth/)
### AvocatSignupForm (Session 012 — Phase 1)
| Champ | Valeur |
|---|---|
| Composant | src/components/auth/AvocatSignupForm.tsx |
| Fonction principale | AvocatSignupForm() → handleSubmit() |
| Service appelé | src/services/auth.ts → signUp(email, password, locale, metadata) |
| API Route | Aucune directe — signUp appelle Supabase Auth ; la promotion réelle passe par les triggers 011/012 + rpc register_avocat (009) |
| Table(s) Supabase | auth.users (raw_user_meta_data) → lu par le trigger 011 pour écrire pending_avocat_registrations (010) |
| Politique RLS | N/A côté composant (écriture via Supabase Auth, pas une table RLS directe) |
| Explication | Formulaire d'inscription avocat (8 champs : email, password, confirmation, nom, prenom, telephone, wilaya, cabinet_nom). Envoie options.data = { intent:'avocat', ... } à signUp — jamais de role transmis (T01/T03, forcé serveur). Réutilise TextField + WilayaSelect (DRY, sous 300 lignes). |

## Pages (src/app/[locale]/)
### RootLayout (Session 001 · modifié Session 005)
| Champ | Valeur |
|---|---|
| Composant | src/app/layout.tsx |
| Fonction principale | RootLayout() |
| Explication | Root layout devenu thin pass-through (Session 005) : ne possède plus `<html>`/`<body>` — c'est désormais [locale]/layout.tsx qui les porte (lang + dir par locale). Se contente de relayer children. |

### LocaleLayout (Session 005 — Phase 0.3)
| Champ | Valeur |
|---|---|
| Composant | src/app/[locale]/layout.tsx |
| Fonction principale | LocaleLayout() |
| Explication | Layout par locale : possède `<html lang dir>` (dir=rtl pour ar, ltr sinon), charge les messages et enveloppe l'arbre dans NextIntlClientProvider. Point d'entrée RTL et i18n côté client. |

### Home (placeholder) (Session 001 · déplacée Session 005)
| Champ | Valeur |
|---|---|
| Composant | src/app/[locale]/page.tsx |
| Fonction principale | Home() |
| Explication | Landing placeholder déplacée de src/app/page.tsx vers src/app/[locale]/page.tsx (routing par locale, Session 005). Valide scaffolding + tokens Tailwind. Aucune couleur hardcodée (Règle 8). |

### SignupAvocatPage (Session 012 — Phase 1)
| Champ | Valeur |
|---|---|
| Composant | src/app/[locale]/auth/signup-avocat/page.tsx |
| Fonction principale | SignupAvocatPage() |
| Explication | Page d'inscription avocat — Server Component fin (Rule 7), enveloppe `<AuthLayout>` + `<AvocatSignupForm>`. Toute la logique vit dans AvocatSignupForm (composant client). |

## API Routes (src/app/api/)
*[Vide — à remplir au fur et à mesure]*

## Services (src/services/)
### auth.ts (Session 001 · étendu Session 010 — Phase 1)
| Champ | Valeur |
|---|---|
| Fichier | src/services/auth.ts |
| Fonction principale | signIn() · signOut() · signUp(email, password, locale, metadata?) · resetPasswordForEmail() · updatePassword() |
| Explication | Toutes les opérations Supabase Auth (Rule 9), clé anon uniquement (Rule 11). signUp étendu Session 010 : 4e paramètre `metadata` optionnel (undefined pour le citoyen, `{ intent:'avocat', ... }` pour AvocatSignupForm) — transmis en `options.data`, lu par le trigger 011. Renvoie toujours `{ data, error }` brut (Rule 1 : la UI décide du message). |

### wilaya.ts (Session 011 — Phase 1)
| Champ | Valeur |
|---|---|
| Fichier | src/services/wilaya.ts |
| Fonction principale | getWilayas() |
| Explication | SELECT des wilayas actives (id, code, nom_fr, nom_ar), triées par id. Client anon (lecture publique, policy wilaya_select_public). Utilisé par WilayaSelect. |

## Types (src/types/)
### Wilaya (Session 011 — Phase 1)
| Champ | Valeur |
|---|---|
| Fichier | src/types/wilaya.ts |
| Explication | Interface `Wilaya { id, code, nom_fr, nom_ar }` — forme minimale pour WilayaSelect, alignée sur le SELECT de wilaya.ts (pas de latitude/longitude, réservées à la recherche Haversine Phase 2). |

## Base de données — Migrations (supabase/migrations/)
### wilaya (Session 002 — Phase 0.2)
| Champ | Valeur |
|---|---|
| Migration | supabase/migrations/001_wilaya.sql |
| Table(s) | wilaya — id, code, nom_fr, nom_ar, latitude, longitude, actif, created_at |
| Index | idx_wilaya_code (code) |
| Politique RLS | wilaya_select_public (SELECT anon+authenticated) ; aucune écriture client |
| Test négatif | tests/rls/wilaya.test.sql (SELECT ok · INSERT/UPDATE/DELETE bloqués) |
| Explication | Référence des 69 wilayas (loi 26-06). Lecture publique pour la découverte marketplace ; lat/long pour Haversine (Phase 2). Structure seule, seed séparé. |

### specialites (Session 002 — Phase 0.2)
| Champ | Valeur |
|---|---|
| Migration | supabase/migrations/002_specialites.sql |
| Table(s) | specialites — id, slug (unique), nom_fr, nom_ar, actif, created_at |
| Index | index unique sur slug (via contrainte UNIQUE) |
| Politique RLS | specialites_select_public (SELECT anon+authenticated) ; aucune écriture client |
| Test négatif | tests/rls/specialites.test.sql (SELECT ok · INSERT/UPDATE/DELETE bloqués) |
| Explication | Référence des spécialités juridiques. slug utilisé dans les URLs de recherche. Structure seule, seed séparé. |

### users (Session 002 — Phase 0.2)
| Champ | Valeur |
|---|---|
| Migration | supabase/migrations/003_users.sql |
| ENUMs | user_role ('citoyen','avocat','admin') · user_locale ('fr','ar','en') |
| Table(s) | users — id (FK auth.users, cascade), role, email, nom, prenom, telephone, wilaya_id (FK wilaya), locale, avatar_url, created_at, updated_at, deleted_at/by/reason |
| Index | idx_users_role (role) · idx_users_wilaya_id (wilaya_id) |
| Trigger | trg_users_updated_at → set_updated_at() (updated_at = now() à chaque UPDATE) |
| Politique RLS | users_select_own + users_update_own (auth.uid() = id) ; pas de DELETE (soft delete, Rule 10) ; pas d'INSERT client (signup via service_role) |
| Test négatif | tests/rls/users.test.sql (A voit/modifie son profil ; A↛B SELECT/UPDATE bloqués ; hard DELETE bloqué) |
| Explication | Profil lié à auth.users, RBAC-ready (role 3 valeurs fixes). Isolation absolue des profils. Soft delete uniquement. Structure seule. |

### avocats (Session 007 — Phase 1)
| Champ | Valeur |
|---|---|
| Migration | supabase/migrations/006_avocats.sql |
| ENUMs | avocat_statut ('en_attente','verifie','suspendu','rejete') |
| Table(s) | avocats — id (PK, FK users.id), cabinet_id (FK cabinets), statut, numero_barreau, barreau, verifie_jusqu_a, bio, annees_experience, pratique_generale, avatar_url, soft delete (deleted_at/by/reason) |
| Index | idx_avocats_cabinet_id · idx_avocats_statut |
| Trigger | trg_avocats_updated_at → set_updated_at() (réutilisé de 003) |
| Politique RLS | avocats_select_public_verifies (statut='verifie' AND deleted_at is null) · avocats_select_own (auth.uid()=id) ; aucune écriture client (T03 — statut jamais modifiable côté client) |
| Test négatif | tests/rls/avocats.test.sql |
| Explication | Extension 1:1 de users (PK partagée) — cœur de la vérification T03 « Faux Avocat ». Le statut n'est visible publiquement que pour les avocats vérifiés ; la RLS l'impose en dernière ligne de défense, pas seulement la requête app. |

### avocat_specialites (Session 007 — Phase 1)
| Champ | Valeur |
|---|---|
| Migration | supabase/migrations/007_avocat_specialites.sql |
| Table(s) | avocat_specialites — avocat_id (FK avocats, cascade), specialite_id (FK specialites), created_at. PK composite (avocat_id, specialite_id) |
| Index | idx_avocat_specialites_specialite (recherche inverse par spécialité, Phase 2) |
| Politique RLS | avocat_specialites_select_public (using(true)) ; aucune écriture client |
| Test négatif | tests/rls/avocat_specialites.test.sql |
| Explication | Jointure N:N pure avocat↔spécialité. EXCEPTION documentée à Rule 10 (hard delete) : une ligne de jointure n'a aucune valeur historique — DELETE reste service_role only. |

### disponibilites (Session 007 — Phase 1)
| Champ | Valeur |
|---|---|
| Migration | supabase/migrations/008_disponibilites.sql |
| Table(s) | disponibilites — id, avocat_id (FK avocats, cascade), jour_semaine (CHECK 1-7), heure_debut, heure_fin (CHECK fin>debut), soft delete |
| Index | idx_disponibilites_avocat_id |
| Trigger | trg_disponibilites_updated_at → set_updated_at() |
| Politique RLS | disponibilites_select_public (deleted_at is null) ; aucune écriture client |
| Test négatif | tests/rls/disponibilites.test.sql |
| Explication | Créneaux hebdomadaires récurrents (affichage profil public Phase 1) — PAS un système de réservation (booking = hors scope MVP). Soft delete car donnée métier (horaires), contrairement à la jointure 007. |

### register_avocat (Session 011 — Phase 1)
| Champ | Valeur |
|---|---|
| Migration | supabase/migrations/009_register_avocat.sql |
| Fonction(s) | slugify(text) · register_avocat(p_user_id, p_nom, p_prenom, p_telephone, p_wilaya_id, p_cabinet_nom) — SECURITY DEFINER, atomique (cabinet + users.role + avocats en une transaction) |
| Trigger | trg_guard_user_role → guard_user_role() (verrou : bloque tout changement de users.role venant d'un client authenticated/anon — défense en profondeur T01/T03) |
| Grant | EXECUTE revoke public/anon/authenticated, grant service_role uniquement (least privilege) |
| Test négatif | tests/rls/register_avocat.test.sql (permissions + happy path + éligibilité) |
| Explication | RPC atomique de promotion citoyen→avocat : vérifie l'éligibilité (role='citoyen'), crée le cabinet (slug déterministe), promeut users.role, crée la ligne avocats (statut='en_attente'). Réservée à service_role — jamais appelable depuis le client. |

### pending_avocat_registrations (Session 011 — Phase 1)
| Champ | Valeur |
|---|---|
| Migration | supabase/migrations/010_pending_avocat_registrations.sql |
| Table(s) | pending_avocat_registrations — user_id (PK, FK auth.users cascade), nom, prenom, telephone, wilaya_id (FK wilaya), cabinet_nom, created_at |
| Index | Aucun au-delà de la PK (accès uniquement par user_id) |
| Politique RLS | AUCUNE policy → refus total anon/authenticated par défaut ; seul service_role (bypass RLS) lit/écrit/supprime |
| Test négatif | tests/rls/pending_avocat_registrations.test.sql |
| Explication | Registre serveur pur — sas entre signUp avocat et promotion réelle (post-confirmation email). Aucune donnée orpheline possible (28e table, approuvée fondateur 2026-06-28). Pas de soft delete (registre transitoire, hard delete justifié après promotion). |

### handle_new_avocat_pending (Session 011 — Phase 1)
| Champ | Valeur |
|---|---|
| Migration | supabase/migrations/011_handle_new_avocat_pending.sql |
| Fonction | handle_new_avocat_pending() — SECURITY DEFINER |
| Trigger | on_auth_user_avocat_pending → AFTER INSERT on auth.users |
| Test | tests/rls/handle_new_avocat_pending.test.sql (STRUCTUREL uniquement — fonction/trigger existent ; comportemental impossible en SQL Editor, reporté E2E Phase 7) |
| Explication | Trigger défensif : lit raw_user_meta_data du nouvel auth.users, écrit UNE ligne pending (010) si intent='avocat' et champs valides. Toute erreur est capturée en silence — ne fait JAMAIS échouer le signUp (principe défensif absolu). Indépendant du trigger 004 (responsabilité unique). |

### promote_avocat_on_confirm (Session 012 — Phase 1)
| Champ | Valeur |
|---|---|
| Migration | supabase/migrations/012_promote_avocat_on_confirm.sql |
| Fonction | promote_avocat_on_email_confirm() — SECURITY DEFINER |
| Trigger | on_auth_email_confirmed_promote → AFTER UPDATE OF email_confirmed_at on auth.users, WHEN (old NULL → new NOT NULL) |
| Test | tests/rls/promote_avocat_on_confirm.test.sql (TEST 0 structurel + TEST 1/2 comportemental simulé) · utilitaire tests/rls/reset_trigger_test_account.sql (récupération manuelle) |
| État | ⚠️ ÉCRIT, NON ENCORE EXÉCUTÉ EN BASE — fichier non commité au moment de cette entrée (git status ??), exécution réelle sur Supabase à confirmer par le fondateur |
| Explication | Trigger défensif déclenché par la confirmation email (événement en base, indépendant d'un callback HTTP faillible). Lit le pending (010), appelle register_avocat (009), supprime le pending si succès. Toute erreur capturée — ne fait jamais échouer la confirmation email. |

## Base de données — Seed (supabase/seed.sql)
### seed wilaya (Session 003 — Phase 0.2)
| Champ | Valeur |
|---|---|
| Fichier | supabase/seed.sql |
| Table(s) | wilaya — id, code, nom_fr, nom_ar, latitude, longitude (actif/created_at = défauts) |
| Contenu | 69 lignes : 1-58 numérotation officielle 2019 + 59-69 loi n° 26-06 (04/04/2026) |
| Ordre d'exécution | APRÈS migrations 001/002/003 |
| Explication | Données de référence des 69 wilayas (chef-lieu lat/long en degrés décimaux). Coordonnées incertaines marquées `⚠️ VERIF` (tout 49-69 + wilayas mineures) — à vérifier avant prod. Pas encore exécuté. |

## Infrastructure (src/lib/)
### logger (Session 001)
| Champ | Valeur |
|---|---|
| Fichier | src/lib/logger.ts → ligne 30 (export logger) |
| Fonction principale | logger.info/warn/error() |
| Explication | Logger central (Règle 13). En prod le détail reste serveur ; l'utilisateur ne voit qu'un message générique (Règle 1). Stub — transport à brancher ultérieurement. |

### supabaseBrowser (Session 001)
| Champ | Valeur |
|---|---|
| Fichier | src/lib/supabase/client.ts → ligne 18 |
| Explication | Client Supabase navigateur, clé anon uniquement. RLS protège les données. Jamais service_role ici (Règle 11). |

### createSupabaseServerClient (Session 001)
| Champ | Valeur |
|---|---|
| Fichier | src/lib/supabase/server.ts → ligne 26 |
| Fonction principale | createSupabaseServerClient() |
| Explication | Client Supabase serveur, clé service_role (bypass RLS). Garde-fou anti-bundle navigateur (Règle 11, P0). Sans session persistée. INCHANGÉ en Phase 0.3 (la session vit dans server-session.ts). |

### createServerSessionClient (Session 005 — Phase 0.3)
| Champ | Valeur |
|---|---|
| Fichier | src/lib/supabase/server-session.ts |
| Fonction principale | createServerSessionClient() |
| Explication | Client SSR @supabase/ssr, clé anon, lecture/écriture des cookies de session — RESPECTE la RLS (jamais service_role). Fichier NOUVEAU, distinct de server.ts : porte la session utilisateur côté serveur. Base du flux auth Phase 0.3. |

## Internationalisation (src/i18n/ · next.config.mjs · messages/)
### routing (Session 005 — Phase 0.3)
| Champ | Valeur |
|---|---|
| Fichier | src/i18n/routing.ts |
| Explication | Config next-intl : locales fr/ar/en, locale par défaut fr. Source de vérité des locales pour le routing [locale]. |

### request config (Session 005 — Phase 0.3)
| Champ | Valeur |
|---|---|
| Fichier | src/i18n/request.ts |
| Fonction principale | getRequestConfig() (v4) |
| Explication | getRequestConfig next-intl v4 : charge messages/{locale}.json par requête selon la locale active. |

### plugin next-intl (Session 005 — Phase 0.3)
| Champ | Valeur |
|---|---|
| Fichier | next.config.mjs |
| Explication | Config Next enveloppée par le plugin next-intl (createNextIntlPlugin) pointant sur src/i18n/request.ts. Toujours .mjs (Next 14 ne lit pas .ts). |

### messages stubs (Session 005 — Phase 0.3)
| Champ | Valeur |
|---|---|
| Fichier | messages/fr.json · messages/ar.json · messages/en.json |
| Explication | Stubs de traduction — namespace `common` uniquement pour l'instant. Trio fr/ar/en maintenu en lockstep (Rule 4). Traductions complètes à ajouter par composant UI (dette i18n loguée STATUS.md). |

---
*Dernière mise à jour: Session 012 — rattrapage CODEMAP (Rule 23) : migrations 006→012 (flux avocat : avocats, avocat_specialites, disponibilites, register_avocat, pending_avocat_registrations, handle_new_avocat_pending, promote_avocat_on_confirm) + UI inscription avocat (WilayaSelect, TextField, AvocatSignupForm, page signup-avocat) + services (wilaya.ts, auth.ts étendu) + type Wilaya.*
