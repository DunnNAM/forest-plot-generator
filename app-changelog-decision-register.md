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
| PDEC-006 | Should `forestHelperR` declare its dependencies more explicitly so that `.tar.gz` installs resolve them automatically, or should the install documentation be updated to instruct users to install dependencies first? | ISS-014 (app), `forestHelperR` `DESCRIPTION` | Low — parked for future package maintenance cycle | Future package release |

> **Closed pending decisions:** PDEC-002 → DEC-002 (May 2026).

---

## Changes

### CHG-014 — ISS-004 Phase 1: testthat unit tests for pure helper functions

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-004 |

**Files added:** `R/helpers.R`, `tests/testthat/test-helpers.R`, `tests/testthat/helper-setup.R`  
**Files changed:** `server.R`, `renv.lock`

**Summary:**

Phase 1 of ISS-004 — unit tests for pure (non-Shiny) functions extracted from `server.R`. `shinytest2` integration testing is a separate phase (not addressed here).

**Test infrastructure:**

`testthat` initialised via `usethis::use_testthat()`. `tests/testthat/helper-setup.R` sources `R/helpers.R` before each test run (testthat auto-sources `helper-*.R` files). `renv::snapshot()` run after install — `testthat` and its dependencies added to `renv.lock`. `usethis` and its dependencies also captured.

**Functions extracted to `R/helpers.R`** (Shiny auto-sources all `R/*.R` files):

| Function | Extracted from | Logic |
|---|---|---|
| `is_col_included(col_name)` | `data_updated()` lines 192–212 | Returns `FALSE` for zero-length input or `"empty"` placeholder; `TRUE` otherwise |
| `get_est_type(regression_type, inv)` | `est_type` reactive | Returns `"RR"`, `"OR"`, `"HR"`, `"1/HR"`, or `"Estimate"` |
| `get_font_expansion(font)` | `dims()` reactive | Returns `1.2` for wide-metric fonts; `1` for all others |
| `serialise_plot_title(plot_title)` | `r_code_string()` | `""` → `"NULL"`; otherwise quoted |
| `serialise_by_var(by_group, group_var_name)` | `r_code_string()` | `FALSE` → `"NA"`; otherwise quoted |
| `serialise_x_ticks(xticks, xlims)` | `r_code_string()` | No ticks in range → `"NULL"`; otherwise `c(...)` of full `xticks` |
| `serialise_chr_vec(vec)` | `r_code_string()` | Zero-length → `"c()"`; otherwise `c("a", "b", ...)` — used for `vars_excl`, `elements`, `rj` |
| `serialise_bg_stripe(striped_bg, bg_stripe)` | `r_code_string()` | `FALSE` → `"NA"`; otherwise quoted colour |
| `serialise_footnote(footnote)` | `r_code_string()` | `""` → `'""'`; otherwise quoted — empty footnote passes `""` not `NULL` |

**`server.R` changes:**

| Location | Before | After |
|---|---|---|
| `data_updated()` lines 192–212 | 18-line `n_included` / `p_included` / `significance_included` if-else blocks | 3 one-liner calls to `is_col_included()` |
| `est_type` reactive body | 9-line if-else chain | `get_est_type(input$regression_type, input$inv)` |
| `dims()` expansion assignment | 3-line if-else | `get_font_expansion(input$font)` |
| `r_code_string()` preamble | 16-line block with inline branching, intermediate `ticks_in_range`, `vars_excl`, `rj` assignments | 10 assignments calling named serialisation helpers |

**Test results:** 48 tests, 0 failures, 0 warnings.

**ISS-004 status:** → **In progress** — Phase 1 (pure function unit tests) complete. Phase 2 (`shinytest2` reactive/UI tests) pending.

---

### CHG-013 — FEAT-001: R code serialiser — Copy R code / Download .R script buttons

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | FEAT-001 |

**Files changed:** `global.R`, `ui.R`, `server.R`

**Summary of changes:**

| File | Change |
|---|---|
| `global.R` | `library(glue)` and `library(clipr)` added after `library(forestHelperR)` |
| `ui.R` | Two buttons added to the Plot tab alongside the existing download buttons: `actionButton("copy_r_code", "Copy R code")` and `downloadButton("download_r_code", "Download .R script")` |
| `server.R` | `r_code_string()` reactive added; `observeEvent(input$copy_r_code)` added; `output$download_r_code` download handler added |

