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
| ISS-031 | Medium | `ui.R` | Export button layout: fourth button wraps with no spacing | ✅ Resolved — CHG-033 |
| ISS-032 | Low | `Rplots.pdf` | Tracked build artifact | ✅ Resolved — CHG-023 |
| ISS-033 | Low | `server/plot.R` | `output$forest` registered inside `observe()` | ✅ Resolved — CHG-024 |
| ISS-034 | Medium | `server.R` / `server/regression.R` | Unqualified `ggsave()`, `glm()`, `as.formula()` | ✅ Resolved — CHG-025 |
| ISS-035 | Medium | `server/export.R`, `renv.lock` | `svglite` not installed; SVG export will error at runtime | ✅ Resolved — CHG-028 |
| ISS-036 | Medium | `renv.lock` | `forestHelperR` recorded as `Source: "unknown"`; blocks `renv::restore()` | ✅ Resolved — CHG-040 (published to `github.com/DunnNAM/forestHelperR`, real GitHub source) |
| ISS-037 | Medium | `CLAUDE.md`, test docs | Documented test command silently skips all 6 integration tests | ✅ Resolved — CHG-037 |
| FEAT-009 | Medium | `ui.R`, `server.R` | Redesign export controls into sidebar accordion panel | ✅ Implemented — CHG-033 (location amended to Export drawer panel) |
| FEAT-010 | Low | `ui.R`, `R/ui_rail.R`, `R/ui_help.R`, `www/style.css` | DEC-005 Step 7 (phase 2): status-chip strip, rail badges, Help nav panel | ✅ Implemented — CHG-038 |
| FEAT-011 | — | `R/ui_wizard.R`, `server/wizard.R`, `www/wizard.js`, `R/ui_plot_options.R`, `www/style.css`, `global.R`, `ui.R`, `server/drawers.R`, `server/plot.R`, `server/export.R`, `tests/testthat/test-shiny-app.R` | Soft-gated setup wizard + Data drawer/navbar visual redesign, extended app-wide | ✅ Merged to `main` — 2026-09-06 |
| ISS-043 | — (feature) | `global.R` | Add internal `styling` package as a dependency (colour palettes, fonts) | Open — doc-only, not started |
| ISS-044 | Low | `www/style.css` | CSS audit quick-fix batch: z-index, `--page-accent` token, dead CSS, fragmented rules, overflow scope | ✅ Resolved — 2026-09-06 |
| ISS-045 | Low-Medium | `R/ui_wizard.R` | Wizard Step 2 modal layout inconsistency (missing `.wizard-modal-footer`/`.btn-wizard-skip`) | Open |
| ISS-046 | Medium | `ui.R`, `R/ui_*.R`, `server/*.R` | Widespread un-namespaced function calls (`pkg::fun()`) | Open |
| ISS-047 | Low/Medium | `server/observers.R` | Pure math helpers (`xticks_default()`, `make_log_range()`) embedded in server file, untestable | Open |
| ISS-048 | Low | `server/preview.R` | Estimate label logic duplicated instead of reusing `get_est_type()` | Open |
| ISS-049 | Note/Minor | `R/ui_plot_options.R` | `group_var_name`/`group_var_values` bypass `drawerFieldUI()` wrapper | Open — doc-only |
| ISS-050 | Drift/Risk | `server.R` | Implicit file execution order unannotated | Open — doc-only |
| ISS-051 | Drift/Risk | `server/preview.R` | Redundant reactive dereferencing (`data_updated()` 7x, `reg_table()` 2x) | Open — doc-only |
| ISS-052 | Note/Minor | `server/regression.R` | Redundant `isTruthy()` inside `req()` | Open — doc-only |
| ISS-053 | Low | `www/style.css` | `.rail-badge` references unbundled `'JetBrains Mono'` font | Open — doc-only |
| ISS-054 | Low | `www/style.css` | Divergent "cream" colour tokens, undocumented as deliberate | Open — doc-only |

---

### ISS-031 — Export button layout: fourth button wraps to new row with no spacing

