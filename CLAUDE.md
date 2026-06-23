# CLAUDE.md — Mémoire Agent E-Mizen DZ

> Lu automatiquement au début de chaque session Claude Code.
> Ce fichier est la constitution du projet. Toute règle ici est active en permanence.
> Glossaire: RLS = Row Level Security (sécurité au niveau des lignes) · MVP = Minimum Viable Product ·
> API = Application Programming Interface · FK = Foreign Key (clé étrangère) · PK = Primary Key (clé primaire) ·
> RAG = Retrieval Augmented Generation · RTL = Right-To-Left · CRUD = Create Read Update Delete ·
> i18n = Internationalisation · SSE = Server-Sent Events.

---

## Section 1 — Règles Non Négociables (24)

1. **Jamais d'erreur brute à l'utilisateur** — message générique traduit uniquement. Jamais de stack trace, jamais d'erreur Postgres affichée.
2. **Streaming: native fetch + AbortController** — pas de réinvention. Le pattern vit dans hooks/useStream.ts.
3. **Aucun composant > 300 lignes** (lignes de code seules). Au-delà: extraire des sous-composants, jamais trimmer les commentaires pour passer.
4. **Traductions dans les 3 fichiers AVANT de construire un composant UI** — fr.json, ar.json, en.json. Clé manquante dans un fichier = build bloquant. Clé déclarée jamais référencée = à supprimer.
5. **`npm run build` à 0 erreur = seule définition de "terminé".** Pas "ça s'affiche", pas "ça marche en local".
6. **Vérifier qu'un composant n'existe pas avant d'en créer un** — grep + docs/CODEMAP.md d'abord.
7. **Un seul composant page par fichier.**
8. **Aucune couleur/spacing/shadow hardcodé** — tokens uidesign.md uniquement. Pas de hex brut, pas de valeurs Tailwind arbitraires.
9. **Appels API/Supabase dans /services/ uniquement** — jamais dans pages ou composants.
10. **Soft delete obligatoire** — deleted_at + deleted_by + deleted_reason. Jamais de hard delete. Tout SELECT filtre `deleted_at IS NULL` par défaut.
11. **Jamais service_role côté frontend** — bypasse RLS entièrement. Faille critique, pas un style. Réservé aux API routes serveur + lib/supabase/server.ts.
12. **Chaque politique RLS a un test négatif** — SELECT/INSERT/UPDATE/DELETE séparément, par table, dans tests/rls/. Test commenté ou .skip = manquant.
13. **Toutes les erreurs via logger.ts** — jamais de console.error brut dans les composants.
14. **Aucune concaténation SQL** — requêtes paramétrées uniquement (prévention injection SQL).
15. **Aucune feature hors scope sans approbation explicite du fondateur** (voir Section 3).
16. **cabinet_id sur chaque entité cabinet** (multi-tenant ready, défaut = avocat.id).
17. **Chaque session se termine par mise à jour STATUS.md + entrée REPORT.md.**
18. **Rate limiting par user (pas par IP) sur TOUS les endpoints.** Routes publiques: fallback IP.
19. **Pagination obligatoire sur tout endpoint liste** — offset pour dashboards, cursor pour feeds. Default 20, max 100.
20. **Validation input frontend (UX) ET backend (sécurité) sur tous les formulaires.**
21. **Aucune clé API dans le code source** — si une clé apparaît dans un diff, la considérer compromise immédiatement → régénérer.
22. **Commentaires: français uniquement, commenter le POURQUOI pas le QUOI.** Obligatoire dans: politiques RLS, fonctions service, .env.example.
23. **CODEMAP.md: enregistrer chaque composant créé OU modifié avant que la tâche soit terminée.**
24. **Auto-amélioration des requêtes casual** — détecter phrasing informel → réécrire en prompt pro → montrer au fondateur → attendre confirmation → exécuter. Rejet → voir scope-rules.md § Rejection handling.

---

## Section 2 — Skill Activation Triggers

