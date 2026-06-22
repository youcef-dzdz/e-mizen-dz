# SECURITY.md — Modèle de Menaces E-Mizen DZ

> Consulter avant de construire toute route touchant: auth, données utilisateur, upload, paiements, RLS, API externe.

---

## Périmètre de Sécurité
**On protège:** données personnelles citoyens, données cabinet, notes internes avocat (jamais visibles citoyen), documents uploadés, intégrité corpus juridique, comptes (usurpation), vérification avocats (crédibilité marketplace).
**On ne défend PAS (hors scope MVP):** attaques nation-state, DDoS à grande échelle (géré par Vercel/Supabase), forensics avancée, conformité RGPD formelle (post-graduation).

---

## Menaces par Sévérité

### 🔴 CRITIQUE
**T01 — Bypass RLS.** Vecteurs: service_role côté client, politique manquante, politique correcte SELECT mais absente INSERT. Mitigations: Rule 11 (service_role serveur uniquement), Rule 12 (test négatif par opération par table), RLS sur les 27 tables, table audit_rls (log auto des tentatives bloquées).

**T02 — Injection SQL.** Mitigations: Supabase JS client uniquement (paramétré), zéro concaténation SQL, validation input serveur, rpc() paramétré.

**T03 — Faux Avocat.** Mitigations: statut initial en_attente (zéro accès ERP), documents obligatoires (CNI + carte pro + attestation Barreau + selfie CNI) dans verification_documents (bucket privé), admin vérifie le numéro Barreau, RLS bloque l'ERP si statut != 'vérifié', suspension possible.

**T04 — Accès non autorisé aux documents.** Mitigations: colonne visibilite (avocat/client/les_deux), RLS (citoyen voit uniquement visibilite IN client/les_deux), Storage bucket privé + URLs signées (expiration 1h), test négatif citoyen A vs documents citoyen B.

### 🟡 MOYEN
**T05 — XSS.** Next.js échappe le HTML dans JSX, sanitisation input serveur, jamais dangerouslySetInnerHTML sans DOMPurify, CSP headers.

**T06 — Abus assistant IA (Groq).** Rate limiting per-user (RATE_LIMIT_AI_PER_HOUR=20), AbortController, HTTP 429 avec message FR/AR.

**T07 — Abus upload.** Validation MIME serveur (PDF/JPG/PNG/DOCX), max 10MB, RATE_LIMIT_UPLOADS_PER_DAY=10, fichiers jamais exécutables, pas de path traversal.

**T08 — Énumération de comptes.** Messages auth génériques ("Email ou mot de passe incorrect"), même temps de réponse. **Email confirmation obligatoire avant premier login** · Magic Link expire après 1h · Google OAuth: email vérifié par Google.

**T09 — CSRF.** Vérification Origin header, JWT expiration courte, cookies SameSite=Strict, confirmation UI sur actions sensibles.

