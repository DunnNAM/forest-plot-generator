# Forest Plot Builder — Issues Register

> **Prepared:** May 2026  
> **Reviewer:** Claude (Anthropic)  
> **Source document:** `forest-plot-builder.md` (April 2026); code review of `global.R`, `ui.R`, `server.R` (May 2026)  
> **Status:** Active — code review complete; issues being resolved

---

## How to use this register

| Field | Description |
|---|---|
| **ID** | Unique identifier — prefix `ISS` for issues |
| **Source** | Where the issue was identified: `DOC` = source documentation, `REVIEW` = code review, `RUNTIME` = observed during testing |
| **Severity** | `Critical` / `High` / `Medium` / `Low` |
| **Status** | `Open` / `In progress` / `Resolved` / `Deferred` |
| **Resolution** | Summary of fix applied (populated when resolved) |

---

## Critical Issues

### ISS-001 — Hardcoded absolute file paths (`setwd()`)

| Field | Detail |
|---|---|
| **Source** | DOC |
| **Severity** | Critical |
| **Status** | **Resolved — CHG-004** |
| **Resolution** | `setwd()` block removed. `library(here)` added. `source()` call updated to `source(here::here("data", "data_creation.R"))`. `.here` sentinel file added to project root. |
| **File(s)** | `global.R` |

---

## High Severity Issues

### ISS-002 — Font import not portable

| Field | Detail |
|---|---|
| **Source** | DOC |
| **Severity** | High |
| **Status** | **Resolved — CHG-016** |
| **File(s)** | `global.R` |
| **Description** | `extrafont::font_import()` is commented out. `loadfonts()` will silently fail on any machine where fonts have not been pre-imported interactively. Lato font files are bundled in the `Lato/` directory but the import step is not automated. |
| **Risk** | Font rendering will fall back silently on new machines, producing plots with incorrect fonts without any error message to the user. |
| **Recommended fix** | Add a startup check: if the target font is not found in `extrafont::fonts()`, emit a clear `warning()` or `message()` in the UI. Document the one-time setup step clearly in a `README.md`. Consider whether `sysfonts` / `showtext` would be a more portable alternative (see PDEC-003). |
| **Runtime observation (2026-05-11)** | Confirmed during Batch 3 testing. Font selector shows only 5 base R/system fonts (Helvetica, Times, Courier, Palatino, Bookman). Custom fonts (Lato, Roboto, Open Sans, Source Sans Pro, Montserrat) are absent — consistent with `extrafont` fonts not having been imported on this machine. The silent fallback means no error is surfaced to the user. ISS-016/026 empirical verification (1.2× expansion factor for Open Sans and Montserrat) is blocked until this issue is resolved. **Parked as non-critical for now.** |
| **Resolution** | `extrafont` replaced with `sysfonts`/`showtext` (PDEC-003 → DEC-003). Lato registered at startup from bundled TTF files — no one-time import step required. Roboto, Open Sans, Montserrat loaded via `font_add_google()` wrapped in `tryCatch()` — fail silently when internet is unavailable and are filtered from the selector. Font availability check updated from `grDevices::postscriptFonts()` to `sysfonts::font_families()`. Verified: Lato, Open Sans, Roboto, Montserrat appear in selector on a machine with internet access. Note: `"Source Sans Pro"` has been renamed `"Source Sans 3"` on Google Fonts and fails silently — see ISS-030. Note: OS system fonts (Arial, Helvetica, Times, etc.) no longer appear in the selector — see ISS-029. |

### ISS-003 — Two-file upload uses fragile `for` loop pattern

| Field | Detail |
|---|---|
| **Source** | DOC |
| **Severity** | High |
| **Status** | **Resolved — prior to this review** |
| **Resolution** | Refactored to `lapply()` + `dplyr::bind_rows()` with per-file extension switching. Comment in `server.R` confirms fix. |

### ISS-004 — No unit tests

