# Architecture & Code Review — Function-Based Architecture Audit

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Type** | Architecture & Code Quality Audit (DEC-004 Function-Based Alignment) |
| **Git ref** | `2edee25` (branch `design/modal-progression-workflow`) |
| **Working tree** | **Clean** (untracked: `.agy-context.md`, `.claude/hooks/`, screenshot) |
| **Scope** | `global.R`, `ui.R`, `server.R`, `R/` (`helpers.R`, `ui_drawers.R`, `ui_help.R`, `ui_plot_options.R`, `ui_rail.R`, `ui_wizard.R`), `server/` (`upload.R`, `regression.R`, `preview.R`, `plot.R`, `export.R`, `observers.R`, `drawers.R`, `wizard.R`), `tests/testthat/` (`test-helpers.R`, `test-shiny-app.R`), `issues-register.md`, `app-changelog-decision-register.md` |
| **Purpose** | Audit the codebase against `.agy-context.md` guidelines, DEC-004 function-based architecture standards, `CLAUDE.md` coding conventions, and verify test baseline health |

---

## 1. Executive Summary

A comprehensive architectural and code-quality review was conducted across the application. The codebase strongly adheres to the function-based, file-split architectural model (**DEC-004**), where `server.R` orchestrates 8 topic-focused server scripts via `source(..., local = TRUE)` and UI trees are built using functional builders in `R/`.

Both automated test suites pass completely under R 4.3.3:
- **Pure helper unit tests (`test-helpers.R`)**: 48 / 48 assertions passing.
- **`shinytest2` integration tests (`test-shiny-app.R`)**: 9 / 9 assertions passing.

Previous architectural findings from the 2026-06-10 audit have been resolved:
- `output$forest` is now registered top-level in `server/plot.R` rather than dynamically nested inside an `observe()` (former candidate ISS-033).
- `ggplot2::ggsave()` and `survival::coxph()` are properly namespace-qualified.

However, several areas of convention drift and optimization opportunities were identified:
1. **Extensive package namespace omissions (`pkg::fun()`)** across `ui.R`, `R/ui_*.R`, and `server/*.R`.
2. **Pure numerical logic embedded in `server/observers.R`** (`xticks_default()` and `make_log_range()`) that should be extracted to `R/helpers.R` and unit tested.
3. **DRY violation in `server/preview.R`**: duplicating estimate label logic inline instead of using `get_est_type()`.
4. **Minor reactive dereferencing inefficiencies** in `server/preview.R` (`data_updated()` called 7 times in a single render block).

---

## 2. Audit by Analysis Dimension

### 2.1 Scope & ID Management (No `ns()`)
- ✅ **Module Namespace Decoupling:** Verified 0 occurrences of `ns()` or `session$ns()` in UI functions or server files. The code strictly uses a flat, global namespace conforming to DEC-004.
- ✅ **ID Pairing & Contract Alignment:**
  - All 14 outputs rendered across `server/*.R` (`files`, `sortable`, `dat_upload`, `dat_summary`, `regression_details`, `robust`, `forest`, `download_plot`, `download_r_code`, `sortable_cols`, `xticks_ui`, `status_chips`, `rail_badge_variables`, `rail_badge_display`) correspond to declared UI outputs in `ui.R`, `R/ui_rail.R`, and `R/ui_plot_options.R`.
  - All interactive UI inputs (~45 inputs across Data, Variables, Display, Text, Order, and Export) are correctly matched and consumed by reactive expressions and observers in `server/`.
- ℹ️ **F-1 (Note) — Inconsistent field wrapper in Data panel:** `group_var_name` and `group_var_values` (`R/ui_plot_options.R:166-168`) are raw `textInput()` widgets directly inside a `conditionalPanel()`, omitting the `drawerFieldUI()` wrapper used by all other fields in the panel.