**T10 — Accès admin non autorisé.** Middleware vérifie role='admin' sur /admin/*, table admin_roles (permissions par action), double vérification middleware + service_role.

### 🟢 FAIBLE
**T11 — Données sensibles dans les logs.** logger.ts central, ne log jamais passwords/tokens/contenu messages/descriptions dossiers.
**T12 — Secrets dans le code.** Rule 21, .gitignore exclut .env.local, clé dans un diff → compromise → régénérer.
**T13 — Session hijacking.** JWT expiration, HTTPS prod (Vercel), cookies HttpOnly+Secure+SameSite=Strict.
**T14 — Spam demandes.** Max 5 demandes en_attente simultanées par citoyen, rate limiting POST /api/demandes, expiration 7 jours libère le quota.
**T15 — Manipulation statut dossier.** RLS UPDATE interdit pour citoyens, transitions via API route serveur avec validation, jamais de mise à jour directe depuis le portail.

---

## Règle Storage — Non Négociable
Tous les buckets Supabase Storage sont **PRIVÉS**. Seules exceptions publiques: avatars avocats + logos cabinets (profils publics). Tout autre fichier (documents juridiques, CNI, cartes pro, pièces de dossier): bucket privé, URL signée expiration max 1h, jamais d'URL permanente, accès vérifié côté serveur avant génération.

---

## Protection par Couche
1. **Client** — validation UX + sanitisation affichage (aucune logique sécurité critique)
2. **Middleware** — auth + vérification rôle + rate limiting basique
3. **API Routes** — validation complète + permissions métier + service_role si nécessaire + logger
4. **Supabase RLS** — dernière ligne de défense, politique par table par opération, audit via audit_rls
5. **Storage** — bucket privé, URLs signées, expiration 1h, validation type

---

## Contrôle de Saisie, Cas Vides, Messages

### Validation Input (Rule 20)
Client = UX (feedback immédiat, onBlur, submit désactivé si invalide). Serveur = sécurité (revalider tout, HTTP 400 structuré, logger sans données sensibles).
| Champ | Règle | Message FR |
|---|---|---|
| Email | RFC 5322 | "Adresse email invalide" |
| Téléphone | +213XXXXXXXXX / 0XXXXXXXXX | "Numéro invalide (format algérien)" |
| Numéro Barreau | numérique 4-8 | "Numéro de Barreau invalide" |
| Mot de passe | min 8, 1 majuscule, 1 chiffre | "Mot de passe trop faible" |
| Montant DZD | > 0, max 10M | "Montant invalide" |
| Date événement | pas dans le passé | "La date ne peut pas être dans le passé" |
| Upload | PDF/JPG/PNG/DOCX, max 10MB | "Format non supporté" / "Fichier trop volumineux (max 10MB)" |
| Description demande | min 50, max 2000 | "Description trop courte (min 50 caractères)" |

### États de Chargement — Obligatoires
Toute liste/donnée asynchrone: skeleton (jamais spinner seul, jamais page blanche). Listes → skeleton cards · Tableau admin → skeleton rows · Messages → skeleton bubbles · Calendrier → skeleton events · IA streaming → curseur clignotant + texte progressif. Le skeleton évite le layout shift.

### Cas Vides (exemples)
Marketplace 0 résultats → "Aucun avocat trouvé. Élargissez vos critères." + bouton réinitialiser · Aucun dossier → "Vous n'avez pas encore de dossiers" · Corbeille vide → "La corbeille est vide ✅" · RAG 0 résultats → "Je n'ai pas trouvé d'article pertinent. Consultez un avocat." (jamais inventer).

### Messages — Règle
Type (✅/❌/⚠️/ℹ️) + texte court actionnable + langue de l'utilisateur. Toast 4s succès, persistant erreur. **Jamais exposer l'erreur technique** ("PostgrestError..." → "Une erreur est survenue. Réessayez."). Tous les messages dans fr/ar/en.json, clé `messages.[action].[entité].[résultat]`.

### Catalogue CRUD (extraits)
**CREATE:** Créer dossier → "Dossier créé avec succès" · Envoyer demande → "Votre demande a été envoyée à l'avocat" · Upload → "Document uploadé avec succès" / "Upload échoué. Vérifiez format et taille."
**UPDATE:** Changer étape → "Étape mise à jour: [ancienne] → [nouvelle]" · Accepter demande → "Demande acceptée. Dossier créé." · Vérifier avocat → "Avocat vérifié. Badge activé." · Marquer message lu → (silencieux).
**DELETE (soft):** Supprimer dossier → "Dossier déplacé vers la corbeille. Restaurable sous 30 jours." · Vider corbeille → "Corbeille vidée. Ces éléments ne peuvent plus être restaurés."
**Confirmations obligatoires:** supprimer dossier, vider corbeille, supprimer compte (taper DELETE), désactiver avocat, supprimer article loi.

### Search / Filter / Réinitialiser
Recherche debounce 300ms (useDebounce.ts) · filtres immédiats · pagination reset page 1 · état dans l'URL (`?wilaya=oran&specialite=penal&page=1`). Bouton réinitialiser visible uniquement si filtre actif → reset tout + vide recherche + page 1 + URL nettoyée. Filtres actifs en tags supprimables individuellement: `[Oran ×] [Droit pénal ×]`. Badge compteur "Filtres (3)".

---

## Checklist Avant Déploiement
- [ ] build 0 erreur · RLS sur nouvelles tables · tests négatifs RLS passants
- [ ] aucune clé API dans le code · .env.local absent du repo
- [ ] URLs Storage signées + expiration · rate limiting sur nouveaux endpoints
- [ ] validation serveur sur nouveaux formulaires · erreurs génériques côté client · trigger audit_rls actif

---

## Avantage Compétitif Sécurité
avocatalgerien.com n'a aucun système de vérification. Notre pipeline (documents + numéro Barreau + admin review) est la fondation de la crédibilité de la marketplace — il doit rester rigoureux et non contournable.

---
*Dernière mise à jour: Session 000 — conception initiale.*
