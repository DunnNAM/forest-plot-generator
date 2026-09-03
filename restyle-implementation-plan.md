# Restyle implementation plan — MDT theme, bottom rail + drawer (DEC-005 candidate)

> **Prepared:** 2026-06-10
> **Companion review:** `reviews/architecture/2026-06-10_restyle-readiness-review.md`
> **Source materials (MDT project):**
> - `mdt-activity-dashboard/themed-template/www/style.css` — stylesheet to port
> - `mdt-activity-dashboard/themed-template/www/drawer.js` — drawer open/close custom-message handler
> - `mdt-activity-dashboard/themed-template/design-handoff 2.md` — original rail+drawer design brief
> - `mdt-activity-dashboard/themed-template/R/theme.R` — CAQ palette
>
> **Status:** IMPLEMENTED — accepted as **DEC-005** on 2026-07-17. All steps,
> including phase 2, are complete and shipped; see CHG-023/024, CHG-029 through
> CHG-034, and CHG-038 in `app-changelog-decision-register.md` for the per-step
> record. Step 7 (phase 2) shipped as **FEAT-010** in `issues-register.md`. This
> document is retained as the design rationale for the app's current layout — it
> is a historical plan, not a to-do list.

---

## 1. Goal

Restyle Forest Plot Builder using the MDT dashboard's visual language
(CAQ palette, cream background, navbar, card treatment, rail + drawer +
focused-picker interaction model) — **except** the rail is a **full-width
bar at the bottom of the viewport** and the drawer **slides up from the
rail**, instead of MDT's left side rail with a side drawer.

Why bottom rail suits this app specifically:

- Forest plots are **wide**. Removing both the left sidebar and the
  right-hand 3/12 plot-options column gives the plot the full viewport width.
- The widest UI element — the 10-bucket horizontal `sortable::bucket_list`
  column-mapping widget — fits a full-width bottom drawer naturally; it never
  fit a 360 px side drawer.
- Plot options are set-and-forget: open drawer, adjust, close, look at plot.
  A bottom drawer leaves the plot partially visible above while adjusting.

## 2. Constraints carried over from existing decisions

| Decision | Consequence for this plan |
|---|---|
| **DEC-004 — no Shiny modules** | MDT's `mod_filter_rail` / `mod_filter_drawer` module pattern is **adapted, not copied**. Rail/drawer UI = plain functions in `R/`; drawer server logic = `server/drawers.R` sourced with `local = TRUE`. No `NS()`, no `moduleServer()`. |
| **DEC-004 file split in progress** | Steps 5–7 (CHG-022/023/024) must be completed, committed, and pushed **before** restyle work starts (§8 step 0). |
| Explicit `package::function()` | All new code follows this. |
| CLAUDE.md registers | Every implementation step gets a CHG entry; the layout decision gets DEC-005. |
| shinytest2 suite (7 tests) | **Every existing input/output ID is preserved.** Tests target IDs, not containers, so they should survive; verified per review finding F-6. |

## 3. The single load-bearing design decision: static drawers, not `renderUI`

MDT renders drawer content dynamically (`renderUI` + staged
`reactiveValues`, one picker at a time). That worked because MDT has ~15
filter inputs with an Apply-button staging model.

**This app must NOT do that.** It has ~45 always-live inputs
(`input$font`, `input$xlims`, `input$elements`, …) consumed directly by
`forest_plot_object()` and `r_code_string()`, plus `conditionalPanel()`s and
`update*Input()` calls that assume the inputs exist from app start. Rebuilding
that as staged state would be a rewrite of the entire reactive surface for
zero user benefit (the plot already debounces 1000 ms — live updating is the
desired behaviour, there is no "Apply" semantic here).

**Approach: all drawer panels are rendered statically in `ui.R`, all the
time.** Each panel is a `div` inside the single drawer container; the active
panel is chosen by toggling a CSS class (`display:none` on inactive panels).
Open/close toggles classes via a small JS handler (adapted `drawer.js`).

Consequences:

