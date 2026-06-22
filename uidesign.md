# uidesign.md — Système de Design E-Mizen DZ

> Consulter avant de construire tout composant UI. Source de vérité pour couleurs, typographie, spacing, composants.
> Rule 8: aucune valeur visuelle hardcodée — tokens uniquement.

---

## 1. Philosophie
Chaleureux, humain, professionnel. Inspiré de Claude.ai/Anthropic. Jamais froid, jamais sombre, jamais générique.

## 2. Logo
Icône: silhouette de Thémis (déesse de la justice) en espresso, balance & glaive en or. Wordmark: **"E-Mizen"** bold espresso + **"DZ"** en or. 3 fichiers: logo principal, version fond sombre, favicon.

## 3. Palette
```
Espresso  #3B1E03  → boutons, liens, accents principaux
Or        #C4902A  → "DZ", citations de loi, éléments premium
Crème     #FAF9F7  → fond de page
Beige     #F2EDE6  → fond sidebar
Blanc     #FFFFFF  → cards, modals, inputs
```
Sémantiques: Success #2A7A4B / #D1FAF0 · Warning #B45309 / #FEF3E2 · Error #B91C1C / #FEE2E2 · Info tons espresso.
Spéciaux: bulle user #EDE8DF · bulle IA #FFFFFF · disclaimer juridique fond #FFFBEB · tag citation tons espresso.
Gris chauds: texte secondaire #6B6660 / #9A9490 · désactivé #C9C3BB · bordures #E8E3DC.

## 4. Typographie
Latin (FR/EN): **Inter** · Arabe (AR): **Noto Sans Arabic**.
Échelle: Hero 48px bold · Display 36px · H1 28px · H2 22px · H3 18px semi · H4 15px semi · Body LG 15px · Body 13px · Body SM 12px · Label 12px med · Caption 11px · Micro 10px med uppercase.
RTL: langue arabe → dir="rtl" + font Noto Sans Arabic + coins de bulles inversés.

## 5. Espacement (grille 4px)
4 · 8 · 12 · 16 (card) · 20 · 24 (page) · 32 (sections) · 40 (mobile) · 56 (hero).

## 6. Border Radius
6px badges · 8px boutons/inputs · 10px cards · 14px modals/bulles · full pills/avatars.

## 7. Ombres
Card repos (très subtile) · Card hover (légèrement visible) · Modal (forte, focus) · Focus ring (espresso sur inputs).

## 8. Composants
**Boutons (5):** Primary (espresso/crème) · Secondary (blanc/bordure) · Ghost (beige/espresso) · Gold (or/crème) · Danger (rouge). Tailles sm/md/lg.
**Inputs:** fond blanc, bordure chaude · focus espresso + ring · error bordure rouge + fond rouge clair.
**Badges (6):** Primary, Gold, Success, Warning, Error, Neutral — tous pill.
**Cards:** blanc, bordure subtile, radius 10px, shadow hover.
**Sidebar:** beige #F2EDE6, item actif bordure gauche espresso, labels uppercase gris.
**Bulles chat:** user beige aligné droite · IA blanc aligné gauche.
**Tag citation:** pill tons espresso. **Disclaimer:** fond jaune, bordure/texte ambre.
**KPI cards:** blanc, label gris + valeur large + trend vert/ambre.

## 9. Responsive
Mobile < 768px → bottom nav · Tablet 768-1024 → sidebar icônes (60px) · Desktop > 1024 → sidebar complète (200px).

## 10. Dark Mode
Réservé **post-graduation** — ne pas implémenter pendant le MVP.

## 11. Tailwind Config
Mapper tous les tokens dans tailwind.config.ts (espresso/creme/or/beige + sémantiques) → classes `bg-espresso`, `text-or`, etc. Jamais `text-[#3B1E03]`.

## 12. Pages — Référence Rapide
Fond par défaut Crème. Routes sous `/[locale]/`: marketplace, cabinet, portail, assistant, admin, auth.

