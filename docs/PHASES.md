# PHASES.md — Plan de Build E-Mizen DZ

> Lu à chaque début de session (Étape 2). Définit l'ordre de build, les tâches par phase, et la MVP boundary.
> Ordre dicté par les dépendances FK (Foreign Key) entre les 27 tables.

---

## Phase 0 — Foundation & Setup
**Objectif:** projet fonctionnel, auth opérationnelle, base initialisée. **Statut:** ⏳ À commencer.
**Tables:** users, wilaya, specialites.
- Setup: repo GitHub, Next.js 14 + TS, Tailwind + tokens uidesign.md, tous les fichiers projet, .gitignore
- Supabase: créer projet, activer pgvector, migrations 001-002-025 (users, wilaya+seed 58, specialites+seed)
- Auth: Email+Password, Google OAuth, Magic Link, confirmation email obligatoire
- Auth flow: login, signup, callback OAuth, middleware, useAuth.ts, redirection par rôle
- i18n: next-intl, i18n.ts, fr/ar/en.json, RTLProvider, LanguageSwitcher
- Layout: layout racine, navbar, footer, landing, ErrorBoundary, /api/health
- **Validation:** build 0 erreur, auth fonctionne, switch FR/AR/EN, RTL Arabic OK, /api/health 200

## Phase 1 — Avocat Profile & Cabinet
**Objectif:** un avocat s'inscrit, crée son profil, apparaît dans le système. **Dépend de:** Phase 0.
**Tables:** cabinets, avocats, avocat_specialites, disponibilites.
- Migrations + RLS policies + tests négatifs pour les 4 tables
- Inscription avocat (email uniquement), upload documents vérification (bucket privé), statut en_attente
- Profil public /marketplace/[avocatId] — bio, spécialités, wilaya, badge vérification, disponibilités
- Paramètres cabinet: profil public, spécialités, disponibilités, tarifs (internes)
- **Validation:** build 0 erreur, avocat s'inscrit, profil public visible sans login, CODEMAP à jour

## Phase 2 — Marketplace Public
**Objectif:** un visiteur trouve un avocat, un citoyen envoie une demande. **Dépend de:** Phase 1.
**Tables:** demandes, wilaya_search_log.
- Migrations + RLS + tests négatifs
- Recherche: Haversine par wilaya, filtres (spécialité, expérience, disponibilité), pagination offset, log recherches
- Composants: AvocatCard, SearchFilters, WilayaSelector
- Demande consultation: formulaire (auth requis), redirect login si visiteur, upload documents, email avocat (Resend), statut en_attente
- Edge Function: expire-demandes après 7 jours
- **Validation:** build 0 erreur, critères de succès #1 et #2 validés

## Phase 3 — ERP Cabinet
**Objectif:** l'avocat gère clients, dossiers, tâches, documents, calendrier. **Dépend de:** Phase 2. *(plus grande phase)*
**Tables:** clients, dossiers, dossier_etapes, taches, notes_internes, tags_dossier, paiements, documents, document_versions, evenements_calendrier, activity_log.
- Migrations + RLS + tests négatifs (toutes ces tables)
- **RBAC cabinet (requis encadreur, approuvé 2026-06-23):** membres du cabinet (rôles secrétaire + collaborateur), appartenance par cabinet (membership), vérification des permissions par rôle, politiques RLS isolant ce que chaque rôle peut voir/faire, tests négatifs par rôle (chaque rôle bloqué hors de son périmètre). Schéma détaillé conçu en Phase 3, pas avant.
- Demandes entrantes: accepter → crée client + dossier; rejeter + motif; email citoyen
- Clients: liste, fiche, historique dossiers (pagination offset)
- Dossiers: créer, workflow 5 étapes visuel, historique transitions (dossier_etapes), tags, notes internes, pagination cursor, soft delete + corbeille
- Tâches: créer/modifier/terminer, échéances, soft delete
- Documents: upload, versionnement, visibilité avocat/client/les_deux, soft delete + restauration
- Calendrier: rendez_vous + audiences + échéances, email rappel
- Paiements: enregistrer, historique par dossier
- Dashboard ERP: dossiers actifs, tâches en retard, demandes en attente, activity log
- **Validation:** build 0 erreur, critère de succès #3 (workflow 5 étapes) validé

