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
*[Vide — à remplir au fur et à mesure]*

## API Routes (src/app/api/)
*[Vide — à remplir au fur et à mesure]*

## Services (src/services/)
*[Vide — à remplir au fur et à mesure]*

---
*Dernière mise à jour: Session 000 — template initial.*
