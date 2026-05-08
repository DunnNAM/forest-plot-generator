# Forest Plot Builder — App Changelog & Decision Register

> **Project:** Forest Plot Builder  
> **Organisation:** Cancer Alliance Queensland  
> **Contact:** Nathan Dunn  
> **Register opened:** May 2026  
> **Current phase:** Shiny app — code review & issue resolution  
> **Companion document:** `changelog-decision-register.md` (forestHelperR package phase)

---

## How to use this register

This document records two types of entries:

- **Decisions (DEC)** — Architectural, design, or process choices made during development. Each entry records what was decided, why, and what alternatives were considered.
- **Changes (CHG)** — Code or documentation changes that were implemented. Each entry links to the issue or feature that motivated the change.

Entries are listed in reverse chronological order (newest first) within each section.

| Field | Description |
|---|---|
| **ID** | Unique identifier — `DEC-NNN` for decisions, `CHG-NNN` for changes (numbering scoped to this document) |
| **Date** | Date the decision was made or change was implemented |
| **Author** | Who made the decision or implemented the change |
| **Status** | `Active` / `Superseded` / `Deferred` (decisions); `Implemented` / `Reverted` (changes) |
| **Refs** | Related issue (`ISS-NNN`) or feature (`FEAT-NNN`) identifiers |

> **Cross-phase references:** Where a change in the app depends on a fix made during the `forestHelperR` package phase, the relevant package decision or change is referenced using the companion document's numbering (e.g., `PKG-007`, `CHG-010` from the package register).

---

## Decisions

### DEC-002 — Delete `functions/functions.R`; rely solely on `forestHelperR` package

| Field | Detail |
|---|---|
| **Date** | May 2026 |
| **Author** | Nathan Dunn |
| **Status** | Active |
| **Refs** | ISS-005, PDEC-002 |

**Decision:** Delete `functions/functions.R` from the project. All functions it contained (`regTabler()`, `forestPloter()`, and helpers) are now provided by the `forestHelperR` package. The file is not sourced and serves no active purpose.

**Rationale:** Retaining the file — even with a warning comment — creates an ongoing risk that a future developer uncomments the `source()` call in `global.R`, silently re-introducing stale function versions that override the package versions. Deletion eliminates this risk entirely. The `forestHelperR` package is the authoritative source of truth for all plot generation logic.

**Alternatives considered:**

- Rename to `functions_REFERENCE_ONLY_DO_NOT_SOURCE.R` — rejected; the file adds no reference value that the package source itself does not already provide, and the rename does not fully prevent accidental sourcing.
- Retain with a prominent warning comment block — rejected for the same reason as above.

**Notes:** A comment confirming the deletion has been retained in `global.R` for traceability: `# functions/functions.R removed — all functions now provided by forestHelperR package. The legacy file has been deleted (PDEC-002 / CHG-003).` PDEC-002 is now closed.

---

### DEC-001 — Move project to GitHub for development workflow

| Field | Detail |
|---|---|
| **Date** | May 2026 |
| **Author** | Nathan Dunn |
| **Status** | Active |
| **Refs** | ISS-001, ISS-005, ISS-007, ISS-008, ISS-011, PKG-005, PKG-006, FEAT-005 |

**Decision:** Move the Forest Plot Builder Shiny app to a GitHub repository as the primary version control platform for active development.

**Scope — what this decision covers:**

- Version control and local development workflow only.
- The repository will be used for development purposes; it is not a publication or deployment event.
- No live or hosted version of the app is being deployed as part of this change.

**Scope — what this decision does NOT cover:**

- Public release of the repository (possible future direction, not decided).
- Hosting a running instance of the app on a server (possible future direction, not decided).
- Moving `forestHelperR` to its own GitHub repository (see PDEC-005 — deferred).

**Rationale:** The previous development workflow involved accessing Claude via a web browser over a VPN and proxy server, which caused frequent timeouts and session dropouts. Moving the project to GitHub enables a more stable development workflow and standard version control practices, independent of the network constraints of the previous setup.

