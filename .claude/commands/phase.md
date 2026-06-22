# /project:phase

## What this command does
Drives E-Mizen DZ through one build phase (Phase 0 → 7) end to end,
respecting FK dependency order and the MVP scope boundary.

## Context preload (read before anything)
- CLAUDE.md — 24 rules active
- docs/STATUS.md — current phase + last completed task + resume point
- docs/PHASES.md — phase boundary + full task list for the active phase
- docs/CODEMAP.md — existing components (avoid recreating)
- uidesign.md — if the phase builds UI
- docs/SECURITY.md — if the phase touches auth/data/upload
- docs/RAG.md — if the phase is Phase 6 (Assistant IA)

## Entry gate (preconditions — all must pass before writing)
1. npm run build returns 0 errors on current state
2. Previous phase marked ✅ in STATUS.md (skip for Phase 0 — no predecessor)
3. Previous phase migrations confirmed applied by founder (supabase db push)
4. Read STATUS.md § Resume point → if a phase was interrupted, continue from
   the last completed entity, never re-scaffold completed ones
→ If any fails: STOP, name the failed precondition, wait for founder.

## Execution order
1. Read STATUS.md → identify the phase to run
2. Read PHASES.md → load that phase's task + table list
3. Declare intent (CLAUDE.md session start): date, phase, files to touch,
   files NOT to touch, skills activated → wait for confirm
4. Build in FK dependency order: migration → policy → negative test →
   service → component → page, one entity at a time
   ⚠️ supabase/policies/ AND supabase/migrations/ are in settings.json deny —
   declare each policy/migration file via the out-of-scope protocol (path, why,
   before/after NOT WRITTEN) and wait for "yes" before writing. tests/rls/ is
   allowed — negative tests are written directly, no declaration needed.
5. After each entity: npm run build → 0 errors before the next
6. Translations (fr/ar/en) added BEFORE any UI component (Rule 4)

## Exit criteria (Definition of Done — all required)
- [ ] Each table: migration file written + founder-confirmed applied
      (agent writes migrations only — settings.json denies supabase CLI)
- [ ] RLS policy + negative test written per new table
- [ ] npm run build → 0 errors
- [ ] STATUS.md updated (phase ✅, next task + resume point set)
- [ ] REPORT.md session entry appended
- [ ] CODEMAP.md updated for every component created/modified

## Safety
- Idempotent (idempotent = safe to run twice): before scaffolding any file,
  check CODEMAP.md first — never overwrite a built component
- One phase per invocation — never advance two phases in one run
- Out-of-scope feature spotted → log in STATUS.md § Future Building backlog,
  never implement (Rule 15)

## Scope
Builds the current phase only. Does not: run a bug fix (use /project:fix),
skip ahead, or modify locked constitution files (CLAUDE.md, FIX.md, uidesign.md).
