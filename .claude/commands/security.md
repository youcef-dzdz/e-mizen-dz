# /project:security

## What this command does
Runs a read-only security audit across the codebase against docs/SECURITY.md
(15 threats) and the security rules (11, 12, 13, 14, 18, 20, 21). Reports
findings by severity. Never auto-patches — a bad security auto-fix makes it
worse (FIX.md P0 protocol).

## Context preload
- CLAUDE.md — Rules 11,12,13,14,18,20,21
- docs/SECURITY.md — 15-threat model
- FIX.md — P0 incident protocol (escalation path for criticals)
- supabase/policies/ + tests/rls/ — to detect untested policies

## Audit checklist (scan + severity)
| # | Check | Where | Severity |
|---|-------|-------|----------|
| 1 | SUPABASE_SERVICE_ROLE_KEY referenced | src/** (esp. client.ts, "use client") | 🔴 P0 |
| 2 | Hardcoded API key / secret in source | src/**, *.ts(x) | 🔴 P0 |
| 3 | RLS policy with no negative test | supabase/policies/ vs tests/rls/ | 🔴 P0 |
| 4 | SQL string concatenation | src/services/**, src/app/api/** | 🔴 P0 |
| 5 | Endpoint missing per-user rate limit | src/app/api/**/route.ts | 🟡 P1 |
| 6 | Form missing backend validation | src/app/api/** (paired with form) | 🟡 P1 |
| 7 | Raw error exposed to user | components/pages returning err.message | 🟡 P1 |
| 8 | console.error instead of logger.ts | src/components/**, src/app/** | 🟢 P2 |

## Execution order (dry run only — never writes code)
1. Read SECURITY.md + the security rules → load the model
2. Grep the audit-checklist patterns across the declared scopes
3. Classify each finding by severity (table above)
4. If any 🔴 P0 found → trigger FIX.md P0 Incident Protocol immediately:
   STOP, do not commit, alert founder, (rotate key if service_role exposed)
5. Print the full findings report grouped by severity → wait for founder
6. Append the report to docs/REPORT.md § Security audits (dated)

## False-positive guards
- service_role in supabase/functions/ (edge functions, server-only, never
  bundled to the browser) is NOT a finding — that is a separate deploy target
  outside src/. Only src/** references are P0.
- A negative test that exists but is skipped/commented = treat as MISSING (P0).

## Safety
- Read-only — produces a report, never edits source or policies
- Idempotent: re-running on a clean codebase reports "0 findings"
- Does not rotate keys or commit — those stay founder-controlled (P0 protocol)

## Scope
Audits security posture only. Does not fix bugs (use /project:fix), build
features (/project:phase), or modify any file except docs/REPORT.md.
