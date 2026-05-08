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

*No decisions recorded yet. Entries will be added as the code review and issue resolution phase proceeds.*

---

## Pending Decisions

The following questions were identified during planning and require resolution before or during the app code review phase.

| ID | Question | Refs | Target decision date |
|---|---|---|---|
| PDEC-001 | Should the app be refactored from the 3-file structure (`ui.R`, `server.R`, `global.R`) to a Shiny module architecture? Decision requires reading `server.R` to assess complexity. | FEAT-007 | After initial code review |
| PDEC-002 | Should `functions/functions.R` be deleted, or retained with a clear naming convention to prevent accidental sourcing? | ISS-005 | Early in code review |
| PDEC-003 | Should `extrafont` be replaced with `sysfonts`/`showtext` for font handling in the app? Requires confirming whether font logic lives in the app, in `forestHelperR`, or both. | ISS-002, PKG-007, FEAT-008 | After code review |
| PDEC-004 | Should the `officer` dependency be removed from `global.R` until Word/PowerPoint export is implemented? | ISS-006, FEAT-004 | Early in code review |

---

## Changes

*No changes recorded yet. Entries will be added as issues are resolved.*

---

## Review Log

| Date | Activity | Outcome |
|---|---|---|
| May 2026 | Handoff from `forestHelperR` package phase — package fully stabilised; 112 tests green; `devtools::document()` clean | See companion package changelog for full history. App changelog opened. |
| — | Code review of `global.R`, `ui.R`, `server.R` | Pending — awaiting file uploads |

---

*Document version: 0.1 — Register opened; pending decisions carried forward from package phase; no changes recorded yet*