| Trigger | Doc à consulter |
|---|---|
| Bug signalé / régression | FIX.md |
| Construction composant/page UI | uidesign.md |
| Construction module IA | docs/RAG.md |
| Route sensible (auth/données/upload) | docs/SECURITY.md |
| Endpoint liste/tableau | docs/PAGINATION.md |
| Nouvelle table ou politique RLS | Rule 12 — tests négatifs avant done |
| Question de scope | docs/PHASES.md MVP boundary |
| État projet incertain | docs/STATUS.md |
| Création OU modification composant | docs/CODEMAP.md — enregistrer avant done |
| Début de session | CLAUDE.md → STATUS.md → PHASES.md |
| Fin de session | STATUS.md + REPORT.md + CODEMAP.md |

---

## Section 3 — Règle de Scope (Non Négociable)

L'agent ne peut PAS construire les éléments suivants sans approbation explicite du fondateur:

✅ **RBAC cabinet / Cabinet Pro multi-collaborateurs — APPROUVÉ le 2026-06-23 (requis encadreur, à construire et démontrer en Phase 3).** N'est plus hors scope : rôles secrétaire + collaborateur, membership par cabinet, permissions par rôle, RLS + tests négatifs par rôle. Schéma conçu en Phase 3 (voir docs/PHASES.md).
❌ Facturation / paiements / abonnements Stripe
❌ Messagerie temps réel (WebSockets)
❌ Application mobile
❌ OCR de documents
❌ Vidéo-consultation
❌ Notaires / Huissiers backend (onglets UI "Coming Soon" uniquement)
❌ Migration FastAPI / LangGraph
❌ Architecture microservices

**Quand une feature utile hors scope est détectée:**
→ NE PAS l'implémenter, NE PAS créer de fichiers pour elle
→ L'enregistrer dans docs/STATUS.md § Future Building avec: ce qui est détecté, effort estimé, dépendances, priorité
→ Continuer la tâche courante

---

## Section 4 — Aperçu Projet

| Champ | Valeur |
|---|---|
| Nom produit | E-Mizen DZ |
| Type | Plateforme LegalTech algérienne |
| Modules | Marketplace avocats · ERP Cabinet · Assistant IA · Portail Client · Admin |
| Encadrant | M. Sofiane KHIAT |
| Institution | Université Abdelhamid Ibn Badis — Mostaganem · Master 2 ISI |
| Deadline soutenance | Fin septembre 2026 |
| Double objectif | Démonstrateur académique PFE + base startup opérationnelle |
| Langue code | Français (commentaires) · Anglais (identifiants) |
| Langue UI | Français · Arabe · Anglais (Darija = chat IA uniquement) |
| Repository | [À remplir — URL GitHub] |
| Déploiement | [À remplir — URL Vercel] |
| Supabase project | [À remplir — URL dashboard] |

### Critères de Succès — Démo Jury
Le MVP est terminé quand ces 4 scénarios passent de bout en bout sans bug:
1. **Découverte (non authentifié):** un visiteur recherche un avocat par wilaya + spécialité et consulte son profil — sans compte, sans login forcé.
2. **Demande de consultation:** un citoyen authentifié envoie une demande avec document joint — l'avocat la reçoit dans son ERP.
3. **Workflow dossier complet:** un avocat fait passer un dossier par les 5 étapes (nouveau → collecte_documents → preparation → procedure_judiciaire → cloture).
4. **Assistant IA multilingue:** l'utilisateur pose une question en darija/français/arabe — l'assistant répond dans la même langue avec citation d'article algérien + disclaimer.

---

## Section 5 — Modèle Utilisateur (Terminologie Stricte)

**Visiteur** (non authentifié) — aucun compte, accès marketplace public uniquement. Jamais bloquer la découverte par un login forcé.

**Citoyen** (authentifié) — ligne dans auth.users + table users. `users.role = 'citoyen'` IMMUABLE. Peut envoyer des demandes, accéder au portail, utiliser l'assistant IA. Peut avoir des demandes vers plusieurs cabinets simultanément.

**Client** (état métier — PAS un rôle) — un citoyen devient client quand un avocat accepte sa demande. Stocké dans la table clients, clé composite (citoyen_id, cabinet_id). `users.role` reste 'citoyen' — ne change JAMAIS. Un citoyen peut être client de plusieurs cabinets.
- ❌ Client ≠ nouveau compte ≠ nouvelle inscription ≠ rôle ≠ deuxième authentification.