| Field | Detail |
|---|---|
| **Source** | DOC |
| **Severity** | High |
| **Status** | **Resolved — CHG-014 (Phase 1), CHG-015 (Phase 2)** |
| **File(s)** | All |
| **Description** | No unit tests exist for the reactive chain, data processing logic, or export handlers. |
| **Risk** | Regressions will go undetected. Export handlers and column mapping logic are particularly high-risk without tests. |
| **Recommended fix** | Introduce `shinytest2` for reactive/UI tests and `testthat` for unit tests on pure functions. Prioritise testing the two-file upload path and the column confirmation reactive chain. See FEAT-002. |
| **Resolution** | **Phase 1 (2026-05-11):** `testthat` infrastructure initialised. 9 pure helper functions extracted from `server.R` to `R/helpers.R`. 48 unit tests written in `tests/testthat/test-helpers.R` — all passing. `renv.lock` updated. **Phase 2 (2026-05-11):** `shinytest2` infrastructure added. 7 integration tests written in `tests/testthat/test-shiny-app.R` covering the column confirmation gate (ISS-020 regression guard), two-file upload, and regression type → estimate label reactive chain — all passing. Two fixture files added to `tests/fixtures/`. |

### ISS-005 — `functions/functions.R` is orphaned but retained

| Field | Detail |
|---|---|
| **Source** | DOC |
| **Severity** | High |
| **Status** | **Resolved — DEC-002** |
| **Resolution** | File deleted. All functionality provided by `forestHelperR` package. Traceability comment retained in `global.R`. |

### ISS-013 — `coxph()` called without `survival::` namespace qualifier

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | High |
| **Status** | **Resolved — CHG-007** |
| **File(s)** | `server.R`, line 266 |
| **Description** | The Cox model is fitted with an unqualified `coxph()` call, while the formula construction on line 263 correctly qualifies `survival::Surv()`. If `global.R` is ever refactored to remove `library(survival)`, this will produce a hard-to-diagnose error at runtime. |
| **Recommended fix** | Replace `coxph(form2, data = dat)` with `survival::coxph(form2, data = dat)`. |
| **Resolution** | `survival::coxph()` namespace qualifier added in `server.R`. |

### ISS-014 — `broom`, `lmtest`, and `sandwich` used but not declared in `global.R`

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | High |
| **Status** | **Resolved — CHG-007** |
| **File(s)** | `server.R`, lines 400–412; `global.R` |
| **Description** | `broom::tidy()`, `lmtest::coeftest()`, `lmtest::coefci()`, and `sandwich::vcovHC` are called in the robust variance preview but none of these packages appear in `global.R`. They work currently because they are accessed via `::`, but there is no startup-time check they are installed and they are invisible to dependency audits. |
| **Risk** | On a fresh deployment, the app starts successfully but fails silently when robust variance is enabled. |
| **Recommended fix** | Add `library(broom)`, `library(lmtest)`, and `library(sandwich)` to `global.R`. See also PDEC-006 regarding `forestHelperR` dependency declaration. |
| **Resolution** | `library(broom)`, `library(lmtest)`, and `library(sandwich)` added to `global.R`. |

### ISS-015 — `get_wh()` called without `forestploter::` namespace qualifier

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | High |
| **Status** | **Resolved — CHG-007** |
| **File(s)** | `server.R`, line 499 |
| **Description** | `get_wh()` is called unqualified despite being provided by `forestploter`. Makes it unclear which package provides the function given the adjacent `forestHelperR::forestPloter()` calls. |
| **Recommended fix** | Replace with `forestploter::get_wh(forest_plot_object(), unit = "in")`. |
| **Resolution** | `forestploter::get_wh()` namespace qualifier added in `server.R`. |

---

## Medium Severity Issues

### ISS-006 — `officer` package loaded but unused

