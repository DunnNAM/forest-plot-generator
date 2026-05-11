# Forest Plot Builder — Handover: PDEC-001 Module Architecture Decision

> **Prepared:** 2026-05-11  
> **Author:** Nathan Dunn / Claude (Anthropic)  
> **Purpose:** Context document for the next chat session, which will assess and decide PDEC-001 — whether to refactor `server.R` / `ui.R` from a monolithic 3-file structure into a Shiny module architecture.  
> **Read alongside:** `CLAUDE.md`, `issues-register.md`, `app-changelog-decision-register.md`

---

## 1. Project State at Handover

The code review and issue resolution phase is **complete**. All work is committed and pushed to `main`.

### What was done this phase

| Change | Description |
|---|---|
| CHG-004 to CHG-009 | Batches 1–3: namespace qualifiers, UI label fixes, dead code removal, reactive tidying |
| CHG-010–012 | README, renv, data caching |
| CHG-013 | FEAT-001: R code serialiser (Copy R code / Download .R script buttons) |
| CHG-014 | ISS-004 Phase 1: 48 unit tests for pure helper functions (`tests/testthat/test-helpers.R`) |
| CHG-015 | ISS-004 Phase 2: 7 shinytest2 integration tests (`tests/testthat/test-shiny-app.R`) |
| CHG-016 | ISS-002: `extrafont` replaced with `sysfonts`/`showtext` (DEC-003) |
| CHG-017 | ISS-009/010: presentation repo doc placeholders resolved |

### Test suite (safety net for any refactor)

| File | Tests | What it covers |
|---|---|---|
| `tests/testthat/test-helpers.R` | 48 unit tests | All 9 pure helper functions in `R/helpers.R` |
| `tests/testthat/test-shiny-app.R` | 7 integration tests | Column confirmation gate (ISS-020 regression guard), two-file upload, regression type → estimate label |

Run before and after any refactor:
```r
testthat::test_file("tests/testthat/test-helpers.R")
testthat::test_file("tests/testthat/test-shiny-app.R")
```

### Open issues (not the focus of this session, but be aware)

| ID | Severity | Description |
|---|---|---|
| ISS-028 | Medium | Age group sort order wrong in simulated data — likely in `forestHelperR::regTabler()` |
| ISS-029 | Low | OS system fonts absent from selector after `sysfonts` migration |
| ISS-030 | Low | `"Source Sans Pro"` renamed to `"Source Sans 3"` on Google Fonts — silently absent |
| ISS-031 | Medium | Export button layout: fourth button wraps with no spacing |
| FEAT-009 | Medium | Export controls redesign — sidebar accordion panel (radio button PNG/SVG + two code buttons) |

---

## 2. The PDEC-001 Question

**Decision to make:** Should `server.R` / `ui.R` be refactored from a monolithic 3-file Shiny structure into Shiny modules?

**Recorded in:** `app-changelog-decision-register.md` — Pending Decisions table, PDEC-001.

**Why it matters:** This is the largest remaining architectural decision. The answer shapes how all future features (FEAT-009 export redesign, ISS-028 fix, any new capabilities) are built and tested. Getting this decision right before adding more code is important.

**What Shiny modules provide:**
- Namespaced inputs/outputs — no ID collisions across logical sections
- Reusability — a module can be instantiated multiple times (less relevant here)
- Testability — modules can be unit-tested in isolation with `shinytest2`
- Separation of concerns — each module owns its UI and server logic

**What Shiny modules cost:**
- Boilerplate — each module requires `*UI()` and `*Server()` functions, namespace wrappers (`NS()`, `moduleServer()`), and explicit inter-module communication via reactive returns
- Complexity — passing reactives between modules (e.g. `reg_table()` consumed by both the preview tab and the plot) requires explicit design
- Refactor risk — the existing integration tests will catch regressions, but the refactor itself is non-trivial

---

## 3. Current Architecture

### File structure

```
global.R          ~120 lines   package loads, font setup, global objects
ui.R              ~290 lines   page_sidebar layout, sidebar, tab panels, accordion options
server.R          ~713 lines   all reactive logic
R/helpers.R        ~66 lines   pure helper functions (auto-sourced by Shiny)
```

### server.R logical sections

The server is already structured with section comments (`## step N`, `### a`, `#### i`). The logical groupings map naturally to potential modules:

| Section | Lines (approx) | Reactives / outputs |
|---|---|---|
| **Data upload** | 1–123 | `data_uploaded()`, `output$files`, `output$sortable` (renderUI) |
| **Column confirmation gate** | 125–249 | `cols_confirmed` (reactiveVal), `data_updated()` |
| **Regression fitting** | 251–309 | `fit()`, `predictors_selected()`, `reg_table()` |
| **Data preview tables** | 311–421 | `output$dat_upload`, `output$dat_summary`, `output$regression_details`, `output$robust` |
| **Plot generation** | 423–510 | `est_type()`, `variables_excluded()`, `forest_plot_object()`, `dims()`, `output$forest` |
| **Export handlers** | 512–619 | `output$download_png`, `output$download_svg`, `r_code_string()`, copy handler, `output$download_r_code` |
| **Misc observers** | 621–712 | variable selector update, sortable cols UI, by_group auto-set, element/order/significance observers |

### ui.R logical sections

