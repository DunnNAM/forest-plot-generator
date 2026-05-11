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
DEC-004 file split — in progress. See `handover-dec004-file-split.md` for full context.

**Architecture decision (DEC-004):** No Shiny modules. Using `source()` split into named files in `server/` + UI helper functions in `R/`. All `server/` files sourced inside the `server` function with `local = TRUE`.

**File split progress:**
- Step 1 ✅ CHG-018: `R/ui_plot_options.R` — plot options accordion UI helper
- Step 2 ✅ CHG-019: `server/upload.R` — data upload pipeline + column confirmation gate
- Step 3 ✅ CHG-020: `server/regression.R` — fit(), predictors_selected(), reg_table()
- Step 4 ✅ CHG-021: `server/preview.R` — all Review Data tab outputs
- Step 5 ⚠️ CHG-022: `server/plot.R` — plot generation + order() + concatenate guards — **tests passing, smoke test + commit pending**
- Step 6 🔲 CHG-023: `server/export.R` — download handlers + R code serialiser
- Step 7 🔲 CHG-024: `server/observers.R` — misc observers (variables_displayed, sortable_cols, by_group, sigfigs)

**Open issues (see `issues-register.md`):**
- ISS-028: age group sort order in simulated data (Medium — likely in `forestHelperR`)
- ISS-029: OS system fonts absent from selector after sysfonts migration (Low)
- ISS-030: `"Source Sans Pro"` renamed on Google Fonts, silently absent (Low)
- ISS-031: export button layout — fourth button wraps with no spacing (Medium)
- FEAT-009: export controls redesign — sidebar accordion panel (Medium)

**Next session:** Start by reading `handover-dec004-file-split.md`. Complete Step 5 smoke test, commit, then implement Steps 6 and 7.

## Conventions
- Always use explicit package::function() notation
- Update the changelog register for every code change made
- Do not guess — if unsure, ask before editing
- Prefer req() over is.null() guards in reactives
- All documentation in .md format

## Do not modify
- forestHelperR package files (separate repo)
- renv.lock (if present)