| Field | Detail |
|---|---|
| **Source** | DOC |
| **Severity** | Medium |
| **Status** | **Resolved — prior to this review (PDEC-004 / CHG-002)** |
| **Resolution** | `library(officer)` removed. Comment retained in `global.R` noting it should be added back when FEAT-004 is implemented. |

### ISS-007 — No `README.md` exists

| Field | Detail |
|---|---|
| **Source** | DOC |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-010** |
| **File(s)** | Repository root |
| **Description** | No `README.md` for the Shiny app project. Setup steps (font import, `forestHelperR` installation, how to run) were not documented in an onboarding-friendly format. |
| **Resolution** | `README.md` created at the project root. Covers: project purpose, prerequisites, installation (app dependencies, `forestHelperR`, one-time font import), how to run locally, usage overview, known limitations, project structure, and contributing guidelines. |

### ISS-008 — `forestHelperR` install path undocumented in app project

| Field | Detail |
|---|---|
| **Source** | DOC |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-010** |
| **File(s)** | Repository root |
| **Description** | `forestHelperR` is the core dependency but its install source was not documented in the app project. The package `README.md` contained correct install instructions; these needed to be mirrored in the app `README.md`. |
| **Resolution** | `README.md` documents both install paths: (A) CAQ internal repository for CAQ staff, (B) `.tar.gz` install for others. Pre-installation of undeclared `forestHelperR` dependencies (`extrafont`, `forestploter`, `lmtest`, `sandwich`) also documented, consistent with PDEC-006. |

### ISS-011 — No `renv` or dependency lockfile

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-011** |
| **File(s)** | Repository root |
| **Description** | No `renv.lock` or equivalent. The app depends on 18+ packages. |
| **Resolution** | `renv` initialised and `renv.lock` committed. Package versions are now pinned for reproducible installs. |

### ISS-016 — Duplicate `"Source Sans Pro"` in font expansion check

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-009** |
| **File(s)** | `server.R`, line 496 |
| **Description** | `"Source Sans Pro"` appears twice in the font expansion vector. The duplicate is harmless but suggests a fourth font (possibly `"Open Sans"` or `"Montserrat"`) was intended. See also ISS-026. |
| **Recommended fix** | Confirm the intended expansion font list and correct the vector. |
| **Resolution** | Duplicate `"Source Sans Pro"` removed. `"Open Sans"` and `"Montserrat"` added to the 1.2× expansion group. **Empirical verification pending** — the 1.2× factor for these two fonts has not been tested with actual plot output. Verify before treating as final. |

### ISS-017 — App title is a development placeholder

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-008** |
| **File(s)** | `ui.R`, line 5 |
| **Description** | App title reads `"Forest plot function testing"` — visible in the browser tab and page header. |
| **Resolution** | Title updated to `"Forest Plot Builder"`. |

### ISS-018 — Three `selectizeInput` labels all read `"x-axis label"`

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-008** |
| **File(s)** | `ui.R`, lines 180, 181 |
| **Description** | `input$variable_font_face` (line 180) and `input$pval_font_face` (line 181) both display `"x-axis label"` due to copy-paste. Users cannot identify the purpose of these controls. |
| **Resolution** | Line 180 label corrected to `"Variable header font face"`; line 181 label corrected to `"p-value font face"`. |

### ISS-019 — `ci_colour2` label identical to `ci_colour`

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-008** |
| **File(s)** | `ui.R`, line 120 |
| **Description** | Both CI colour pickers display `"Confidence interval colour"` when `by_group` is enabled. Users cannot distinguish which applies to which group. |
| **Resolution** | `ci_colour2` label updated to `"Group 2 confidence interval colour"`. |

### ISS-020 — Column confirmation not reset on new file upload

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-006** |
| **File(s)** | `server.R` |
| **Resolution** | `reactiveVal` counter `cols_confirmed` introduced. Increments on button click; resets to `0` on new file upload. `data_updated()` binds to the counter and includes `req(cols_confirmed() > 0)` as an explicit suspension gate. A follow-up fix was required during testing: initial implementation used `ignoreNULL = FALSE` on `bindEvent`, which caused a crash when the counter reset to `0` triggered re-execution before the `req()` guard was in place. Fix: `req(cols_confirmed() > 0)` added as the primary gate; `ignoreNULL = FALSE` removed. |