### 2.2 Server Environment Scoping (`local = TRUE`)
- ✅ **Zero Global Environment Mutation:** 0 occurrences of `<<-` or explicit `.GlobalEnv` assignments found across all `.R` files.
- ✅ **Closure Sharing:** `server.R` loads the 8 server scripts into the top-level server closure with `local = TRUE`. Variables and reactives defined in upstream scripts (`data_uploaded`, `data_updated` in `upload.R`; `fit`, `reg_table` in `regression.R`; `est_type`, `order` in `plot.R`) are accessible cleanly in downstream scripts (`preview.R`, `export.R`, `observers.R`, `drawers.R`, `wizard.R`).
- ⚠️ **F-2 (Drift / Risk) — Implicit File Order Coupling:** Because sourcing with `local = TRUE` evaluates sequentially within a single environment, moving file lines in `server.R` would break execution (e.g., `preview.R` requires `data_updated` from `upload.R` and `reg_table` from `regression.R`). While this is intrinsic to the `source(..., local = TRUE)` pattern, `server.R` currently lacks explanatory ordering comments.

### 2.3 Reactivity Performance & Optimization
- ✅ **Observer Output Registration Resolved:** `output$forest` is directly registered via `renderPlot()` passing reactive functions to `width` and `height`, eliminating redundant output re-registrations.
- ✅ **Hidden Output Suspension Handling:** `outputOptions(output, ..., suspendWhenHidden = FALSE)` in `server/drawers.R` correctly keeps `files`, `sortable_cols`, `download_plot`, `download_r_code`, and `xticks_ui` active while drawer panels are hidden (`display: none`).
- ⚠️ **F-3 (Drift / Risk) — Redundant Reactive Evaluations in `server/preview.R`:** In `output$dat_upload`, `data_updated()` is evaluated 7 separate times within a single reactive cycle (`colnames(data_updated())`, `data_updated() %>% ...`, etc.). Similarly, `reg_table()` is called multiple times in `output$dat_summary`. Assigning local aliases (e.g., `df <- data_updated()`, `col_names <- colnames(df)`) at the start of the render expression avoids repetitive reactive dereferencing.
- ℹ️ **F-4 (Note) — Redundant `isTruthy()` inside `req()`:** In `server/regression.R:4-5`, `req(isTruthy(input$dataset_selected == "sim"), isTruthy(length(input$predictor_vars) > 0))` wraps `isTruthy` inside `req()`. `shiny::req()` already calls `shiny::isTruthy()` internally on all arguments.

### 2.4 Package Namespace Qualification (`pkg::fun()`)
- ❌ **F-5 (Violation / Convention Drift) — Widespread Unqualified Calls:**
  `CLAUDE.md` explicitly mandates: *"Always use explicit package::function() notation"*. Widespread un-namespaced calls remain across all application layers:
  - **`ui.R`:** Bare calls to `bslib::page_navbar()`, `bslib::nav_panel()`, `bslib::navset_card_tab()`, `shiny::div()`, `shiny::wellPanel()`, `shiny::conditionalPanel()`, `shiny::radioButtons()`, `shiny::verbatimTextOutput()`, `shiny::strong()`, `shiny::fluidRow()`, `shiny::plotOutput()`, `shiny::uiOutput()`, and un-prefixed `tags$*`.
  - **`R/ui_*.R`:** Functional UI builders in `ui_rail.R`, `ui_drawers.R`, `ui_plot_options.R`, `ui_wizard.R`, and `ui_help.R` make bare calls to `div()`, `p()`, `h4()`, `icon()`, `tagList()`, `tags$*`, `checkboxInput()`, `sliderInput()`, `selectInput()`, `actionButton()`.
  - **`server/*.R`:**
    - Shiny core primitives: bare `reactive()`, `reactiveVal()`, `observe()`, `observeEvent()`, `req()`, `renderUI()`, `renderPrint()`, `renderPlot()`, `downloadHandler()`, `bindEvent()`, `throttle()`, `debounce()`, `updateRadioButtons()`, `updateCheckboxGroupInput()`, `outputOptions()`, `validate()`, `need()`.
    - Package UI controls: `sortable::add_rank_list()` (`server/upload.R:69`), `shinyWidgets::updateMaterialSwitch()` (`server/observers.R:40, 46`).
    - Tidyverse / Tidyselect verbs: `dplyr::between()`, `dplyr::case_when()`, `tidyselect::all_of()`, `tidyselect::any_of()`, `tidyselect::everything()`, `tidyselect::where()`, `rlang::sym()`.

