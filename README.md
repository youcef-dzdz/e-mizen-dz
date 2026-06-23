# E-Mizen DZ

> Plateforme LegalTech algérienne combinant marketplace d'avocats vérifiés, ERP cabinet, assistant juridique IA et portail client — sur un seul compte, sans application séparée pour chaque rôle.

Projet de fin d'études (PFE) — Master 2 ISI, Université Abdelhamid Ibn Badis, Mostaganem (2025-2026). Encadré par M. Sofiane KHIAT. Porté en parallèle comme projet de startup réel. Deadline soutenance: fin septembre 2026.

---

## Vision

Un visiteur, même sans compte, peut chercher un avocat compétent près de chez lui sur le Marketplace Public — sans devoir connaître quelqu'un ou passer par le bouche-à-oreille. Il consulte librement des profils vérifiés, et ce n'est qu'au moment d'envoyer une demande de consultation que l'authentification devient obligatoire.

Ce même citoyen devient Client d'un cabinet après acceptation — toujours le même compte, jamais une nouvelle inscription. L'assistant juridique IA répond en arabe, français, anglais ou darija avec citation systématique des articles de loi algérienne.

---

## Architecture Produit

```
Visiteur public
   ↓
Marketplace Public (recherche avocat par wilaya + spécialité)
   ↓
Consultation profil vérifié
   ↓
Demande de consultation  [AUTH REQUIS ICI]
   ↓
Citoyen (même compte du début à la fin)
   ↓
Acceptation cabinet
   ↓
Client (relation métier — pas un rôle, pas un nouveau compte)
   ↓
Espace Client (portail intégré au même compte)
```

`Citoyen` est le rôle technique authentifié (`users.role = 'citoyen'`, immuable). `Client` est un état métier atteint après acceptation par l'avocat — une ligne dans la table `clients` (clé composite citoyen_id + cabinet_id), jamais un nouveau compte ni un nouveau rôle.

---

## Modules

### 🔍 Marketplace Public
Recherche avocat par wilaya (formule Haversine — 69 wilayas), spécialité, expérience, disponibilité. Profils vérifiés avec badge. Accès public permanent — jamais de login forcé sur la découverte.

### 🏢 ERP Cabinet
Espace de travail avocat: clients, dossiers avec workflow 5 étapes, tâches, documents versionnés, calendrier (rendez-vous + audiences + échéances), suivi paiements, notes internes, corbeille avec restauration.

### 👤 Portail Client
Suivi dossier, timeline des étapes, documents partagés, messagerie asynchrone avocat ↔ citoyen, rendez-vous, notifications in-app.

### 🤖 Assistant Juridique IA
RAG (Retrieval Augmented Generation) sur corpus juridique algérien (Code Civil, Code de la Famille, Code Pénal, Procédure Civile, Procédure Pénale). Réponse en FR/AR/EN/Darija dans la langue de la question. Citation d'article obligatoire. Disclaimer juridique systématique. Modèle: Groq llama-3.3-70b-versatile.

### 🛡️ Admin Panel
Vérification avocats (documents + numéro Barreau), gestion utilisateurs, réclamations, statistiques plateforme, gestion corpus juridique IA, équipe admin (super_admin / sous_admin / secrétaire).

---

## Stack Technique

| Composant | Technologie |
|---|---|
| Frontend | Next.js 14 + TypeScript + Tailwind CSS |
| Auth | Supabase Auth (email + Google OAuth + Magic Link) |
| Base de données | Supabase (PostgreSQL + RLS + Storage + pgvector) |
| Embeddings | @xenova/transformers (multilingual-e5-base, 768 dim) |
| LLM | Groq — llama-3.3-70b-versatile |
| Emails | Resend |
| i18n | next-intl (FR + AR + EN) |
| Déploiement | Vercel |

Pas de backend séparé, pas de Clerk, pas de FastAPI/LangGraph/Redis — décisions documentées dans `CLAUDE.md` et `docs/STATUS.md`.

---

## Base de Données

27 tables organisées en catégories: Référentiel · Auth · Marketplace · Relation métier · ERP Cabinet · Documents · Communication · Calendrier · Admin & Sécurité · Assistant IA · Analytics.

Migrations numérotées: `supabase/migrations/001` → `025`. RLS (Row Level Security) activé sur toutes les tables. Tests négatifs RLS: `tests/rls/`.

---

## État d'Avancement

| Phase | Module | Statut |
|---|---|---|
| 0 | Foundation & Setup | ⏳ À commencer |
| 1 | Avocat Profile & Cabinet | ⏳ À commencer |
| 2 | Marketplace Public | ⏳ À commencer |
| 3 | ERP Cabinet | ⏳ À commencer |
| 4 | Portail Client | ⏳ À commencer |
| 5 | Admin Panel | ⏳ À commencer |
| 6 | Assistant IA | ⏳ À commencer |
| 7 | Intégration + QA + Demo | ⏳ À commencer |

---

## Critères de Succès — Démo Jury

Le MVP est considéré terminé quand ces 4 scénarios passent de bout en bout sans bug:

1. Un visiteur trouve un avocat par wilaya + spécialité sans créer de compte
2. Un citoyen envoie une demande de consultation avec document joint
3. Un avocat fait passer un dossier par les 5 étapes du workflow complet
4. L'assistant IA répond en FR/AR/Darija avec citation d'article de loi algérienne

---

## Installation

### Prérequis
Node.js 18+ · Compte Supabase (gratuit) · Compte Vercel (gratuit) · Clé API Groq (gratuit) · Compte Resend (gratuit).

### Setup

```bash
git clone https://github.com/[username]/e-mizen-dz.git
cd e-mizen-dz
npm install
cp .env.example .env.local   # remplir les valeurs
# Exécuter les migrations 001 → 025 dans l'ordre (Supabase Dashboard → SQL Editor)
npm run dev                  # http://localhost:3000
npm run build                # doit passer à 0 erreur
```

---

## Comptes Démo (Phase 7)
Super Admin: admin@demo.com · Avocat: avocat@demo.com · Citoyen: citoyen@demo.com

---

## Périmètre MVP

**Inclus:** Marketplace avocat · Demande de consultation avec documents · ERP Cabinet complet · Assistant IA · Portail Client · Admin Panel.

**Exclu (post-graduation):** Cabinet Pro / RBAC · Facturation Stripe · Messagerie temps réel (WebSockets) · Application mobile · Notaires/Huissiers · OCR · Vidéo-consultation.

---

## Documentation Technique

| Document | Description |
|---|---|
| `CLAUDE.md` | Mémoire agent — règles, stack, protocoles |
| `FIX.md` | Protocole correction bugs |
| `uidesign.md` | Système de design UI |
| `docs/PHASES.md` | Plan de build 8 phases |
| `docs/STATUS.md` | État courant du projet |
| `docs/SECURITY.md` | Modèle de menaces + mitigations |
| `docs/RAG.md` | Specs pipeline IA |
| `docs/CODEMAP.md` | Registre composants (démo jury) |
| `docs/REPORT.md` | Journal d'audit sessions |
| `docs/PAGINATION.md` | Guide pagination |

---

## Compétiteur Principal

avocatalgerien.com — annuaire statique WordPress, sans vérification, sans ERP, sans IA, sans portail client. Notre différenciateur: vérification avocat rigoureuse + ERP complet + IA multilingue + architecture scalable.

---

*Université Abdelhamid Ibn Badis — Mostaganem · Master 2 ISI · 2025-2026 · Encadrant: M. Sofiane KHIAT*