**`r_code_string()` reactive — edge cases handled:**

| Argument | Rule |
|---|---|
| `plot_title` | `NULL` in output string when `input$plot_title == ""`; otherwise quoted |
| `x_axis_ticks` | `NULL` when no `input$xticks` values fall within `input$xlims`; otherwise `c(...)` of the full `input$xticks` vector (mirrors `forest_plot_object` logic exactly) |
| `by_var` | `NA` when `input$by_group` is `FALSE`; otherwise quoted `input$group_var_name` |
| `variables_excluded` | `c()` when none excluded; otherwise `c("...", ...)` |
| `elements` | Serialised from `order()` reactive to preserve user column ordering |
| `right_justify` | `c()` when empty; otherwise `c("...", ...)` |
| `bg_stripe` | `NA` when `input$striped_bg` is `FALSE`; otherwise quoted colour string |
| Character args | Quoted in output string |
| Logical and numeric args | Unquoted in output string |
| `table` | `your_data` placeholder — the underlying data frame cannot be serialised from the GUI |

**Copy handler:** `clipr::write_clip()` wrapped in `tryCatch()`; `shiny::showNotification()` fired on both success and failure (e.g. headless server with no clipboard).

**Download handler:** `writeLines(r_code_string(), file)` writes a `.R` file named `forestplot_code.R`.

**`req(reg_table())`** added at the top of `r_code_string()` to suspend the reactive until data is available, consistent with project convention.

---

### CHG-012 — Cache simulated dataset as `dat.rds`; resolve ISS-012

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-012 |

**Files changed:** `global.R`

**Change:** Replaced the unconditional `source(here::here("data", "data_creation.R"))` call with a conditional block:

```r
if (file.exists(here::here("data", "dat.rds"))) {
  dat <- readRDS(here::here("data", "dat.rds"))
} else {
  source(here::here("data", "data_creation.R"))
}
```

**Rationale:** `data_creation.R` calls `mvtnorm::rmvnorm()` to generate 5,000 synthetic records on every cold start, adding unnecessary startup latency. The `.rds` path eliminates this by loading a pre-serialised object instead. The `else` fallback ensures the app still starts correctly on machines where the cache has not yet been created.

**To activate the cache:** run once interactively from the project root:

```r
source(here::here("data", "data_creation.R"))
saveRDS(dat, here::here("data", "dat.rds"))
```

Then commit `data/dat.rds`. Until the file is committed, cold-start behaviour is unchanged.

**ISS-012 status:** → **Resolved**

---

### CHG-011 — Initialise `renv`; resolve ISS-011

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn |
| **Status** | Implemented |
| **Refs** | ISS-011 |

**Files added:** `renv.lock`, `renv/` directory, `.Rprofile` (renv bootstrap entry)

`renv::init()` run and `renv.lock` committed. All 18+ app package dependencies are now version-pinned for reproducible installs across machines and deployment targets.

To restore the exact package environment on a new machine:

```r
renv::restore()
```

**ISS-011 status:** → **Resolved**

---

### CHG-010 — Create `README.md`; resolve ISS-007 and ISS-008

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-007, ISS-008 |

**Files added:** `README.md` (project root) — replaces the two-line stub that existed previously.

**Sections:**

| Section | Content |
|---|---|
| Project purpose | Upload and simulated data modes; `forestHelperR` dependency described |
| Prerequisites | R ≥ 4.1, RStudio, `forestHelperR` |
| Installation | Clone; `forestHelperR` install (CAQ internal repo and `.tar.gz` paths documented); app package list; one-time `extrafont::font_import()` step with the silent-fallback caveat (ISS-002) |
| Running the app | RStudio, R console, and terminal invocations |
| Usage overview | 6-step walkthrough of the upload → confirm → plot → export flow |
| Known limitations | ISS-002 (fonts), ISS-004 (no tests), ISS-011 (no renv), ISS-012 (startup latency) |
| Project structure | Annotated directory tree |
| Contributing | Bug reporting via issues register; conventions summary |

**ISS-007 status:** → **Resolved**
**ISS-008 status:** → **Resolved**

---

### CHG-009 — Batch 3: dead code removal + reactive tidying (ISS-022, 023, 024, 025, 016/026)

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-022, ISS-023, ISS-024, ISS-025, ISS-016, ISS-026 |

