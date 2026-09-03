# Forest Plot Builder — Claude Code Context

## Project
Shiny app generating publication-ready forest plots. Wraps the `forestHelperR`
package (already stabilised, 112 tests passing).

## Key files
- `global.R` — package loads, font setup (sysfonts/showtext), global objects
- `ui.R` — `page_navbar()` shell, rail, and statically-rendered drawer panels
- `server.R` — thin shell; sources everything in `server/` with `local = TRUE`
- `server/` — reactive logic, split per DEC-004:
  - `upload.R` — data upload pipeline + column confirmation gate
  - `regression.R` — `fit()`, `predictors_selected()`, `reg_table()`
  - `preview.R` — Review Data tab outputs
  - `plot.R` — plot generation + `order()` + concatenate guards
  - `export.R` — download handlers + R code serialiser
  - `observers.R` — misc observers (variables_displayed, sortable_cols, by_group, sigfigs)
  - `drawers.R` — rail/drawer panel switching + `suspendWhenHidden` overrides
- `R/` — pure helpers and UI helper functions (auto-sourced by Shiny):
  - `helpers.R` — pure helper functions (also used by tests)
  - `ui_rail.R` — `railUI()`, the six bottom-rail buttons
  - `ui_drawers.R` — drawer shell
  - `ui_plot_options.R` — per-panel UI (`dataPanelUI()`, `variablesPanelUI()`,
    `displayPanelUI()`, `textPanelUI()`, `orderPanelUI()`, `exportPanelUI()`)
- `www/style.css` — single stylesheet (CAQ palette); linked with a `?v=` cache-buster
- `app-changelog-decision-register.md` — decisions and changes log (update this for every change)
- `issues-register.md` — open issues register

## Test suite
- `tests/testthat/test-helpers.R` — unit tests for pure helper functions
- `tests/testthat/test-shiny-app.R` — shinytest2 integration tests
- `tests/fixtures/` — CSV fixture files for integration tests
- Run with: `testthat::test_file("tests/testthat/test-helpers.R")` or `testthat::test_file("tests/testthat/test-shiny-app.R")`

## Current phase
DEC-005 restyle — **core migration complete**. See `restyle-implementation-plan.md`
for the full plan and `app-changelog-decision-register.md` (CHG-029 – CHG-034) for
what each step did.

**Architecture decisions in force:**
- **DEC-004** — no Shiny modules. `source()` split into named files in `server/` +
  UI helper functions in `R/`. All `server/` files sourced inside the `server`
  function with `local = TRUE`.
- **DEC-005** — MDT visual language (CAQ palette, cream background, navbar) with a
  full-width **bottom** rail and a drawer sliding **up**. No sidebar. Drawer panels
  are rendered *statically* in `ui.R` and the active panel is chosen by toggling a
  CSS class — every input ID stays in the DOM from app start.

**Restyle progress:**
- Step 1 ✅ CHG-029: theme, stylesheet, `page_navbar` shell
- Step 2 ✅ CHG-030: rail + drawer shell, empty panels
- Step 3 ✅ CHG-031: Variables/Display/Text drawer panels (`bslib::accordion()` retired)
- Step 4 ✅ CHG-032: Data panel — sidebar removed from `ui.R` entirely
- Step 5 ✅ CHG-033: Order panel + Export redesign (FEAT-009, ISS-031)
- Step 6 ✅ CHG-034: CSS merge/polish, dead-code prune
- Step 7 🔲 status chips, rail badges, Help nav — explicitly phase-2/optional in the
  plan, not started ("ship the core first")

**Gotcha worth remembering:** drawer panels are `display:none` by default, so Shiny
suspends any output inside them — including `downloadButton`s, which render as
`disabled` with an empty `href`. Anything live inside a hidden panel needs
`outputOptions(output, "<id>", suspendWhenHidden = FALSE)` in `server/drawers.R`.

**Open issues (see `issues-register.md`):**
- ISS-028: age group sort order in simulated data (Medium — likely in `forestHelperR`)
- ISS-029: OS system fonts absent from selector after sysfonts migration (Low)
- ISS-030: `"Source Sans Pro"` renamed on Google Fonts, silently absent (Low)

**Next session:** Core restyle is shipped and committed. Either pick up DEC-005
Step 7, or address the open issues above. `handover-dec004-file-split.md` is now
historical — DEC-004 is complete.

## Conventions
- Always use explicit package::function() notation
- Update the changelog register for every code change made
- Do not guess — if unsure, ask before editing
- Prefer req() over is.null() guards in reactives
- All documentation in .md format

## Do not modify
- forestHelperR package files (separate repo)
- renv.lock (if present)
