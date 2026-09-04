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

### DEC-006 — `renv::snapshot()` authorised for the R 4.5.2 migration

| Field | Detail |
|---|---|
| **Date** | 2026-09-03 |
| **Author** | Nathan Dunn (decision) / Claude (Anthropic) |
| **Status** | Active — migration not yet completed |
| **Refs** | ISS-036, CHG-037, `session-handoff.md` §3 |

**Decision:** For the migration of this project from R 4.3.x to R 4.5.2, `renv::snapshot()`
may rewrite `renv.lock`, overriding the standing "Do not modify renv.lock" convention in
`CLAUDE.md`. The convention otherwise stands.

**Why the override is needed:** `renv::restore()` installs packages but never edits the
lockfile, so restoring under 4.5.2 would leave `renv.lock` still recording
`"R": { "Version": "4.3.1" }` while the project actually ran on 4.5.2. A lockfile that
misstates its own R version is a worse failure mode than the convention protects against —
it silently misleads the next person to rebuild the environment. Only `snapshot()` can
correct it.

**Conditions attached:**

1. **Snapshot only after the test suite is green under R 4.5.2.** The pre-migration
   baseline is 48 assertions / 23 blocks (`test-helpers.R`) and 9 assertions / 6 blocks
   (`test-shiny-app.R`), all passing under R 4.3.3, captured 2026-09-03. A lockfile
   recording a broken environment is worse than a stale one.
2. **Rollback is `git checkout renv.lock`** — the lockfile is tracked, so the override is
   reversible in one command.
3. **The override is scoped to this migration.** It does not authorise routine
   `snapshot()` calls; the convention resumes once the migration lands.

**Status note:** the first automated attempt (2026-09-03) failed before reaching the
snapshot step — see CHG-037. `renv.lock` is unmodified. A manual retry is planned for
2026-09-04; this decision remains in force for it.

**Alternatives considered:** *Restore only, leave the lock alone* — respects the convention
but leaves the lockfile permanently inaccurate. *Stay on R 4.3.x* — zero risk and the
environment that works today, but declines the upgrade; this remains the fallback if the
manual retry also fails.

---

### DEC-005 — Restyle: MDT theme + bottom rail/drawer layout

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Active — core migration (Steps 1-6) complete; Step 7 phase-2 not started, tracked as FEAT-010 |
| **Refs** | DEC-004 (prerequisite, complete), `restyle-implementation-plan.md` |

**Decision:** Restyle the app using the `mdt-activity-dashboard` project's visual language (CAQ palette, cream background, navbar, card treatment) and its rail + drawer + focused-picker interaction model — with the rail relocated from MDT's left side to a **full-width bar at the bottom** of the viewport, and the drawer sliding **up** from the rail instead of out from the side. Forest plots are wide; removing both the left sidebar and the right-hand plot-options column gives the plot the full viewport width, and the widest control (the 10-bucket column-mapping `bucket_list`) fits a full-width bottom drawer naturally.

**Key constraint carried over from DEC-004:** no Shiny modules. MDT's `mod_filter_rail`/`mod_filter_drawer` pattern is adapted as plain UI helper functions (`R/ui_rail.R`, `R/ui_drawers.R`) and a `server/drawers.R` sourced with `local = TRUE`, consistent with the rest of the app.

**Key implementation choice:** drawer panels are rendered **statically** in `ui.R` (not via `renderUI`/staged `reactiveValues` as MDT does) — this app has ~45 always-live inputs consumed directly by `forest_plot_object()`/`r_code_string()`, and staging them would be a rewrite of the entire reactive surface for no user benefit. The active panel is chosen by toggling a CSS class; every input ID stays in the DOM from app start, so the existing shinytest2 suite (which targets IDs, not containers) should survive unmodified except where the plan explicitly retires an ID (export button IDs, in a later step).

**Migration:** 7 shippable steps (see `restyle-implementation-plan.md` §8), each gated on tests passing. Steps 1-6 (theme/navbar shell → rail/drawer shell → Variables/Display/Text panels → Data panel/sidebar retired → Order panel + FEAT-009 export redesign → CSS merge/polish) are complete — see CHG-029 through CHG-034. Step 7 (status chips, rail badges, Help nav) is explicitly phase-2/optional per the plan and has not been started.

**Alternatives considered:** see `restyle-implementation-plan.md` §1 for the side-rail-vs-bottom-rail rationale, and its companion review `reviews/architecture/2026-06-10_restyle-readiness-review.md` for the pre-restyle codebase audit.

---

### DEC-004 — File organisation: `source()` split + UI helper functions in place of Shiny modules

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Active |
| **Refs** | PDEC-001 |

**Decision:** Resolve PDEC-001 by implementing a `source()` file split and UI helper functions rather than full Shiny module architecture.

**Planned structure:**
- `server.R` reduced to a thin wrapper of six `source()` calls
- `ui.R` trimmed; plot options accordion extracted to `plotOptionsUI()` in `R/ui_plot_options.R`
- Server logic split across six files in a new `server/` directory: `upload.R`, `regression.R`, `preview.R`, `plot.R`, `export.R`, `observers.R`
- All server files sourced inside the `server` function with `local = TRUE`, sharing the server environment — no reactive wiring required

**Rationale:** The two drivers for considering modularisation were file organisation and UI authoring clarity. Both are satisfied by this lighter approach. Full Shiny module architecture solves namespace isolation and per-module testability — neither of which is a requirement. The app has no reuse requirement (modules would never be instantiated more than once), and the existing test suite already provides adequate integration coverage via `shinytest2`.

**Alternatives considered:**
- Full Shiny module architecture (four candidate modules: data upload, regression, plot, preview) — rejected. Adds `NS()`/`moduleServer()` boilerplate, requires explicit reactive-passing contracts (particularly for `reg_table()` shared between plot and preview), and solves problems the app does not have.
- Monolith retained as-is — rejected. `server.R` at ~713 lines and `ui.R` at ~192 lines are manageable but the section structure is only communicated via comments. File-level separation makes the architecture legible without opening a file.

> **Closes PDEC-001.**

**File split status (2026-07-17): complete.** All seven steps implemented and committed — `server.R` is now the six-`source()` wrapper this decision specified. See CHG-018 through CHG-027.

---

### DEC-003 — Replace `extrafont` with `sysfonts`/`showtext` for font handling

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Active |
| **Refs** | ISS-002, PDEC-003 |

**Decision:** Replace `extrafont` + `loadfonts()` with `sysfonts` + `showtext`. Register Lato at startup from the bundled `Lato/` TTF files. Attempt to load Roboto, Open Sans, Source Sans Pro, and Montserrat via `font_add_google()`, each wrapped in `tryCatch()` so internet unavailability fails silently.

**Rationale:** `extrafont` requires a one-time `font_import()` per machine — a manual step that is not automated, produces no user-visible error when skipped, and was confirmed to leave the font selector showing only 5 base system fonts on the development machine (ISS-002 runtime observation). `sysfonts`/`showtext` loads fonts from TTF files at startup with no per-machine setup. The `tryCatch()` pattern for Google Fonts provides a graceful degradation path for server deployments without external internet access.

**Alternatives considered:**

- Automate `font_import()` at startup — rejected; `font_import()` is slow, scans entire font directories, and is still machine-dependent. Does not solve the portability problem for deployment targets.
- Bundle all custom font TTF files and drop Google Fonts dependency entirely — deferred; would require sourcing and bundling Roboto, Open Sans, Source Sans Pro, Montserrat TTF files. Viable future improvement (eliminates internet dependency entirely).

**Known limitations introduced:** OS system fonts (Arial, Helvetica, Times, etc.) no longer appear in the selector — see ISS-029. `"Source Sans Pro"` silently absent (renamed to `"Source Sans 3"` on Google Fonts) — see ISS-030.

> **Closes PDEC-003.**

---

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
| ~~PDEC-001~~ | ~~Should the app be refactored from the 3-file structure (`ui.R`, `server.R`, `global.R`) to a Shiny module architecture? Decision requires reading `server.R` to assess complexity.~~ | FEAT-007 | — | **Closed as DEC-004** |
| ~~PDEC-003~~ | ~~Should `extrafont` be replaced with `sysfonts`/`showtext`?~~ | ISS-002 | — | **Closed as DEC-003** |
| PDEC-004 | Should the `officer` dependency be removed from `global.R` until Word/PowerPoint export is implemented? | ISS-006, FEAT-004 | Low | Early in code review |
| PDEC-005 | Should `forestHelperR` be moved to its own GitHub repository? | ISS-008, PKG-006 | **Deferred** — no hosting or sharing requirement at this stage. Leave package in current local location. Revisit when publication or server hosting is being planned. | When hosting/publication is scoped |
| PDEC-006 | Should `forestHelperR` declare its dependencies more explicitly so that `.tar.gz` installs resolve them automatically, or should the install documentation be updated to instruct users to install dependencies first? | ISS-014 (app), `forestHelperR` `DESCRIPTION` | Low — parked for future package maintenance cycle | Future package release |

> **Closed pending decisions:** PDEC-001 → DEC-004 (2026-05-11). PDEC-002 → DEC-002 (May 2026).

---

## Changes

> **Renumbering note (2026-09-06 merge):** `design/modal-progression-workflow` independently
> numbered its own branch-only entries CHG-039 onward, unaware `main` had since taken those
> same numbers for the Connect Cloud publish work below. To merge both histories into one
> sequence without collision, every branch-only entry originally numbered CHG-039–CHG-056
> is renumbered **+2** here (→ CHG-041–CHG-058); `main`'s real CHG-039/CHG-040 are
> unchanged. Commit subject lines on the branch still cite the old numbers — treat this
> register as the authoritative numbering going forward.

### CHG-050 — Wizard welcome modal redesign, auto-advance fix, styling (FEAT-011)

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Branch** | `design/modal-progression-workflow` (merged to `main`) |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | FEAT-011 |
| **Commit** | `907ce40` (originally registered as CHG-048 on the branch) |