**Avocat** — `users.role = 'avocat'`, accès ERP uniquement, vérifié par admin avant activation. cabinet_id obligatoire (défaut = avocat.id). **Inscription avocat: email uniquement, pas d'OAuth** (vérification admin requise).

**Admin** — `users.role = 'admin'` + table admin_roles (super_admin / sous_admin / secrétaire). Bypass RLS via service_role côté serveur uniquement.

Parcours: Visiteur → [envoie demande] → Citoyen → [avocat accepte] → Client → Espace Client.

### Méthodes d'authentification
- Citoyen: Email + Password · Google OAuth · Magic Link
- Avocat: Email + Password uniquement (jamais OAuth)
- Demande timeout: 7 jours sans réponse → statut 'expiré' (Edge Function)

---

## Section 6 — Stack Verrouillé

| Couche | Technologie | Ne jamais remplacer par |
|---|---|---|
| Frontend | Next.js 14 + TypeScript | CRA, Vite standalone |
| Styling | Tailwind CSS (tokens uidesign.md) | CSS modules, styled-components |
| DB | Supabase (PostgreSQL + RLS + Storage + pgvector) | Firebase, PlanetScale, MongoDB |
| Auth | **Supabase Auth** | **Clerk**, NextAuth, Auth0 |
| Recherche vectorielle | pgvector | Pinecone, Weaviate, ChromaDB |
| Embeddings | @xenova/transformers (multilingual-e5-base, 768 dim) | OpenAI embeddings, Cohere |
| LLM | Groq — llama-3.3-70b-versatile | GPT-4, Anthropic (payants) |
| Email | Resend | SendGrid, Mailgun |
| i18n | next-intl (FR/AR/EN) | i18next, react-intl |
| Hosting | Vercel | Netlify, Railway |

**Architecture interdite:** backend séparé (FastAPI/NestJS/Express), ORM (Prisma/Drizzle), state lib (Redux/Zustand), realtime (WebSockets/Pusher), mobile (React Native/Flutter).

---

## Section 7 — Structure des Dossiers

```
e-mizen-dz/
├── CLAUDE.md · FIX.md · uidesign.md · README.md
├── .env.local (⛔) · .env.example · .gitignore
├── next.config.ts · tailwind.config.ts · tsconfig.json · package.json
├── .claude/
│   ├── settings.json · settings.local.json (gitignored)
│   ├── commands/ (fix.md, phase.md, codemap.md, security.md)
│   └── rules/ (code-style.md, security-rules.md, data-rules.md, scope-rules.md)
├── docs/ (PHASES, STATUS, REPORT, SECURITY, RAG, CODEMAP, PAGINATION).md
├── messages/ (fr.json, ar.json, en.json)
├── supabase/ (migrations/ 001→025, policies/, functions/expire-demandes/, seed.sql)
├── tests/rls/ (tests négatifs par table)
├── public/ (fonts/, images/)
└── src/
    ├── app/[locale]/ (marketplace, cabinet, portail, assistant, admin, auth)
    ├── app/api/ (ai/chat, auth/confirm, health)
    ├── components/ (ui, marketplace, cabinet, portail, assistant, admin, shared)
    ├── services/ (Supabase uniquement — un fichier par entité)
    ├── lib/ (supabase/client, supabase/server, groq, resend, logger, embeddings, rag)
    ├── hooks/ (useStream, useAuth, usePagination, useRTL, useDebounce)
    ├── utils/ (haversine, dates, text, language)
    ├── types/ (database, api, index)
    ├── middleware.ts · i18n.ts
```

---

