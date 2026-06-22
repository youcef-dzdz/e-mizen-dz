# /project:fix

## What this command does
Activates the full bug fix protocol for E-Mizen DZ.
Reads FIX.md and executes it from Step 1 (triage) through Step 5 (report).

## Context preload (read before asking anything)
- CLAUDE.md — 24 rules active
- FIX.md — full protocol
- docs/STATUS.md — current phase + last stable state
- docs/CODEMAP.md — existing components (to assess blast radius)
- docs/SECURITY.md — if the bug is in the auth or API layer
- docs/RAG.md — if the bug is in the AI module

## Execution order
1. Read docs/STATUS.md → identify current phase and last stable state
2. Read FIX.md → load the full protocol into context
3. Ask the founder: "Describe the bug — what broke, where, and how it manifests"
4. Run FIX.md Step 1 (triage) → declare severity + blast radius → wait for confirm
5. Run FIX.md Step 2 (reproduce) → confirm reproduction before proceeding
6. Run FIX.md Step 3 (precision-fix skill) → dry run → wait for confirm
7. Run FIX.md Step 4 (validate) → npm run build must return 0 errors
8. Run FIX.md Step 5 (report) → append to docs/REPORT.md + update docs/STATUS.md

## Safety
- This command is idempotent — safe to run twice on the same bug
- If run on a clean codebase: reports "No bug described — provide a bug description to proceed"
- Never auto-starts writing — always waits for founder confirmation at each gate
- If P0 detected at any point: stops immediately, escalates per FIX.md P0 protocol

## Scope
This command only activates FIX.md. It does not:
- Start a new phase
- Generate new components
- Modify docs/PHASES.md or docs/CODEMAP.md
