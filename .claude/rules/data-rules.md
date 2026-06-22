# data-rules.md — Data Access & Persistence Rules

These load on every turn touching the database, services, or list endpoints.

## R9 — data access lives in /services/ only
- Every Supabase call goes through a function in src/services/ (one file per
  entity: dossiers.service.ts, demandes.service.ts, …).
- FORBIDDEN: supabase.from(...) inside a component, page, or hook.
- Components/pages call service functions; services hold the queries.
- WHY: one place to audit RLS, pagination, and soft-delete filters per entity.
  Queries scattered in components can't be reviewed or reused.

## R10 — soft delete only, never hard delete
- No DELETE removes a row. Deletion = set deleted_at + deleted_by +
  deleted_reason.
- Every SELECT in a service MUST filter `deleted_at IS NULL` by default.
- A "restore" = clear those three columns. History is never destroyed.
- Exception: nothing. Even admin "delete" is soft (legal audit trail).
- WHY: a LegalTech platform must prove what existed and when. Hard delete =
  evidence destroyed, and an accidental delete is unrecoverable.

## R16 — cabinet_id on every cabinet entity (multi-tenant key)
- Every table inside the ERP Cabinet scope carries cabinet_id.
- Default value = the avocat's id (solo cabinet today; collaborators are
  post-MVP, but the column exists now so no migration rewrite later).
- Every ERP service query filters by cabinet_id — a cabinet never sees another
  cabinet's dossiers, even with a query bug, because RLS + the filter both gate it.
- WHY: retrofitting a tenant key after data exists is a painful migration.
  Add the column free now; switch on the collaborator feature later.

## R19 — pagination mandatory on all list endpoints
- No endpoint returns an unbounded list. Ever.
- Dashboards / admin tables → OFFSET pagination (jump to page N, show counts).
- Feeds / infinite scroll (notifications, messages) → CURSOR pagination
  (cursor = a stable pointer to the last item, avoids skips on inserts).
- Default page size 20, hard max 100 (reject larger in backend validation).
- See docs/PAGINATION.md for the exact helper signatures.
- WHY: one cabinet with 5000 dossiers freezes the browser and the DB on a
  naive SELECT *. The jury demo dies on the first scaled table.