| Field | Detail |
|---|---|
| **Source** | RUNTIME |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-033** |
| **File(s)** | `ui.R` — Plot tab export button block (now `R/ui_plot_options.R`'s `exportPanelUI()`) |
| **Description** | The Plot tab contains four action/download buttons: Download PNG, Download SVG, Copy R code, and Download .R script. The first three sit on one line; the fourth wraps to a new row with no vertical gap, appearing hard against the bottom of the first button. The layout degrades without CSS or flex controls to keep all four on one row (or wrap cleanly with spacing). |
| **Resolution** | Superseded by the FEAT-009 redesign as part of the DEC-005 restyle: the four-button block is retired entirely for a colour-separated Export drawer panel (format radio + single download button; separate copy/download for code). No layout-patch fix needed since the buttons no longer share a cramped `fluidRow`. |

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
| **Status** | **Resolved — CHG-028** |
| **File(s)** | `server/export.R`, `renv.lock` |
| **Description** | `ggplot2::ggsave(device = "svg")` requires the `svglite` package. `svglite` appears in `renv.lock` only as a transitive dependency string of other packages — it is **not** itself installed in `renv/library`. Clicking "Download svg" will error at runtime on any machine using this lockfile. |
| **Risk** | Silent-until-clicked export failure; no test currently exercises the SVG download handler, so this would not be caught by the existing suite. |
| **Resolution** | `svglite` (2.2.2), `systemfonts` (1.3.2), and `textshaping` (1.0.5, a hard dependency of `svglite`) installed. `codetools` (missing, required by `globals`) installed alongside since it blocked a general `renv::snapshot()`. Rather than a full `renv::snapshot()` — which rewrote the CRAN mirror URL and ~40 unrelated `Repository` fields, and separately, when scoped with `packages=`, destructively stripped the lockfile down to 11 entries because renv's implicit-type snapshot doesn't detect `svglite` as "used" (nothing calls `svglite::` directly in code) — used `renv::record()` to add exactly the three new package records to `renv.lock` with no other changes. Verified via shinytest2 smoke test that `output$download_svg` now produces a real SVG file instead of erroring. |

---

### ISS-036 — `forestHelperR` has no resolvable source in `renv.lock`

| Field | Detail |
|---|---|
| **Source** | Discovered 2026-09-03 during the failed R 4.5.2 migration (CHG-037) |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-040 (2026-09-06).** (An interim CHG-039 fix, manifest-only via a committed `renv/cellar/` tarball, was superseded the same day — see Resolution.) |
| **File(s)** | `renv.lock`, `manifest.json`, `github.com/DunnNAM/forestHelperR` (new repo) |
| **Description** | `renv.lock` records the entry `"forestHelperR": { "Version": "0.2.0", "Source": "unknown" }`. With no source, renv cannot fetch or reinstall the package, so **`renv::restore()` can never fully succeed on any R version** — not just during an R upgrade. The package was installed locally from a `.tar.gz` and the provenance was never captured. This surfaced as one of 12 failures in the 2026-09-03 restore attempt, but unlike the others it is structural rather than a build failure. **Confirmed as a hard deploy blocker 2026-09-06:** `rsconnect::writeManifest()` in its library-resolution mode calls `renv::snapshot()` internally, whose pre-flight validation aborts outright on any "unknown"-source package — not a soft warning. |
| **Impact** | Blocks the R 4.5.2 migration. More broadly, the lockfile does not currently describe a reproducible environment: a fresh clone cannot rebuild the project library, which undercuts the point of committing `renv.lock` (ISS-011 / CHG-011). Also blocks generating a Connect Cloud deployment manifest (see Resolution). |
| **Recommended fix** | Give the package a resolvable source. Options, roughly in order of robustness: (1) host `forestHelperR` in a git repository renv can reference — this is PDEC-005, currently deferred, which ISS-036 may force earlier; (2) place the `.tar.gz` in a local renv cellar (`renv/cellar/`) so `renv::restore()` finds it, and commit or document the cellar; (3) document the manual pre-install step and accept that `restore()` will always report this package as failed. |
| **Related** | PDEC-005 (package hosting — now effectively actioned by this fix), PDEC-006 (dependency declaration), CHG-037, CHG-039, CHG-040 |
| **Resolution** | **CHG-039 (interim, 2026-09-06):** committed `renv/cellar/forestHelperR_0.2.0.tar.gz` and reinstalled via `renv::install()` from that path, giving the installed package a resolvable `"Cellar"` source without editing `renv.lock`. Confirmed **insufficient** the same day: Connect Cloud's own GitHub-integrated deploy does its own server-side dependency resolution reading `manifest.json`/`renv.lock` directly (it doesn't bundle a local library the way `rsconnect::deployApp()` would), and `"Cellar"` is a reference to the *local machine's* directory — meaningless to Connect Cloud's build servers. First deploy attempt failed with `Package forestHelperR has invalid package source Cellar.` <br><br>**CHG-040 (real fix, same day):** published `forestHelperR`'s source to a new public repo, `github.com/DunnNAM/forestHelperR` (PDEC-005, effectively decided by this) — the package's own dependencies (`broom`, `dplyr`, `extrafont`, `forcats`, `forestploter`, `gtable`, `lmtest`, `magrittr`, `rlang`, `sandwich`, `scales`, `stringr`, `tibble`, `tidyr`, plus base `grid`/`stats`) were confirmed all CRAN-resolvable first, so nothing else needed the same treatment. **Sanitized before publishing:** the original maintainer's personal work email was in `DESCRIPTION`/`man/forestHelperR-package.Rd`; scanned the full extracted source tree for any other internal references (Gitea URLs, `qld.gov.au`, internal IPs/paths, credentials) and found none elsewhere. Reattributed rather than stripped: the original author is credited with a masked name/contact (`Helen ***` / `H*.*@health.qld.gov.au`, pending her own confirmation before using her real details publicly), and Nathan Dunn is now listed as maintainer with a real, working contact, since a public package needs one. Reinstalled via `renv::install("DunnNAM/forestHelperR")`, then `renv.lock`'s `forestHelperR` entry updated to a real `"Source": "GitHub"` record (`RemoteType`/`RemoteRepo`/`RemoteSha`) via `renv::record()` — **this required the scoped `renv.lock` override the user explicitly authorized**, mirroring DEC-006's carve-out but for this deploy blocker rather than the R 4.5.2 migration; scoped to this one package entry, not a full `renv::snapshot()`. `manifest.json` regenerated successfully via the **default, lockfile-based** `rsconnect::writeManifest()` path this time (no `dependencyResolution = "library"` workaround needed) — 138/138 packages match `renv.lock` exactly. <br><br>**A real, live privacy exposure was found and fixed along the way:** the CHG-039 commit had put the *original, unsanitized* tarball (containing the real email) into `renv/cellar/` on the now-public `forest-plot-generator` repo, and separately the first `forestHelperR` publish commit's own message quoted that same email in prose while describing its removal. Both fixed same-day: the cellar tarball removed from `main`'s current tree (git history on `main` not rewritten — a deliberate, lower-disruption choice given the in-progress `design/modal-progression-workflow` branch would need rebasing onto any rewritten history); the `forestHelperR` repo's commit amended and force-pushed (safe here — brand-new single-commit repo, nothing else depended on it yet). Verified: 48/48 unit + 9/9 integration assertions still pass; no occurrence of the real email anywhere in the current `forestHelperR` repo, `renv.lock`, or `manifest.json`. |

---
### ISS-037 — Documented test command silently skips every integration test

| Field | Detail |
|---|---|
| **Source** | Discovered 2026-09-03 while establishing an authoritative test baseline (CHG-037) |
| **Severity** | Medium |
| **Status** | **Resolved — CHG-037** (documentation fix) |
| **File(s)** | `CLAUDE.md`, `session-handoff.md` |
| **Description** | `CLAUDE.md` documented the integration suite as `testthat::test_file("tests/testthat/test-shiny-app.R")`. Run that way from a bare `Rscript`, **all 6 `test_that` blocks skip** — `shinytest2`'s `AppDriver$new()` calls `skip_on_cran()` internally, and `NOT_CRAN` is only set automatically by `devtools::test()` and the RStudio runner. The run prints `SSSSSS` and **exits 0**, so it reads as a pass at a glance and in any CI check keying on exit code. |
| **Why it mattered** | The register's per-CHG claims of "9/9 integration assertions passing" were correct, but anyone verifying them with the documented command would have seen skips and had no signal that the suite had not actually run. |
| **Resolution** | `CLAUDE.md` §Test suite and `session-handoff.md` §5 now document `NOT_CRAN=true` explicitly, with a warning that the exit code is misleading without it. Verified: with `NOT_CRAN=true`, 6 blocks / 9 assertions pass, 0 skipped. |

---

### ISS-038 — `shiny:connected` fired via jQuery, never caught by `document.addEventListener` — first-visit wizard trigger never actually worked