## Phase 4 — Portail Client
**Objectif:** le citoyen suit son dossier, communique, accède aux documents. **Dépend de:** Phase 3.
**Tables:** messages_dossier, notifications.
- Migrations + RLS + tests négatifs
- Espace Client: mes dossiers (lecture seule), timeline (dossier_etapes), documents partagés, rendez-vous
- Messagerie asynchrone par dossier (citoyen ↔ avocat), badge non lus
- Notifications in-app: demande acceptée/rejetée, nouveau message, dossier mis à jour, rendez-vous
- **Validation:** build 0 erreur, citoyen voit son dossier, messagerie bidirectionnelle, notifications

## Phase 5 — Admin Panel
**Objectif:** l'admin vérifie les avocats, gère réclamations et statistiques. **Dépend de:** Phase 4.
**Tables:** reclamations, audit_rls, verification_documents, admin_roles.
- Migrations + RLS + tests négatifs + trigger Postgres audit_rls
- Vérification avocats: liste en attente, documents soumis (CNI, carte pro, attestation Barreau, selfie), cross-check numéro Barreau, approuver/rejeter/suspendre, statut en_attente_documents
- Gestion utilisateurs: liste, filtres rôle, bloquer/débloquer compte
- Gestion réclamations: liste par statut, traiter, résolution + notification
- Statistiques: avocats vérifiés/en attente, demandes par wilaya, dossiers actifs/clôturés, spécialités recherchées
- Gestion corpus juridique: ajouter/désactiver/supprimer article (legal_chunks)
- Équipe admin: créer sous-admin/secrétaire (3 rôles fixes, permissions hardcodées)
- Audit RLS: affichage tentatives bloquées
- **Validation:** build 0 erreur, admin vérifie un avocat qui apparaît ensuite dans le marketplace

## Phase 6 — Assistant IA Juridique
**Objectif:** répondre en FR/AR/Darija avec citation d'article. **Dépend de:** Phase 0 (pgvector). *Indépendant des autres modules.*
**Tables:** legal_chunks.
- ⚠️ **Bloqueur connu:** PDFs Arabic des 5 codes juridiques pas encore trouvés (voir STATUS.md § À faire avant Phase 6)
- Migration legal_chunks (pgvector) + index vectoriel + RLS (public SELECT)
- Ingestion corpus: 5 codes, embeddings @xenova/transformers, deux lignes par article (FR + AR), articles abrogés → actif=false, "bis" → chunks séparés
- Pipeline RAG: embeddings.ts, rag.ts, seuil similarité, RAG_MIN_RESULTS, extraction source+numero_article
- Endpoint streaming /api/ai/chat: Groq, AbortController, rate limit, validation input, détection langue
- Interface chat: ChatWindow, ChatMessage + citation, ChatInput, LegalDisclaimer, useStream
- **Validation:** build 0 erreur, critère de succès #4 (FR/AR/Darija + citation) validé

## Phase 7 — Intégration + QA + Demo Polish
**Objectif:** parcours complet sans bug, 4 critères validés, démo prête. **Dépend de:** Phases 0→6. **Deadline:** fin septembre 2026.
- Tests RLS complets: SELECT/INSERT/UPDATE/DELETE par table, aucune fuite entre cabinets, citoyen ne voit jamais notes_internes
- Parcours jury complet de bout en bout (les 4 critères de succès)
- Performance: toutes listes paginées, < 2s, aucune erreur console, mobile responsive basique, RTL propre
- Seed démo: 3 avocats vérifiés, 2 citoyens, 5 dossiers à différentes étapes; comptes demo par rôle
- Déploiement Vercel production propre

---

## MVP Boundary — Non Négociable
Ces features n'existent PAS dans les phases ci-dessus. Toute implémentation nécessite approbation fondateur. Backlog: docs/STATUS.md § Future Building.

❌ Facturation / Stripe · ❌ Messagerie temps réel (WebSockets) · ❌ Application mobile · ❌ OCR documents · ❌ Vidéo-consultation · ❌ Notaires/Huissiers backend (UI Coming Soon uniquement) · ❌ Migration FastAPI/LangGraph · ❌ Microservices

> ℹ️ **RBAC cabinet (multi-collaborateurs)** était ici — désormais **approuvé et in-scope Phase 3** (requis encadreur, 2026-06-23). Voir Phase 3 ci-dessus.

**Décision testing:** pas de tests automatisés feature pour le MVP — QA manuelle + tests négatifs RLS uniquement. Tests automatisés complets = post-graduation.

---
*Dernière mise à jour: Session 000 — conception initiale.*
