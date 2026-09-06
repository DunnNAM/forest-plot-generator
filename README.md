# Forest Plot Builder

A Shiny app for generating publication-ready forest plots. Built for the Cancer Alliance Queensland (CAQ) Data Science Community.

The app wraps the `forestHelperR` package, which handles regression table construction and plot rendering. Supported input modes are:

- **Upload mode** — upload one or two CSV/TSV files containing pre-computed regression output, map columns interactively, and generate a plot. To compare two regressions side by side, select both files at once (Ctrl+click / Cmd+click) and turn on comparison mode.
- **Simulated data mode** (the default on first load) — fit a Poisson, logistic, or Cox proportional hazards regression on a built-in synthetic dataset and plot the results directly.

Published on Posit Connect Cloud; also runs locally from source (see below).

---

## Prerequisites

- **R 4.3.x** — the project currently targets R 4.3.1 specifically (`renv.lock` pins it). A migration to R 4.5.2 is planned but not yet complete; see `session-handoff.md` §4 if you're picking that up.
- [`renv`](https://rstudio.github.io/renv/) — dependencies are locked via `renv.lock`, not installed ad hoc.
- RStudio (recommended) or any environment that can serve a Shiny app.
- A working internet connection the first time you restore the environment (`forestHelperR` installs from GitHub; a couple of fonts load from Google Fonts and fail silently if unreachable — see [Known limitations](#known-limitations)).

---

## Installation

### 1. Clone the repository

```bash
git clone https://github.com/DunnNAM/forest-plot-generator.git
```

### 2. Restore the R environment

From an R console in the project root, with R 4.3.x active:

```r
renv::restore()
```

This installs every pinned dependency, including `forestHelperR` (recorded in `renv.lock` with a real GitHub source, `github.com/DunnNAM/forestHelperR`) — no separate manual install step or `.tar.gz` needed.

No font-import step is required either: `Lato` is bundled as TTF files in the `Lato/` directory and registered directly via `sysfonts::font_add()` in `global.R`; a few additional fonts (Roboto, Open Sans, Source Sans Pro, Montserrat) load from Google Fonts on startup and are simply omitted from the font selector if that fails (see [Known limitations](#known-limitations)).

---

## Running the app

**From RStudio:** open `ui.R`, `server.R`, or `global.R` and click **Run App**.

**From an R console:**

```r
shiny::runApp()
```

`here::here()` resolves all paths relative to the project root, so no `setwd()` is needed regardless of your working directory when you launch this.

---

## Usage overview

The app opens with a working example already plotted (Simulated data, a default response/predictor selection) rather than an empty screen. A first-visit setup wizard walks through the basics — skippable, and restartable any time via **Tour**, the first icon on the bottom rail.

Settings live in **drawers**, opened from the bottom rail and closed the same way (or by clicking outside):

1. **Data** — choose Regression output (upload) or Simulated data; for uploads, map columns and confirm them, then check the import on the **Review data** tab.
2. **Variables** — choose which variables and elements (counts, estimate, CI, p-value) are plotted.
3. **Display** — axis domain/ticks, colours, backgrounds, spacing.
4. **Text** — title, footnote, font, font sizing.
5. **Order** — optionally drag the plot's element columns into a custom order.
6. **Export** — download the plot as PNG or SVG, copy the reproducing R code to the clipboard, or download it as a `.R` script.

The plot updates live as you change settings — there's no "Apply" button. The in-app **Help** tab covers the same ground in more detail.

---

## Testing

```r
testthat::test_file("tests/testthat/test-helpers.R")     # pure helper functions
testthat::test_file("tests/testthat/test-shiny-app.R")   # shinytest2 integration tests
```

**`NOT_CRAN=true` is required for the integration tests.** `shinytest2`'s `AppDriver$new()` calls `skip_on_cran()` internally — without this env var, every integration test block skips silently and the run still exits `0`, reading as a pass. `devtools::test()` and RStudio's test runner set it for you; a bare `Rscript -e ...` call does not:

```bash
NOT_CRAN=true Rscript -e 'testthat::test_file("tests/testthat/test-shiny-app.R")'
```

---

## Known limitations

| Issue | Description |
|---|---|
| ISS-028 | Age group levels aren't in clinical sort order in the simulated dataset (lives in `forestHelperR`, out of this repo's scope). |
| ISS-029 | OS system fonts are no longer available in the font selector, following the `sysfonts`/`showtext` migration away from `extrafont`. |
| ISS-030 | `"Source Sans Pro"` was renamed to `"Source Sans 3"` on Google Fonts and is silently absent from the selector. |
| ISS-039 | x-axis tick generation always splits the tick count evenly either side of 1 — doesn't suit a skewed result distribution. |
| ISS-040 | The Variables rail badge can briefly flash a stale "hidden variables" count on load; self-corrects, cosmetic only. |
| ISS-046 | Widespread un-namespaced `pkg::fun()` calls, contradicting this project's own explicit-namespacing convention. |

Full details, plus the current architecture-review and CSS-audit backlog, in [`issues-register.md`](issues-register.md).

---

## Project structure

```
forest-plot-generator/
├── global.R                    # Package loads, font setup, global objects
├── ui.R                        # page_navbar() shell, rail, statically-rendered drawer panels
├── server.R                    # Thin shell — sources server/*.R with local = TRUE
├── server/                     # Reactive logic, one file per concern
│   ├── upload.R                #   data upload pipeline + column confirmation gate
│   ├── regression.R            #   fit(), predictors_selected(), reg_table()
│   ├── preview.R                #   Review Data tab outputs
│   ├── plot.R                  #   plot generation + order() + concatenate guards
│   ├── export.R                #   download handlers + R code serialiser + clipboard copy
│   ├── observers.R             #   misc observers
│   ├── drawers.R               #   rail/drawer panel switching
│   └── wizard.R                #   first-visit setup wizard logic
├── R/                          # Pure helpers and UI helper functions (auto-sourced)
│   ├── helpers.R                #   pure helper functions (also used by tests)
│   ├── ui_rail.R                #   bottom-rail buttons
│   ├── ui_drawers.R             #   drawer shell
│   ├── ui_plot_options.R        #   per-panel drawer UI
│   ├── ui_help.R                #   static Help tab content
│   └── ui_wizard.R              #   setup wizard modal content
├── www/
│   ├── style.css                # Single stylesheet (CAQ palette)
│   ├── drawer.js                # Drawer open/close client-side handler
│   ├── wizard.js                # First-visit wizard detection
│   └── export.js                # Client-side clipboard copy for "Copy R code"
├── data/
│   └── data_creation.R          # Synthetic dataset generation
├── Lato/                        # Bundled Lato font files
├── tests/
│   ├── testthat/                # Unit + shinytest2 integration tests
│   └── fixtures/                # CSV fixtures for integration tests
├── renv.lock                    # Locked dependency versions (R 4.3.1)
├── manifest.json                # Posit Connect Cloud deployment manifest
├── issues-register.md
└── app-changelog-decision-register.md
```

---

## Deployment

The app is published on [Posit Connect Cloud](https://connect.posit.cloud/). The deploy manifest, `manifest.json`, is regenerated via:

```r
rsconnect::writeManifest(appDir = ".")
```

`forestHelperR` installs from its public GitHub source during a Connect Cloud build — no internal package repository or bundled `.tar.gz` needed.

---

## Contributing

This is a private development repository. If you find a bug or want to propose a change:

1. Add an entry to [`issues-register.md`](issues-register.md) describing the problem.
2. Implement the fix following the project conventions below.
3. Record the change in [`app-changelog-decision-register.md`](app-changelog-decision-register.md).

**Conventions:**

- Use explicit `package::function()` notation throughout (currently violated in places — see ISS-046).
- Prefer `req()` over `is.null()` guards in reactives.
- Update both registers for every code change — no exceptions.
- Do not modify `forestHelperR` package files (separate repository).
- Do not modify `renv.lock`, except as part of the authorised R 4.5.2 migration (DEC-006).

Full architectural context and current phase lives in [`CLAUDE.md`](CLAUDE.md); day-to-day status and next steps live in `session-handoff.md`.

---

> **Organisation:** Cancer Alliance Queensland
> **Author / Maintainer:** Nathan Dunn — nathan.dunn@health.qld.gov.au
