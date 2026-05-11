# Forest Plot Builder — Claude Code Context

## Project
Shiny app generating publication-ready forest plots. Wraps the `forestHelperR`
package (already stabilised, 112 tests passing).

## Key files
- `global.R` — package loads, font setup (sysfonts/showtext), global objects
- `server.R` — all reactive logic
- `ui.R` — layout and inputs
- `R/helpers.R` — pure helper functions (auto-sourced by Shiny; also used by tests)
- `app-changelog-decision-register.md` — decisions and changes log (update this for every change)
- `issues-register.md` — open issues register

## Test suite
- `tests/testthat/test-helpers.R` — 48 unit tests for pure helper functions
- `tests/testthat/test-shiny-app.R` — 7 shinytest2 integration tests
- `tests/fixtures/` — CSV fixture files for integration tests
- Run with: `testthat::test_file("tests/testthat/test-helpers.R")` or `testthat::test_file("tests/testthat/test-shiny-app.R")`

## Current phase
Code review and issue resolution complete. Preparing for architecture work.

**Completed:**
- Batch 1: namespace qualifiers + undeclared packages (ISS-013, 014, 015)
- Batch 2: UI label corrections (ISS-017, 018, 019, 027)
- Batch 3: dead code removal + reactive tidying (ISS-022, 023, 024, 025, 016/026)
- ISS-004: test suite — 48 unit tests (`tests/testthat/test-helpers.R`) + 7 shinytest2 integration tests (`tests/testthat/test-shiny-app.R`)
- ISS-002: font handling replaced — `extrafont` → `sysfonts`/`showtext` (DEC-003)

**Open issues (see `issues-register.md`):**
- ISS-028: age group sort order in simulated data (Medium — likely in `forestHelperR`)
- ISS-029: OS system fonts absent from selector after sysfonts migration (Low)
- ISS-030: `"Source Sans Pro"` renamed on Google Fonts, silently absent (Low)
- ISS-031: export button layout — fourth button wraps with no spacing (Medium)
- FEAT-009: export controls redesign — sidebar accordion panel (Medium)

**Next major piece of work:**
PDEC-001 — decide whether to refactor from 3-file structure to Shiny module architecture. This is scoped for a new chat session with a dedicated handover document.

## Conventions
- Always use explicit package::function() notation
- Update the changelog register for every code change made
- Do not guess — if unsure, ask before editing
- Prefer req() over is.null() guards in reactives
- All documentation in .md format

## Do not modify
- forestHelperR package files (separate repo)
- renv.lock (if present)