The CHG-048 default-load-state change (Simulated data, already valid) surfaced a real bug: the wizard's auto-advance from the welcome modal to the "Variables ready" modal was a plain `observe()` re-firing on every reactive flush, so with valid data present from the very first flush the two modals stacked almost instantly — confirmed via a shinytest2 "duplicate `wizard_skip` id" warning appearing on every test block. Fixed by `bindEvent()`-ing the observer to actual Data-panel input changes (`ignoreInit = TRUE`), so step 1 only advances because of something the user did after entering it. The welcome modal itself was redesigned to a three-button footer — Skip wizard / Update data source/s / Go to plot styling (new: for a visitor happy with the already-valid example data) — and restyled: title reuses the drawer panels' colour/weight/size (new `.wizard-modal-title`), a paragraph rebuilt as one `HTML()` string rather than separate `strong()`/text arguments after tracing stray spaces to htmltools' pretty-printer inserting whitespace between inline elements, tightened vertical rhythm (25% less padding top/bottom on `.modal-header/-body/-footer`), one-row equal-width buttons (`flex: 1 1 0; min-width: 0`, not `nowrap` — that combination briefly forced a button past the modal's edge), and a 650px modal width so the longest label wraps at most two lines. `tests/testthat/test-shiny-app.R`'s three upload/column-confirmation blocks needed an explicit switch to `dataset_selected = "upload"` first, since they'd relied on its old default to reach the `cols` button (a `conditionalPanel` Shiny suspends when hidden).

Verified: 48/48 unit assertions, 9/9 integration assertions pass, 0 warnings (previously 6, one per test block).

---

### CHG-049 — Returning-user Data drawer default; fixed `shiny:connected` never firing (ISS-038) (FEAT-011)

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Branch** | `design/modal-progression-workflow` (merged to `main`) |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | FEAT-011, ISS-038 |
| **Commit** | `907ce40` (originally registered as CHG-047 on the branch) |

A returning user (`fpb_wizard_seen` already in `localStorage`) now default-opens the Data drawer instead of landing with no drawer open, while the main tab still defaults to Review data — `rv_drawer("data")` is set directly rather than through the rail-click path, so it doesn't also trigger that path's Plot-tab anchoring (CHG-047). Implementing this surfaced a real, pre-existing bug (present as far back as CHG-041, not introduced this session): `www/wizard.js` registered its "first visit?" check via `document.addEventListener("shiny:connected", ...)`, but Shiny fires that event through jQuery's `.trigger()`, not the native DOM event system — a native `addEventListener` can never catch it. The first-visit wizard modal's trigger had never actually worked reliably. Fixed by binding through jQuery itself (`jQuery(document).on("shiny:connected", ...)`), with a `Shiny.shinyapp.isConnected()` load-time check as a fallback for the case where the connection already completed before the script ran. Full root-cause trace (confirmed via server-side debug logging, then reading the bundled `shiny.min.js` directly) is in the commit body. Raises and resolves ISS-038.

Verified: 48/48 unit assertions, 9/9 integration assertions pass.

---

### CHG-048 — Default load state (Simulated data / Indicator 3 / Sex, Age-group, Time period); predictor label renames (FEAT-011)

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Branch** | `design/modal-progression-workflow` (merged to `main`) |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | FEAT-011 |
| **Commit** | `69f364f` (originally registered as CHG-046 on the branch) |

App now loads with Data set = Simulated data, Response variable = Indicator 3 (`IND_3`), Predictor variables = Sex, Age-group (`AgeGroupAtDiagnosis`), Time period (`DxYearGroup`) — Regression type unchanged (Poisson, robust variance on). Underlying column mapping confirmed by inspecting `forestHelperR::dat`'s actual `colnames()`. Three predictor display labels renamed in `global.R`: "Age group at diagnosis" → "Age-group", "Residence at diagnosis" → "Remoteness area of residence", "Diagnosis time period" → "Time period" — confirmed these are this repo's own display labels (`names(predictors) <- c(...)`), not anything sourced from `forestHelperR`, so no cross-repo change was needed.

Verified: 48/48 unit assertions, 9/9 integration assertions pass (integration suite needed updates for the new default — see CHG-050).

---

### CHG-047 — Rail/status-chip clicks anchor the main body tab to the open drawer (FEAT-011)

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Branch** | `design/modal-progression-workflow` (merged to `main`) |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | FEAT-011 |
| **Commit** | `69f364f` (originally registered as CHG-045 on the branch) |

The Review data tab is only useful while the Data drawer is what's being edited. `navset_card_tab()` given an explicit `id = "main_tabs"` (`ui.R`) so `server/drawers.R` can drive it with `bslib::nav_select()`: opening any drawer other than Data (via rail click or status chip) switches the main body to Plot; returning to the Data drawer switches it back to Review data. Closing a drawer (clicking its already-open rail item) leaves the current tab alone — there's no drawer left to anchor it to at that point.

Verified: 48/48 unit assertions, 9/9 integration assertions pass.

---

### CHG-046 — Variables panel: combined estimate-column toggles into one radio group; removed misleading static switch captions app-wide (FEAT-011)

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Branch** | `design/modal-progression-workflow` (merged to `main`) |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | FEAT-011 |
| **Commit** | `69f364f` (originally registered as CHG-044 on the branch) |

Three separate estimate-column fields ("Include significance symbol", "Combine estimate and CI", "Combine estimate and significance symbol") combined into one "Estimate Column Formatting" field. "Include significance symbol" is now a plain `checkboxInput()` (was a `materialSwitch()` whose label wrapped one word per line in the narrow field column); the other two — always mutually exclusive in practice — became a single three-way `radioButtons()`, "Combine estimate with:" (Significance symbol / Confidence interval / Neither, default Confidence interval, matching the old default). `server/plot.R` and `server/export.R` now derive `forestHelperR`'s `concatenate_est_ci`/`concatenate_est_sig` parameters from this one radio's value (`identical(input$combine_estimate_with, "ci"/"sig")`) rather than reading two independent switch inputs — the package's own parameters are unchanged, only what feeds them. The reset observers that used to unset the two switches when their underlying condition disappeared (estimate/CI deselected, significance turned off) now reset the radio to "Neither" instead. Separately: the static `"On"` caption on every `materialSwitch()` in the app (`by_group`, `inv`, `transparent_table_bg`, `striped_bg`, `transparent_plot_bg`, `sigfigs`, plus the three above before the redesign) was removed — it was static text that never tracked the switch's actual live state, so it read as mislabeled for any switch defaulting `FALSE` and would go stale the instant a `TRUE`-defaulting one was toggled off. Each switch now relies on its own on/off colour plus its adjacent title/label.

Verified: 48/48 unit assertions, 9/9 integration assertions pass.

---

### CHG-045 — Extend Data-drawer titled-field styling to Variables/Display/Text/Order panels (FEAT-011)

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Branch** | `design/modal-progression-workflow` (merged to `main`) |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | FEAT-011 |
| **Commit** | `69f364f` (originally registered as CHG-043 on the branch) |

CHG-043's Data-panel-only `drawerFieldUI()` title-over-content convention extended to Variables, Display, Text, and Order — Export is explicitly out of scope, pending its own design pass. `.drawer-row-divided` (vertical dividers, CHG-043) attempted on Variables as well as Data, since its base fields stay in one row at typical widths — Display and Text keep the plain `.drawer-columns` grid, since both reliably wrap across several rows and the divider technique (an absolutely-positioned line sized to a single flex line's height) only positions correctly within one row; Order has only one field, so dividers don't apply there either way.

Verified: 48/48 unit assertions, 9/9 integration assertions pass (CSS/layout-only change).

---

### CHG-044 — Data drawer: icon+uppercase panel headings, response-field padding (FEAT-011)

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Branch** | `design/modal-progression-workflow` (merged to `main`) |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | FEAT-011 |
| **Commit** | `69fef17` (originally registered as CHG-042 on the branch) |