| Field | Detail |
|---|---|
| **Source** | Discovered 2026-09-04 debugging why a returning user's default-open Data drawer (FEAT-011 follow-up) never opened |
| **Severity** | Medium — the setup wizard is the entire point of FEAT-011, and its trigger mechanism was non-functional |
| **Status** | **Resolved — CHG-047** |
| **File(s)** | `www/wizard.js` |
| **Description** | `www/wizard.js` (as far back as CHG-039, so pre-existing — not introduced this session) registered its first-visit check with `document.addEventListener("shiny:connected", ...)`. Confirmed via server-side trace (a plain `observe()` printing every value `input$wizard_should_show` ever took) across four separate fresh sessions that the input **never arrived, at all** — not a timing race, a deterministic failure. Root cause, confirmed by reading the bundled `shiny.min.js` directly: Shiny fires `"shiny:connected"` via jQuery's `.trigger()` — `(0,G.default)(document).trigger({type:"shiny:connected", socket:i})` — which is jQuery's own event system, not a real browser/DOM event. `document.addEventListener` can never see a jQuery-only trigger for a made-up event name like this one; no amount of "register the listener earlier" would have fixed it. |
| **Why it mattered** | The soft-gated setup wizard (FEAT-011's core mechanism) never actually showed itself to a genuine first-time visitor in any tested configuration — the whole feature's entry point was silently dead code from the point it was written. |
| **Resolution** | `www/wizard.js` now binds through jQuery itself — `jQuery(document).on("shiny:connected", reportWizardVisit)` — with a `Shiny.shinyapp.isConnected()` load-time check as a fallback for the case where the connection already completed before the script ran. Verified: with `fpb_wizard_seen` cleared, the welcome modal now reliably shows; with it set, the returning-user path (CHG-047) reliably fires instead. |

---

### FEAT-009 — Redesign export controls into a dedicated sidebar accordion panel

| Field | Detail |
|---|---|
| **Source** | USER |
| **Severity** | Medium |
| **Status** | **Implemented — CHG-033 (location amended)** |
| **File(s)** | `R/ui_plot_options.R` (`exportPanelUI()`), `server/export.R` |
| **Description** | Replace the current four-button export block in the Plot tab with a dedicated "Export graph / code" section. Proposed structure: **(1) Export graph** — a single export button whose output format (PNG / SVG) is controlled by a `radioButtons()` input above it; **(2) Export code** — two buttons side-by-side, "Copy R code" and "Download .R script", representing distinct functionalities that cannot be merged. Colour-code the two sections to visually separate plot export from code export. |
| **Design notes** | Radio button + single button approach for graph export reduces cognitive load vs. two separate download buttons. Two buttons remain necessary for code export since clipboard copy and file download are distinct actions. |
| **Resolution** | Implemented exactly as designed, with one amendment: the DEC-005 restyle replaced the originally-proposed **sidebar accordion** location with the **Export drawer panel** (the sidebar itself was retired in Step 4). `export_format` radio (PNG/SVG) + single `download_plot` button in a `.export-section--graph` block; `copy_r_code` + `download_r_code` unchanged in a `.export-section--code` block; both colour-separated via a left-border accent. `download_png`/`download_svg` retired. Resolves ISS-031. |

---

### FEAT-010 — DEC-005 Step 7 (phase 2): status chips, rail badges, Help nav

| Field | Detail |
|---|---|
| **Source** | `restyle-implementation-plan.md` §8, deferred at plan time |
| **Severity** | Low |
| **Status** | **Implemented — CHG-038** |
| **File(s)** | `ui.R`, `R/ui_rail.R`, `R/ui_help.R` (new), `server/drawers.R`, `www/style.css` |
| **Description** | The three polish items the DEC-005 restyle plan explicitly held back as optional phase 2, now that Steps 0-6 have shipped: **(1) status-chip strip** — the `div.dashboard-body` status strip placeholder added in Step 1 is still empty and renders nothing; **(2) rail badges** — MDT-style counts on `.rail-item` (e.g. number of hidden/excluded variables), for which `.rail-item` inner styling already carries a `badge` slot in `www/style.css`; **(3) Help nav panel** — the second `page_navbar` nav item, alongside *Builder*, using MDT's How-to-Use pattern. |
| **Design notes** | All three are additive — none changes an existing input ID, reactive, or the drawer mechanism, so the shinytest2 suite should be unaffected. The CSS hooks (`chip-strip`, `.rail-item` badge slot) were deliberately ported in Step 1/6 so this work would not need another stylesheet pass. Anything rendered inside a hidden drawer panel needs `outputOptions(..., suspendWhenHidden = FALSE)` — see CHG-033. |
| **Raised** | 2026-09-03 — CHG-036. Registered so the deferred work is visible in the open-items list rather than living only in DEC-005 prose and the plan's own step table. |
| **Resolution** | Implemented 2026-09-04 (CHG-038). **Chip strip:** `output$status_chips` (`server/drawers.R`) renders read-only chips (Dataset, Regression type, Variables/predictor count, Font) above `navset_card_tab`; clicking a chip sets a new `input$chip_open_key` which always opens (not toggles) the matching drawer — deliberately distinct from the rail buttons' own toggle semantics. **Rail badges:** `uiOutput("rail_badge_<key>")` nested in `rail_button()` (`R/ui_rail.R`); wired for *Variables* (count of variables hidden from the plot, via `reg_table()` vs `input$variables_displayed`) and *Display* (a dot when any of a fixed set of display inputs differs from its `ui_plot_options.R` default). Both render `NULL` (nothing) in the common case, so unbadged/at-default state looks identical to before. **Help nav panel:** `helpPanelUI()` (new file `R/ui_help.R`) — static content only, no reactive inputs; reuses the `.card`/`.card-header` rules already kept in `www/style.css` rather than the dropped MDT `.htu-*` classes. Verified: 48/48 unit assertions and 9/9 integration assertions pass unmodified (additive change, no existing ID touched). |

---

### FEAT-011 — Soft-gated setup wizard + Data drawer visual redesign (draft, branch-only)

| Field | Detail |
|---|---|
| **Source** | USER, session 2026-09-04 |
| **Severity** | — (design experiment, not a defect) |
| **Status** | **Merged to `main`** (2026-09-06, rebase — see `app-changelog-decision-register.md`'s renumbering note) |
| **File(s)** | `R/ui_wizard.R`, `server/wizard.R`, `www/wizard.js` (new); `R/ui_rail.R`, `R/ui_help.R`, `R/ui_plot_options.R`, `www/style.css`, `ui.R`, `server.R`, `server/drawers.R`, `server/plot.R`, `server/export.R`, `global.R`, `tests/testthat/test-shiny-app.R` (modified) |
| **Description** | Three related but separable pieces of work, both exploring whether the app's first-launch "directionless" feeling (no cue where to start) can be fixed without abandoning DEC-005's static rail/drawer model: **(1) a soft-gated setup wizard** — a three-button welcome modal (Skip wizard / Update data source/s / Go to plot styling) shown on first visit, a second "Variables ready" modal that auto-advances once the user has actually changed something in the Data panel, always skippable, restartable any time via a "Tour" rail item, and a returning-user default (Data drawer open, Review data tab); **(2) a Data-drawer visual redesign, extended app-wide** — title/content field convention and icon+uppercase panel headings on every drawer panel except Export, vertical dividers attempted where a panel's fields stay single-row (Data, Variables), and two real layout/logic bugs fixed along the way (`.card` had no explicit background, blending into the cream page; three related Variables-panel toggles combined into one field with a mutually-exclusive radio group, replacing two switches a user could nonsensically both enable); **(3) app-wide defaults and navigation** — the app now loads with a working Simulated-data example already plotted (previously an empty upload prompt), and the bottom rail/status chips anchor the main body tab to whichever drawer is open. |
| **Design notes** | The wizard is deliberately *instructional*, not a duplicate control surface: DEC-005's restyle plan already made the case (§3) against duplicating any of the ~45 live plot-option inputs, so the wizard's modals tell the user what to do and the server opens the matching drawer for them, rather than embedding copies of `dataset_selected` etc. inside a modal. Several real Shiny/CSS/JS gotchas surfaced and are documented in situ: `conditionalPanel()` renders `display: contents` when shown, which promotes its child into a parent flex row for *layout* but not for CSS structural selectors (`:not(:first-child)` silently matched nothing); `flex: 1` stretch-to-fill only works if the *immediate* parent is a flex container; a plain `observe()` re-fires on the very first reactive flush too, which matters once the data it's watching can already be valid by default; htmltools' pretty-printer inserts whitespace between a multi-argument tag call's children that becomes a visible stray space between adjacent *inline* elements (invisible for block-level ones); and — the most significant, ISS-038 — Shiny fires `"shiny:connected"` through jQuery's `.trigger()`, which a native `document.addEventListener` can never catch, so the entire first-visit wizard trigger had silently never worked since it was written (CHG-041). |
| **Commits so far** | `d2fb1b7` (wizard + Tour rail item), `69f9b33` (`.card` background fix — candidate to cherry-pick to `main` independently, since it's a real bug fix unrelated to the wizard experiment), `a63dd99` (Data panel titled fields, dividers, Robust variance renested under Regression type), `69fef17` (icon+uppercase panel headings, response-field padding, divider re-measurement), `69f364f` (CHG-045–048: titled-field styling extended app-wide, Variables' estimate-column redesign, rail/tab anchoring, default load state), `907ce40` (CHG-049–050, ISS-038: returning-user default, `shiny:connected` event fix, welcome modal redesign), `fd490b7` (CHG-051–053: Plot tab card-height/plot-resolution fixes, Display panel 3-group 50/25/25 layout + x-axis tick count/mirror-pairing, rail badge default-state fix; ISS-040/041 raised), `e1ef3a9` (CHG-054: navbar/Help-tab restyle attempt — didn't land, see ISS-042), `d974748` (CHG-055–057: navbar tabs redesigned as filled pills resolving ISS-042's navbar sub-issues, pill buttons on wizard/Export, Export drawer redesign — done via live user-directed visual iteration after the Chrome extension was removed from the session). |
| **Open question** | Whether the wizard pattern and/or the Data-drawer visual language get adopted app-wide and merged to `main`, or stay a documented experiment. The visual language is now applied to every drawer panel except Export (deliberately deferred, pending its own design pass), narrowing what's actually still Data-panel-only. No DEC has been raised for this yet — raise one (working title: **DEC-007**) if/when a merge decision is made. |
| **Resolution** | — |

---

### ISS-039 — x-axis tick generation always splits evenly either side of 1; doesn't suit a skewed distribution

| Field | Detail |
|---|---|
| **Source** | USER, session 2026-09-04, flagged as a future-development note rather than an immediate request |
| **Severity** | Low — a real gap, not a defect in what's shipped |
| **Status** | **Open — deferred, not implemented** |
| **File(s)** | `server/observers.R` (`xticks_default()`) |
| **Description** | `xticks_default()` (added the same session, FEAT-011) always splits the requested tick count evenly either side of 1 when the domain straddles it — e.g. 6 ticks means 3 below 1 and 3 above. For a highly skewed result distribution, an even split may not be the most useful layout; the user gave the example of wanting 1 tick below 1 and 3 above. This would parallel how the *domain* (`xlims`) already works today — its two limits are independently draggable, not constrained to be exact inverses of each other — so an analogous "independent tick count on each side" control would be a natural, consistent extension. |
| **Why it matters** | Not urgent — the current even-split behaviour is a reasonable default and nothing is broken. Worth having on record before the next round of x-axis tick work, so the asymmetric case is designed in from the start rather than retrofitted around the mirror-pairing logic ISS-038's neighbouring feature (the drag-to-mirror behaviour, same commit) already relies on. |
| **Resolution** | — |

---

### ISS-040 — Variables rail badge can briefly show a stale "hidden variables" count on load

| Field | Detail |
|---|---|
| **Source** | USER, session 2026-09-04, flagged explicitly as low priority — future fix, not urgent |
| **Severity** | Low — cosmetic, self-corrects within a fraction of a second |
| **Status** | **Open — deferred** |
| **File(s)** | `server/drawers.R` (`output$rail_badge_variables`), `server/observers.R` (§a, the `variables_displayed` sync observer) |
| **Description** | `rail_badge_variables` computes `hidden = total - length(input$variables_displayed)` from `reg_table()`'s unique display names vs. the current selection. A separate observer (`server/observers.R` §a) is what actually syncs `variables_displayed` to the full set whenever `reg_table()` changes, via `updateCheckboxGroupInput()`. On initial load, `reg_table()` can resolve (making `total` correct) before that sync observer has run in the same reactive flush, so the badge briefly computes `hidden > 0` against the *old* (usually empty or partial) `variables_displayed`, showing a false "N hidden" badge on the Variables rail item for a moment before it self-corrects. |
| **Why it's newly visible** | This race likely always existed, but the app previously only reached a valid `reg_table()` after a real user upload — never on load itself — so there was no moment for the flash to occur. The 2026-09-04 default-load-state change (app now opens with Simulated data already valid) made `reg_table()` valid from the very first reactive flush, exposing the pre-existing race. |
| **Possible fix** | Give the `variables_displayed` sync observer (`server/observers.R` §a) a higher `priority` than the default, so it reliably runs before `rail_badge_variables` renders within the same flush — not implemented, since the user asked this be logged as a low-priority future item rather than fixed now. |
| **Resolution** | — |

---

### ISS-041 — `README.md` describes the pre-restyle app; hasn't tracked DEC-004/DEC-005 or later work

| Field | Detail |
|---|---|
| **Source** | USER, session 2026-09-04, asked whether `README.md` exists on this branch and reflects current functionality |
| **Severity** | Medium — user-facing, and actively misleading rather than merely incomplete |
| **Status** | **Open — not fixed this session, deliberately deferred as its own pass** |
| **File(s)** | `README.md` |
| **Description** | `README.md` exists on `design/modal-progression-workflow` (same file as `main` — untouched by this branch) and has had exactly one commit since the project's initial commit (`5ca095a`, an `renv` fix), predating DEC-004 (the `server/`+`R/` file split) and DEC-005 (the full rail/drawer restyle) entirely. Specific stale claims: describes a "left sidebar" and a "right-hand accordion panel" for plot options — both retired by DEC-005 in favour of the bottom rail + slide-up drawer; says export happens via "buttons in the Plot tab" — export is now its own dedicated Export drawer panel (FEAT-009); lists `server.R`/`ui.R` as flat files under "Project structure" — `server.R` is now a 6-file `source()` wrapper (DEC-004); references `www/styles.css` — the actual file is `www/style.css` (no `s`); lists "No automated tests" and "No `renv` lockfile" under Known limitations (ISS-004, ISS-011) — both resolved (a `testthat` + `shinytest2` suite exists, and `renv.lock` is committed and pins R 4.3.1); "Prerequisites: R ≥ 4.1" — the project now specifically targets R 4.3.x. |
| **Why it matters** | A new contributor or returning user following the README today would be given fundamentally wrong instructions for using the app (there is no sidebar or accordion to find) and a wrong risk picture (both listed "known limitations" are actually resolved). |
| **Resolution** | — deliberately not rewritten this session; flagged for its own pass rather than folded into an unrelated round of Display/Variables UI work. |

---

### ISS-042 — CHG-054 navbar/Help-tab restyle: three visual issues not actually fixed, one made worse

| Field | Detail |
|---|---|
| **Source** | USER, session 2026-09-04, live visual check of CHG-054 (this register's own author could not check live — the Chrome browser extension was unavailable that session, so CHG-054 was verified only against served HTML/CSS, not rendered appearance) |
| **Severity** | Medium — the whole point of the session was these three specific visual fixes, and one is now worse than before |
| **Status** | **Resolved — all three sub-issues. Sub-issues 2 and 3 by CHG-055 (2026-09-04); sub-issue 1 (Help page title alignment) confirmed already fixed by Nathan, 2026-09-06 — see Resolution below.** |
| **File(s)** | `www/style.css` (`.navbar`, `.navbar-brand`, `.navbar-nav .nav-link`, `.help-title`), `R/ui_help.R` |
| **Description** | Three sub-issues, all against CHG-054's intended fixes: |

1. **Help page title still not left-aligned.** `R/ui_help.R`'s `<h4>` was moved off `.drawer-header` (which centers within a 1280px `max-width`) onto a new `.help-title` class with no such constraint — on paper this should already render flush with the section cards below, since neither `.help-title` nor `.content-area` sets any centering. **Prime suspect: this is an `R/*.R` file change, which needs a full R process restart to take effect** (per `session-handoff.md` §6) — if the session that reviewed this didn't restart (vs. a plain browser refresh, which is enough for the CSS-only navbar changes in the same commit), the page would still be running the *old* `helpPanelUI()` with the old `drawer-header` class, exactly reproducing the reported symptom. **First step next session: hard-restart R, hard-refresh the browser, and re-check before touching any CSS.** If it's still off after that, inspect the actual rendered class on the `<h4>` via devtools to confirm `.help-title` is even present.
2. **App title / tab-label vertical alignment is worse, and the tab labels now look too small.** CHG-054 set `align-items: flex-end` on both `.navbar` and `.navbar > .container-fluid`, on the theory that `.navbar-brand` and `.navbar-collapse` (the flex children of `.container-fluid`) would both settle onto one shared bottom edge, since `.navbar-nav .nav-link`'s `line-height: 56px` makes the collapsed nav effectively 56px tall while `.navbar-brand` is much shorter. That reasoning doesn't obviously explain a *bigger* gap and *smaller*-looking tab text — worth checking directly in devtools next session rather than re-deriving on paper: (a) confirm what `.navbar-brand`'s actual rendered `font-size`/line-box height is — Bootstrap's own `.navbar-brand` rule may be winning on specificity or cascade order against the plain `.navbar-brand { font-size: 22px; ... }` added in this stylesheet, especially if bslib injects its own navbar CSS after this stylesheet in the `<head>`; (b) confirm `.navbar-nav .nav-link`'s computed `line-height` and `font-size` are actually 56px/14px as written, not overridden elsewhere; (c) check whether `.navbar > .container-fluid { align-items: flex-end; }` is even taking effect — Bootstrap's own `.navbar > .container-fluid` rule sets `align-items: center` at the same specificity (single class + descendant combinator on both), so cascade order (which stylesheet loads/is declared last) decides the winner, and bslib's own compiled theme CSS may load after this app's `style.css` link in `<head>` rather than before it.
3. **Active-tab underline still reads as a second line, not overlaid on the divider.** CHG-054 replaced `.nav-link.active`'s own `border-bottom` with an absolutely-positioned `::after` (`bottom: -4px; height: 4px;`) intended to land exactly on `.navbar`'s new 4px `border-bottom`. `bottom: -4px` on an absolutely-positioned element is relative to its *nearest positioned ancestor's padding edge* — `.navbar-nav .nav-link` was given `position: relative` for exactly this, but the `::after`'s containing block is the `<a>` itself, not `.navbar`, so if the `<a>`'s own box bottom doesn't sit flush with `.navbar`'s content-box bottom (e.g. because of sub-issue 2's alignment problem, or residual padding/margin somewhere in the `.nav-item`/`.navbar-nav`/`.navbar-collapse` chain), the `::after` lands a few pixels short of or past the navbar's actual border, reproducing the "two lines" look CHG-054 was meant to remove. **This is likely downstream of sub-issue 2** — fixing the baseline alignment first, then re-measuring the `::after`'s actual position via devtools (not guessing the pixel offset again), is the more reliable order of operations than adjusting the `::after` in isolation.

| **Why it matters** | This was the entire scope of the session that produced CHG-054 — the user asked for exactly these three things (title alignment, divider unification, active-tab highlight legibility) and, per their own live check, none of the three landed as intended, with the title/tab alignment actively regressing. |
| **Recommended approach for next session** | (1) Restart R fully and hard-refresh before assuming anything is still broken — rule out sub-issue 1 being a stale-render artifact first. (2) For sub-issues 2 and 3, use actual browser devtools (computed styles + box model) rather than reasoning about cascade/specificity from the stylesheet text alone — this session's author did not have Chrome extension access, and CHG-054's own alignment reasoning, while plausible on paper, produced the opposite of the intended result once actually rendered, which is a strong signal to verify empirically this time rather than repeat the same reason-from-CSS-text approach. (3) Do this before ISS-041 (`README.md` refresh) — the user's explicit priority order for next session. |
| **Resolution** | **Sub-issues 2 and 3 — CHG-055 (2026-09-04).** The user removed the Chrome extension entirely this session ("burning tokens wastefully") and instead checked each round live in their own browser, directing the next fix — which is what actually got this resolved, confirming the recommended approach above (devtools/live verification over reasoning from CSS text) was correct, just not available to CHG-054's author. Sub-issue 2's real cause, found by fetching the served HTML/CSS directly rather than guessing: bslib's `page_navbar()` uses Bootstrap-3-style compatibility markup where `.navbar-brand` is nested inside a `.navbar-header` wrapper (not a direct flex child of `.container-fluid` as assumed), and separately Bootstrap 5.3's `.nav-underline` utility class (present by default on the tab `<ul>`) was silently overriding `.nav-link`'s padding/margin at higher specificity regardless of stylesheet order — the actual mechanism behind sub-issue 3 too, and the reason repeated pixel-offset tuning kept failing. Resolved by abandoning the shared-underline design for filled pill tabs (slate/cream, matching a later CHG-056 button restyle), which removes the dependency on exact box-edge alignment entirely rather than continuing to chase it. **Sub-issue 1 — confirmed resolved 2026-09-06, no code change needed.** Following this entry's own recommended order of operations (full R restart before assuming it's still broken), Claude confirmed the running app's served HTML already carried `<h4 class="help-title">` (not the old `.drawer-header`), and re-traced `www/style.css` to confirm neither `.help-title` nor any ancestor (`.content-area`, `.help-panel`) sets `text-align` or a centering `max-width`/`margin: auto` — nothing in the stylesheet should have been misaligning it. Nathan then confirmed live: the title renders flush left with the section cards below, as intended. The "prime suspect" theory this entry proposed (a stale pre-restart render, from whenever `R/ui_help.R`'s `helpPanelUI()` was actually last changed to use `.help-title`) was most likely correct — by the time this was rechecked, an unrelated R restart earlier in the same session had already picked up the fix. |

---

### ISS-044 — CSS audit quick-fix batch: z-index inversion, undeclared token, dead template CSS, fragmented rules, overflow scope

| Field | Detail |
|---|---|
| **Source** | `reviews/architecture/2026-09-04_css-stylesheet-audit.md` (§2.2, §3, §4.1, §4.2, §5.1) |
| **Severity** | Low (cosmetic/maintainability; one real stacking bug) |
| **Status** | **Resolved — 2026-09-06** |
| **File(s)** | `www/style.css` |
| **Description** | Five items from the audit's action plan, all mechanical and low-risk: (1) `.drawer-scrim` z-index `98` → `1027` — was inverted below Bootstrap 5/Selectize's own `1000`, letting a dropdown render in front of the dimmed backdrop; (2) declared `:root { --page-accent: #426175; }`, which 13 `var(--page-accent, #426175)` reads were silently relying on as a fallback; (3) removed ~65 lines of dead template CSS never referenced by any `.R`/`.js` file (`.drawer-btn*`, `.drawer-search`, `.drawer-count`, `.drawer-section-label`, `.chips-right`, `.filter-chip.add`/`.active`, `.filter-chips:has(.filter-chip.active)`); (4) consolidated the two pure `.export-section .btn` blocks (background/border/color/min-width/text-align) into one, leaving the separate `.export-section .btn, .modal-footer .btn` shared block alone since it also targets the wizard's buttons; (5) scoped `overflow: visible !important` from every `.tab-pane` down to `#main_tabs .tab-pane[data-value="Plot"]` specifically, so the Review data tab's `DT::dataTableOutput` keeps normal overflow containment instead of spilling past the card on wide tables. |
| **Not included** | The audit's candidate wizard-modal-footer fix (`wizardVariablesModal()` missing `.wizard-modal-footer`/`.btn-wizard-skip`) is an `R/ui_wizard.R` change, not CSS — left open, see **ISS-045**. |
| **Verification** | Visual check pending — user to confirm no regression on the Review data tab (wide table scroll) and Plot tab (still grows to full height) after this change; CSS-only edit, no R restart needed. |
| **Resolution** | All five items applied directly in `www/style.css` with in-situ comments; see file for exact diffs. |

---

### ISS-045 — Wizard Step 2 modal layout inconsistency (`wizardVariablesModal` missing `.wizard-modal-footer`/`.btn-wizard-skip`)

| Field | Detail |
|---|---|
| **Source** | `reviews/architecture/2026-09-04_css-stylesheet-audit.md` §2.1 (was candidate ISS-046 in that review; renumbered to avoid colliding with the already-registered ISS-043/044) |
| **Severity** | Low-Medium — visible regression mid-flow, but only on the still-draft FEAT-011 branch |
| **Status** | **Open — not fixed** |
| **File(s)** | `R/ui_wizard.R`, `www/style.css` (`:has(.wizard-modal-footer)` scoping) |
| **Description** | `wizardWelcomeModal()`'s footer is wrapped in `div(class = "wizard-modal-footer", ...)`, which the CSS `:has()` selector uses to widen the modal to 650px and give its buttons equal-width flex. `wizardVariablesModal()` (Step 2) uses a bare `tagList()` with no such wrapper and no `.btn-wizard-skip` class on its skip button. When the wizard auto-advances from Step 1 to Step 2, the modal visibly shrinks back to Bootstrap's default ~500px, button widths lose flex parity, and "Skip wizard" reverts to a plain grey Bootstrap button instead of the maroon pill. |
| **Recommended fix** | Wrap `wizardVariablesModal()`'s footer in `div(class = "wizard-modal-footer", ...)` and add `class = "btn-wizard-skip"` to its `wizard_skip` button — mirrors `wizardWelcomeModal()` exactly. |
| **Resolution** | — |

---

### ISS-046 — Widespread un-namespaced function calls (`pkg::fun()`)

| Field | Detail |
|---|---|
| **Source** | `reviews/architecture/2026-09-04_architecture-code-review.md` §2.4/F-5 (was candidate ISS-043 in that review; renumbered to avoid colliding with the already-registered ISS-043 styling-package entry) |
| **Severity** | Medium (convention violation — direct contradiction of `CLAUDE.md`'s "Always use explicit package::function() notation") |
| **Status** | **Open — not started** |
| **File(s)** | `ui.R`, all of `R/ui_*.R`, all of `server/*.R` |
| **Description** | Widespread bare calls across every application layer — Shiny core primitives (`reactive()`, `observe()`, `req()`, `renderUI()`, …), `bslib::*`, `sortable::*`, `shinyWidgets::*`, `dplyr::*`, `tidyselect::*`, `rlang::sym()`, and bare `tags$*`/UI builders. Full inventory in the source review. |
| **Recommended approach** | Not a "quick fix" — large surface area across nearly every file. Do deliberately, one file/topic at a time, verifying the test suite after each. |
| **Target CHG** | `CHG-058` (per the source review) |
| **Resolution** | — |

---

### ISS-047 — Pure mathematical helpers embedded in `server/observers.R`

| Field | Detail |
|---|---|
| **Source** | `reviews/architecture/2026-09-04_architecture-code-review.md` §2.5/F-6 (was candidate ISS-044 in that review; renumbered) |
| **Severity** | Low/Medium (testability & separation of concerns) |
| **Status** | **Open — not started** |
| **File(s)** | `server/observers.R`, `R/helpers.R`, `tests/testthat/test-helpers.R` |
| **Description** | `xticks_default(n, domain)` and `make_log_range(lo, hi)` are pure numerical utilities with zero reactive dependencies, but live inside the server closure — they can't be unit tested without running the full app. |
| **Recommended fix** | Extract both to `R/helpers.R`; add unit test coverage in `tests/testthat/test-helpers.R`. |
| **Target CHG** | `CHG-059` (per the source review) |
| **Resolution** | — |

---

### ISS-048 — Estimate label logic duplicated in `server/preview.R`

| Field | Detail |
|---|---|
| **Source** | `reviews/architecture/2026-09-04_architecture-code-review.md` §2.5/F-7 (was candidate ISS-045 in that review; renumbered) |
| **Severity** | Low (DRY / maintainability) |
| **Status** | **Open — not started** |
| **File(s)** | `server/preview.R`, `R/helpers.R` |
| **Description** | `server/preview.R:74-79` writes an inline `case_when(...)` to format estimate column headers ("RR", "OR", "HR", "1/HR"), duplicating the already-tested `get_est_type()` helper in `R/helpers.R`. |
| **Recommended fix** | Replace the inline block with a call to `get_est_type(input$regression_type, input$inv)`. |
| **Target CHG** | `CHG-060` (per the source review) |
| **Resolution** | — |

---

### ISS-049 — `group_var_name`/`group_var_values` bypass `drawerFieldUI()` wrapper in Data panel

| Field | Detail |
|---|---|
| **Source** | `reviews/architecture/2026-09-04_architecture-code-review.md` §2.1/F-1 |
| **Severity** | Note/Minor |
| **Status** | **Open — doc-only, not started** |
| **File(s)** | `R/ui_plot_options.R` (`dataPanelUI()`) |
| **Description** | `group_var_name` and `group_var_values` (lines ~166-168) are raw `textInput()` widgets sitting directly inside a `conditionalPanel()`, the only fields in the Data panel that skip the `drawerFieldUI()` title/content wrapper every other field uses. |
| **Recommended fix** | Wrap in `drawerFieldUI("Group variable settings", ...)` during the next UI polish pass. |
| **Resolution** | — |

---

### ISS-050 — Implicit file execution order in `server.R` is unannotated

| Field | Detail |
|---|---|
| **Source** | `reviews/architecture/2026-09-04_architecture-code-review.md` §2.2/F-2 |
| **Severity** | Drift/Risk (documentation gap, not a defect) |
| **Status** | **Open — doc-only, not started** |
| **File(s)** | `server.R` |
| **Description** | `server.R` sources the 8 `server/*.R` files sequentially with `local = TRUE` into one shared closure. Downstream files depend on reactives defined upstream (`preview.R` needs `data_updated` from `upload.R` and `reg_table` from `regression.R`, etc.), but this ordering dependency isn't documented in `server.R` itself — reordering the `source()` calls would silently break the app with no comment warning against it. |
| **Recommended fix** | Add a short comment block in `server.R` documenting the pipeline: `upload.R` (data input) → `regression.R` (model fit) → `preview.R` / `plot.R` → `export.R` / `observers.R` / `drawers.R` / `wizard.R`. |
| **Resolution** | — |

---

### ISS-051 — Redundant reactive dereferencing in `server/preview.R`

| Field | Detail |
|---|---|
| **Source** | `reviews/architecture/2026-09-04_architecture-code-review.md` §2.3/F-3 |
| **Severity** | Drift/Risk (performance/maintainability, not a defect) |
| **Status** | **Open — doc-only, not started** |
| **File(s)** | `server/preview.R` |
| **Description** | `output$dat_upload` calls `data_updated()` 7 separate times within a single render expression (`colnames(data_updated())`, `data_updated() %>% ...`, etc.), and `output$dat_summary` calls `reg_table()` twice — each call re-dereferences the reactive rather than reusing one evaluated value. |
| **Recommended fix** | Assign a local alias once at the top of each render block (e.g. `df <- data_updated()`, `col_names <- colnames(df)`) and reuse it. |
| **Resolution** | — |

---

### ISS-052 — Redundant `isTruthy()` inside `req()` in `server/regression.R`

| Field | Detail |
|---|---|
| **Source** | `reviews/architecture/2026-09-04_architecture-code-review.md` §2.3/F-4 |
| **Severity** | Note/Minor |
| **Status** | **Open — doc-only, not started** |
| **File(s)** | `server/regression.R` (lines 4-5) |
| **Description** | `req(isTruthy(input$dataset_selected == "sim"), isTruthy(length(input$predictor_vars) > 0))` wraps `isTruthy()` inside `req()`, which already calls `shiny::isTruthy()` internally on all its arguments — harmless but redundant. |
| **Recommended fix** | Simplify to `req(input$dataset_selected == "sim", length(input$predictor_vars) > 0)`. |
| **Resolution** | — |

---

### ISS-053 — `.rail-badge` references unbundled `'JetBrains Mono'` font

| Field | Detail |
|---|---|
| **Source** | `reviews/architecture/2026-09-04_css-stylesheet-audit.md` §5.2 |
| **Severity** | Low (cosmetic — silent fallback, no visible error) |
| **Status** | **Open — doc-only, not started** |
| **File(s)** | `www/style.css` (`.rail-badge`) |
| **Description** | `.rail-badge` sets `font-family: 'JetBrains Mono', monospace;`, but `JetBrains Mono` is never loaded or bundled anywhere in the app (`global.R`'s `sysfonts`/`showtext` setup doesn't register it). Browsers silently fall back to the generic system monospace font — same class of silent-fallback issue as ISS-029/030, just for a UI chrome element rather than plot text. |
| **Recommended fix** | Either add `sysfonts::font_add_google("JetBrains Mono")` (consistent with the app's existing Google Fonts pattern in `global.R`) or drop the specific family name from the CSS rule and rely on the generic `monospace` fallback deliberately. |
| **Resolution** | — |

---

### ISS-054 — Divergent "cream" colour tokens, undocumented as deliberate

| Field | Detail |
|---|---|
| **Source** | `reviews/architecture/2026-09-04_css-stylesheet-audit.md` §5.3 |
| **Severity** | Low (documentation/consistency, not a visible defect) |
| **Status** | **Open — doc-only, not started** |
| **File(s)** | `www/style.css` |
| **Description** | Two different "cream" values are in use: `#f7f4ec` (page body background, navbar active-pill text, theme default) and `#f3eedb` (rail text colour, active rail button background). May be a deliberate two-tone palette choice (rail vs. page-level cream) or may be drift from separate design passes — the audit couldn't tell which from the stylesheet alone. |
| **Recommended fix** | Confirm with whoever owns the CAQ palette intent; either declare both as named custom properties (e.g. `--cream-page`, `--cream-rail`) to make the two-tone choice explicit, or consolidate to one value if the difference wasn't deliberate. |
| **Resolution** | — |

---

### ISS-043 — Add internal `styling` package as a dependency (colour palettes, fonts)

| Field | Detail |
|---|---|
| **Source** | USER, session 2026-09-06, during Connect Cloud publish planning |
| **Severity** | — (feature request, not a defect) |
| **Status** | **Open — not started, doc-only entry** |
| **File(s)** | Likely `global.R` (package load), possibly `R/helpers.R` / plot styling code once implemented |
| **Description** | Queensland Health has an internal `styling` package (colour palettes, fonts, etc. — analogous provenance to `forestHelperR`: not on CRAN, installed locally from a `.tar.gz`) that the user wants to bring in as a dependency so the app's visual styling (CAQ palette, fonts) can be updated by changing the package rather than editing app code directly. |
| **Why it matters** | Same deployability question as **ISS-036** (`forestHelperR`'s unresolvable `renv.lock` source) applies here too — whatever fix is chosen for ISS-036 (internal package repository vs. `renv/cellar/` bundling) should probably cover `styling` as well, since it's the same category of problem. |
| **Recommended approach** | Treat as a follow-up piece of real work, not a doc-only change: (1) decide how `styling` is sourced for deployment (see ISS-036's options — internal Package Manager repo is the robust long-term fix); (2) add it to `global.R` and `renv.lock`; (3) work out which existing styling logic (palette/font handling, currently hardcoded per `CLAUDE.md`'s "CAQ palette") it should replace or wrap. Not scoped or started this session — raised so the Connect Cloud publish work happening in parallel doesn't quietly assume this is already handled. |
| **Related** | ISS-036 (same class of internal-package deployability problem) |
| **Resolution** | — |

---

### FEAT-012 — Back/Next navigation buttons on each open drawer

| Field | Detail |
|---|---|
| **Source** | USER, session 2026-09-06, raised alongside the Export drawer layout fix (CHG-061) |
| **Severity** | — (feature idea, not a defect) |
| **Status** | **Open — not started, doc-only entry** |
| **File(s)** | Likely `R/ui_plot_options.R` (a shared `drawerNavUI()`-style helper, one call per panel), `www/style.css`, `server/drawers.R` (to advance/retreat the open-drawer state) |
| **Description** | In addition to jumping between drawers via the rail icons, add a "Back"/"Next" button pair inside each open drawer (left/right, presumably bottom-anchored near the panel content) that steps to the adjacent drawer in rail order. Data (first in the sequence) only needs "Next"; Order (last) only needs "Back"; every drawer in between gets both. |
| **Design notes** | User's own suggestion: reuse the Export drawer's pill button sizing (CHG-057/061) rather than a new size. Claude's recommendation (2026-09-06, not yet actioned): keep the same shape/size/radius as the Export buttons for one consistent button vocabulary, but give Back/Next a *lighter/outline* variant (slate text+border on a light/transparent fill, inverting to solid on hover) rather than the identical solid slate fill — the Export buttons are one-off committal actions (Download, Copy) that should read as "the thing to click," while Back/Next will recur on every drawer and would dilute that hierarchy if styled identically. Not settled — worth confirming visually once actually built, per this project's standing "verify live, don't just reason about CSS" process (see `session-handoff.md` §7, CHG-055's account of why). |
| **Related** | CHG-057 (Export drawer redesign — the pill button styling this borrows from), CHG-061 (Export layout fix, same session this idea was raised in) |
| **Resolution** | — |

---

*Document version: 3.19 — FEAT-012 raised (doc-only): Back/Next drawer-navigation buttons,
idea only, not yet built — see entry for the open styling question. Previously: Document
version 3.18 — ISS-049 through ISS-054 raised (doc-only): remaining findings
from the 2026-09-04 architecture/CSS review docs that weren't already covered by
ISS-044..048 — Data panel field wrapper inconsistency, unannotated server.R file-order
dependency, redundant reactive dereferencing in server/preview.R, redundant
isTruthy()-in-req() in server/regression.R, unbundled 'JetBrains Mono' font reference,
and undocumented divergent cream colour tokens. Previously: Document version 3.17 —
ISS-044 raised and resolved (CSS audit quick-fix batch: `.drawer-scrim` z-index 98→1027,
`--page-accent` token declared, ~65 lines dead template CSS removed, `.export-section
.btn` rules consolidated, `overflow: visible` scoped from every `.tab-pane` to the Plot
tab only). ISS-045/046/047/048 raised (renumbered from the 2026-09-04 architecture/CSS
review docs' candidate IDs, which collided with the already-registered ISS-043 — wizard
Step 2 modal footer inconsistency; widespread un-namespaced calls; pure math helpers
embedded in server/observers.R; duplicated estimate-label logic in server/preview.R —
all still open). Previously: ISS-043 raised (internal `styling` package dependency,
doc-only, raised during Connect Cloud publish planning; same deployability question as
ISS-036). Previously: Document version: 3.16 — ISS-042 partially resolved (CHG-055:
navbar tabs redesigned as
filled pills, resolving sub-issues 2/3 — done via live user-directed visual iteration
after the Chrome extension was removed from the session entirely; sub-issue 1, Help page
title alignment, not touched and still open). FEAT-011 updated (CHG-055–057: navbar pill
redesign, pill buttons extended to wizard/Export, Export drawer redesign — narrower,
centred, single divider, uniform-width inverted pills, a real flex-stretch bug found and
fixed along the way). Previously: Document version 3.15 — ISS-042 raised (CHG-054's
navbar/Help-tab restyle: Help title
still not left-aligned, app-title/tab-label baseline alignment made worse, active-tab
underline still reads as a second line — flagged by the user's own live check; next
session should fix this before starting ISS-041). Previously: Document version 3.14 —
ISS-039/040/041 raised (x-axis tick generation asymmetry,
deferred; Variables rail badge stale-count race on load, low priority; `README.md` stale
since before DEC-004/DEC-005, not fixed yet); FEAT-011's commit list extended with
`fd490b7` (CHG-051–053: Plot tab card-height/resolution fixes, Display panel 3-group
layout, rail badge default-state fix). Previously: Document version 3.13 — ISS-038 raised
and resolved (CHG-049: `shiny:connected` fired via
jQuery, never caught by `document.addEventListener` — first-visit wizard trigger had
silently never worked since CHG-041); FEAT-011 updated (Data-drawer visual language
extended to Variables/Display/Text/Order, Variables' estimate-column toggles combined,
rail/tab anchoring, default load state, wizard welcome modal redesign — CHG-045 through
CHG-050, carried forward through the `main` merge rebase). Previously: Document version
3.12 — merged `design/modal-progression-workflow` branch docs onto `main`
(rebase, 2026-09-06): FEAT-011 raised (branch: soft-gated setup wizard + Data drawer
visual redesign, draft, now carried forward through the rebase); ISS-036 fully resolved
(CHG-040, 2026-09-06): CHG-039's Cellar-based workaround was confirmed insufficient the
same day (Connect Cloud's own server-side deploy can't resolve a local-machine Cellar
reference — first deploy attempt failed on exactly this). Real fix: forestHelperR
published to a new public repo, github.com/DunnNAM/forestHelperR, sanitized (original
maintainer's personal email removed/masked pending her confirmation, Nathan Dunn added
as real maintainer) and confirmed free of any other internal references; renv.lock's
forestHelperR entry updated to a real GitHub source (scoped override of the "do not
modify renv.lock" convention, explicitly authorized by the user, mirroring DEC-006's
migration carve-out); manifest.json regenerated successfully via rsconnect's default
lockfile-based path (no workaround needed this time). Also fixed two real, live privacy
exposures found along the way: the original unsanitized tarball that CHG-039 had
committed to the now-public forest-plot-generator repo, and the real email appearing in
that same commit's own message on the new forestHelperR repo (fixed via a safe
amend+force-push, since that repo had only the one commit). Previously: Document version
3.10 — ISS-036 partially resolved (CHG-039, 2026-09-06): Connect Cloud publish prep
confirmed ISS-036 as a hard blocker for generating a deployment manifest (rsconnect's
internal renv snapshot pre-flight aborts outright on any unknown-source package), not
just the R 4.5.2 migration. Fixed for manifest.json generation by committing
renv/cellar/forestHelperR_0.2.0.tar.gz and reinstalling via renv::install() from that
path — renv.lock itself deliberately left untouched at the time (CLAUDE.md reserves
lockfile edits for the R 4.5.2 migration, DEC-006). Also found and patched a recurrence
of the ISS-035 pattern: svglite/systemfonts/textshaping missing from the generated
manifest (dependency scanner can't see them since nothing calls them via :: directly) —
patched from their already-correct renv.lock entries; final manifest matches renv.lock's
package list exactly (138/138). Previously: Document version 3.9 — FEAT-010 implemented
(CHG-038: DEC-005 Step 7 — status-chip strip, rail badges, Help nav panel); previously:
ISS-036 raised (CHG-037: `forestHelperR` unresolvable in `renv.lock`); ISS-037 raised and
resolved (CHG-037: NOT_CRAN skip); ISS-032/033/034 resolved (CHG-023/024/025); ISS-035
raised and resolved (CHG-028: svglite installed); ISS-031 resolved and FEAT-009
implemented (CHG-033: Export drawer panel redesign); FEAT-010 raised (CHG-036: DEC-005
Step 7 phase-2 work registered)*