**Files changed:** `server.R`, `ui.R`

**Summary of changes:**

| ISS | File | Change |
|---|---|---|
| ISS-024 | `ui.R` | Deleted 83-line commented-out `page_sidebar()` alternative layout (lines 190–272). Dead code with a development note; preserved in this register for traceability. |
| ISS-025 | `server.R` | Deleted 42-line commented-out `display_option_update` reactive and associated `observe()` (§h / §i, lines 679–720). Implementation was incomplete and contained a copy-paste bug (`input$n_name` checked instead of `input$significance_name` in the `significance_included` branch). |
| ISS-022 | `server.R` | Deleted redundant §b observer (`!("est" %in% input$elements)` → unset `concatenate_est_ci`). Its condition is a strict subset of §e's (`!est \| !lci`), making §b dead in practice. Added `bindEvent(input$elements)` to §e so it no longer fires on every reactive flush. |
| ISS-023 | `server.R` | Replaced `if (!is.null(fit()))` and `if (!is.null(data_updated()))` guards in `reg_table()` with `req(fit())` and `req(data_updated())`. Both callees already use `req()` internally so cannot return `NULL`; the `is.null` checks were guarding an unreachable state. `req()` suspends cleanly and is consistent with the project convention. |
| ISS-016/026 | `server.R` | Removed duplicate `"Source Sans Pro"` from the 1.2× font expansion vector in `dims()`; added `"Open Sans"` and `"Montserrat"`, which have similar character metrics and are available in the font selector. **Verification required:** the 1.2× multiplier for `"Open Sans"` and `"Montserrat"` has not been empirically tested — render a test plot with each font and confirm sizing before treating this list as final. |

**ISS-022 status:** → **Resolved**
**ISS-023 status:** → **Resolved**
**ISS-024 status:** → **Resolved**
**ISS-025 status:** → **Resolved**
**ISS-016 status:** → **Resolved** *(empirical verification of Open Sans / Montserrat expansion factor pending)*
**ISS-026 status:** → **Resolved** *(empirical verification of Open Sans expansion factor pending)*

---

### CHG-008 — Fix ISS-017, ISS-018, ISS-019, ISS-027: UI label corrections (Batch 2)

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-017, ISS-018, ISS-019, ISS-027 |

**Files changed:** `ui.R`

**Summary of changes:**

| ISS | Location | Before | After |
|---|---|---|---|
| ISS-017 | `ui.R`, line 5 | `title = "Forest plot function testing"` | `title = "Forest Plot Builder"` |
| ISS-018 | `ui.R`, line 180 | `selectizeInput("variable_font_face", "x-axis label", ...)` | label → `"Variable header font face"` |
| ISS-018 | `ui.R`, line 181 | `selectizeInput("pval_font_face", "x-axis label", ...)` | label → `"p-value font face"` |
| ISS-019 | `ui.R`, line 120 | `colourInput("ci_colour2", "Confidence interval colour", ...)` | label → `"Group 2 confidence interval colour"` |
| ISS-027 | `ui.R`, line 17 | `fileInput` label — no instruction on simultaneous selection | Appended: `"To compare two regressions, select both files at once using Ctrl+click (Windows) or Cmd+click (Mac)."` |

**Rationale:**

- **ISS-017:** Development placeholder title was visible in the browser tab and page header.
- **ISS-018:** `variable_font_face` and `pval_font_face` both displayed `"x-axis label"` due to copy-paste, making the controls unidentifiable to users.
- **ISS-019:** Both CI colour pickers showed identical `"Confidence interval colour"` labels when `by_group` was enabled, preventing users from distinguishing which group each controlled.
- **ISS-027:** The file input gave no indication that simultaneous selection is required for two-group comparison; users attempting sequential upload received no feedback.

**ISS-017 status:** → **Resolved**
**ISS-018 status:** → **Resolved**
**ISS-019 status:** → **Resolved**
**ISS-027 status:** → **Resolved**

---

### CHG-007 — Fix ISS-013, ISS-014, ISS-015: namespace qualifiers and undeclared package declarations

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-013, ISS-014, ISS-015 |

**Files changed:** `server.R`, `global.R`

**Summary of changes:**