Every drawer panel heading now shows its matching rail icon inline with an uppercase title (new `drawerHeaderUI()` helper), sized/weighted distinctly from field titles (20px/800 vs 16px/700 — previously identical, so a panel heading and a field title were indistinguishable). Left-aligned to match the fields below it, sealed off by a slate-blue bottom rule reusing the existing `.card-header` treatment. `.drawer-field-block` gained matching right-padding so full-width controls (Response variable's `<select>`) don't run into the next divider. Divider's bottom inset re-measured (20px → 70px) to stay symmetric against the taller header — verified via `getBoundingClientRect()`, not eyeballed. Full detail in the commit body.

Verified: 48/48 unit assertions, 9/9 integration assertions pass.

---

### CHG-043 — Data drawer: titled fields, divider rules, Robust variance nesting (FEAT-011)

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Branch** | `design/modal-progression-workflow` (merged to `main`) |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | FEAT-011 |
| **Commit** | `a63dd99` (originally registered as CHG-041 on the branch) |

Three related Data-panel changes: (1) every field (Data set, Comparison mode, Regression type, Response variable, Predictor variables) now uses a bold-title-over-smaller-content convention via a new `drawerFieldUI()` helper; (2) Robust variance moved from a separate top-level field to a checkbox nested under Regression type's Poisson option (Regression type reordered alphabetically — Cox, Logistic, Poisson — so the nested checkbox never repositions the other two), fixing a real layout break where selecting "Simulated data" stranded Robust variance under Data set at the bottom of the drawer; (3) faint vertical divider rules added between fields, centered within the drawer's available height via a `flex: 1`-stretching `.drawer-row-divided` layout (replacing `.drawer-columns` for this panel only). Two Shiny/CSS gotchas surfaced and are documented in the CSS: `conditionalPanel()`'s `display: contents` when shown defeats DOM-structural CSS selectors, and `flex: 1` needs an actual flex *parent*, which required making `.drawer-panel.active` a flex column. Full detail in the commit body.

Verified: 48/48 unit assertions, 9/9 integration assertions pass.

---

### CHG-042 — `.card` background invisible against cream page; sharper `.card-header` rule

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Branch** | `design/modal-progression-workflow` (merged to `main` — a real bug fix, unrelated to the wizard/Data-panel experiment) |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | FEAT-011 |
| **Commit** | `69f9b33` (originally registered as CHG-040 on the branch) |

`.card` had no explicit `background`; Bootstrap 5's `--bs-card-bg` defaults to `--bs-body-bg`, which `bs_theme()` sets to the same cream as the page (`global.R`), so every `bslib::card()` — including the FEAT-010 Help panel's four section cards — blended into the page instead of reading as a raised surface. Fixed with an explicit `background: #fff`. `.card-header`'s `border-bottom` also sharpened from a barely-visible `1px rgba(0,0,0,0.06)` hairline to a `2px` slate-blue rule (`color-mix()` at 35% of `--page-accent`), at the user's request once the card fix made the header line worth noticing.

Verified: 48/48 unit assertions, 9/9 integration assertions pass (CSS-only change).

---

### CHG-041 — Soft-gated setup wizard — modal-progression experiment (FEAT-011)

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Branch** | `design/modal-progression-workflow` (merged to `main`) |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | FEAT-011 |
| **Commit** | `d2fb1b7` (originally registered as CHG-039 on the branch) |

A first-visit setup wizard exploring whether the app's "directionless on first launch" problem can be fixed without abandoning DEC-005's static rail/drawer model. Two instructional `modalDialog()`s (welcome → Data; then Variables) guide a new user through the two required setup steps, auto-advancing from the first to the second the moment a plot-worthy table exists (`reg_table()`), always skippable, and restartable any time via a new "Tour" rail item (first, far left, styled as an action button like Export). Deliberately does not duplicate any of the ~45 live plot-option inputs DEC-005 keeps as single instances (restyle plan §3) — the modals tell the user what to do and the server opens the matching drawer, rather than embedding copies of controls like `dataset_selected`. First-visit detection uses `localStorage` (`www/wizard.js`), wrapped in `try/catch` so a blocked/private-browsing context just shows the tour every visit rather than erroring.

New files: `R/ui_wizard.R`, `server/wizard.R`, `www/wizard.js`. Modified: `R/ui_rail.R` (Tour item, generalised `rail_button()` to support a non-drawer click target), `R/ui_help.R` (pointer text to the Tour button), `server.R`, `ui.R`.

Verified: 48/48 unit assertions, 9/9 integration assertions pass — additive, no existing input ID or reactive touched.

---

### CHG-040 — Publish forestHelperR to GitHub, sanitized; fixes ISS-036 for real; two exposure incidents fixed along the way

| Field | Detail |
|---|---|
| **Date** | 2026-09-06 |
| **Branch** | `main` |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-036 (resolved), PDEC-005 (effectively actioned), CHG-039 |

CHG-039's `renv/cellar/` workaround was confirmed insufficient the same day: the first real Connect Cloud deploy attempt from `main` failed with `Package forestHelperR has invalid package source Cellar. Check your manifest.json or renv.lock.` Connect Cloud's GitHub-integrated deploy does its own server-side dependency resolution against the cloned repo's `manifest.json`/`renv.lock` — it doesn't bundle a local library the way `rsconnect::deployApp()` would — so `"Cellar"`, a reference to *this machine's* directory, is meaningless to it even though the tarball sits right there in the repo.

**Real fix:** published `forestHelperR`'s source to a new repo, `github.com/DunnNAM/forestHelperR` (public — matches the app repo's own visibility for the same Connect Cloud reason). Before publishing:
- Extracted the tarball and grepped the full source tree (code, docs, vendored JS libs, binary-inclusive) for Gitea URLs, `qld.gov.au`, internal IPs/paths, and credentials — found nothing beyond the maintainer's own email.
- Confirmed every one of `forestHelperR`'s own dependencies (`broom`, `dplyr`, `extrafont`, `forcats`, `forestploter`, `gtable`, `lmtest`, `magrittr`, `rlang`, `sandwich`, `scales`, `stringr`, `tibble`, `tidyr`, plus base `grid`/`stats`) is a plain CRAN package — nothing else needed the same treatment.
- **Sanitized attribution, not stripped:** the original author's personal work email was in `DESCRIPTION` and the generated `man/forestHelperR-package.Rd`. At the user's explicit direction, the original author is still credited (`Helen ***`, contact masked as `H*.*@health.qld.gov.au`) pending her own confirmation she's comfortable being publicly identified, and Nathan Dunn is added as the package's maintainer (`role = c("aut", "cre")`) with a real, working contact — a publicly-hosted package needs one. Verified the sanitized source still installs and passes the app's own test suite unchanged (48/48, 9/9) before publishing.

**Reinstalled and re-recorded:** `renv::install("DunnNAM/forestHelperR")` gives the installed package real `RemoteType`/`RemoteRepo`/`RemoteSha` GitHub provenance. Updated `renv.lock`'s `forestHelperR` entry to match via `renv::record()` — **this is the scoped `renv.lock` override the user explicitly authorized** for this fix, the same kind of deliberate exception DEC-006 made for the R 4.5.2 migration, scoped to this one package entry only (not a full `renv::snapshot()`, which CHG-028's experience already showed rewrites unrelated `Repository` fields and can drop packages `renv`'s implicit-type detection doesn't consider "used"). Note: `renv::record()`'s own return value, when passed a manually-assembled record already containing `Source`, wrote a duplicate `"Source"` JSON key — worked around by hand-editing the one duplicate line rather than fighting the undocumented internal API further.

`manifest.json` regenerated via `rsconnect::writeManifest()`'s **default, lockfile-based** path this time — no `dependencyResolution = "library"` workaround needed, since `renv.lock` now correctly resolves everything itself. 138/138 packages match exactly, including `svglite`/`systemfonts`/`textshaping` (the ISS-035-pattern gap from CHG-039's manifest, resolved automatically this time since the lockfile path picks them up correctly).

**Two real, live exposure incidents found and fixed in the process, not just the intended sanitization:**
1. CHG-039's commit had put the *original, unsanitized* tarball — containing the real email — into `renv/cellar/` on the now-public `forest-plot-generator` repo. Removed from `main`'s current tree this session (`git rm`); **git history on `main` was deliberately left unrewritten** — a lower-disruption call given `design/modal-progression-workflow` is an active, unmerged branch that forked before this point and would need rebasing onto any rewritten `main` history. The now-unused `renv/cellar/` un-ignore rules in `.gitignore`/`renv/.gitignore` were reverted alongside.
2. The first `forestHelperR` publish commit's own message quoted the real email in prose while describing its removal from the files — an ironic self-inflicted leak. Fixed by amending that commit and force-pushing; safe here specifically because `forestHelperR` was a brand-new single-commit repo with nothing else depending on it yet, unlike `main`.

Verified end to end: 48/48 unit + 9/9 integration assertions pass; no occurrence of the real email anywhere in the current `forestHelperR` repo (files or commit messages), `renv.lock`, or `manifest.json`.

---

### CHG-039 — Generate Connect Cloud manifest.json; commit forestHelperR cellar tarball (ISS-036 partial, superseded by CHG-040)

| Field | Detail |
|---|---|
| **Date** | 2026-09-06 |
| **Branch** | `main` |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-036 (partial), ISS-035 |

Prep for publishing `main` to Posit Connect Cloud:

- `rsconnect::writeManifest()` failed outright in its default (lockfile-based) mode on a small pre-existing library/lockfile drift (`codetools` version — fixed with `renv::restore(packages = "codetools")`, which doesn't touch `renv.lock`), and in library-resolution mode on **ISS-036** itself: `forestHelperR`'s `"Source": "unknown"` in `renv.lock` fails `rsconnect`'s internal `renv::snapshot()` pre-flight validation, which refuses any package with no resolvable source — not a soft warning, a hard abort. This is the first time ISS-036 was confirmed to block something beyond the R 4.5.2 migration.
- Fixed by placing `forestHelperR_0.2.0.tar.gz` (found at `~/Downloads/`, matching the version already recorded in `renv.lock`) in `renv/cellar/` and reinstalling it via `renv::install()` from that path — this gives the **installed package** a resolvable `"Cellar"` source without editing `renv.lock` (`CLAUDE.md` reserves lockfile edits for the R 4.5.2 migration, DEC-006). `renv/.gitignore` excludes `cellar/` by default; added a targeted un-ignore there (a negation in the root `.gitignore` alone can't reach into a directory a closer, more specific `.gitignore` already excludes — the un-ignore has to live in `renv/.gitignore` itself).
- Diffed the generated `manifest.json`'s package list against `renv.lock` in full (not just spot-checked): found `svglite`, `systemfonts`, and `textshaping` (needed by `ggplot2::ggsave(device = "svg")`, the SVG export handler) missing — the same root cause as **ISS-035** (nothing calls them via `::` directly, so dependency scanning can't see them). Patched all three into `manifest.json` from their already-correct `renv.lock` entries. Final manifest: 138/138 packages match `renv.lock` exactly, no gaps either direction, no spurious extras.

**`renv.lock` itself is intentionally untouched — ISS-036 is only partially resolved.** If Connect Cloud's GitHub-integrated deploy does its own server-side `renv::restore()` against the committed lockfile rather than trusting the committed `manifest.json`, it may hit the identical "unknown source" failure independently; that would be the next thing to fix if so, and would need the same kind of explicit convention-override authorization DEC-006 gave the R 4.5.2 migration.

---

### CHG-038 — DEC-005 Step 7: status-chip strip, rail badges, Help nav panel (FEAT-010)

| Field | Detail |
|---|---|
| **Date** | 2026-09-04 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-005, FEAT-010 |

**Files changed:** `ui.R`, `R/ui_rail.R`, `server/drawers.R`, `www/style.css`, `CLAUDE.md`,
`restyle-implementation-plan.md`, `issues-register.md`

**Files added:** `R/ui_help.R`

**Summary:**

Implements the three items the DEC-005 restyle plan deliberately deferred as optional
phase 2 (§8 Step 7 / FEAT-010), now that the core restyle (Steps 0-6) has been settled
for several weeks. All additive — no existing input ID, reactive, or the drawer
open/close mechanism changed.

**1. Status-chip strip.** `output$status_chips` (new, `server/drawers.R`) renders a
read-only chip row above `navset_card_tab`, filling the placeholder left empty since
Step 1: Dataset (simulated/upload), Regression type, a Variables/predictor count, and
Font. Clicking a chip sets a new `input$chip_open_key`, handled by a new observer that
always opens the matching drawer — deliberately *not* the rail buttons' toggle
semantics, since a chip is a shortcut to a setting rather than an open/close control for
a drawer the user probably hasn't touched yet.

**2. Rail badges.** `rail_button()` (`R/ui_rail.R`) gained an optional `badge` slot —
`uiOutput("rail_badge_<key>", container = tags$span)` nested inside the button, so the
server-rendered badge doesn't add its own wrapping `<div>` and break the button's flex
layout. Wired for two items:
- **Variables** — a count badge (`.rail-badge`) showing how many variables from the
  current `reg_table()` are unselected in `input$variables_displayed`. Uses `req()`,
  consistent with the existing `req(reg_table())` pattern in `server/observers.R`.
- **Display** — a dot badge (`.rail-badge.dot`, new CSS variant) shown when any of a
  fixed set of display inputs (`plotting_width`, `ci_colour`, `reference_colour`,
  `transparent_table_bg`, `transparent_plot_bg`, `gaps`, `indent`, `sigfigs`, `digits`,
  `right_justify`) differs from its `R/ui_plot_options.R` default.

Both `renderUI`s return `NULL` in the common case (nothing hidden / all defaults), so an
unbadged rail item looks identical to before this change.

**3. Help nav panel.** New `R/ui_help.R` — `helpPanelUI()`, a second `page_navbar` nav
item alongside *Builder*. Static content only (no reactive inputs, no server-side
rendering): one section per rail item plus a short workflow note, built with
`bslib::card()`/`card_header()`/`card_body()` to reuse the `.card`/`.card-header` CSS
rules already kept from the MDT port, rather than the MDT `.htu-*` How-to-Use classes,
which the restyle plan explicitly dropped (plan §7 — "not applicable" to a single-page
app).

**CSS changes:** `.rail-badge.dot` variant added; `.filter-chips` gained
`margin-bottom: 16px` (previously unused, no layout context); `.filter-chip` gained
`font-family: inherit` (the chips are `<button>`s, not the `<a>`s the rule was
originally written for — without it they'd render in the browser's default UI font).
Both `.filter-chips`/`.filter-chip` and `.rail-badge` blocks already existed,
pre-ported and unused, since Steps 1/6 — this change is what wires them up. No other
rule touched.

**Testing:** `parse()` clean on all changed/added R files. Full suite run under R 4.3.3:
48/48 unit assertions (`test-helpers.R`), 9/9 integration assertions with
`NOT_CRAN=true` (`test-shiny-app.R`) — both unchanged from the pre-change baseline,
confirming the change is additive as intended.

**FEAT-010 status:** → **Implemented**

**Docs:** `CLAUDE.md` §Current phase and §Key files updated (DEC-005 now complete
including phase 2; `R/ui_help.R` added to the file map; FEAT-010 dropped from the open
issues list). `restyle-implementation-plan.md` §8 Step 7 marked done. `issues-register.md`
FEAT-010 entry and summary table row marked Implemented.

---

### CHG-037 — Test-count reconciliation, session-handoff refresh, failed R 4.5.2 migration attempt

| Field | Detail |
|---|---|
| **Date** | 2026-09-03 / 2026-09-04 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented (documentation); **migration attempt failed — not implemented** |
| **Refs** | DEC-006, ISS-036, ISS-037 |

**Files changed:** `CLAUDE.md`, `session-handoff.md`, `issues-register.md`, `app-changelog-decision-register.md`

**Files added:** none · **Files removed:** none · **Application source changed:** none

**Summary:**

Three tidy-up tasks ahead of further development. Two landed; the third failed and is
recorded here as a failed attempt rather than a change.

---

**1. Test counts reconciled — and a real defect found (ISS-037).**

`CLAUDE.md` claimed "48 unit tests" and "7 shinytest2 integration tests"; the files contain
23 and 6 `test_that` blocks; CHG-033/034 cited "9/9 integration assertions". Three different
figures for two files. Resolved by running the suite rather than reasoning about it:

| File | Blocks | Assertions | Result |
|---|---|---|---|
| `test-helpers.R` | 23 | 48 | all pass |
| `test-shiny-app.R` | 6 | 9 | all pass |

So "48" was assertions (correct), the register's "9/9" was correct, and "7 integration
tests" was simply wrong. `CLAUDE.md` now states both blocks and assertions explicitly.

Establishing that baseline surfaced **ISS-037**: run via the command `CLAUDE.md` documented,
**all 6 integration blocks skip**. `shinytest2`'s `AppDriver$new()` calls `skip_on_cran()`,
and `NOT_CRAN` is set automatically only by `devtools::test()` and the RStudio runner — not
by a bare `Rscript`. The run prints `SSSSSS` and **exits 0**, so it reads as a pass. The
documented command had therefore been verifying nothing. Both `CLAUDE.md` and
`session-handoff.md` now document `NOT_CRAN=true` with an explicit warning about the
misleading exit code.

---

**2. `session-handoff.md` refreshed.**

The file was dated May 2026 and described the project as mid code-review: `ui.R` "unchanged,
no fixes applied yet", the register at v0.5, and §3-§6 giving step-by-step instructions for
Batches 1-3 (ISS-013 … ISS-026) — all resolved in CHG-007/008/009. §5 assumed a pre-git
workflow of uploading files to a chat session. Four development phases had happened since.

Rewritten (335 lines → ~150): current state of play, the open queue in priority order, the
migration brief for the next session, how to run the tests correctly, and the drawer
`suspendWhenHidden` trap. This is the second stale-document failure found in two sessions —
the restyle plan was the first (CHG-036) — so the refreshed file carries an explicit note to
update it alongside `CLAUDE.md` when a phase completes.

---

**3. R 4.5.2 migration — attempted, failed, not implemented.**

Decided per DEC-006 (snapshot authorised) with Rtools45 installed first so source builds
would succeed. Both preconditions were met; the restore still failed.

`renv::restore()` under R 4.5.2 aborted:

> Error: failed to install "DT", "broom", "colourpicker", "forestHelperR", "forestploter",
> "ggplot2", "gridExtra", "stringi", "stringr", "svglite", "textshaping", "tidyr"

`renv/library/windows/R-4.5/` was left containing nothing but renv itself. Two causes:

- **Structural (ISS-036, raised):** `renv.lock` records `forestHelperR` with
  `"Source": "unknown"`. renv cannot fetch it on any R version, so no `restore()` can fully
  succeed — this would have defeated the attempt independently of the R upgrade, and means
  the lockfile does not presently describe a reproducible environment.
- **Build cascade:** `stringi` compiles from source (building the whole ICU library) and
  most of the other failures depend on it directly or through `stringr`;
  `textshaping`/`svglite` are the other compiled group. The toolchain was *not* the blocker
  — the build log references `c:/rtools45/` correctly.

**Not diagnosed, and why:** the restore was run with its output piped through `tail`, so the
per-package diagnostics were discarded and only the summary survived. The specific `stringi`
failure is therefore unknown. A retry must capture the full log.

**`renv::snapshot()` was deliberately not run.** Per DEC-006's first condition, snapshotting
an environment that fails to build would record a broken lockfile — worse than the stale one.
`renv.lock` is unmodified; `git status` confirms.

**State after the attempt — nothing broken:**

| Check | Result |
|---|---|
| `renv.lock` | Unmodified |
| R 4.3.3 environment | Intact — `shiny`, `forestHelperR`, `shinytest2` all load |
| `renv/library/windows/R-4.5/` | Empty apart from renv |
| Application source | Untouched |

**One durable environment change:** installing Rtools45 via winget **removed Rtools43** — it
upgraded the existing package rather than installing alongside, so `C:\rtools43` no longer
exists. The R-4.3 library is already built so the app still runs under 4.3.x, but compiling
source packages there now requires reinstalling Rtools43 from CRAN. This was an unanticipated
consequence of the install, not an intended part of the change.

**Next:** a manual migration is planned for 2026-09-04. `session-handoff.md` §3 carries the
brief — fix ISS-036 first, capture the full install log, and verify against the 48/9 baseline
before snapshotting.

---

### CHG-036 — Track the restyle plan and readiness review; register DEC-005 Step 7 as FEAT-010

| Field | Detail |
|---|---|
| **Date** | 2026-09-03 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-005, FEAT-010 |

**Files added (now tracked):** `restyle-implementation-plan.md`, `reviews/README.md`, `reviews/architecture/2026-06-10_restyle-readiness-review.md`
**Files changed:** `restyle-implementation-plan.md`, `issues-register.md`, `CLAUDE.md`

**Summary:**

Documentation-only. No application source, test, or `renv.lock` change.

**The design documents were never committed.** `restyle-implementation-plan.md` and the
whole `reviews/` directory had sat untracked since 2026-06-10, despite DEC-005 citing the
plan twice and naming
`reviews/architecture/2026-06-10_restyle-readiness-review.md` as its companion review —
both references dangled for anyone cloning the repository. The plan is the design rationale
for the app's entire current layout (bottom rail, static drawers, the no-`renderUI`
decision), so losing it would mean losing the *why* behind DEC-005. Both are now tracked.

**The plan's status header was materially misleading.** It still read:

> **Status:** PLAN — nothing implemented. Becomes DEC-005 when accepted into
> `app-changelog-decision-register.md`.

That was true on 2026-06-10 and wrong from 2026-07-17 onward, by which point Steps 0-6 had
shipped. Anyone opening the file — including a fresh Claude Code session — would reasonably
conclude the restyle was still to do. Header rewritten to record acceptance as DEC-005,
completion of Steps 0-6, and the outstanding Step 7, with an explicit note that the document
is retained as design rationale rather than a to-do list.

**§8 migration table annotated.** A Status column maps each planned step to the change that
delivered it — Step 0 → CHG-023/024, Steps 1-6 → CHG-029 through CHG-034, Step 7 → not
started. The plan-to-commit correspondence is now readable from the plan itself instead of
having to be reconstructed from the register.