- Every input ID exists in the DOM from startup → reactive graph,
  `conditionalPanel()`s, `update*Input()` calls, and shinytest2 tests are
  untouched.
- Hidden **inputs** keep their values (Shiny only suspends hidden *outputs*).
- The few **outputs** living inside drawers (`output$files` DT,
  `output$sortable_cols`) need `outputOptions(output, ..., suspendWhenHidden = FALSE)`
  *or* a `window.dispatchEvent(new Event('resize'))` after drawer-open in the
  JS handler (see §7 risks — we do both for the sliders' sake anyway).

## 4. Target layout

```
┌──────────────────────────────────────────────────────────────────┐
│ navbar (sticky, 56px) — "Forest Plot Builder"   [Builder] [Help] │
├──────────────────────────────────────────────────────────────────┤ ← 4px accent strip
│ content-area (scrolls, full width)                               │
│   ┌────────────────────────────────────────────────────────────┐ │
│   │ status strip (chip-style: dataset · regression · font · …) │ │   ← phase 2, optional
│   └────────────────────────────────────────────────────────────┘ │
│   ┌────────────────────────────────────────────────────────────┐ │
│   │ navset_card_tab:  [Review data] [Plot]                     │ │
│   │   …full-width plot / data preview…                         │ │
│   └────────────────────────────────────────────────────────────┘ │
│                                                                  │
├──────────────────────────────────────────────────────────────────┤
│ ▲ filter-drawer (slides UP from rail when open, h ≈ 48vh)        │  ← overlays content,
│   drawer-inner: responsive multi-column grid of the active       │    scrim above it
│   panel's controls                                               │
├──────────────────────────────────────────────────────────────────┤
│ rail (fixed bottom, full width, 60px)                            │
│  [Data] [Variables] [Display] [Text] [Order]   ····   [Export]  │
└──────────────────────────────────────────────────────────────────┘
```

## 5. Rail item → control inventory map

Every existing control, mapped. **No input IDs change.**

| Rail item | Icon (bsicons) | Contents (current home) |
|---|---|---|
| **Data** | `database` | `dataset_selected`, `by_group` switch, `upload` + `files` DT, `regression_type`, `group_var_name`, `group_var_values`, `response_var`, `predictor_vars`, `robust_variance` (all currently in `page_sidebar` sidebar) |
| **Variables** | `list-check` | "Variables and Elements" accordion panel: `variables_displayed`, `elements`, `n_display`, `concatenate_est_ci`, `concatenate_est_sig`, `significance`, `inv` (`R/ui_plot_options.R`) |
| **Display** | `sliders` | "Plot Display Options" panel: `plotting_width`, `ci_colour`, `ci_colour2`, `reference_colour`, `xlims`, `xticks`, background switches/colours, `gaps`, `indent`, `sigfigs`, `digits`, `right_justify` |
| **Text** | `fonts` | "Plot Text Options" panel: `plot_title` (+ centre/wrap), `font`, `base_size`, `base_font_colour`, `xaxis_text`, `plot_footnote` (+ long/wrap), `variable_font_colour`, `variable_font_face`, `pval_font_face` |
| **Order** | `arrow-left-right` | `reorder` checkbox + `sortable_cols` rank list (currently above the plot) |
| *(rail-grow spacer)* | | |
| **Export** (action style) | `download` | **FEAT-009 design, new home:** format `radioButtons` (PNG/SVG) + one `downloadButton`; "Copy R code" + "Download .R script" side by side, colour-separated sections. Resolves **ISS-031**; supersedes FEAT-009's sidebar-accordion location while keeping its interaction design. |

Stays where it is:

- The **column-mapping `bucket_list` + Confirm button** stays in the
  *Review data* tab. It is a data-workflow step gated per upload
  (ISS-020 counter), not a setting — and it benefits from the full-width
  content area.
- The `dat_summary` / `dat_upload` / regression preview outputs stay in
  *Review data*.

Optional polish (phase 2): MDT-style **rail badges** (e.g. count of hidden
variables on *Variables*, dot on *Display* when non-default) and the
**status strip** (read-only chips: dataset, regression type, k predictors,
font — each chip click opens its drawer). Ship the core first.

## 6. File plan

| Status | Path | Action |
|---|---|---|
| 🟢 NEW | `www/style.css` | Ported MDT stylesheet + bottom-rail adaptations (§7). Existing `www/styles.css` rules (sortable + noUiSlider tweaks) merged in, recoloured to palette; old file deleted to avoid two sheets. |
| 🟢 NEW | `www/drawer.js` | MDT handler, extended: toggles `open` on the drawer, `active` on scrim and rail items, **shows the matching panel / hides siblings**, and dispatches a `resize` event after opening (slider/DT redraw). |
| 🟢 NEW | `R/ui_rail.R` | `railUI()` — plain function. Buttons use `onclick = Shiny.setInputValue('rail_key', '<key>', {priority:'event'})` exactly like MDT's rail, minus `NS()`. |
| 🟢 NEW | `R/ui_drawers.R` | `drawerUI()` — scrim + drawer container holding five statically-rendered panel `div`s. Data panel = current sidebar content moved verbatim; Variables/Display/Text panels = the three `accordion_panel` bodies from `plotOptionsUI()`, re-laid-out into `.drawer-columns` grids; Order panel = `reorder` + `sortable_cols`. Export panel per FEAT-009 design. |
| 🟢 NEW | `server/drawers.R` | `rv_drawer <- reactiveVal(NULL)`; observer on `input$rail_key` (toggle semantics — same key closes); observer on `input$drawer_close` (scrim click); `session$sendCustomMessage("drawer-open", …)` observer. Sourced `local = TRUE` like the other `server/` files. |
| 🟠 MOD | `ui.R` | `page_sidebar` → `bslib::page_navbar` (nav: *Builder*, later *Help*). Builder panel = `div.dashboard-body` > status strip placeholder + `navset_card_tab` (Review data / Plot) + `drawerUI()` + `railUI()`. Right-hand `plotOptionsUI()` column and the four-button export block **removed**. Stylesheet link gains `?v=` cache-buster (review F-4). |
| 🟠 MOD | `R/ui_plot_options.R` | Refactored: the three panel bodies become three functions (`variablesPanelUI()`, `displayPanelUI()`, `textPanelUI()`) consumed by `drawerUI()`. `plotOptionsUI()` accordion wrapper retired. File rename to follow content if desired (keep CHG entry honest). |
| 🟠 MOD | `global.R` | `bs_theme(version = 5, bootswatch = "flatly")` replaced with explicit palette theme (see below). `theme` object defined here. |
| 🟠 MOD | `server.R` | One added `source()` line for `server/drawers.R`. (By this point Steps 6–7 have already moved export/observers out.) |
| 🟠 MOD | `server/export.R` (exists after Step 6) | `download_png`/`download_svg` collapse into one `downloadHandler` reading the new `export_format` radio; `copy_r_code` / `download_r_code` unchanged. **New input ID `export_format`; the IDs `download_png`/`download_svg` are retired — this is the one place test fixtures may need touching.** |
| ⚪ SAME | `server/upload.R`, `regression.R`, `preview.R`, `plot.R`, `R/helpers.R` | Untouched — verified layout-agnostic (review F-7). |

Theme (in `global.R`):

```r
theme <- bslib::bs_theme(
  version = 5,
  bg = "#f7f4ec", fg = "#3A3A3A",
  primary = "#426175", secondary = "#5B89A6",
  success = "#56958F", warning = "#F4D35E", danger = "#993366"
)
```

(Values from `mdt-activity-dashboard/themed-template/R/theme.R` `caq_colours`.)

## 7. CSS port — what changes side → bottom

**Kept verbatim from MDT `style.css`:** body/background, navbar block,
card + card-header + sub-tab rules, accordion rules (drop later if accordions
fully retire), `.drawer-header/-count/-search/-section-label/-btnrow/-btn`,
focus-visible rules, `.rail-item` inner styling (ico/lbl/badge), chip-strip
block (phase 2).

**Dropped:** `.cancer-tree`, `.htu-*` (How-to-Use), `.kpi-*` (no KPIs here —
keep the block commented out or omit until needed), `.proj-select`,
`.dfl-*` modal rules, per-page accent variants (single-page app — keep one
`--page-accent: #426175`).

**Adapted (the actual side→bottom deltas):**

```css
/* Layout root: column flex instead of 60px|1fr grid */
.dashboard-body {
  display: flex;
  flex-direction: column;
  min-height: calc(100vh - 56px);
  border-top: 4px solid var(--page-accent, #426175);
}
.content-area {
  flex: 1;
  padding: 16px;
  padding-bottom: 76px;            /* clear the fixed 60px rail */
  min-width: 0;
}

/* Rail: fixed full-width bar at the bottom; items flow horizontally */
.filter-rail {
  position: fixed;
  left: 0; right: 0; bottom: 0;
  height: 60px;
  flex-direction: row;             /* was column */
  align-items: center;
  justify-content: flex-start;
  padding: 0 14px;                 /* was 14px 0 */
  gap: 6px;
  border-top: 1px solid rgba(0,0,0,0.12);   /* was border-right */
  border-right: none;
  z-index: 1029;                   /* under the sticky navbar (1030) */
}
.rail-item { width: auto; min-width: 64px; padding: 6px 12px; }
.rail-grow { flex: 1; }            /* pushes Export to the right edge */

/* Scrim: covers viewport between navbar and rail */
.drawer-scrim {
  position: fixed;
  left: 0; right: 0;
  top: 56px; bottom: 60px;         /* was left: 60px */
}

/* Drawer: slides UP from the rail; height animates instead of width */
.filter-drawer {
  position: fixed;
  left: 0; right: 0;
  bottom: 60px;                    /* sits on the rail */
  top: auto;
  width: auto;
  height: 0;                       /* was width: 0 */
  overflow: hidden;
  background: #F0F4F8;
  border-top: 1px solid #d8e0e8;   /* was border-right */
  transition: height 0.18s ease;   /* was width */
  z-index: 1028;
}
.filter-drawer.open { height: min(48vh, 480px); }

/* Drawer panels: all rendered, one visible */
.drawer-panel { display: none; }
.drawer-panel.active { display: block; }

/* Full-width drawer content: responsive columns, centred, scrollable */
.filter-drawer-inner {
  height: 100%;
  overflow-y: auto;
  padding: 16px 24px;
}
.drawer-columns {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: 8px 24px;
  max-width: 1280px;
  margin: 0 auto;
}
```

`drawer.js` adaptation — same custom-message contract as MDT
(`drawer-open` with `open` + `key`), plus two lines:

```js
// show the active panel, hide siblings
document.querySelectorAll(".drawer-panel").forEach(function (el) {
  el.classList.toggle("active", data.open && el.dataset.key === data.key);
});
// let sliders / DT / plots recompute their width now they're visible
if (data.open) window.dispatchEvent(new Event("resize"));
```

## 8. Migration order (each step = one CHG entry, tests green before commit)

| Step | Work | Gate | Status |
|---|---|---|---|
| **0 — prerequisite** | Finish DEC-004: smoke-test + commit Step 5 (CHG-022), implement Steps 6 (CHG-023 `server/export.R`) and 7 (CHG-024 `server/observers.R`). **Push to origin** (5+ commits stale). Optionally fold review candidates ISS-032 (`Rplots.pdf` untrack) and ISS-033/034 here. | Both test files pass; remote up to date | ✅ Done — CHG-023/024; ISS-032/033/034 folded in; pushed |
| **1** | Add `www/style.css` + `www/drawer.js`; register DEC-005 in the register; theme swap in `global.R`; `ui.R` → `page_navbar` shell with `dashboard-body`/`content-area` wrapping the **existing** layout (sidebar + options column still present, just reskinned). | App launches; visual check; tests pass | ✅ Done — CHG-029 |
| **2** | `R/ui_rail.R` + `server/drawers.R` + empty `R/ui_drawers.R` panels. Rail renders, clicking opens/closes an empty drawer, scrim works. | Manual drawer interaction check; tests pass | ✅ Done — CHG-030 |
| **3** | Move plot-options accordion content into Variables / Display / Text drawer panels (`drawer-columns` layout); remove the right-hand 3/12 column. | All 45 inputs respond; plot updates from each drawer; `conditionalPanel`s fire; tests pass | ✅ Done — CHG-031 |
| **4** | Move sidebar content into the Data drawer; drop `page_sidebar` for good. Check upload → bucket-list → confirm → preview flow end-to-end. | shinytest2 upload/confirm tests pass unmodified | ✅ Done — CHG-032 |
| **5** | Order panel (`reorder` + `sortable_cols`) into drawer; remove from Plot tab. Export drawer per FEAT-009 design; retire `download_png`/`download_svg` IDs for `export_format` + `download_plot`; update `server/export.R`. Mark **ISS-031 resolved, FEAT-009 implemented (location amended)** in the register. | Manual export of PNG/SVG/code; tests updated for new export IDs | ✅ Done — CHG-033 |
| **6** | Polish: merge old `styles.css` slider/sortable rules (recoloured `#2c3e50` → `#426175`), delete old file; focus-visible audit; cache-buster; smoke test at 1366×768 and ~2560 width. | Full suite + manual smoke test | ✅ Done — CHG-034 |
| **7 (phase 2)** | Status-chip strip (clicking a chip opens its drawer); rail badges (Variables: hidden-variable count; Display: non-default dot); *Help* nav panel (static content, not the MDT `.htu-*` pattern — that CSS was dropped per §7). | Full suite green | ✅ Done — CHG-038 |

Steps 1–7 are individually shippable; the app works after every step.

**Outcome:** Steps 0–6 were delivered as planned between 2026-06-10 and
2026-07-17, each as its own CHG entry with tests green before commit, exactly as
this table specifies. Step 7 was deliberately deferred — "ship the core first" —
and picked up on 2026-09-04 as CHG-038.

## 9. Risks and mitigations

| Risk | Mitigation |
|---|---|
| `shinyWidgets::noUiSliderInput` (`xlims`, `xticks`) initialised inside `display:none` containers renders with zero width | `resize` dispatch on drawer-open (in `drawer.js`); verify on first open during step 3. Known fallback: re-trigger via `shinyWidgets::updateNoUiSliderInput()` once on first open. |
| Hidden outputs inside drawers (`files` DT, `sortable_cols`) suspended at start | `outputOptions(output, "files", suspendWhenHidden = FALSE)` (and `sortable_cols`) in `server/drawers.R`, plus the resize dispatch. |
| shinytest2 tests break | IDs preserved everywhere except step 5's export rework — only that step touches test fixtures. Run the suite at every gate. |
| `colourpicker` popups inside an `overflow-y: auto` drawer may clip | Colour pickers open in a floating panel attached to `body` in current versions; verify during step 3, else set drawer `overflow` to `visible` while a picker is open (CSS `:has()` is available — Bootstrap 5 browsers). |
| Drawer (48vh) covers the plot users are tuning | Acceptable: plot top remains visible; drawer closes on scrim click. If it bites, add a half-height "peek" mode later — do not build speculatively. |
| `materialSwitch`/`strong()` label pairs look ragged in multi-column grid | Wrap each switch+label in a `.drawer-field` div during step 3; pure CSS, no ID changes. |

## 10. Out of scope

- `forestHelperR` changes (ISS-028 stays a package issue).
- Font/selector issues ISS-029, ISS-030 — unaffected by restyle (plot
  rendering fonts are sysfonts/showtext, independent of UI CSS).
- Multi-page navigation, KPI boxes, MDT chip popovers — not applicable or
  deferred to phase 2.
