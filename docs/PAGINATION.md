# PAGINATION.md — Guide de Pagination E-Mizen DZ

> Consulter avant de construire tout endpoint retournant une liste (Rule 19).

---

## Le Problème
Retourner toutes les lignes en une réponse = un pic de trafic suffit à faire tomber le serveur. Avec 100 000 lignes, chaque requête charge tout en mémoire, sérialise 100K objets, envoie des mégaoctets. Aucune erreur n'est levée — l'app devient juste de plus en plus lente. **Le fix: retourner une tranche par requête, pas tout.**

---

## Deux Types

### Offset Pagination
Params `page` + `limit`. **Pour:** dashboards, listes admin, listes standard.
- ✅ Simple, saut à n'importe quelle page (page 7), navigation facile
- ⚠️ Les pages se décalent si données insérées · perf dégradée à très haut offset (scan de 50 000 lignes pour les sauter)

### Cursor Pagination
On passe l'ID du dernier élément reçu. **Pour:** infinite scroll, feeds temps réel (notifications, messages).
- ✅ Stable même avec insertions · perf constante sur grandes tables
- ⚠️ Pas de saut à une page précise · légèrement plus complexe

**Règle:** offset pour dashboards/listes standard, cursor pour infinite scroll/feeds.

---

## Deux Règles Toujours Respectées
1. **Toujours un limit par défaut** — si le client n'envoie rien, on choisit (20). Jamais d'endpoint qui retourne tout.
2. **Toujours un limit max** — même si le client envoie limit=10000, on cap côté serveur (100). Le client ne contrôle jamais la charge serveur.

---

## Forme de la Réponse
Toujours un objet `meta` à côté de `data`:
```json
{ "data": [...], "meta": { "total": 248, "page": 1, "totalPages": 13, "hasNextPage": true } }
```

---

## Index Base de Données
Pagination sans index sur la colonne `ORDER BY` = full table scan à chaque requête. **Index obligatoire** sur la colonne de tri.

---

## Bonnes Pratiques
- Limit par défaut 20 · max 100 (validation backend, Rule 20)
- `count` et `data` en parallèle (Promise.all), jamais deux requêtes séquentielles
- Toujours retourner `meta` (total, page, totalPages, hasNextPage)
- Index sur la colonne ORDER BY
- Offset pour dashboards, cursor pour feeds
- Valider côté backend — jamais faire confiance au client

---

## Référence Rapide
| Type | Pour | Saut page | Stable insert | Perf à l'échelle |
|---|---|---|---|---|
| Offset | dashboards, listes | ✅ | ⚠️ peut décaler | ⚠️ dégrade haut offset |
| Cursor | infinite scroll, feeds | ❌ | ✅ | ✅ constant |

Le hook partagé `src/hooks/usePagination.ts` centralise la logique offset + cursor — tout composant liste l'utilise. L'enregistrer dans CODEMAP.md à la création.

---
*Dernière mise à jour: Session 000 — conception initiale.*