**FEAT-010 raised.** DEC-005 Step 7 (status-chip strip, rail badges, Help nav panel) existed
only in DEC-005's prose and the plan's own step table, so it appeared in no open-items list
and was effectively invisible — which is how it came to be mistaken for unstarted work more
broadly. Registered as FEAT-010 (Low, Open) with the three sub-items described, and added to
the open-issues list in `CLAUDE.md`. The CSS hooks for two of the three (`chip-strip`, the
`.rail-item` badge slot) were already ported in Steps 1/6, so the work needs no further
stylesheet pass.

**Note on scope:** the plan is now a historical record. Step 7 is tracked in
`issues-register.md`, which is where future work on it should be managed — the plan should
not be edited to add new scope.

---

### CHG-035 — Claude Code settings repair, R formatting hook, stale worktree cleanup

| Field | Detail |
|---|---|
| **Date** | 2026-09-03 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | — (tooling only; no app source changed) |

**Files added:** `.claude/hooks/style-r.R` (untracked as of this entry)
**Files removed:** `.claude/worktrees/dec004-finish/` (orphaned worktree checkout)
**Files changed:** `.claude/settings.json`, `.claude/settings.local.json` (git-ignored), `CLAUDE.md`

**Summary:**

Housekeeping session. No application source, test, or `renv.lock` change — `global.R`,
`ui.R`, `server.R`, `server/`, `R/`, and `www/` are untouched.

**`.claude/settings.json` was invalid JSON and therefore entirely inert.** The file used
`//` comments, which JSON does not permit, so every permission rule, the hook, and the
status line in it had been silently inactive for as long as the comments have been there.
Comments stripped. Alongside that repair:

- `statusLine` removed — it pointed at `~/.claude/statusline.sh`, which does not exist on
  this machine (and is a `.sh` script on Windows).
- `PostToolUse` prettier hook removed — it referenced `$FILE_PATH`, which is not a hook
  variable (hooks receive their payload as JSON on stdin), there is no `package.json` in
  this project, and prettier has no R parser.
- `Edit(src/**)` / `Write(src/**)` dropped — there is no `src/` directory; R code lives in
  `R/`, `server/`, and the root `.R` files.
- `Write(*.R)` widened to `Write(**/*.R)` — the gitignore-style pattern matched only
  root-level files, missing `R/helpers.R`, `server/plot.R`, and the rest of the split.
- `Bash(rm *)` → `Bash(rm:*)` and `Bash(git push *)` → `Bash(git push:*)` — the space-glob
  form does not prefix-match, so both deny rules were ineffective even once the file
  parsed. Same normalisation applied to the allow rules in `settings.local.json`.

**R formatting hook — built, evaluated, deliberately left disabled.** `.claude/hooks/style-r.R`
reads the hook payload from stdin, filters to `.R` files, and calls `styler::style_file()`;
it exits 0 on every path so a formatting failure can never block an edit. `styler` 1.11.0
was installed into the user library (`win-library/4.5`), not into `renv` — it is a dev tool,
not a project dependency, and adding it would mean touching `renv.lock`. The hook runs
`Rscript --vanilla` so it bypasses `.Rprofile` and never activates the project's renv
environment.

It is **not wired into any settings file**, on evidence rather than preference. Trialled
against `R/helpers.R`:

| Scope | Result |
|---|---|
| default | 33 insertions / 14 deletions — expands every brace-less `if/else` into a full braced chain |
| `"spaces"` | 4 / 4 — keeps the braces but strips the aligned-column padding |
| `I("indention")` | **file unchanged** |

Five helpers would have been reformatted at default scope (`is_col_included`,
`get_est_type`, `get_font_expansion`, `serialise_x_ticks`, `serialise_chr_vec`) — each a
compact aligned dispatch table turned into a tall braced block. Since the file is already
clean under `I("indention")`, styler's only disagreements with this codebase are ones where
the existing style is the more readable. The script is kept on disk should that judgement
change; enabling it means adding a `PostToolUse` block to `settings.local.json` (it must be
the *local* file — the command needs an absolute path to `Rscript.exe`, which is not on
PATH on this machine).

**Stale worktree removed.** `.claude/worktrees/dec004-finish/` — a 145-file, 5.8 MB orphaned
checkout from the DEC-004 phase — was left behind with its `.git/worktrees/dec004-finish/`
metadata directory emptied, so `git worktree list` no longer knew about it while
`git fetch` failed on every invocation trying to prune it:
`error: failed to delete '.git/worktrees/dec004-finish': Permission denied` (a OneDrive
file lock). Before deleting, all 49 non-generated files were hashed with `git hash-object`
and each blob confirmed present in the repository's object database — nothing in the
checkout was unique. Directory and metadata removed; `git fetch` now exits 0 silently. The
leftover `worktree-dec004-finish` branch, which pointed at the same commit as `main`, was
deleted with `git branch -d` (which accepted it, confirming no unmerged work).

**`CLAUDE.md` brought up to date.** Its "Current phase" section still described DEC-004 as
in progress at Step 5 with Steps 6-7 outstanding, while `main` had been at DEC-005 Step 6
(CHG-034) since 2026-07-17. Rewritten to describe DEC-005, its step status, and both
architecture decisions in force. "Key files" expanded to list the actual `server/` and `R/`
contents rather than the pre-split `server.R`-holds-everything description, and the
resolved ISS-031 / FEAT-009 were dropped from the open-issues list, leaving ISS-028/029/030
to match `issues-register.md`.

**Verification:** both settings files parse as valid JSON. Hook script tested against three
payloads (R file, `.md` file, malformed JSON) — all exit 0. `git fetch` clean. `main` level
with `origin/main` at `891d3cd`, no unpushed commits. No test run — no application code was
touched.

**Known-stale, not addressed:** the `renv` library is built for R 4.3.x
(`renv/library/R-4.3/`), so running under the R 4.5.2 installation reports every lockfile
package as missing. Pre-existing and unrelated to this session; resolving it means either
staying on R 4.3.x or a full `renv::restore()` under 4.5.2.

---

### CHG-034 — DEC-005 Step 6: CSS merge/polish, dead-code prune, viewport smoke test

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-005 |

**Files added:** none  
**Files removed:** `www/styles.css`  
**Files changed:** `www/style.css`, `ui.R`

**Summary:**

Final polish step of the DEC-005 restyle. `www/styles.css` (the pre-restyle `sortable::bucket_list`/`noUiSlider` tweaks) merged into `www/style.css` and deleted — the app now serves one stylesheet instead of two. Colours recoloured to the CAQ palette: `#2c3e50` → `#426175` in the `noUi-tooltip`/`noUi-connect` rules (the `noUi-handle` grey `#dedede` and sizing rules are unchanged, not palette-driven).

**Dead-code audit:** the `.accordion-button` rules ported from MDT in Step 1 are removed — `bslib::accordion()` was retired from the codebase in Step 3 (confirmed via `grep`, no `accordion` calls remain anywhere in `R/`), so these rules were pure dead weight.

`ui.R`'s stylesheet link cache-buster bumped `?v=dec005-1` → `?v=dec005-2` to reflect this round of CSS changes (per review finding F-4, addressed in Step 1 and maintained here).

**Test results:** 48 unit tests, 9/9 integration assertions passing. Smoke test verified: the old stylesheet link is gone and the new one loads with the bumped cache-buster; the `noUi-connect` slider fill renders at the recoloured `#426175` (not the old `#2c3e50`); no horizontal overflow at either 1366×768 or 2560×1440; the bottom rail stays flush with the viewport edge at 1366×768; and the `.drawer-columns` responsive grid correctly expands to more columns at the wide viewport.

**DEC-005 status:** Steps 1–6 (the plan's core migration) are now complete. Step 7 (status chips, rail badges, Help nav) is explicitly phase-2/optional in the plan and has not been started — "ship the core first," per the plan's own framing.

---

### CHG-033 — DEC-005 Step 5: Order panel + Export redesign (FEAT-009, ISS-031)

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-005, FEAT-009, ISS-031 |

**Files changed:** `R/ui_plot_options.R`, `R/ui_drawers.R`, `ui.R`, `server/export.R`, `server/drawers.R`, `www/style.css`

**Summary:**

Fifth step of the DEC-005 restyle, and the one step the plan flagged as touching test fixtures. `orderPanelUI()` moves the `reorder` checkbox + `sortable_cols` rank list from the Plot tab into the Order drawer panel, unchanged. `exportPanelUI()` implements the FEAT-009 redesign: a colour-separated "Export graph" section (`export_format` radio — PNG/SVG — plus a single `download_plot` button) and an "Export code" section (unchanged `copy_r_code`/`download_r_code`). `download_png` and `download_svg` are retired.

`server/export.R`: the two separate `downloadHandler`s collapsed into one `output$download_plot`, branching on `input$export_format` for both the `ggplot2::ggsave()` device and the filename extension.

`ui.R`: the Plot tab's export-button `fluidRow` and reorder `fluidRow` removed — the Plot tab is now just the plot itself.

`www/style.css`: `.export-section`/`.export-section--graph`/`.export-section--code` added (4px left-border accent, `#426175` for graph / `#56958F` for code) for the colour-separated layout FEAT-009 asked for.

**Test fixtures:** checked `tests/` for any reference to `download_png`/`download_svg`/`export_format`/`download_plot` — none exists. The plan anticipated this step would be the one place fixtures needed updating; in practice no test touches the export buttons at all, so no fixture changes were needed.

**Bug found and fixed during verification, not just assumed away:** the same hidden-drawer-panel risk that hit `output$files`/`output$sortable_cols` in Steps 4 turned out to also affect **any** `downloadButton`, not just data/UI outputs. Confirmed directly: with the Export panel `display:none` by default, both the new `download_plot` and the untouched, pre-existing `download_r_code` rendered as `<a class="... disabled ...", href="">` — Shiny's suspend-when-hidden behaviour disables download links exactly like any other suspended output. Fixed by adding `outputOptions(output, "download_plot", suspendWhenHidden = FALSE)` and the same for `download_r_code` in `server/drawers.R`.

**Test results:** 48 unit tests, 9/9 integration assertions passing. Targeted shinytest2 smoke test verified: the old `download_png`/`download_svg` buttons are gone; the Order panel contains `reorder` and correctly shows `sortable_cols` when checked; the Export panel contains `export_format`, `download_plot`, `copy_r_code`, `download_r_code`; downloading with each format selected produces a file with the correct extension and non-zero size.

**Register updates:** ISS-031 marked resolved (this fix). FEAT-009 marked implemented, with its originally-proposed location (sidebar accordion) superseded by the Export drawer panel — the design itself (radio + single button; separate copy/download for code) is unchanged from the feature request.

---

### CHG-032 — DEC-005 Step 4: move sidebar into the Data drawer panel

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-005 |

**Files changed:** `R/ui_plot_options.R`, `R/ui_drawers.R`, `ui.R`, `server/drawers.R`

**Summary:**

Fourth step of the DEC-005 restyle. `dataPanelUI()` added to `R/ui_plot_options.R`, moving the entire former `page_navbar(sidebar = ...)` content verbatim: `dataset_selected`, the `by_group` switch + `upload` fileInput + `files` DT (conditional on upload mode), `regression_type`, `group_var_name`/`group_var_values` (conditional on upload + by_group), `response_var`/`predictor_vars` (conditional on sim), and `robust_variance` (conditional on poisson). No input IDs or defaults changed. `sidebar = sidebar(...)` removed from `ui.R`'s `page_navbar()` call entirely — the app no longer has any sidebar-style layout.

`R/ui_drawers.R`'s Data panel placeholder now calls `dataPanelUI()`.

`server/drawers.R` gains `outputOptions(output, "files", suspendWhenHidden = FALSE)` — `output$files` now lives inside the Data drawer panel, which is `display:none` until first opened, and this is one of the two hidden-output cases the plan's §3/§9 flagged needing an explicit suspend override (the other, `sortable_cols`, is Step 5's concern).

