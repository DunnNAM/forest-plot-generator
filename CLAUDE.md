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
  - `ui_help.R` — `helpPanelUI()`, the static Help nav panel content (FEAT-010)
- `www/style.css` — single stylesheet (CAQ palette); linked with a `?v=` cache-buster
- `app-changelog-decision-register.md` — decisions and changes log (update this for every change)
- `issues-register.md` — open issues register
- `manifest.json` — Posit Connect Cloud deployment manifest (CHG-039/CHG-040,
  2026-09-06). Regenerate via the plain `rsconnect::writeManifest(appDir = ".")` —
  as of CHG-040 (`forestHelperR`'s `renv.lock` entry now has a real GitHub source)
  the default lockfile-based path works cleanly; the `dependencyResolution =
  "library"` workaround from CHG-039 is no longer needed and shouldn't be, since it
  can silently miss packages nothing calls via `::` directly (see CHG-040's account
  of that recurring, ISS-035-shaped failure mode).

## Environment
**The project targets R 4.3.x.** `renv.lock` pins R 4.3.1 and `renv/library/R-4.3/`
is the populated library. Use `C:\Program Files\R\R-4.3.3\bin\` — R 4.5.2 is
installed on this machine but its renv library is empty.

A migration to R 4.5.2 was attempted on 2026-09-03 and failed (CHG-037); a manual
retry is planned — recorded in `session-handoff.md` §4. One of its two original
blockers, **ISS-036** (`forestHelperR` had no resolvable source in the lockfile), is
now resolved (CHG-040, 2026-09-06) as part of unrelated Connect Cloud publish work —
not yet re-verified against an actual restore under 4.5.2. The other blocker, a
compiled-package cascade led by `stringi`, is untouched.

**Toolchain:** Rtools45 (`C:\rtools45`). Rtools43 was removed by the winget upgrade,
so compiling source packages under R 4.3.x needs it reinstalled from CRAN first;
the existing R-4.3 library is already built, so running the app there is unaffected.

## Test suite
- `tests/testthat/test-helpers.R` — 23 `test_that` blocks / **48 assertions**, pure helper functions
- `tests/testthat/test-shiny-app.R` — 6 `test_that` blocks / **9 assertions**, shinytest2 integration
- `tests/fixtures/` — CSV fixture files for integration tests

Run with:

```r
testthat::test_file("tests/testthat/test-helpers.R")
testthat::test_file("tests/testthat/test-shiny-app.R")
```

**`NOT_CRAN=true` is required for the integration tests.** `shinytest2`'s
`AppDriver$new()` calls `skip_on_cran()` internally, so without it all 6 blocks
skip silently and the run still exits 0 — it looks like a pass. `devtools::test()`
and RStudio's test runner set it for you; a bare `Rscript -e ...` does not:

```sh
NOT_CRAN=true Rscript -e 'testthat::test_file("tests/testthat/test-shiny-app.R")'
```

Counts above are assertions, not blocks — the register's per-CHG "48 unit tests,
9/9 integration assertions" refers to the same figures.

## Current phase
DEC-005 restyle — **complete, including phase 2**. See `restyle-implementation-plan.md`
for the full plan and `app-changelog-decision-register.md` (CHG-029 – CHG-034, CHG-038) for
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
- Step 7 ✅ CHG-038: status-chip strip, rail badges (Variables count, Display dot),
  Help nav panel (FEAT-010)

**Gotcha worth remembering:** drawer panels are `display:none` by default, so Shiny
suspends any output inside them — including `downloadButton`s, which render as
`disabled` with an empty `href`. Anything live inside a hidden panel needs
`outputOptions(output, "<id>", suspendWhenHidden = FALSE)` in `server/drawers.R`.

**Open issues (see `issues-register.md`):**
- ISS-028: age group sort order in simulated data (Medium — likely in `forestHelperR`)
- ISS-029: OS system fonts absent from selector after sysfonts migration (Low)
- ISS-030: `"Source Sans Pro"` renamed on Google Fonts, silently absent (Low)

**Next session:** Restyle (including Step 7 / FEAT-010) is shipped and committed.
`handover-dec004-file-split.md` is now historical — DEC-004 is complete.

**2026-09-06 — Connect Cloud publish in progress.** See `session-handoff.md` §3 for
full detail and current status. ISS-036 turned out to block this too, not just the
R 4.5.2 migration — first deploy attempt failed on it directly (`forestHelperR`'s
`"Cellar"` source meant nothing to Connect Cloud's own server-side resolution), so
it's now **fully resolved** (CHG-040): `forestHelperR` published to
`github.com/DunnNAM/forestHelperR` (sanitized — see that repo and CHG-040 for what
attribution changed and why), `renv.lock` updated to a real GitHub source. Also
turned up that Connect Cloud's free tier only lists public repos regardless of
GitHub App permissions — both this repo and `forestHelperR` are now public as a
result. Next: push, retry the deploy (should now succeed), enable auto-deploy, then
merge `design/modal-progression-workflow` into `main`.

## Conventions
- Always use explicit package::function() notation
- Update the changelog register for every code change made
- Do not guess — if unsure, ask before editing
- Prefer req() over is.null() guards in reactives
- All documentation in .md format

## Do not modify
- forestHelperR package files (separate repo)
- renv.lock — **except** the R 4.5.2 migration, where `renv::snapshot()` is
  authorised by DEC-006, and only once the suite is green under 4.5.2
