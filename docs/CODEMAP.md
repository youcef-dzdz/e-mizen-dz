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
*[Vide — à remplir en Phase 0]*

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

## Pages (src/app/[locale]/)
### RootLayout (Session 001)
| Champ | Valeur |
|---|---|
| Composant | src/app/layout.tsx → ligne 13 |
| Fonction principale | RootLayout() |
| Explication | Coquille HTML racine (lang="fr"), importe globals.css. i18n/[locale] + RTL en Phase 0 ultérieure. |

### Home (placeholder) (Session 001)
| Champ | Valeur |
|---|---|
| Composant | src/app/page.tsx → ligne 5 |
| Fonction principale | Home() |
| Explication | Landing placeholder Phase 0.1 — valide le scaffolding + les tokens Tailwind (bg/text espresso, or, success). Aucune couleur hardcodée (Règle 8). |

## API Routes (src/app/api/)
*[Vide — à remplir au fur et à mesure]*

## Services (src/services/)
*[Vide — à remplir au fur et à mesure]*

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
| Explication | Client Supabase serveur, clé service_role (bypass RLS). Garde-fou anti-bundle navigateur (Règle 11, P0). Sans session persistée. |

---
*Dernière mise à jour: Session 003 — Phase 0.2 seed wilayas (69 lignes, coords flaggées ⚠️ VERIF).*