| ISS | File | Location | Before | After |
|---|---|---|---|---|
| ISS-013 | `server.R` | Line 291 | `coxph(form2, data = dat)` | `survival::coxph(form2, data = dat)` |
| ISS-015 | `server.R` | Line 526 | `get_wh(forest_plot_object(), unit = "in")` | `forestploter::get_wh(forest_plot_object(), unit = "in")` |
| ISS-014 | `global.R` | After `library(colourpicker)` | — | `library(broom)`, `library(lmtest)`, `library(sandwich)` added |

**Rationale:**

- **ISS-013:** `coxph()` is exported by the `survival` package, which is loaded via `library(survival)`. Without an explicit qualifier the call relies on search-path resolution, which can break if package load order changes or if another package exports a symbol with the same name. Convention requires `package::function()` throughout.
- **ISS-015:** `get_wh()` is exported by `forestploter`. Same rationale as ISS-013.
- **ISS-014:** `broom`, `lmtest`, and `sandwich` are used in `output$robust` (`broom::tidy()`, `lmtest::coeftest()`, `lmtest::coefci()`, `sandwich::vcovHC`) but were not declared in `global.R`. The app relied on these packages being present as indirect dependencies of other loaded packages, which is not guaranteed. Explicit `library()` calls make the dependency contract clear and ensure the app fails loudly at startup if any package is missing rather than silently at runtime.

**ISS-013 status:** → **Resolved**  
**ISS-014 status:** → **Resolved**  
**ISS-015 status:** → **Resolved**

---

### CHG-006 — Fix ISS-020: reset column confirmation on new file upload

| Field | Detail |
|---|---|
| **Date** | May 2026 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-020 |

**Files changed:** `server.R`

**Summary of changes:**

Three additions immediately after `output$sortable`:

```r
cols_confirmed <- reactiveVal(0)

observeEvent(input$cols, {
  cols_confirmed(cols_confirmed() + 1)
})

observeEvent(input$upload, {
  cols_confirmed(0)
})
```

`data_updated()` changes:
- `req(cols_confirmed() > 0)` added immediately after `req(data_uploaded())` as an explicit suspension gate
- `bindEvent(input$cols)` replaced with `bindEvent(cols_confirmed(), ignoreInit = TRUE)`
- `ignoreNULL = FALSE` not used — `req()` handles the zero-state gate cleanly

The section heading `#### ii` was also renumbered to `#### iii` to reflect the new `#### ii — column confirmation gate` section inserted above it.