## Section 8 — Variables d'Environnement
Noms uniquement. Valeurs dans .env.local (jamais commité). Détail commenté dans .env.example.
`NEXT_PUBLIC_SUPABASE_URL` · `NEXT_PUBLIC_SUPABASE_ANON_KEY` · `SUPABASE_SERVICE_ROLE_KEY` (serveur uniquement) · `GROQ_API_KEY` · `GROQ_MODEL` · `RESEND_API_KEY` · `RESEND_FROM_EMAIL` · `NEXT_PUBLIC_AUTH_CALLBACK_URL` · `NEXT_PUBLIC_APP_URL` · `NODE_ENV` · `RAG_TOP_K` · `RAG_MIN_RESULTS` · `RAG_SIMILARITY_THRESHOLD` · `RATE_LIMIT_AI_PER_HOUR` · `RATE_LIMIT_UPLOADS_PER_DAY`

---

## Section 9 — Référence RLS (27 tables)
RLS activé sur les 27 tables. service_role bypasse RLS — API routes serveur uniquement. SQL complet: supabase/policies/. Tests négatifs: tests/rls/.
Principes clés:
- **Public SELECT:** wilaya, specialites, cabinets, avocats, avocat_specialites, disponibilites, legal_chunks
- **API route serveur uniquement (INSERT):** clients, dossiers, dossier_etapes, paiements, document_versions, notifications, activity_log
- **Soft delete uniquement (DELETE):** demandes, dossiers, taches, documents, evenements_calendrier (politique DELETE = false partout sauf entités sans soft delete)
- **Isolation absolue:** notes_internes visible par l'avocat du cabinet UNIQUEMENT — jamais le citoyen, aucune exception
- **Admin:** audit_rls + wilaya_search_log visibles admin uniquement; admin_roles visible super_admin uniquement
Voir docs/SECURITY.md pour le modèle de menaces complet.

---

## Section 10 — Protocole de Session

### Début (ordre exact, ne rien coder avant l'étape 5)
1. Lire docs/STATUS.md → phase courante + dernière session + résumé point + prochaine tâche
2. Lire docs/PHASES.md → confirmer la frontière de phase + MVP boundary
3. Vérifier le fichier .claude/rules/ pertinent
4. **Déclarer l'intention:** date, phase, tâche, fichiers à toucher, fichiers à NE PAS toucher, skill activé. Tâche ambiguë → poser UNE question, jamais assumer.
5. Vérifier docs/CODEMAP.md pour composants existants
6. Seulement alors: coder

### Fin (obligatoire)
1. `npm run build` → 0 erreur (ne pas fermer avant propre)
2. Mettre à jour docs/STATUS.md (+ résumé point)
3. Ajouter une entrée à docs/REPORT.md
4. Mettre à jour docs/CODEMAP.md
5. Si politique RLS créée: confirmer tests négatifs écrits

### Rapport de Modification (après chaque fichier édité)
```
#### [chemin/exact/fichier.tsx]
Lignes: N → N
Cause: [cause racine — une phrase]
Avant: [code exact]
Après: [code exact]
```

### Règle absolue de scope fichiers
L'agent touche UNIQUEMENT les fichiers déclarés en Étape 4. Toucher un fichier non déclaré = violation critique. Pas d'exceptions, pas de "juste une petite modif", pas de "c'était nécessaire donc je l'ai fait".

```
⛔ Fichier hors scope détecté
→ STOP immédiat — ne pas écrire une seule ligne
→ Déclarer: Fichier / Lignes / Pourquoi (impossible à éviter) / Risque 🟢🟡🔴 / Avant [NON ÉCRIT] / Après [NON ÉCRIT]
→ Attendre confirmation fondateur → écrire uniquement après "oui" explicite
→ Si refus → trouver une autre approche dans scope
```

**Violation détectée en cours de session:** STOP → reverter → déclarer → attendre instruction → logger dans REPORT.md.

### Situations exceptionnelles
- 🔴 Build cassé en début de session → activer FIX.md avant toute feature
- 🔴 Fichier hors scope nécessaire → STOP, déclarer, attendre permission
- 🔴 Tâche ambiguë/contradictoire avec une règle → UNE question, attendre réponse
- 🔴 Bug hors scope découvert → noter dans STATUS.md § Bugs connus, ne pas corriger silencieusement
- 🔴 Plus de 5 itérations sans converger → STOP, exposer le problème au fondateur

---

*Dernière mise à jour: Session 000 — conception initiale.*