**Alternatives considered:**

- Continue with the existing local/network-share approach — rejected due to workflow instability and the absence of version history.
- Move to GitHub and simultaneously publish — deferred; publication scope is not yet decided.

**Pre-commit hygiene requirements — final status:**

| Issue | Description | Status |
|---|---|---|
| ISS-001 | Hardcoded `setwd()` paths referencing internal server directory structure | ✅ Resolved — CHG-004 |
| ISS-005 | Orphaned `functions/functions.R` | ✅ Resolved — DEC-002 |
| PKG-005 | Hardcoded developer machine path in `data.R` | ✅ Resolved in package phase — verified May 2026 |
| PKG-006 | Hardcoded Windows local path in `README.md` | ✅ Resolved in package phase — verified May 2026 |

**All pre-commit hygiene items are resolved. The project is clear for an initial GitHub commit to a private development repository.**

> **Note:** ISS-008 (undocumented `forestHelperR` install path) is addressed by the updated `README.md`, which now documents installation via internal CAQ repository and `.tar.gz` for external collaborators. PDEC-005 (whether to host `forestHelperR` on GitHub) remains deferred until publication or server hosting is scoped.

---

## Pending Decisions

| ID | Question | Refs | Priority | Target decision date |
|---|---|---|---|---|
| PDEC-001 | Should the app be refactored from the 3-file structure (`ui.R`, `server.R`, `global.R`) to a Shiny module architecture? Decision requires reading `server.R` to assess complexity. | FEAT-007 | Medium | After initial code review |
| PDEC-003 | Should `extrafont` be replaced with `sysfonts`/`showtext` for font handling in the app? Requires confirming whether font logic lives in the app, in `forestHelperR`, or both. | ISS-002, PKG-007, FEAT-008 | Medium | After code review |
| PDEC-004 | Should the `officer` dependency be removed from `global.R` until Word/PowerPoint export is implemented? | ISS-006, FEAT-004 | Low | Early in code review |
| PDEC-005 | Should `forestHelperR` be moved to its own GitHub repository? | ISS-008, PKG-006 | **Deferred** — no hosting or sharing requirement at this stage. Leave package in current local location. Revisit when publication or server hosting is being planned. | When hosting/publication is scoped |

> **Closed pending decisions:** PDEC-002 → DEC-002 (May 2026).

---

## Changes

### CHG-004 — Remove `setwd()` block from `global.R`; replace `source()` with `here::here()`

| Field | Detail |
|---|---|
| **Date** | May 2026 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-001, DEC-001 |

**Files changed:** `global.R`  
**Files added:** `.here` (project root)

**Summary of changes to `global.R`:**

| Location | Before | After |
|---|---|---|
| Package block | — | `library(here)` added |
| Lines 31–36 | `temp <- getwd()` / `if/else setwd(...)` block | Deleted entirely; replaced with explanatory comment |
| Line 39 | `source("./data/data_creation.R")` | `source(here::here("data", "data_creation.R"))` |

**Rationale:** The `setwd()` block used a `getwd()` string-detection heuristic to choose between two hardcoded server paths. This approach: (a) exposed internal server directory structure in version-controlled source; (b) was non-portable to any machine not matching those exact paths; and (c) was unnecessary once the project has an anchored root.

`here::here()` resolves paths relative to the project root using a priority order: `.here` sentinel file → `.Rproj` → `.git` → `DESCRIPTION` → working directory fallback. This is correct and consistent across both local RStudio development and the existing Shiny Server deployment, with no server-side changes required.

**`.here` sentinel file:** An empty `.here` file has been added to the project root. This explicitly anchors `here::here()` resolution regardless of whether an `.Rproj` file is present on the server, ensuring consistent behaviour across all deployment contexts. The file contains no content and has no runtime effect beyond root anchoring.

**Dependency added:** `here` — must be present on all deployment targets. Install with `install.packages("here")`.

