# Code review lenses

Severity lenses for review agents. `REVIEW.md` has the house rules and the mechanical checks;
`AGENTS.md` the architecture. Escalate the review depth when a diff touches any **Critical**
area, even if the diff is small.

> Template. Fill the tables with your project's real boundaries. The split — Critical blocks
> the merge, Major is fixed-or-justified — is the reusable part.

## Critical: block the merge

| Lens | What to check | Where |
|---|---|---|
| `<tenant / data isolation>` | `<the exact pattern a new table/query/handler must follow>` | `<files>` |
| `<auth source & route auth>` | `<identity comes from the session, not a header; every route has an auth dependency>` | `<files>` |
| Secrets | No secret value in code, tests, fixtures, config, logs, or infra state. | everywhere |
| Production safety | Nothing applies, deploys, or writes to production from code, scripts or CI. | `scripts/`, infra, CI |
| `<writes to the system of record>` | `<go through the sanctioned path; shadow-mode components never write>` | `<files>` |
| Credential storage | Stored credentials encrypted at rest, never returned in plain text. | `<files>` |

## Major: fix before merge, or record why not

| Lens | What to check |
|---|---|
| `<production-mode behaviour>` | Works in the real (prod) configuration; no silent no-op without the dev shortcut. |
| `<concurrency / resource pools>` | Background tasks carry their context explicitly; pools are not shared across event loops. |
| Error mapping | Domain errors raised in the service/data layers, mapped to the transport layer only at the edge. |
| Settings | Config read from the one typed settings object, not the raw environment. A new setting has a safe local default. |
| `<external clients / model clients>` | Built only in the sanctioned place; a new integration follows the existing pattern. |
| `<layer neutrality>` | No cross-layer leakage (e.g. vendor-specific logic in a vendor-neutral layer). |

## Minor / Nit
Naming, local clarity, comments that drifted from the code, small dead code. Report, don't block.
