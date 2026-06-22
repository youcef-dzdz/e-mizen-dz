# RAG.md — Pipeline Assistant IA Juridique

> Consulter avant de toucher: src/app/api/ai/, src/lib/rag.ts, embeddings.ts, groq.ts, src/components/assistant/.

---

## Pipeline
```
Question (FR/AR/EN/Darija)
→ 1. Détection langue dominante (utils/language.ts)
→ 2. Embedding question (@xenova/transformers, multilingual-e5-base, 768 dim)
→ 3. Recherche vectorielle pgvector (similarité cosinus, legal_chunks, actif=true, top K=RAG_TOP_K, seuil=RAG_SIMILARITY_THRESHOLD)
→ 4. Vérif seuil: si résultats < RAG_MIN_RESULTS → réponse "article non trouvé" (jamais inventer)
→ 5. Construction prompt Groq (articles + métadonnées + instructions langue/citation)
→ 6. Appel Groq llama-3.3-70b-versatile (streaming, AbortController, max 1000 tokens, temperature 0.1)
→ 7. Réponse streamée (texte + citations + disclaimer, langue = question)
```

---

## 6 Règles Absolues
1. **Jamais de réponse sans source citée.** ✅ "Selon l'article 7 du Code de la Famille (Loi 84-11)..." ❌ "En Algérie, l'âge légal est 19 ans" (même si vrai — pas de citation = refusé).
2. **Disclaimer juridique obligatoire** à chaque réponse, dans la langue de la réponse. FR/AR/EN. Jamais omis.
3. **Règle de langue:** détecter la langue dominante, répondre dedans. Citation article toujours en langue officielle du texte (arabe pour lois algériennes) + explication dans la langue de l'utilisateur. Mélange darija/français → darija. Mélange arabe/français → arabe. **Ambiguïté totale → arabe (fallback unique).**
4. **Réponse si corpus insuffisant** (résultats < RAG_MIN_RESULTS ou similarité < seuil): FR "Je n'ai pas trouvé d'article pertinent... consultez un avocat." Logger l'absence (question_hash, langue, score_max — jamais le texte). Jamais inventer.
5. **Format citation:** `[Article N — Nom du Code]` + extrait. Si modifié (modifie_par non null): ajouter "(Modifié par [ordonnance])".
6. **Articles inactifs exclus:** `WHERE actif = true` obligatoire avant la recherche vectorielle. Un article désactivé (loi abrogée) ne doit jamais apparaître.

---

## Gestion de l'Historique de Conversation
Max 10 tours (5 Q + 5 R). Au-delà: FIFO (supprimer les plus anciens), garder le message système. **Stockage: mémoire client uniquement (useState) — JAMAIS en base** (données juridiques sensibles, PII, coût). Bouton "Nouvelle conversation" → reset (avec confirmation). Entre sessions: non persisté (voulu).

## Gestion des Pannes Groq
Tentative 1 normale → timeout 30s → retry 1 fois → si échec: arrêter (pas de retry infini). Message: FR "L'assistant est temporairement indisponible. Réessayez dans quelques minutes." / AR équivalent. Logger via logger.ts (type, status, timestamp, user_id hashé — jamais le contenu). /api/health vérifie Groq: `{ groq: 'ok'|'degraded'|'down' }`.

## Modération du Contenu
Question hors droit algérien → ne pas répondre sur le fond, rediriger. Droit étranger → même comportement. Médical/financier/autre → rediriger vers professionnel. Ton: neutre, factuel, jamais d'opinion ni de jugement moral, jamais de réponse différente selon sexe/religion/région. Détresse (violence, urgence): donner l'info juridique + "Si votre situation est urgente, contactez immédiatement un avocat ou les autorités." Ne pas jouer le conseiller psychologique.

---

## Paramètres Techniques
**Embeddings:** Xenova/multilingual-e5-base, 768 dim, Node.js serveur uniquement, lazy loading + cache.
**LLM:** Groq llama-3.3-70b-versatile, temperature 0.1, max 1000 tokens, stream true, timeout 30s, retry 1.
**Requête pgvector (pattern obligatoire):**
```sql
SELECT id, numero_article, titre_article, contenu, source, langue, modifie_par,
  1 - (embedding <=> query_embedding) AS similarity
FROM legal_chunks
WHERE actif = true AND langue = [langue_detectee]
  AND 1 - (embedding <=> query_embedding) >= [RAG_SIMILARITY_THRESHOLD]
ORDER BY similarity DESC LIMIT [RAG_TOP_K];
```
**Env vars:** RAG_TOP_K=5 · RAG_MIN_RESULTS=3 · RAG_SIMILARITY_THRESHOLD=0.7 · GROQ_MODEL=llama-3.3-70b-versatile · RATE_LIMIT_AI_PER_HOUR=20 (limite chat IA). Note: l'upload de documents juridiques (Phase 6 ingestion / pièces jointes) est plafonné séparément par RATE_LIMIT_UPLOADS_PER_DAY=10 — voir docs/SECURITY.md T07.

---

## Endpoint /api/ai/chat
POST, auth Supabase requise, rate limit par user_id. Body: `{ message: string (max 500), conversation_history: Message[] (max 10 tours) }`. Response: SSE stream. Erreurs: 429 rate limit, 400 invalide/trop long, 401 non authentifié, 500 Groq/pipeline. AbortController: annulation immédiate, pas de token consommé.

---

## Corpus Juridique — État
| Source | FR | AR | Articles | Statut |
|---|---|---|---|---|
| Code de la Famille (84-11) | ✅ | ⏳ | ~223 | ⏳ Non ingéré |
| Code Civil | ⏳ | ⏳ | ~1000 | ⏳ |
| Code Pénal | ⏳ | ⏳ | ~500 | ⏳ |
| Procédure Civile | ⏳ | ⏳ | ~1000 | ⏳ |
| Procédure Pénale | ⏳ | ⏳ | ~600 | ⏳ |
Source: avocatalgerien.com § Codes & Lois. À compléter avant Phase 6.

## Script d'Ingestion — Règles
1 chunk = 1 article (pas un paragraphe), "bis" = chunks séparés. Vérifier l'ordre des mots après parsing (zéro tolérance corruption). Abrogés → actif=false. Modifiés → version courante + modifie_par. Embeddings par batch de 50. Vérif post-ingestion: COUNT par source, zéro embedding null.

## Tests Obligatoires Phase 6
Question FR → réponse FR + citation + disclaimer · idem AR · idem darija (citation arabe) · hors corpus → "non trouvé" (jamais inventé) · 21ème requête → 429 · article inactif jamais cité · fermeture onglet pendant streaming → Groq annulé · question > 500 → 400 · réponse < 30s.

---
*Dernière mise à jour: Session 000 — conception initiale.*
