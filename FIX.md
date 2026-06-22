# FIX.md — Bug Fix Protocol

**Stack:** Next.js 14 + TypeScript + Tailwind CSS + Supabase (Auth, PostgreSQL, RLS, Storage, pgvector) + Groq (llama-3.3-70b-versatile) + @xenova/transformers (multilingual-e5-base, 768 dim) + Resend + next-intl (FR/AR/EN) + Vercel

## Activation
Activate this protocol when:
- A bug is reported by the founder or detected during `npm run build`
- A runtime error appears in Vercel logs or Supabase logs
- A failing RLS (Row Level Security) negative test is detected
- An API route returns an unexpected status code

---

## P0 Incident Protocol (activate immediately — before any other step)

P0 triggers:
- `SUPABASE_SERVICE_ROLE_KEY` found in any file under `src/`
- RLS bypass confirmed (a user accesses another user's data)
- Auth broken (no user can log in)
- Data leak detected in an API response

On P0:
1. STOP — do not write any code
2. Do not commit — do not `git add` anything
3. If service_role key exposed: treat as compromised immediately (Rule 21)
   → Rotate the key in the Supabase dashboard before anything else
4. Document the incident in `docs/REPORT.md` § P0 Incidents
5. Alert the founder — wait for explicit instruction before proceeding

WHY: P0s require key rotation and a founder decision, not an autonomous fix.
An agent that auto-fixes a security incident can make it worse.

---

## Step 1 — Triage (before touching any file)

1. Read `docs/STATUS.md` → identify current phase and last stable state
2. Identify the **blast radius** (blast radius = which tables, routes, and components are affected)
3. Classify severity:

| Level | Definition | Max fix time |
|---|---|---|
| P0 | Auth broken / data leak / RLS bypass | Fix before anything else |
| P1 | Core user flow broken (marketplace, ERP, portail) | Same session |
| P2 | UI bug, wrong translation, minor logic error | Next session acceptable |
| P3 | Cosmetic, non-blocking | Backlog in STATUS.md |

4. Declare intent:
```
Fichier: [exact path]
Severity: P0 / P1 / P2 / P3
Blast radius: [tables / routes / components affected]
Root cause hypothesis: [one sentence]
Fix approach: [one sentence]
→ Confirmer pour écrire?
```

**Never start writing before the founder confirms.**

---

## Step 2 — Reproduce First

Before fixing, reproduce the bug in isolation:
- **API bugs:** test the route directly via `curl` or Supabase Studio
- **RLS bugs:** run the negative test from `tests/rls/`
- **UI bugs:** identify the exact component + prop combination that triggers it
- **Build errors:** paste the exact `npm run build` output

**If you cannot reproduce it, stop. Do not guess-fix.**

---

## Step 3 — Fix Protocol (precision-fix skill)

- Surgical edits only — never refactor out-of-scope code while fixing
- One fix per commit — never bundle two bug fixes
- All errors through `logger.ts` — never raw `console.error`
- If the fix requires a new file: declare it with the out-of-scope file protocol from CLAUDE.md

### Par couche (layer-specific rules)

**Supabase / DB layer** (`supabase/migrations/`, `supabase/policies/`)
- Never edit an existing migration — create a new sequential one
- If an RLS policy is touched: run the negative test from `tests/rls/` before done
- Soft delete only: `deleted_at` + `deleted_by` + `deleted_reason` (never hard delete)
- No SQL string concatenation — parameterized queries only

**Auth layer** (`src/middleware.ts`, `src/lib/supabase/`)
- Read `docs/SECURITY.md` before touching any auth path
- Magic Link + Google OAuth + email flows must all remain functional after a fix
- Avocat signup = email only — never add OAuth to that flow
- Never use the service_role key on the frontend (see P0 protocol above)

**i18n layer** (`messages/fr.json`, `messages/ar.json`, `messages/en.json`)
- Any new translation key must exist in all 3 files before the component is touched
- RTL (Right-To-Left) layout must be verified in the AR locale after any UI fix

**API layer** (`src/app/api/`)
- Rate limiting per user (not per IP) must be preserved on all endpoints
- Input validation: frontend (UX) AND backend (security) — both required
- Never expose raw errors — generic translated message only (Rule 1)

### AI module fixes
Paths in scope:
- `src/lib/groq.ts` — Groq client + failover logic
- `src/lib/rag.ts` — RAG (Retrieval Augmented Generation) pipeline
- `src/lib/embeddings.ts` — @xenova/transformers embedding generation
- `src/app/api/ai/chat/` — streaming chat API route

Rules:
- Read `docs/RAG.md` before touching any AI path — non-negotiable
- Groq failover logic must be preserved — never remove the fallback
- Embedding dimension is locked at 768 — never change this value
- Conversation history format must be preserved (RAG.md § History)
- Moderation check runs before RAG — never move it after
- If fixing the chat route: verify streaming (AbortController) still works after the fix

---

## Step 4 — Validate

```bash
npm run build          # must return 0 errors — non-negotiable
```

Then verify:
- [ ] The specific bug no longer reproduces
- [ ] No regression in adjacent components (check blast radius from Step 1)
- [ ] If an RLS policy was touched: negative test passes
- [ ] If a translation key was added: key exists in `fr.json`, `ar.json`, `en.json`
- [ ] If a new Supabase migration was created: migration number is sequential

---

## Step 5 — Report

### Normal fix (P1/P2/P3)
Append to `docs/REPORT.md`:
```
---
## Fix — [YYYY-MM-DD] — [P level] — [one-line description]
**Fichier:** [path]
**Cause:** [root cause — one sentence]
**Avant:** [exact code before]
**Après:** [exact code after]
**Testé:** npm run build ✅ | Reproduction ✅ | RLS ✅/N/A
---
```
Then update `docs/STATUS.md` § Last session.

### P0 fix
Same REPORT.md entry + an additional block:
```
**P0 Incident:**
- Trigger: [what was detected]
- Key rotated: ✅ / N/A
- Founder notified: ✅
- Commit blocked: ✅
```

---

## Hard Rules (never violate)

- ❌ Never edit an existing Supabase migration file (`supabase/migrations/0XX_*`)
  → Always create a new sequential migration file
  → Editing an existing migration destroys reproducibility for every environment
    that already ran it (Vercel preview, Supabase prod)
  → If a migration has a bug: new migration with a compensating change only
- ❌ Never hard delete — soft delete only (`deleted_at`, `deleted_by`, `deleted_reason`)
- ❌ Never expose raw errors to the user — generic translated message only (Rule 1)
- ❌ Never fix two bugs in one commit
- ❌ Never skip `npm run build` validation
- ❌ If `SUPABASE_SERVICE_ROLE_KEY` appears in any file under `src/` → P0 incident, stop immediately, do not commit, alert founder
