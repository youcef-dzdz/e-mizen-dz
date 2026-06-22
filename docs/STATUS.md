# STATUS.md — État du Projet E-Mizen DZ

> Mis à jour à chaque fin de session. Lu en premier à chaque session (Étape 1).
> Ne jamais résumer ou tronquer — toujours ajouter, jamais écraser.

---

## Dernière Session
Date: [À remplir à la première session]
Ce qui a été fait: Projet initialisé — aucun code écrit (conception complète des docs)
Prochaine tâche: Phase 0 — 0.1 Project Setup
Résumé point (reprise): aucune — Phase 0 non commencée

---

## Phase Courante
**Phase 0 — Foundation & Setup** · Statut: ⏳ À commencer · Progression: 0%
Prochaine tâche immédiate: créer repo GitHub → init Next.js 14 + TS → créer projet Supabase + pgvector

---

## État des Phases
| Phase | Nom | Statut |
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

## Checklist Environnement
À vérifier en début de session si environnement non confirmé:
- [ ] Supabase project accessible — [URL dashboard à remplir]
- [ ] Vercel deployment actif — [URL à remplir]
- [ ] Variables .env.local présentes et complètes
- [ ] `npm run dev` démarre sans erreur
- [ ] /api/health retourne 200
- [ ] Supabase Auth fonctionne (test login)
- [ ] pgvector activée (Phase 6+ uniquement)

Statut actuel: ⚠️ Non vérifié — projet non créé

---

## Décisions Verrouillées
**Stack:** Next.js 14 + TS + Tailwind · **Supabase Auth (PAS Clerk — définitif)** · Supabase (PostgreSQL + RLS + Storage + pgvector) · Groq llama-3.3-70b-versatile · @xenova/transformers (multilingual-e5-base, 768 dim) · Resend · Vercel · next-intl (FR+AR+EN, pas de dz.json).
**Architecture:** pas de backend séparé (API routes Next.js) · services/ = Supabase uniquement · lib/ = clients externes · RTL Arabic via useRTL + RTLProvider.
**Modèle utilisateur:** Visiteur / Citoyen (role immuable) / Client (état métier, jamais un rôle) / Avocat / Admin (+ admin_roles).
**Auth methods:** Email+Password, Google OAuth, Magic Link · Avocat = email uniquement.
**Tables:** 27 — voir docs/PHASES.md pour l'ordre de migration.
**Compétiteur:** avocatalgerien.com (annuaire WordPress, pas de vérification/ERP/IA) — avantage intact.

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

## Future Building — Backlog
| # | Feature | Effort | Dépendances | Priorité |
|---|---|---|---|---|
| 1 | Graphify MCP | Faible | Phase 2+ | Moyenne |
| 2 | Impersonation admin | Moyen | Phase 5 | Faible |
| 3 | Notifications WebSockets | Élevé | Phase 4 | Haute |
| 4 | Cabinet Pro / RBAC | Très élevé | Phase 3 | Haute |
| 5 | Facturation Stripe | Très élevé | Cabinet Pro | Moyenne |
| 6 | OCR documents | Moyen | Phase 3 | Moyenne |
| 7 | Notaires / Huissiers | Très élevé | Phase 2 | Haute |
| 8 | Application mobile | Très élevé | MVP complet | Haute |
| 9 | Migration FastAPI + LangGraph | Très élevé | MVP complet | Faible |

---

## Renommage et Historique
Nom produit: E-Mizen DZ (définitif). Ancien projet de référence: LegalBot DZ — **base de code différente, zéro héritage**. Repository / Vercel / Supabase: à créer.

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

[Sessions suivantes ajoutées ici par l'agent]