**Rationale:** Previously `data_updated()` bound directly to `input$cols`. When a new file was uploaded, `input$cols` retained its previous value and `data_updated()` immediately re-executed with the new file's data but the old column mapping, causing a `Column 'variable' doesn't exist` crash. The `reactiveVal` counter is reset to `0` on upload and incremented on confirmation, giving explicit control over when processing is permitted. The `req(cols_confirmed() > 0)` guard provides a clean suspension point that prevents any downstream reactives from receiving stale or mismatched data.

**Testing notes:** Tested by uploading File A, confirming, then uploading File B. Before fix: app crashed with `dplyr::select` error. After fix: Review Data tab clears on File B upload and remains blank until the user confirms the new column mapping.

**ISS-020 status:** → **Resolved**

---

### CHG-005 — Fix ISS-021: correct LCI/UCI label order; dynamic column label vector in `output$dat_upload`

| Field | Detail |
|---|---|
| **Date** | May 2026 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-021 |

**Files changed:** `server.R`

**Summary of changes to `output$dat_upload`:**

| Before | After |
|---|---|
| `cols <- c("Variable", "Level", "Estimate", "UCI (95%CI)", "LCI (95%CI)", "n", "p", "Significance")` — hardcoded 8-element vector with LCI/UCI swapped | `cols` built dynamically starting from the five always-present columns in correct order; optional columns appended only when present in `colnames(data_updated())` |
| `formatRound` checks used `input$n_name != "empty"` | `formatRound` checks use `"n" %in% colnames(data_updated())` — consistent with the dynamic cols vector and more direct |

**Rationale:** The hardcoded `cols` vector had two defects: (1) `"UCI (95%CI)"` and `"LCI (95%CI)"` were in the wrong order relative to the actual column order produced by `data_updated()` (`est`, `lci`, `uci`), meaning the lower CI bound was labelled as the upper and vice versa — a correctness risk in a clinical reporting context; (2) the fixed-length vector would cause a DT column count mismatch error if optional columns (`n`, `p`, `significance`) were absent from the uploaded file.

**Testing notes:** Tested with File A (8 columns — all labels correct, LCI/UCI in correct positions) and File B (5 columns — table renders without error, no spurious optional column headers).

**ISS-021 status:** → **Resolved**

---

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

**`.here` sentinel file:** An empty `.here` file has been added to the project root. This explicitly anchors `here::here()` resolution regardless of whether an `.Rproj` file is present on the server, ensuring consistent behaviour across all deployment contexts.

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
| May 2026 | Full code review of `global.R`, `ui.R`, `server.R` | ISS-013 through ISS-026 raised. ISS-021 and ISS-020 prioritised for resolution. |
| May 2026 | ISS-021 resolved (CHG-005) — LCI/UCI label swap corrected; dynamic column label vector implemented | Tested with 8-column and 5-column files. Pass. |
| May 2026 | ISS-020 resolved (CHG-006) — column confirmation reset on new file upload | Initial implementation required a follow-up fix: `req(cols_confirmed() > 0)` added after crash observed on sequential file upload. Tested with File A → File B sequence. Pass. |
| May 2026 | Two-group upload UX clarified during ISS-020 testing | Confirmed by design: both files must be selected simultaneously in the file picker for two-group comparison. Sequential upload replaces the previous file. ISS-027 raised as a low-priority UX clarification item. |
| May 2026 | `forestHelperR` v0.2.0 built as `.tar.gz` and installed locally | Four undeclared dependencies (`extrafont`, `forestploter`, `lmtest`, `sandwich`) required manual pre-installation. PDEC-006 raised to address in a future package maintenance cycle. |
| 2026-05-11 | Batch 1 fixes applied — ISS-013, ISS-014, ISS-015 resolved (CHG-007) | `survival::coxph()`, `forestploter::get_wh()` qualified; `broom`, `lmtest`, `sandwich` declared in `global.R` |
| 2026-05-11 | Batch 2 fixes applied — ISS-017, ISS-018, ISS-019, ISS-027 resolved (CHG-008) | App title corrected; font face labels fixed; ci_colour2 label disambiguated; fileInput label expanded with two-file selection instruction |
| — | Remaining open issues | Pending — Batch 3 (ISS-022, 023, 024, 025, 016/026) to be addressed in subsequent sessions |
| 2026-05-11 | Batch 3 fixes applied — ISS-022, ISS-023, ISS-024, ISS-025, ISS-016, ISS-026 resolved (CHG-009) | Dead code deleted (commented-out UI block, commented-out reactive); §b observer consolidated into §e with `bindEvent`; `reg_table()` `is.null` guards replaced with `req()`; font expansion vector corrected (duplicate removed, Open Sans and Montserrat added — empirical verification pending) |
| 2026-05-11 | Batch 3 runtime testing — ISS-002 confirmed active | Font selector shows only 5 base system fonts (Helvetica, Times, Courier, Palatino, Bookman). Custom fonts absent — `extrafont` import has not been run on this machine. Silent fallback with no user-facing error, consistent with ISS-002 description. ISS-016/026 expansion factor verification blocked. Issue parked as non-critical. |
| 2026-05-11 | `README.md` created — ISS-007, ISS-008 resolved (CHG-010) | Stub README replaced. Full install instructions, one-time font import step, `forestHelperR` both-path documentation, usage overview, known limitations, and contributing guidelines. |
| 2026-05-11 | `renv` initialised and committed — ISS-011 resolved (CHG-011) | `renv.lock` committed. All app package dependencies version-pinned. |
| 2026-05-11 | `dat.rds` caching logic added to `global.R` — ISS-012 resolved (CHG-012) | Conditional load: reads `data/dat.rds` if present, falls back to `source(data_creation.R)`. Cache must be created once interactively and committed to activate. |
| 2026-05-11 | ISS-004 Phase 1 — test infrastructure initialised; 9 pure helpers extracted to `R/helpers.R`; 48 unit tests passing (CHG-014) | `testthat` wired up via `usethis::use_testthat()`. `renv.lock` updated. `server.R` refactored to call helpers. Phase 2 (`shinytest2`) pending. |

---

*Document version: 1.3 — CHG-014 implemented; ISS-004 Phase 1 (pure function unit tests) delivered*