**Test results:** 48 unit tests, 9/9 integration assertions passing — critically, the existing upload/confirm shinytest2 scenarios (which exercise `input$upload`, `input$cols`, `input$by_group`, `input$regression_type` — all now living in the Data drawer panel) pass **unmodified**, confirming Shiny inputs work correctly regardless of their container's visibility, exactly as the plan's §3 assumption predicted. An additional targeted smoke test confirmed: no sidebar layout remains; opening the Data panel shows `dataset_selected` and `upload`; the `files` DT renders correctly after upload (verifying the `suspendWhenHidden` fix); and the full upload → confirm → `dat_upload` preview flow works end-to-end from within the new panel location.

---

### CHG-031 — DEC-005 Step 3: move Variables/Display/Text into drawer panels

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-005 |

**Files changed:** `R/ui_plot_options.R`, `R/ui_drawers.R`, `ui.R`, `www/style.css`

**Summary:**

Third and largest step of the DEC-005 restyle. `R/ui_plot_options.R`'s single `plotOptionsUI()` (an `bslib::accordion()` with three panels) retired in favour of three functions — `variablesPanelUI()`, `displayPanelUI()`, `textPanelUI()` — each returning a `.drawer-header` title plus a `.drawer-columns` responsive grid. Every input is unchanged (same ID, same default, same `conditionalPanel` gating); `strong()` + `materialSwitch()` label pairs are wrapped in a new `.drawer-field` flex class (added to `www/style.css`) per the plan's §9 risk note, so they don't look ragged as a grid cell narrower than the old single-column accordion. File kept as `R/ui_plot_options.R` rather than renamed — the content changed but the file's role (plot-option UI definitions) didn't.

`R/ui_drawers.R`: the Variables/Display/Text placeholder panels from Step 2 now call the three new panel functions. Data/Order/Export remain placeholders (Steps 4–5).

`ui.R`: the `layout_columns(col_widths = c(9, 3), navset_card_tab(...), plotOptionsUI())` wrapper removed — `navset_card_tab()` now sits directly in `content-area` at full width, since there's no second column left.

**Risk verified, not just assumed:** the plan's §9 flags that `shinyWidgets::noUiSliderInput` (`xlims`, `xticks`) initialised inside a `display:none` container can render with zero width. Checked directly: both sliders render at ~288px width (not zero) after first opening the Display panel, confirming the `resize` event dispatch added to `www/drawer.js` in Step 1 correctly mitigates this.

**Test results:** 48 unit tests, 9/9 integration assertions passing. Targeted shinytest2 smoke test verified: no `bslib::accordion` remains in the DOM; the forest plot renders before any drawer is opened; `plotting_width` still defaults to 120; `xlims`/`xticks` sliders have non-zero rendered width; the plot re-renders after changing an input from the Display panel (`base_size`) and from the Text panel (`plot_title`); the `n_display` `conditionalPanel` correctly hides when `"n"` is deselected from `elements` in the Variables panel.

---

### CHG-030 — DEC-005 Step 2: rail + drawer shell, empty panels

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-005 |

**Files added:** `R/ui_rail.R`, `R/ui_drawers.R`, `server/drawers.R`  
**Files changed:** `ui.R`, `server.R`

**Summary:**

Second step of the DEC-005 restyle. `railUI()` in `R/ui_rail.R` renders the six bottom-rail buttons (Data, Variables, Display, Text, Order, spacer, Export) — plain `tags$button()` elements, no `NS()`/`moduleServer()`, each setting `input$rail_key` via `Shiny.setInvalue(...)` on click exactly as the plan specifies. Icons use `shiny::icon()` (Font Awesome) rather than the plan's suggested `bsicons` package, which is not installed — avoids adding a new dependency for a cosmetic choice; icon names map 1:1 to the plan's `bsicons` suggestions (`database`, `list-check`, `sliders`, `font`, `arrows-left-right`, `download`).

`drawerUI()` in `R/ui_drawers.R` renders the scrim + a single drawer containing six statically-rendered `.drawer-panel` divs (one per rail key), each currently just a placeholder header — panel content moves in during Steps 3–5.

`server/drawers.R`: `rv_drawer` reactiveVal holds the currently-open key (`NULL` = closed). `input$rail_key` observer implements toggle semantics (clicking the open key closes it). `input$drawer_close` (scrim click) always closes. A third observer pushes `session$sendCustomMessage("drawer-open", list(drawerId, scrimId, open, key))` on every `rv_drawer()` change — `www/drawer.js` (added in Step 1) picks this up to toggle the `open`/`active` CSS classes.

`ui.R`: `drawerUI()` and `railUI()` added as siblings of `content-area` inside `dashboard-body`. `server.R`: `source(here::here("server", "drawers.R"), local = TRUE)` added as the seventh source call.

**Test results:** 48 unit tests, 9/9 integration assertions passing. Targeted shinytest2 smoke test verified: rail renders with all 6 items; drawer starts closed; clicking a rail item opens the drawer with the matching panel and rail item marked active; clicking the same item again closes it (toggle); clicking a different item switches the active panel; clicking the scrim closes the drawer.

---

### CHG-029 — DEC-005 Step 1: stylesheet, theme swap, `page_navbar` shell

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-005 |

**Files added:** `www/style.css`, `www/drawer.js`  
**Files changed:** `global.R`, `ui.R`

**Summary:**

First step of the DEC-005 restyle. `www/style.css` ported from `mdt-activity-dashboard/themed-template/www/style.css` per the plan's keep/drop/adapt rules: kept the navbar/card/accordion/drawer-internals rules verbatim; dropped MDT-specific blocks not applicable here (`.cancer-tree`, `.htu-*`, `.kpi-*`, `.proj-select`, `.dfl-*`, per-page accent variants, year-style toggle); replaced `.dashboard-body`/`.content-area`/`.filter-rail`/`.rail-item`/`.drawer-scrim`/`.filter-drawer`/`.filter-drawer-inner` with the bottom-rail adaptations from the plan's §7, and added `.drawer-panel`/`.drawer-columns` for the static-panel approach. `www/drawer.js` ported with the two additional lines (active-panel toggle, resize dispatch) the plan's static-drawer approach requires.

`global.R` gains a `theme` object — explicit CAQ `bs_theme()` (bg/fg/primary/secondary/success/warning/danger) replacing the previous `bootswatch = "flatly"` inline in `ui.R`.

`ui.R` restructured: `page_sidebar()` → `bslib::page_navbar()` with the existing `sidebar()` content moved into the `sidebar` argument unchanged, and the existing `layout_columns()` (navset_card_tab + `plotOptionsUI()`) wrapped in `div.dashboard-body > div.content-area`, inside a single `nav_panel("Builder", ...)`. Stylesheet link gains a `?v=` cache-buster (resolves review finding F-4). The old `www/styles.css` (sortable/noUiSlider tweaks) is kept as a separate link for now — merging it into `style.css` and recolouring is deferred to the final polish step (§8 step 6), per the plan.

No input/output IDs changed; the rail and drawer markup do not exist yet (Step 2) so the new CSS classes are currently inert — the app is functionally identical, just reskinned and under a navbar.

**Test results:** 48 unit tests, 9/9 integration assertions passing. Visual check: app launches, navbar renders with "Forest Plot Builder" title and CAQ colours, sidebar and plot-options column present and functional, forest plot still renders in both upload and simulated-data modes.

---

### CHG-028 — ISS-035: install `svglite` and dependencies, pin in `renv.lock`

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-035 |

**Files changed:** `renv.lock`

**Summary:**

Installed `svglite` (2.2.2) and its dependencies `systemfonts` (1.3.2) and `textshaping` (1.0.5) into the project library, plus `codetools` (missing, required by `globals`, blocking a general snapshot). Two broader approaches were tried and rejected before landing on the minimal fix:

1. `renv::snapshot(packages = c("svglite", ...))` — the `packages` filter restricts the *entire* implicit-type dependency scan to just the named packages rather than adding to the existing set, and since renv's implicit scan only detects packages referenced via `library()`/`::` in code (nothing calls `svglite::` directly — it's invoked indirectly via `ggplot2::ggsave(device = "svg")`), this collapsed the lockfile from 135 packages down to 11. Reverted immediately via `git checkout`, no commit made.
2. A full unscoped `renv::snapshot(force = TRUE)` (needed `force` to bypass a pre-existing, already-accepted "unknown source" warning for `forestHelperR`) succeeded but rewrote the top-level CRAN mirror URL (`packagemanager.posit.co` → `cloud.r-project.org`, picked up from the R session's default repo option rather than the lockfile's configured mirror) and ~40 unrelated packages' `Repository` field, and bumped `codetools` to a newer patch version — all incidental noise unrelated to this fix. Reverted, no commit made.
3. `renv::record(list(svglite = "svglite@2.2.2", systemfonts = "systemfonts@1.3.2", textshaping = "textshaping@1.0.5"))` — updates only the named package records directly, no re-scan of the rest of the lockfile. Produced a clean 15-line diff: three new entries in correct alphabetical position, nothing else touched. `"Repository": "CRAN"` added by hand to each new entry afterward for consistency with existing `Source: "Repository"` entries.

**Verified:** `renv.lock` parses as valid JSON (138 packages, up from 135). shinytest2 smoke test confirms `output$download_svg` now produces a real SVG file instead of erroring at runtime.

**Test results:** 48 unit tests, 9/9 integration assertions passing.

---

### CHG-027 — DEC-004 Step 7: extract misc observers to `server/observers.R`

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-004 |

**Files added:** `server/observers.R`  
**Files changed:** `server.R`

**Summary:**

Final step of the DEC-004 file split. The four remaining misc observers — `variables_displayed` update, `sortable_cols` renderUI, `by_group` auto-set on multi-file upload, and the `sigfigs` label toggle — moved from `server.R` into `server/observers.R`. `server.R` is now the thin six-source wrapper the plan targeted from the start.

Committed together with CHG-026 (Step 6, `server/export.R`) in the same session.

**Test results:** 48 unit tests, 9/9 integration assertions passing (two known environment flakes — a chromote startup timeout and a transient renv-library file lock — were reproduced and confirmed unrelated to this change before this commit). A targeted smoke test additionally exercised the moved `copy_r_code` / `download_r_code` path directly.

---

### CHG-026 — DEC-004 Step 6: extract export handlers to `server/export.R`

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-004 |

**Files added:** `server/export.R`  
**Files changed:** `server.R`

**Summary:**

Sixth step of the DEC-004 file split. `output$download_png`, `output$download_svg`, `r_code_string()`, the `copy_r_code` observer, and `output$download_r_code` extracted from `server.R` into `server/export.R`.

**Test results:** 48 unit tests, 9/9 integration assertions passing (see CHG-027 note on flakes).

---

### CHG-025 — ISS-034: qualify `ggsave()`, `glm()`, `as.formula()`, `poisson()`/`binomial()`

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-034 |

**Files changed:** `server.R`, `server/regression.R`

**Summary:**

`ggsave()` → `ggplot2::ggsave()` in both download handlers in `server.R`. `glm()` → `stats::glm()`, `as.formula()` → `stats::as.formula()`, and the family constructors `"poisson"(...)`/`"binomial"(...)` → `stats::poisson()`/`stats::binomial()` in `server/regression.R`. Brings these calls in line with the explicit `package::function()` convention (CLAUDE.md). No new `library()` call needed — `::` only requires the package be installed, not attached, and `ggplot2` is already an implicit dependency via `forestploter`/`forestHelperR`.

**Finding raised, not fixed here:** while verifying the SVG export path, confirmed `svglite` is **not** actually installed in `renv/library` despite appearing as a transitive dependency elsewhere in `renv.lock`. `ggplot2::ggsave(device = "svg")` will error at runtime when a user clicks "Download svg". Fixing this requires a `renv.lock` change, which CLAUDE.md forbids without explicit sign-off — raised as **ISS-035** instead.

**Test results:** 48 unit tests pass; shinytest2 suite passes 9/9 on rerun (one run showed a chromote startup flake on this same suite, reproduced as pre-existing and unrelated).

---

### CHG-024 — ISS-033: `output$forest` registered outside `observe()`, function-valued dims

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-033 |

**Files changed:** `server/plot.R`

**Summary:**

`output$forest` was assigned inside an `observe()` block solely so `width`/`height` could read the reactive `dims()` — re-registering the render function on every invalidation, a known Shiny anti-pattern. `renderPlot()` accepts function-valued `width`/`height` directly (`function() dims()[1]*72*1.5`), which is the supported idiom. The outer `req(forest_plot_object())` guard was removed — `forest_plot_object()`'s own internal `req()` already suspends rendering cleanly when its inputs aren't ready.

**Test results:** 48 unit tests pass. Verified via automated shinytest2 smoke test that the forest plot still renders correctly in simulated-data mode after the change.

---

### CHG-023 — ISS-032: untrack `Rplots.pdf` build artifact

| Field | Detail |
|---|---|
| **Date** | 2026-07-17 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-032 |

**Files changed:** `.gitignore`  
**Files removed from tracking:** `Rplots.pdf`

**Summary:**

`Rplots.pdf` is headless plot-device output regenerated on every local R session and was churning on every commit with no useful history value. `git rm --cached` run; `Rplots.pdf` added to `.gitignore`.

---

### CHG-022 — DEC-004 Step 5: extract plot generation to `server/plot.R`

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 (committed 2026-07-17) |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-004 |

**Files added:** `server/plot.R`  
**Files changed:** `server.R`

**Summary:**

Fifth step of the DEC-004 file split. `est_type()`, `variables_excluded()`, `forest_plot_object()`, `dims()`, and `observe({output$forest})` extracted from the step 4 block, plus three plot-coupled observers relocated from the Misc section: `order()` (§f — feeds `forest_plot_object()` and `r_code_string()`), the `concatenate_est_ci` guard (§e), and the `concatenate_est_sig` guard (§g). These are co-located in `plot.R` because they are all tightly coupled to plot state.

`server.R` Misc section retains only the four observers with no plot-specific coupling: `variables_displayed` update, `sortable_cols` renderUI, `by_group` auto-set, and the `sigfigs` label toggle — these will move to `observers.R` in the final step.

**Note (2026-07-17):** the code for this step had been sitting uncommitted since 2026-05-11 pending a smoke test. The smoke test (simulated-data forest plot renders, `concatenate_est_ci` resets on element deselect, reorder checkbox reveals rank-list) was completed via an automated shinytest2 script this session, and the commit was made. See CHG-023 through CHG-027 for the remainder of this session's work, which finishes DEC-004.

**Test results:** 48 unit tests, 9 integration assertions — 0 failures, 0 warnings.

---

### CHG-021 — DEC-004 Step 4: extract preview outputs to `server/preview.R`

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-004 |

**Files added:** `server/preview.R`  
**Files changed:** `server.R`

**Summary:**

Fourth step of the DEC-004 file split. All four Review Data tab outputs — `output$dat_upload`, `output$dat_summary`, `output$regression_details`, and `output$robust` — extracted from `server.R` into `server/preview.R`. These are display-only outputs with no reactive values returned; they consume `data_updated()`, `reg_table()`, and `fit()` defined in the earlier sourced files.

**Test results:** 48 unit tests, 9 integration assertions — 0 failures, 0 warnings.

---

### CHG-020 — DEC-004 Step 3: extract regression fitting to `server/regression.R`

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-004 |

**Files added:** `server/regression.R`  
**Files changed:** `server.R`

**Summary:**

Third step of the DEC-004 file split. `fit()`, `predictors_selected()`, and `reg_table()` extracted from `server.R` into `server/regression.R`. `reg_table()` serves both data paths: the sim path calls `forestHelperR::regTabler()`; the upload path passes `data_updated()` through as a data frame. Both paths use `req()` for suspension, consistent with project convention.

`server.R` source block grows to two calls; both upload and regression logic are now in named files.

**Test results:** 48 unit tests, 9 integration assertions — 0 failures, 0 warnings.

---

### CHG-019 — DEC-004 Step 2: extract data upload pipeline to `server/upload.R`

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-004 |

**Files added:** `server/upload.R`  
**Files changed:** `server.R`

**Summary:**

Second step of the DEC-004 file split. Steps 1 and 2a — `data_uploaded()`, `output$files`, `output$sortable`, the `cols_confirmed` reactiveVal and its two observers, and `data_updated()` — extracted from `server.R` into `server/upload.R`.

`server.R` replaces ~248 lines with a single `source(here::here("server", "upload.R"), local = TRUE)` call. `local = TRUE` evaluates the sourced code in the server function's environment, giving it access to `input`, `output`, and `session` and placing all defined reactives (`data_uploaded`, `data_updated`, `cols_confirmed`) in that environment for use by downstream code.

The ISS-020 column confirmation gate (`cols_confirmed` reactiveVal, reset on upload, incremented on confirm, `req(cols_confirmed() > 0)` guard in `data_updated()`) is preserved exactly.

**Test results:** 48 unit tests, 9 integration assertions — 0 failures, 0 warnings.

---

### CHG-018 — DEC-004 Step 1: extract plot options accordion to `R/ui_plot_options.R`

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | DEC-004, PDEC-001 |

**Files added:** `R/ui_plot_options.R`  
**Files changed:** `ui.R`

**Summary:**

First step of the DEC-004 file split. The right-hand accordion (`div(h4("Plot Options"), bslib::accordion(...))`) — three accordion panels, ~105 lines — extracted from `ui.R` into a `plotOptionsUI()` helper function in `R/ui_plot_options.R`. Shiny auto-sources all `R/*.R` files at startup, so the function is available when `ui.R` assembles the layout.

`ui.R` call site reduced from ~105 lines to a single `plotOptionsUI()` call. The dead `#open = "closed"` comment (which referred to an accordion parameter that was never set) was not carried forward.

**No reactive changes.** UI helper functions return static tag structures — zero risk to the reactive graph.

**Test results:** 48 unit tests, 7 integration tests — 0 failures, 0 warnings.

---

### CHG-017 — ISS-009 / ISS-010: fix documentation placeholders in presentation repo

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-009, ISS-010 |

**Repo:** `DataScienceHangout-Shinytalk`  
**File changed:** `docs/forest-plot-builder.md`