### ISS-021 — UCI/LCI labels swapped in `dat_upload` table; column count fragile

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-005** |
| **File(s)** | `server.R` |
| **Resolution** | `cols` vector in `output$dat_upload` rebuilt dynamically. Corrected label order: `"LCI (95%CI)"` before `"UCI (95%CI)"`. Optional columns (`n`, `p`, `significance`) appended only when present in `colnames(data_updated())`. `formatRound` checks updated to use column presence rather than `input$*_name` checks, consistent with the dynamic vector. Tested with 8-column and 5-column files — pass. |

### ISS-022 — `observe()` at §e missing `bindEvent()`

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-009** |
| **File(s)** | `server.R` |
| **Description** | The observer that unsets `concatenate_est_ci` when `est` or `lci` is deselected had no `bindEvent()`, causing it to fire on every reactive flush. There was also functional overlap with the §b observer (which fired on `!est` only — a strict subset of §e's `!est | !lci` condition). |
| **Resolution** | §b observer deleted (redundant — §e's condition is a superset). `bindEvent(input$elements)` added to §e so it fires only when `input$elements` changes. |

### ISS-023 — `reg_table()` returns `NULL` silently; fragile pattern

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-009** |
| **File(s)** | `server.R` |
| **Description** | `reg_table()` used `if (!is.null(...))` guards rather than `req()`, returning `NULL` silently when conditions were not met. `fit()` and `data_updated()` both use `req()` internally, so neither can return `NULL` — the guards were protecting an unreachable state. |
| **Resolution** | `if (!is.null(fit()))` replaced with `req(fit())`; `if (!is.null(data_updated()))` replaced with `req(data_updated())`. `req()` suspends cleanly and is consistent with the project convention. |

### ISS-027 — Two-group upload workflow not discoverable from UI

| Field | Detail |
|---|---|
| **Source** | RUNTIME — identified during ISS-020 testing |
| **Severity** | Low |
| **Status** | **Resolved — CHG-008** |
| **File(s)** | `ui.R` |
| **Description** | The two-group comparison feature requires both files to be selected simultaneously in the file picker. This is not explained anywhere in the UI — the file input label reads only `"Upload one or two files with regression output (csv/tsv required)."` with no indication that simultaneous selection is required. Users who upload files sequentially (a natural assumption) will find the first file replaced by the second with no feedback explaining why or how to use the two-group feature correctly. |
| **Resolution** | `fileInput` label extended to include: `"To compare two regressions, select both files at once using Ctrl+click (Windows) or Cmd+click (Mac)."` |

---

## Low Severity Issues

### ISS-028 — Age group levels not sorted in expected clinical order (simulated data)

| Field | Detail |
|---|---|
| **Source** | RUNTIME |
| **Severity** | Medium |
| **Status** | Open |
| **File(s)** | `data/data_creation.R`, `forestHelperR` package (`regTabler()`) |
| **Description** | In simulated data mode, the age group variable displays with the reference category (60–69) appearing first in the forest plot, ahead of the non-reference levels (<50, 50–59). Expected clinical display order is <50 → 50–59 → 60–69 (ref). The root cause is likely factor level ordering in `data_creation.R` or in `forestHelperR::regTabler()` — the reference level is the base factor level in the regression, which R places first by default. |
| **Risk** | Misleading variable display order in a clinical reporting context. |
| **Recommended fix** | Investigate factor level assignment in `data_creation.R` and row ordering in `regTabler()`. Reorder factor levels so the reference category appears last within each variable group, consistent with standard forest plot convention. Fix likely sits in the `forestHelperR` package, so raise as a package-level issue. |
| **Resolution** | — |

### ISS-029 — OS system fonts no longer available in font selector after `sysfonts`/`showtext` migration

| Field | Detail |
|---|---|
| **Source** | RUNTIME — identified during CHG-016 testing |
| **Severity** | Low |
| **Status** | Open |
| **File(s)** | `global.R` |
| **Description** | Prior to CHG-016, `extrafont::loadfonts()` registered OS system fonts (Helvetica, Times, Courier, Palatino, Bookman) with `grDevices`, making them available via `postscriptFonts()`. After migration to `sysfonts`/`showtext`, these fonts are no longer in `sysfonts::font_families()` because `sysfonts` requires explicit registration via `font_add()`. The font selector now shows only Lato and the Google Fonts that loaded successfully. |
| **Recommended fix** | Add `sysfonts::font_add()` calls for common OS system fonts using platform-conditional paths (e.g. `C:/Windows/Fonts/` on Windows, `/System/Library/Fonts/` on macOS). Wrap in `tryCatch()` consistent with the Google Fonts pattern so missing fonts fail silently. Limit to fonts already in the `fonts` vector in `global.R`. |
| **Resolution** | — |

### ISS-030 — `"Source Sans Pro"` renamed to `"Source Sans 3"` on Google Fonts; silently absent from selector

| Field | Detail |
|---|---|
| **Source** | RUNTIME — identified during CHG-016 testing |
| **Severity** | Low |
| **Status** | Open |
| **File(s)** | `global.R` |
| **Description** | `sysfonts::font_add_google("Source Sans Pro")` fails silently because Google Fonts renamed the family to `"Source Sans 3"`. The font does not appear in `font_families()` and is filtered from the selector. The `fonts` vector and the 1.2× expansion group in `R/helpers.R` both still reference `"Source Sans Pro"` by the old name. |
| **Recommended fix** | Update the `font_add_google()` call to `"Source Sans 3"`, update the `fonts` vector and `get_font_expansion()` in `R/helpers.R` to use the new family name. Verify the 1.2× expansion factor applies correctly under the new name. |
| **Resolution** | — |

### ISS-009 — Screenshot path is a placeholder

| Field | Detail |
|---|---|
| **Source** | DOC |
| **Severity** | Low |
| **Status** | **Resolved — CHG-017** |
| **File(s)** | `forest-plot-builder.md` (DataScienceHangout-Shinytalk repo) |
| **Description** | Documentation references `../assets/screenshot_forest.png` — a placeholder path. |
| **Recommended fix** | Add an actual screenshot and update the path. |
| **Resolution** | Screenshot file confirmed present at `assets/screenshot_forest.png`. Stale `<!-- Replace with actual screenshot path -->` HTML comment removed. Path was already correct. |

### ISS-010 — Talk date placeholder in documentation footer

| Field | Detail |
|---|---|
| **Source** | DOC |
| **Severity** | Low |
| **Status** | **Resolved — CHG-017** |
| **File(s)** | `forest-plot-builder.md` (DataScienceHangout-Shinytalk repo) |
| **Description** | Footer contains `[Month] [Year]` placeholders. |
| **Recommended fix** | Fill in the actual date or remove the footer. |
| **Resolution** | Footer updated to `May 2026`. |

### ISS-012 — `data_creation.R` sourced at startup with no caching

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Low |
| **Status** | **Resolved — CHG-012** |
| **File(s)** | `global.R` |
| **Description** | Synthetic dataset regenerated on every cold start via `mvtnorm::rmvnorm()`. Unnecessary latency. |
| **Resolution** | `global.R` updated to load `data/dat.rds` if the file exists, falling back to `source(data_creation.R)` if not. The cache must be created once interactively: `source(here::here("data", "data_creation.R")); saveRDS(dat, here::here("data", "dat.rds"))`. Until the `.rds` file is committed, cold-start behaviour is unchanged. |

### ISS-024 — Large commented-out UI block in `ui.R`

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Low |
| **Status** | **Resolved — CHG-009** |
| **File(s)** | `ui.R` |
| **Description** | 83-line commented-out `page_sidebar()` alternative layout. Dead code with a development note. |
| **Resolution** | Block deleted. The development note ("this code works and shows no grey box! but not pretty") is recorded here for traceability. |

### ISS-025 — Large commented-out reactive block in `server.R`

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Low |
| **Status** | **Resolved — CHG-009** |
| **File(s)** | `server.R` |
| **Description** | 42-line commented-out `display_option_update` reactive with an incomplete implementation and a copy-paste bug (`input$n_name` checked instead of `input$significance_name` in the `significance_included` branch). |
| **Resolution** | Block deleted. If dynamic element filtering is wanted in future, raise a clean feature request and implement from scratch. |

### ISS-026 — `"Open Sans"` likely missing from font expansion group

| Field | Detail |
|---|---|
| **Source** | REVIEW |
| **Severity** | Low |
| **Status** | **Resolved — CHG-009** |
| **File(s)** | `server.R` |
| **Description** | `"Open Sans"` was available in the font selector but absent from the 1.2× expansion group. Has similar character metrics to `"Lato"` and `"Roboto"`. |
| **Resolution** | `"Open Sans"` added to the expansion group (resolved alongside ISS-016). **Empirical verification pending** — confirm the 1.2× factor produces correct sizing for `"Open Sans"` with actual plot output. |

---

## Summary Table

| ID | Severity | Area | Short description | Status |
|---|---|---|---|---|
| ISS-001 | Critical | `global.R` | Hardcoded `setwd()` paths | ✅ Resolved — CHG-004 |
| ISS-002 | High | `global.R` | Font import not portable | ✅ Resolved — CHG-016 |
| ISS-003 | High | `server.R` | Two-file upload `for` loop | ✅ Resolved |
| ISS-004 | High | All | No unit tests | ✅ Resolved — CHG-014 (Phase 1), CHG-015 (Phase 2) |
| ISS-005 | High | `functions.R` | Orphaned legacy file | ✅ Resolved — DEC-002 |
| ISS-006 | Medium | `global.R` | `officer` loaded but unused | ✅ Resolved — CHG-002 |
| ISS-007 | Medium | Root | No `README.md` | ✅ Resolved — CHG-010 |
| ISS-008 | Medium | Root | `forestHelperR` install undocumented | ✅ Resolved — CHG-010 |
| ISS-009 | Low | Docs | Screenshot placeholder path | ✅ Resolved — CHG-017 |
| ISS-010 | Low | Docs | Talk date placeholder in footer | ✅ Resolved — CHG-017 |
| ISS-011 | Medium | Root | No `renv` lockfile | ✅ Resolved — CHG-011 |
| ISS-012 | Low | `global.R` | `data_creation.R` not cached | ✅ Resolved — CHG-012 |
| ISS-013 | High | `server.R` | `coxph()` missing `survival::` qualifier | ✅ Resolved — CHG-007 |
| ISS-014 | High | `server.R` / `global.R` | `broom`, `lmtest`, `sandwich` undeclared | ✅ Resolved — CHG-007 |
| ISS-015 | High | `server.R` | `get_wh()` missing `forestploter::` qualifier | ✅ Resolved — CHG-007 |
| ISS-016 | Medium | `server.R` | Duplicate `"Source Sans Pro"` in expansion font list | ✅ Resolved — CHG-009 *(verification pending)* |
| ISS-017 | Medium | `ui.R` | App title is a development placeholder | ✅ Resolved — CHG-008 |
| ISS-018 | Medium | `ui.R` | Three `selectizeInput` labels all read `"x-axis label"` | ✅ Resolved — CHG-008 |
| ISS-019 | Medium | `ui.R` | `ci_colour2` has same label as `ci_colour` | ✅ Resolved — CHG-008 |
| ISS-020 | Medium | `server.R` | Column confirmation not reset on new file upload | ✅ Resolved — CHG-006 |
| ISS-021 | Medium | `server.R` | UCI/LCI labels swapped; column count fragile | ✅ Resolved — CHG-005 |
| ISS-022 | Medium | `server.R` | `observe()` at §e missing `bindEvent()` | ✅ Resolved — CHG-009 |
| ISS-023 | Medium | `server.R` | `reg_table()` returns `NULL` silently | ✅ Resolved — CHG-009 |
| ISS-024 | Low | `ui.R` | 83-line commented-out layout block | ✅ Resolved — CHG-009 |
| ISS-025 | Low | `server.R` | 42-line commented-out reactive with copy-paste bug | ✅ Resolved — CHG-009 |
| ISS-026 | Low | `server.R` / `global.R` | `"Open Sans"` missing from font expansion group | ✅ Resolved — CHG-009 *(verification pending)* |
| ISS-027 | Low | `ui.R` | Two-group upload workflow not discoverable from UI | ✅ Resolved — CHG-008 |
| ISS-028 | Medium | `data_creation.R` / `forestHelperR` | Age group levels not sorted in expected clinical order | Open |
| ISS-029 | Low | `global.R` | OS system fonts absent from selector after `sysfonts` migration | Open |
| ISS-030 | Low | `global.R` / `R/helpers.R` | `"Source Sans Pro"` renamed on Google Fonts; silently absent | Open |
| ISS-031 | Medium | `ui.R` | Export button layout: fourth button wraps with no spacing | Open |
| ISS-032 | Low | `Rplots.pdf` | Tracked build artifact | ✅ Resolved — CHG-023 |
| ISS-033 | Low | `server/plot.R` | `output$forest` registered inside `observe()` | ✅ Resolved — CHG-024 |
| ISS-034 | Medium | `server.R` / `server/regression.R` | Unqualified `ggsave()`, `glm()`, `as.formula()` | ✅ Resolved — CHG-025 |
| ISS-035 | Medium | `server/export.R`, `renv.lock` | `svglite` not installed; SVG export will error at runtime | Open |
| FEAT-009 | Medium | `ui.R`, `server.R` | Redesign export controls into sidebar accordion panel | Open |

---

### ISS-031 — Export button layout: fourth button wraps to new row with no spacing

| Field | Detail |
|---|---|
| **Source** | RUNTIME |
| **Severity** | Medium |
| **Status** | Open |
| **File(s)** | `ui.R` — Plot tab export button block |
| **Description** | The Plot tab contains four action/download buttons: Download PNG, Download SVG, Copy R code, and Download .R script. The first three sit on one line; the fourth wraps to a new row with no vertical gap, appearing hard against the bottom of the first button. The layout degrades without CSS or flex controls to keep all four on one row (or wrap cleanly with spacing). |
| **Recommended fix** | See FEAT-009. Preferred solution is a redesigned Export panel in the right sidebar accordion rather than a layout patch in the current location. Short-term patch: add `margin-top` or `gap` CSS to the button group, or use `shiny::fluidRow()` / `bslib` layout helpers to keep buttons on one row up to the minimum supported screen width. |
| **Resolution** | — |

### ISS-032 — `Rplots.pdf` tracked build artifact

| Field | Detail |
|---|---|
| **Source** | REVIEW — `2026-06-10_restyle-readiness-review.md` |
| **Severity** | Low |
| **Status** | **Resolved — CHG-023** |
| **File(s)** | `Rplots.pdf`, `.gitignore` |
| **Description** | `Rplots.pdf` was committed and showed as modified on every run — headless plot device output regenerated every R session. Churned in every commit and bloated history. |
| **Resolution** | `git rm --cached Rplots.pdf`; added to `.gitignore`. |

### ISS-033 — `output$forest` registered inside `observe()`

| Field | Detail |
|---|---|
| **Source** | REVIEW — `2026-06-10_restyle-readiness-review.md` |
| **Severity** | Low |
| **Status** | **Resolved — CHG-024** |
| **File(s)** | `server/plot.R` |
| **Description** | `output$forest <- renderPlot(...)` was assigned inside an `observe()` block so that `width`/`height` could read the reactive `dims()`. This re-registers the render function on every invalidation — a known Shiny anti-pattern. |
| **Resolution** | Moved to a direct `output$forest <- renderPlot(...)` call using function-valued `width`/`height` (`function() dims()[1]*72*1.5`), the supported idiom. Verified via automated shinytest2 smoke test that the plot still renders correctly. |

### ISS-034 — Unqualified `ggsave()`, `glm()`, `as.formula()` calls

| Field | Detail |
|---|---|
| **Source** | REVIEW — `2026-06-10_restyle-readiness-review.md` |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-025** |
| **File(s)** | `server.R` (now `server/export.R`), `server/regression.R` |
| **Description** | `ggsave()` called unqualified in both download handlers with `ggplot2` not loaded anywhere in `global.R` — worked only because a dependency (`forestploter`/`forestHelperR`) attaches it transitively. `glm()` and `as.formula()` also called unqualified in `server/regression.R`. |
| **Resolution** | `ggsave()` → `ggplot2::ggsave()`; `glm()` → `stats::glm()`; `as.formula()` → `stats::as.formula()`; family constructors `"poisson"(...)`/`"binomial"(...)` → `stats::poisson()`/`stats::binomial()`. No `library(ggplot2)` added — `::` only requires the package be installed. |

### ISS-035 — `svglite` not installed; SVG export will error at runtime

| Field | Detail |
|---|---|
| **Source** | RUNTIME — discovered while resolving ISS-034 |
| **Severity** | Medium |
| **Status** | Open |
| **File(s)** | `server/export.R`, `renv.lock` |
| **Description** | `ggplot2::ggsave(device = "svg")` requires the `svglite` package. `svglite` appears in `renv.lock` only as a transitive dependency string of other packages — it is **not** itself installed in `renv/library`. Clicking "Download svg" will error at runtime on any machine using this lockfile. |
| **Risk** | Silent-until-clicked export failure; no test currently exercises the SVG download handler, so this would not be caught by the existing suite. |
| **Recommended fix** | Install `svglite` and run `renv::snapshot()` to pin it explicitly, or switch the SVG handler to `grDevices::svg()` if a lighter dependency is preferred. Requires a `renv.lock` change — CLAUDE.md forbids modifying `renv.lock` without explicit sign-off, so this was raised rather than fixed. |
| **Resolution** | — |

---

### FEAT-009 — Redesign export controls into a dedicated sidebar accordion panel

| Field | Detail |
|---|---|
| **Source** | USER |
| **Severity** | Medium |
| **Status** | Open |
| **File(s)** | `ui.R`, `server.R` |
| **Description** | Replace the current four-button export block in the Plot tab with a dedicated "Export graph / code" accordion section in the right-hand sidebar. Proposed structure: **(1) Export graph** — a single export button whose output format (PNG / SVG) is controlled by a `radioButtons()` input above it; **(2) Export code** — two buttons side-by-side, "Copy R code" and "Download .R script", representing distinct functionalities that cannot be merged. Colour-code the two sections to visually separate plot export from code export. |
| **Design notes** | Radio button + single button approach for graph export reduces cognitive load vs. two separate download buttons. Two buttons remain necessary for code export since clipboard copy and file download are distinct actions. Using the sidebar accordion (vs. fixing the Plot tab layout) removes export controls from the main view and groups them logically with other settings. |
| **Dependencies** | ISS-031 (current layout bug, resolved by this feature). Sidebar accordion requires `bslib::accordion()` or similar — confirm available in current bslib version. |
| **Resolution** | — |

---

*Document version: 3.4 — ISS-032/033/034 resolved (CHG-023/024/025); ISS-035 raised (svglite not installed, SVG export will error)*