### 2.5 Function Separation & Testability
- ⚠️ **F-6 (Drift / Risk) — Pure Math Helpers Embedded in Server File:**
  `xticks_default(n, domain)` (`server/observers.R:79-92`) and `make_log_range(lo, hi)` (`server/observers.R:105-119`) are pure numerical utility functions with zero reactive dependencies. Defined inside a server closure, they cannot be tested by `testthat` without running the full application. Extracting them to `R/helpers.R` will allow direct unit testing.
- ⚠️ **F-7 (Drift / Risk) — Estimate Label Logic Duplication:**
  `server/preview.R:74-79` writes an inline `case_when(...)` block to format estimate column headers ("RR", "OR", "HR", "1/HR"), duplicating the logic of the tested helper `get_est_type()` in `R/helpers.R`.

---

## 3. Findings & Candidate Register Entries

### F-1 ℹ️ Unstyled inputs in Data panel
`group_var_name` and `group_var_values` in `dataPanelUI()` (`R/ui_plot_options.R`) bypass `drawerFieldUI()`.
- **Status:** Note / Minor.
- **Action:** Wrap in `drawerFieldUI("Group variable settings", ...)` during the next UI polish pass.

### F-2 ⚠️ Implicit file execution order in `server.R`
The sequential dependencies across `server/*.R` are unannotated in `server.R`.
- **Status:** Drift / Risk.
- **Action:** Add dependency flow comments in `server.R` documenting the pipeline: `upload.R` (data input) → `regression.R` (model fit) → `preview.R` / `plot.R` → `export.R` / `observers.R` / `drawers.R` / `wizard.R`.

### F-3 ⚠️ Redundant reactive dereferencing in `server/preview.R`
`data_updated()` is called 7 times and `reg_table()` twice within single render expressions.
- **Status:** Drift / Risk.
- **Action:** Store result in local variable `df <- data_updated()` once at the top of the render block.

### F-4 ℹ️ Redundant `isTruthy()` inside `req()` in `server/regression.R`
`req(isTruthy(...))` is redundant since `req()` evaluates truthiness internally.
- **Status:** Note / Minor.
- **Action:** Simplify to `req(input$dataset_selected == "sim", length(input$predictor_vars) > 0)`.

### F-5 ❌ Widespread un-namespaced function calls (`pkg::fun()`)
Direct contradiction of `CLAUDE.md` and `.agy-context.md` Rule 4 across `ui.R`, `R/`, and `server/`.
- **Severity:** Medium (Convention violation).
- **Candidate ISS-043:** Qualify external package functions with explicit namespaces (`shiny::`, `bslib::`, `sortable::`, `shinyWidgets::`, `dplyr::`, `tidyselect::`, `rlang::`).
- **Target CHG:** `CHG-056`.

### F-6 ⚠️ Pure mathematical helpers embedded in `server/observers.R`
`xticks_default()` and `make_log_range()` reside in `server/observers.R` and lack unit tests.
- **Severity:** Low/Medium (Testability & separation of concerns).
- **Candidate ISS-044:** Extract `xticks_default()` and `make_log_range()` into `R/helpers.R`; add unit test coverage in `tests/testthat/test-helpers.R`.
- **Target CHG:** `CHG-057`.

### F-7 ⚠️ Estimate label logic duplicated in `server/preview.R`
`server/preview.R` duplicates `get_est_type()` logic with an inline `case_when()`.
- **Severity:** Low (DRY / Maintainability).
- **Candidate ISS-045:** Replace inline `case_when()` with `get_est_type(input$regression_type, input$inv)`.
- **Target CHG:** `CHG-058`.

---

## 4. Test Suite Verification Summary

Both suites executed against commit `2edee25` on R 4.3.3 (`x86_64-w64-mingw32`):

```
══ Testing test-helpers.R ══════════════════════════════════════════════════════
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 48 ] Done!

══ Testing test-shiny-app.R ════════════════════════════════════════════════════
[ FAIL 0 | WARN 0 | SKIP 0 | PASS 9 ] Done!
```

- ✅ Pure helper unit tests: 23 blocks / 48 assertions passing.
- ✅ `shinytest2` integration tests: 6 blocks / 9 assertions passing (under `NOT_CRAN=true`).
