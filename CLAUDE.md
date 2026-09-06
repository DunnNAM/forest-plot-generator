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
  - `wizard.R` — first-visit setup wizard show/skip/auto-advance logic (FEAT-011,
    merged 2026-09-06)
- `R/` — pure helpers and UI helper functions (auto-sourced by Shiny):
  - `helpers.R` — pure helper functions (also used by tests)
  - `ui_rail.R` — `railUI()`, the seven bottom-rail buttons (adds "Tour", FEAT-011)
  - `ui_drawers.R` — drawer shell
  - `ui_plot_options.R` — per-panel UI (`dataPanelUI()`, `variablesPanelUI()`,
    `displayPanelUI()`, `textPanelUI()`, `orderPanelUI()`, `exportPanelUI()`)
  - `ui_help.R` — `helpPanelUI()`, the static Help nav panel content (FEAT-010)
  - `ui_wizard.R` — `wizardWelcomeModal()`/`wizardVariablesModal()`, the first-visit
    setup wizard's modal content (FEAT-011)
- `www/wizard.js` — first-visit `localStorage` detection for the wizard, bound via
  jQuery (`shiny:connected` fires through `.trigger()`, which a native
  `addEventListener` can't catch — ISS-038, fixed)
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
DEC-005 restyle — **complete** (Steps 0-7, CHG-029–034/038). `design/modal-progression-
workflow` (FEAT-011, the first-visit wizard + Data-drawer/navbar visual redesign) —
**merged to `main` 2026-09-06** via rebase + fast-forward; both branches now point at
the same commit. See `restyle-implementation-plan.md` for the DEC-005 plan and
`app-changelog-decision-register.md`'s **CHG-041–058** for what FEAT-011 shipped (its
own commits/docs originally used CHG-039–056 — see that file's renumbering note for
why the merge shifted them by +2 to avoid colliding with `main`'s real CHG-039/040).

**Architecture decisions in force:**
- **DEC-004** — no Shiny modules. `source()` split into named files in `server/` +
  UI helper functions in `R/`. All `server/` files sourced inside the `server`
  function with `local = TRUE`.
- **DEC-005** — MDT visual language (CAQ palette, cream background, navbar) with a
  full-width **bottom** rail and a drawer sliding **up**. No sidebar. Drawer panels
  are rendered *statically* in `ui.R` and the active panel is chosen by toggling a
  CSS class — every input ID stays in the DOM from app start. Navbar tabs are now
  filled slate/cream **pills** (CHG-055), not an underline/divider — see that entry
  if touching navbar CSS again.
- **Posit Connect Cloud** — `main` is published there (confirmed 2026-09-06). Deploy
  manifest is `manifest.json`, regenerated via `rsconnect::writeManifest(appDir = ".")`.
  `forestHelperR` is installed from a real GitHub source
  (`github.com/DunnNAM/forestHelperR`, sanitized), not a local `.tar.gz` — both that
  repo and this one are now **public** (Connect Cloud's free tier only lists public
  repos in its picker). **Not yet confirmed:** whether auto-deploy-on-push is turned
  on — check Connect Cloud directly.

**Gotcha worth remembering:** drawer panels are `display:none` by default, so Shiny
suspends any output inside them — including `downloadButton`s, which render as
`disabled` with an empty `href`. Anything live inside a hidden panel needs
`outputOptions(output, "<id>", suspendWhenHidden = FALSE)` in `server/drawers.R`.

**A real history purge happened 2026-09-06** (see `session-handoff.md`'s top-of-file
note): a colleague's real name/email were in every historical version of `renv.lock`
(CHG-040 had sanitized the *current* content but deliberately left history
unrewritten). A `git filter-branch` pass scrubbed it from every historical blob on
both `main` and this branch, verified by scanning the object database directly, then
force-pushed. **Every commit hash predating 2026-09-06 no longer exists** — match old
references by commit subject line, not hash.

**Open issues (see `issues-register.md` for full detail on all of these):**
- ISS-042: Help page title still not left-aligned (Low — navbar sub-issues 2/3 already
  resolved, CHG-055)
- ISS-041: `README.md` describes the pre-restyle app — stale, not yet rewritten (Medium)
- ISS-045–048: architecture-review findings (wizard Step 2 modal styling gap; widespread
  un-namespaced calls; testability/DRY items) — all open, none started
- ISS-028/029/030: pre-existing, unchanged (age-group sort order, OS fonts, renamed
  Google Font — all Low/Medium, mostly out of this repo's scope)

**Next session:** see `session-handoff.md` for the full post-merge checklist — it has
specific things worth verifying that this session didn't (Connect Cloud auto-deploy
status, a live visual check of the merged FEAT-011 UI, GitHub Support's response on
the history-purge ticket).

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