## 13. Règles Non Négociables
1. Jamais hardcoder une couleur — tokens uniquement · 2. Jamais #000000 pur — utiliser #1A1A1A · 3. Jamais de gris froids — tokens chauds · 4. Sidebar toujours #F2EDE6 · 5. Bulles user toujours #EDE8DF · 6. Bouton primary toujours #3B1E03 · 7. "DZ"/premium toujours #C4902A · 8. Focus ring toujours shadow-focus · 9. Dark mode post-graduation · 10. Arabe → font-arabic + dir="rtl" · 11. Règle logo fond clair/sombre · 12. Nouvelle valeur → l'ajouter ici AVANT de l'utiliser.

---

## Additions Verrouillées (9)

### A1. Skeleton Loaders
Base bg #E8E3DC → shimmer → #F2EDE6. Card = mêmes dimensions, 3 lignes. Texte: h 12px, radius 4px, largeurs 100%/75%/50%. Avatar: cercle même taille. Animation pulse 1.5s ease-in-out infinite.

### A2. États Form (compléments)
Disabled: bg #F2EDE6, texte #C9C3BB, cursor not-allowed, bordure #E8E3DC (jamais opacity 0.5 — casse le rendu arabe). Success: bordure #2A7A4B + bg #F0FDF4. Loading: bordure #D9C9B8 + spinner à droite.

### A3. Navbar Active States
Marketplace public: texte #3B1E03 + weight 600 + underline 2px #C4902A, fond transparent. Mobile bottom nav actif: icône #3B1E03 + label weight 600 + dot #C4902A au-dessus.

### A4. Workflow Steps (5 étapes dossier)
Complétée: cercle bg #3B1E03 + check #FAF9F7, connecteur plein #3B1E03. Courante: cercle bordure 2px #3B1E03 + bg blanc + numéro #3B1E03 + pulse subtil + label weight 600. Future: cercle bordure 2px #E8E3DC + numéro #C9C3BB, connecteur #E8E3DC, label #9A9490. RTL: connecteurs miroir horizontal.

### A5. Toasts
Position top-right desktop / top-center mobile. Largeur 320px / 100%-32px. Z-index 50. Variants: success bg #D1FAF0 + border-left 4px #2A7A4B · error #FEE2E2 / #B91C1C · warning #FEF3E2 / #B45309 · info #F0E8DF / #3B1E03. Enter slide-in 200ms, exit fade 150ms. Durée 4s succès/info, persistant erreur/warning. RTL: top-left + slide depuis gauche + accent border-right.

### A6. Modals
Overlay rgba(0,0,0,0.4). Container blanc, radius 14px, shadow-modal, max-width 480/640/800px, padding 24px. Header titre H3 + close. Body padding-top 16px, overflow-y auto, max-height calc(100vh-200px). Footer border-top #E8E3DC, boutons cancel (gauche) + confirm (droite). RTL: ordre miroir. Enter scale 0.95→1 + fade 150ms. Confirmation destructive: confirm danger + titre #B91C1C.

### A7. Verification Badge
Vérifié: shield + "Vérifié", bg #D1FAF0 / texte #047857 / bordure #2A7A4B. En attente: clock + "En attente" #FEF3E2/#B45309. Suspendu: warning + "Suspendu" #FEE2E2/#B91C1C. Taille 12px, padding 3px 8px, radius full. Placement: top-right de la card, à côté du nom sur le profil, jamais dans l'avatar.

### A8. Empty States
Container centré padding 48px 24px. Illustration: SVG simple #D9C9B8, 64×64px, jamais photographique. Titre H3 #6B6660. Sous-titre body #9A9490, max-width 280px. CTA seulement si action disponible. Espacements 16/8/24px.

### A9. RTL Expansion
Sidebar: border-right→left, padding-left→right. Cards: text-align right, flex-row→row-reverse. Boutons: icône gauche→droite. Form: labels + erreurs alignés droite, input RTL. Toast: top-left, slide gauche, accent border-right.

---
*Dernière mise à jour: Session 000 — conception initiale.*