| ISS | Change |
|---|---|
| ISS-009 | Removed stale `<!-- Replace with actual screenshot path -->` HTML comment. Screenshot file `assets/screenshot_forest.png` confirmed present; path `../assets/screenshot_forest.png` was already correct. |
| ISS-010 | Footer updated from `[Month] [Year]` to `May 2026`. |

**ISS-009 status:** → **Resolved**  
**ISS-010 status:** → **Resolved**

---

### CHG-016 — ISS-002 / PDEC-003: replace `extrafont` with `sysfonts`/`showtext`

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-002, DEC-003 |

**Files changed:** `global.R`

**Summary of changes to `global.R`:**

| Location | Before | After |
|---|---|---|
| Package block | `library(extrafont)` | `library(sysfonts)` + `library(showtext)` |
| Setup block | `font_import()` comment + `loadfonts(device = "all")` | `sysfonts::font_add("Lato", ...)` from bundled TTFs; `tryCatch(font_add_google(...))` loop for Google Fonts; `showtext::showtext_auto()` |
| Font filter | `fonts %in% names(grDevices::postscriptFonts())` | `fonts %in% sysfonts::font_families()` |

**Verified:** App starts cleanly. Font selector shows Lato, Open Sans, Roboto, Montserrat on a machine with internet access. `Source Sans Pro` absent (renamed on Google Fonts — ISS-030). OS system fonts absent (ISS-029).

**ISS-002 status:** → **Resolved**
**PDEC-003 status:** → **Closed as DEC-003**

---

### CHG-015 — ISS-004 Phase 2: shinytest2 integration tests

| Field | Detail |
|---|---|
| **Date** | 2026-05-11 |
| **Author** | Nathan Dunn / Claude (Anthropic) |
| **Status** | Implemented |
| **Refs** | ISS-004 |

**Files added:** `tests/testthat/setup-shinytest2.R`, `tests/testthat/test-shiny-app.R`, `tests/fixtures/group_a.csv`, `tests/fixtures/group_b.csv`  
**Files changed:** `renv.lock` (shinytest2, chromote, knitr, sortable and transitive dependencies pinned)

**Summary:**

Phase 2 of ISS-004 — `shinytest2` integration tests for reactive logic that cannot be covered by pure-function unit tests. Each test launches a headless Shiny app via `AppDriver` and drives the UI programmatically.

**Infrastructure:**

`tests/testthat/setup-shinytest2.R` created. `load_app_env()` intentionally omitted — `AppDriver` runs the app in a separate process and does not require the app environment sourced into the test session. `library(here)` loaded for path resolution only. Two CSV fixture files added to `tests/fixtures/` (same 8-column structure, different estimates) for use in upload and two-group tests.

**Dependency resolution:** `sortable` updated to 0.6.0 (dropped `xfun` dependency); `knitr` updated to 1.51 (removed `xfun::attr` import); `shinytest2` and `chromote` pinned in `renv.lock`.

**Tests written (`tests/testthat/test-shiny-app.R`):**

| Scenario | Test | What it verifies |
|---|---|---|
| (a) Column confirmation gate | `dat_upload` suspended before confirmation | `req(cols_confirmed() > 0)` holds before button click |
| (a) Column confirmation gate | `dat_upload` renders after confirmation | Gate releases on button click |
| (a) ISS-020 regression guard | `dat_upload` reverts to suspended after new upload | `cols_confirmed` resets to 0 on new file; old mapping cannot silently apply |
| (b) Two-file upload | `by_group` set to TRUE on two-file upload | `observe()` §d fires when `nrow(input$upload) > 1` |
| (b) Two-file upload | `dat_upload` non-suspended after two-file confirmation | Two-file data path processes cleanly end-to-end |
| (c) Estimate label | "RR" in table header for poisson | Reactive binding wired correctly |
| (c) Estimate label | "OR" / "HR" after switching regression type | `input$regression_type` → `dat_summary` header update |

**Helper added:** `is_suspended()` — detects both `NULL` and the `shiny.silent.error` / `validation` character vector that `shinytest2` returns when `req()` suspends an output.

**Test results:** 7 tests, 0 failures, 0 warnings.

**ISS-004 status:** → **Resolved**

---

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
| 2026-05-11 | ISS-004 Phase 2 — `shinytest2` integration tests (CHG-015) | 7 integration tests passing across 3 scenarios: column confirmation gate (incl. ISS-020 regression guard), two-file upload, and regression type → estimate label. `renv.lock` updated (sortable, knitr, shinytest2 pinned). ISS-004 fully resolved. ISS-013/014/015 register entries corrected to Resolved (were incorrectly showing Open). |
| 2026-05-11 | ISS-002 resolved — `extrafont` replaced with `sysfonts`/`showtext` (CHG-016, DEC-003) | Lato now registered at startup from bundled TTFs. Google Fonts load via `tryCatch()` — fail silently without internet. Verified: Lato, Open Sans, Roboto, Montserrat appear in selector. ISS-028 (age group sort order), ISS-029 (system fonts absent), ISS-030 (Source Sans Pro renamed) raised. |
| 2026-09-03 | Tooling housekeeping — Claude Code settings repaired, stale DEC-004 worktree removed, `CLAUDE.md` refreshed for DEC-005 (CHG-035) | `.claude/settings.json` was invalid JSON and silently inert; comments stripped, dead rules removed, permission patterns normalised. Orphaned worktree (145 files) deleted after verifying every blob existed in history — `git fetch` now clean. `styler` hook built and tested but left disabled: it reformats the codebase against its own house style. No app source, test, or `renv.lock` change. |
| 2026-09-03 | Restyle plan and readiness review brought under version control; DEC-005 Step 7 registered (CHG-036) | `restyle-implementation-plan.md` and `reviews/` had been untracked since 2026-06-10 despite DEC-005 citing both. Plan header still read “PLAN — nothing implemented”, four months after Steps 0-6 shipped; corrected, and §8 annotated with the CHG that delivered each step. Step 7 raised as FEAT-010 so the deferred work appears in the open-items list. Documentation only. |
| 2026-09-03 | Test baseline established; handoff refreshed; R 4.5.2 migration attempted and failed (CHG-037, DEC-006) | Suite run to settle three conflicting test counts: 23 blocks/48 assertions and 6 blocks/9 assertions, all passing under R 4.3.3. Doing so exposed ISS-037 — the documented test command skips every integration test and still exits 0. `session-handoff.md` (335 lines, four phases out of date) rewritten. `renv::restore()` under 4.5.2 failed on 12 packages; ISS-036 raised (`forestHelperR` has no resolvable source, so no restore can succeed). `renv.lock` untouched, R 4.3.x environment intact, no app source changed. Rtools43 removed as a side effect of installing Rtools45. Manual retry planned 2026-09-04. |
| 2026-09-04 | DEC-005 Step 7 implemented — status-chip strip, rail badges, Help nav panel (CHG-038, FEAT-010) | Status chips (dataset/regression/variables/font) above the plot, each opening its drawer on click; rail badges for Variables (hidden-variable count) and Display (non-default dot); new static Help nav panel (`R/ui_help.R`). Additive — no input ID or reactive changed. 48/48 unit assertions and 9/9 integration assertions pass unmodified. DEC-005 restyle now fully complete, including phase 2. |
| 2026-09-04 | `design/modal-progression-workflow` branch opened — soft-gated setup wizard + Data drawer visual redesign (CHG-039 through CHG-042, FEAT-011, **draft, not merged**) | User-directed design session exploring the app's "directionless on first launch" problem via a two-step instructional setup wizard (CHG-039), plus a visual pass on the Data drawer specifically: titled fields, vertical dividers, Robust variance renested under Regression type, icon+uppercase panel headings (CHG-041, CHG-042). A genuine `.card` background bug was found and fixed along the way (CHG-040 — candidate to cherry-pick to `main` independently of the experiment). Two real Shiny/CSS gotchas documented in `www/style.css`: `conditionalPanel()`'s `display: contents` defeats DOM-structural CSS selectors, and `flex: 1` needs an actual flex parent. Also surfaced and fixed during the session (not app-related): `TaskStop` on this environment doesn't reliably kill the underlying Windows `Rscript.exe` child process when a background dev-server task is restarted, leaking orphaned R processes across the session — three stray processes were found and killed. No DEC raised yet for whether this branch's patterns get adopted app-wide/merged to `main`; see FEAT-011 for the open question. |

---

*Document version: 3.5 — CHG-039 through CHG-048 record the design/modal-progression-workflow branch's work to date (FEAT-011, draft, NOT merged to `main`): soft-gated setup wizard (CHG-039), `.card` background bug fix (CHG-040 — candidate to cherry-pick to `main` independently), Data drawer titled fields/dividers/Robust variance renesting (CHG-041), icon+uppercase panel headings (CHG-042), titled-field styling extended to Variables/Display/Text/Order (CHG-043), Variables' estimate-column toggles combined into one radio group + misleading switch captions removed app-wide (CHG-044), rail/chip-to-main-tab anchoring (CHG-045), default load state + predictor label renames (CHG-046), returning-user Data drawer default + a real pre-existing `shiny:connected` event bug fixed (CHG-047, ISS-038), wizard welcome modal redesign + auto-advance fix + styling (CHG-048). Previously: CHG-022 through CHG-038 — DEC-004 file split complete; ISS-035 (svglite) resolved; DEC-005 restyle Steps 1-7 (theme/navbar shell, rail/drawer, Variables/Display/Text panels, Data panel/sidebar retired, Order panel + FEAT-009 export redesign, CSS merge/polish, status chips/rail badges/Help nav) complete — restyle fully done. CHG-035 is tooling-only (Claude Code settings repair, stale worktree cleanup) — no app source changed. CHG-036 tracks the restyle plan and readiness review in git, corrects the plan’s stale “nothing implemented” header, and registers DEC-005 Step 7 as FEAT-010. CHG-037 reconciles the test counts (ISS-037: documented command silently skipped all integration tests), refreshes session-handoff.md, and records the FAILED R 4.5.2 migration attempt — blocked by ISS-036; DEC-006 authorises the snapshot when it is retried. CHG-038 implements FEAT-010 (DEC-005 Step 7 phase 2), completing the restyle.*
