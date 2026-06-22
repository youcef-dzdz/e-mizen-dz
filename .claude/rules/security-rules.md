# security-rules.md — Security Rules (non-negotiable)

These load on every turn touching auth, data, API, or upload. A violation here
is never a P2 — minimum P1, often P0 (see FIX.md P0 protocol).

## R11 — service_role never on the frontend
- SUPABASE_SERVICE_ROLE_KEY is server-only. It bypasses RLS entirely.
- ALLOWED: server-only contexts → src/lib/supabase/server.ts, route handlers,
  supabase/functions/ edge functions.
- FORBIDDEN: any "use client" file, any component, anything in the browser bundle.
- Detection: key referenced under a client boundary → 🔴 P0, stop, do not commit.
- WHY: one leaked service_role = every user reads every row. Total RLS bypass.

## R12 — every RLS policy has a negative test, per operation
- Each policy needs four separate negative tests: SELECT, INSERT, UPDATE, DELETE.
- "Negative" = proves an unauthorized user is BLOCKED, not just that an owner
  is allowed (a positive-only test gives false confidence).
- Test file lives in tests/rls/ named after the table.
- A commented-out or .skip'd test = MISSING (blocks done).
- WHY: untested RLS is unverified RLS — and RLS is the whole security model.

## R13 — all errors through logger.ts
- No raw console.error / console.log in components, pages, services, routes.
- logger.ts decides what is logged server-side vs shown to the user.
- The user always sees a generic translated message (Rule 1), never a stack.
- WHY: raw errors leak table names, query shape, and internal paths to attackers.

## R14 — no SQL string concatenation
- All queries via the Supabase client (parameterized) or parameterized rpc.
- FORBIDDEN: building SQL with template strings / + concatenation of any user
  input, even "trusted" admin input.
- WHY: string-built SQL is the classic injection vector — one gap is enough.

## R18 — rate limiting per user
- Every API route enforces a per-user limit (by user id, NOT by IP).
- IP limiting is bypassable (shared NAT, proxies) and punishes co-located users.
- Unauthenticated public routes (marketplace search): limit by IP as fallback.
- WHY: per-user is the only honest throttle once a user is authenticated.

## R20 — validate on both sides
- Frontend validation = UX (instant feedback). Backend validation = security.
- Both required on every form/endpoint. Frontend validation is never trusted
  server-side — the client is attacker-controlled.
- Shared schema (one validator reused both sides) preferred over duplicating.
- WHY: anyone can POST straight to the API and skip the form entirely.

## R21 — no secrets in source
- No API key, token, or secret literal anywhere in the repo. Secrets live in
  .env.local (gitignored) and Vercel env vars only.
- If a secret appears in any diff: treat as COMPROMISED immediately → rotate it,
  do not commit, follow FIX.md P0 protocol.
- WHY: git history is forever — a committed key is leaked even after deletion.
