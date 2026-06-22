# scope-rules.md — Scope, Registry & Workflow Rules

These load on every turn. They protect the MVP boundary and the agent's own
discipline.

## R15 — MVP scope is locked
FORBIDDEN without explicit founder approval:
- Cabinet Pro / RBAC multi-collaborateurs
- Facturation / Stripe
- WebSockets / real-time messaging
- Mobile app · OCR · Video consultation
- Notaires/Huissiers backend (UI "Coming Soon" only)
- FastAPI / LangGraph migration · Microservices

When an out-of-scope feature is spotted:
1. Do NOT implement it. Do NOT create files for it.
2. Log it in docs/STATUS.md § Future Building backlog with: effort estimate,
   dependencies, priority.
3. Continue the in-scope task.
WHY: scope creep is what kills a solo PFE before the September jury.

## File scope rule (per session)
- The agent may only touch files declared in the session's Step 4 declaration.
- Out-of-scope file needed mid-task → STOP → declare it (path, why unavoidable,
  risk 🟢/🟡/🔴, before/after NOT WRITTEN) → wait for explicit "yes" → only
  then write.
- settings.json deny list is the hard backstop; this rule is the behavioural one.

## R23 — CODEMAP registry
- Register every component created OR modified in docs/CODEMAP.md before the
  task is "done" (full schema in /project:codemap).
- Modified ≠ exempt: a touched file gets its Session id updated.
- WHY: the registry is what makes blast-radius (FIX.md) and check-before-create
  (R6) actually work.

## R24 — auto-improve casual requests
On an informal/casual request, before executing:
1. Detect the loose phrasing.
2. Rewrite it as a precise pro prompt (intent, files, constraints, done-criteria).
3. Show the rewritten prompt to the founder.
4. WAIT for an explicit signal before executing.

### Signals
- Approve: "yes" / "go" / "next" / "ok" → execute the improved prompt as-is.
- Reject: "no" / "stop" / "not that" → see Rejection handling.
- Edit: founder rewrites part → treat the edited version as the new prompt,
  re-show only if a NEW ambiguity was introduced, else execute.

### Rejection handling
- On reject: do NOT fall back to the original casual request, and do NOT
  proceed on a guess. Both are failure modes.
- Ask ONE targeted question to find what was wrong (scope? approach? file?).
- Produce a single revised prompt addressing that answer → show → wait again.
- Max 2 revision rounds. If still rejected after 2: stop, state plainly that
  the request is underspecified, ask the founder to describe the goal directly.
WHY: a missing rejection path makes an agent either freeze or guess. Both
waste a tired founder's time.

## R18 cross-reference
Rate limiting per user lives in security-rules.md (it is a security control,
not a scope control). See R18 there.