```
Sidebar:       data mode selector, file upload, regression type, group controls,
               predictor/response selectors (sim mode)
Tab 1:         Review data — sortable column mapper, dat_upload table, dat_summary table
Tab 2:         Plot — forest plot output, export buttons
Right panel:   Three accordion sections (Variables & Elements, Plot Display, Plot Text)
```

---

## 4. Proposed Module Breakdown (Starting Point for Discussion)

Four candidate modules based on the natural section groupings above:

### Module A — `dataUploadModule`
**Owns:** File upload, column mapping drag-drop UI, confirmation gate  
**Inputs:** none (file picker is user-driven)  
**Returns:** `data_updated()` reactive — the processed, column-confirmed data frame  
**Notes:** Encapsulates the ISS-020 fix (`cols_confirmed` reactiveVal) cleanly. The `output$sortable` renderUI is complex but self-contained.

### Module B — `regressionModule`
**Owns:** Simulated data model fitting, `reg_table()` construction  
**Inputs:** `dataset_selected` input, `data_updated()` from Module A (upload path)  
**Returns:** `reg_table()` reactive — the standardised table consumed downstream  
**Notes:** This module serves both data paths (upload and sim). The upload path is trivial (pass-through from Module A); the sim path runs `glm()`/`coxph()`. `reg_table()` is the key shared reactive — both the preview tab and the plot consume it.

### Module C — `plotModule`
**Owns:** Forest plot generation, display, all export handlers, R code serialiser  
**Inputs:** `reg_table()` from Module B, all plot option inputs from the accordion panels  
**Returns:** nothing (all side effects — rendered plot, downloads)  
**Notes:** The accordion panels in the right sidebar are plot-option inputs — they could live inside this module's UI or remain in the top-level UI and be passed as inputs. The `order()` reactive and `variables_excluded()` reactive both live here.

### Module D — `dataPreviewModule`
**Owns:** Review Data tab — `output$dat_upload`, `output$dat_summary`, regression details  
**Inputs:** `reg_table()` from Module B, `data_updated()` from Module A, various inputs  
**Returns:** nothing (display only)  
**Notes:** Smallest module. Could alternatively remain inline rather than becoming a module — the Review Data tab is display-only with no outputs consumed elsewhere.

---

## 5. Key Design Questions for the Session

These need to be answered before implementation begins:

**Q1 — How is `reg_table()` shared?**  
`reg_table()` is consumed by both Module C (plot) and Module D (preview). In Shiny modules, a reactive can only be returned from one module and passed as an argument to others. The natural owner is Module B — it returns `reg_table()`, which is passed to both C and D. Confirm this pattern is acceptable before proceeding.

**Q2 — Where do the accordion panel inputs live?**  
The right-hand accordion (Variables & Elements, Plot Display, Plot Text) contains ~40 inputs that are all consumed by `forestPloter()` in Module C. Options:
- (a) Keep accordion panels in the top-level `ui.R`, pass inputs to Module C via `session$input` — simpler, less encapsulation
- (b) Move accordion UI into Module C's UI function — full encapsulation, but makes Module C's UI function very large

**Q3 — What is the minimum viable module refactor?**  
Full modularisation is a large change. A pragmatic minimum might be:
- Extract only Module A (`dataUploadModule`) — the most self-contained section and the one with the most test coverage (ISS-020 regression guard)
- Leave everything else as-is
- Re-evaluate whether further modularisation is warranted

**Q4 — Is modularisation warranted at all?**  
`server.R` at ~713 lines is large but not unmanageable. The existing section comments (`## step N`) already provide logical separation. The strongest argument for modules is testability; the counter-argument is that the shinytest2 suite already provides integration coverage and `R/helpers.R` provides unit coverage for the pure functions. If the answer to PDEC-001 is "not required at this stage", record it as DEC-004 with clear rationale and close the pending decision.

---

## 6. Recommended Session Approach

1. **Read `server.R` in full** before making any decisions — the session opener should include reading the file so Claude has full context on the actual complexity and inter-dependencies.

2. **Make the PDEC-001 decision first** — before writing any code. Present a clear recommendation (modularise fully / modularise partially / defer) with rationale, and get Nathan's sign-off.

3. **If modularising, start with Module A** — it is the most self-contained, has the best test coverage, and delivers the most isolated benefit. Deliver one module at a time, running the full test suite after each.

4. **Run tests before and after every change:**
   ```r
   testthat::test_file("tests/testthat/test-helpers.R")
   testthat::test_file("tests/testthat/test-shiny-app.R")
   ```

5. **Update both registers for every change** — `app-changelog-decision-register.md` and `issues-register.md`. The next CHG number is **CHG-018**. The next DEC number is **DEC-004**.

---

## 7. Conventions (Reminder)

- Always use explicit `package::function()` notation
- Prefer `req()` over `is.null()` guards in reactives
- Update `app-changelog-decision-register.md` for every code change
- Do not modify `forestHelperR` package files (separate repo)
- Do not modify `renv.lock` directly — use `renv::snapshot()` after installs
- All documentation in `.md` format

---

## 8. Repository

```
Remote:   https://github.com/DunnNAM/forest-plot-generator
Branch:   main
Latest:   ed2df84 — docs: update CLAUDE.md to reflect completed review phase
```

Clone or pull before starting:
```r
# In terminal
git pull origin main
```

---

*Handover document version: 1.0 — prepared 2026-05-11*
