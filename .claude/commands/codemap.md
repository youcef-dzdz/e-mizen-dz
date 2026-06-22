# /project:codemap

## What this command does
Audits the codebase against docs/CODEMAP.md and repairs drift — the registry
of every component, service, hook, lib module, page, and API route (Rule 23).
Keeps CODEMAP.md trustworthy so /project:fix (blast radius) and /project:phase
(avoid recreating) make correct decisions.

## Context preload
- CLAUDE.md — Rule 6 (check exists before creating), Rule 23 (register)
- docs/CODEMAP.md — current registry
- docs/STATUS.md — current phase + session (to tag new entries)

## Scan scope (what counts as a registrable unit)
- src/components/**/*.tsx
- src/services/**/*.ts
- src/hooks/**/*.ts
- src/lib/**/*.ts
- src/app/[locale]/**/page.tsx   (route pages)
- src/app/api/**/route.ts         (API routes)
Ignored: utils/, types/, *.test.ts, *.d.ts — not registry units.

## Registry row schema (every entry must have all fields)
| Field   | Meaning |
|---------|---------|
| Path    | exact file path |
| Type    | component / service / hook / lib / page / api |
| Phase   | phase that created it (0–7) |
| Status  | active / deprecated |
| Session | session id of last create/modify |

## Execution order (dry run first — never auto-write)
1. Read CODEMAP.md → load current registry
2. Scan the scan-scope globs → build the actual file list
3. Diff:
   - In code, NOT in registry → 🟡 orphan (must be registered)
   - In registry, NOT in code → 🔴 stale (deleted — mark deprecated)
   - In both → 🟢 ok
   - Orphan + stale sharing the same basename → ⚠️ possible rename
4. For each orphan: tag phase = current (from STATUS.md), session = current,
   note "auto-registered — verify phase is correct"
5. Print the full drift report → wait for founder confirm
6. On confirm: update CODEMAP.md (add orphans, mark stale deprecated)

## Safety
- Dry run by default — reports drift, writes only on explicit confirm
- Idempotent (safe to run twice): re-running on a synced registry reports
  "0 drift" and changes nothing
- Never deletes a registry row — stale entries are marked deprecated, kept for
  audit history (a deleted component may still be referenced in REPORT.md)
- Append-only history: never rewrite past Session ids

## Scope
Audits and repairs the registry only. Does not: create or delete source files,
run a build, or modify any file other than docs/CODEMAP.md.