**ISS-001 status:** → **Resolved**

---

*No earlier changes recorded in this register. See companion package changelog (`changelog-decision-register.md`) for changes made during the `forestHelperR` package phase.*

---

## Security Review

### Security Assessment — May 2026

> **Scope:** All project documentation and source files reviewed. `global.R`, `ui.R`, `server.R`, `data_creation.R` (app); `data.R`, `README.md` (package) reviewed directly.  
> **Trigger:** Developer query prior to moving project to GitHub.  
> **Reviewer:** Claude (Anthropic)  
> **Assessment complete:** May 2026

#### Overall Assessment: **Low Risk — cleared for private GitHub commit**

The app is a visualisation tool with no patient-facing interface, no authentication layer, no database connectivity, and no real patient data. No security vulnerabilities were identified. All pre-commit hygiene items are resolved.

**No sensitive information found:**

| Area | Assessment |
|---|---|
| Patient / clinical data | Simulated dataset only — 5,000 synthetically generated records, no real identifiers |
| Authentication credentials | None present in any reviewed file |
| Database connection strings | None — out of scope by design |
| Network / infrastructure details | Previously exposed via `setwd()` — resolved CHG-004 |
| External service integrations | None — app is self-contained |

**Pre-commit hygiene — all items resolved:**

| Ref | File | Finding | Status |
|---|---|---|---|
| ISS-001 | `global.R` | Hardcoded internal server paths via `setwd()` | ✅ Resolved — CHG-004 |
| ISS-005 | `functions/functions.R` | Orphaned legacy file | ✅ Resolved — DEC-002 (deleted) |
| PKG-005 | `data.R` | Hardcoded developer machine path in `@details` | ✅ Resolved in package phase — verified May 2026 |
| PKG-006 | `README.md` | Hardcoded Windows install path | ✅ Resolved in package phase — verified May 2026 |

**Notes for future public release:** Register headers and source documentation reference developer name (Nathan Dunn), organisation (Cancer Alliance Queensland), and internal community name (CAQ Data Science Community). This is standard attribution and not sensitive, but worth being aware of before any public release.

#### Final Security Checklist

| Item | Status |
|---|---|
| No real patient data | ✅ Confirmed |
| No credentials or secrets in any reviewed file | ✅ Confirmed |
| No database connectivity | ✅ Confirmed |
| No hardcoded internal paths remaining | ✅ Confirmed — all resolved |
| Orphaned legacy code deleted | ✅ Confirmed — DEC-002 |
| All app source files reviewed (`global.R`, `ui.R`, `server.R`, `data_creation.R`) | ✅ Complete |
| All package files reviewed (`data.R`, `README.md`) | ✅ Complete |
| **Cleared for private GitHub commit** | ✅ |

---

## Review Log

| Date | Activity | Outcome |
|---|---|---|
| May 2026 | Handoff from `forestHelperR` package phase — package fully stabilised; 112 tests green; `devtools::document()` clean | See companion package changelog for full history. App changelog opened. |
| May 2026 | Decision to move project to GitHub for development workflow | DEC-001 recorded. PDEC-005 raised and deferred. Pre-commit hygiene checklist documented. |
| May 2026 | Preliminary security review | Low risk. No patient data, credentials, or sensitive infrastructure details found. |
| May 2026 | `global.R`, `ui.R`, `server.R`, `data_creation.R` uploaded and reviewed | ISS-001 resolved (CHG-004). `data_creation.R` confirmed clean. PDEC-002 formally closed as DEC-002. |
| May 2026 | `data.R` and `README.md` (package files) uploaded and reviewed | PKG-005 and PKG-006 confirmed already resolved in package phase. Pre-commit checklist fully cleared. Security assessment marked complete. |
| — | Broader code review of `ui.R` and `server.R` for functional issues | Pending |

---

*Document version: 0.4 — Pre-commit hygiene checklist fully cleared; PKG-005 and PKG-006 verified resolved; security assessment complete; project cleared for private GitHub commit*
