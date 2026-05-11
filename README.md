# Forest Plot Builder

A Shiny app for generating publication-ready forest plots. Built for the Cancer Alliance Queensland (CAQ) Data Science Community.

The app wraps the `forestHelperR` package, which handles regression table construction and plot rendering. Supported input modes are:

- **Upload mode** — upload one or two CSV/TSV/Excel files containing pre-computed regression output, map columns interactively, and generate a plot.
- **Simulated data mode** — fit a Poisson, logistic, or Cox proportional hazards regression on a built-in synthetic dataset and plot the results directly.

---

## Prerequisites

- R ≥ 4.1
- RStudio (recommended) or any environment that can serve a Shiny app
- The `forestHelperR` package (see [Installation](#installation) below)

---

## Installation

### 1. Clone the repository

```bash
git clone <repository-url>
```

Or download and unzip the source.

### 2. Install `forestHelperR`

`forestHelperR` is a private package and is not on CRAN.

**Option A — CAQ internal repository (CAQ staff):**

```r
# Contact the CAQ Data Science Community for the internal repository URL
install.packages("forestHelperR", repos = "<internal-repo-url>")
```

**Option B — from a `.tar.gz` file:**

```r
install.packages(
  "path/to/forestHelperR_x.x.x.tar.gz",
  repos = NULL,
  type = "source"
)
```

`forestHelperR` has dependencies that are not declared in its `DESCRIPTION` and will not be resolved automatically on a `.tar.gz` install (see [Known limitations](#known-limitations)). Install them first:

```r
install.packages(c("extrafont", "forestploter", "lmtest", "sandwich"))
```

### 3. Install app dependencies

```r
install.packages(c(
  "shiny", "bslib", "DT", "sortable",
  "readxl", "vroom",
  "dplyr", "forcats", "stringr", "rlang",
  "survival",
  "broom", "lmtest", "sandwich",
  "colourpicker", "shinyWidgets",
  "here", "extrafont"
))
```

### 4. One-time font import

The app supports custom fonts (Lato, Roboto, Open Sans, Source Sans Pro, Montserrat). These are loaded via `extrafont` and require a one-time import step **per machine**. Run this once in an interactive R session — it may take a few minutes:

```r
extrafont::font_import()   # imports all fonts found on the system
extrafont::loadfonts()     # registers them with R graphics devices
```

If you have font files to add (e.g., the `Lato/` directory bundled in this repo), place them in your system fonts directory before running `font_import()`.

> **Note:** If this step is skipped, the font selector will fall back to five base R fonts (Helvetica, Times, Courier, Palatino, Bookman) with no error message. See [ISS-002](issues-register.md#iss-002--font-import-not-portable) for details and the planned fix.

---

## Running the app

**From RStudio:** open any of `global.R`, `ui.R`, or `server.R` and click **Run App**.

**From an R console:**

```r
setwd("path/to/forest-plot-generator")
shiny::runApp()
```

**From the terminal:**

```bash
Rscript -e "shiny::runApp('path/to/forest-plot-generator')"
```

---

## Usage overview

1. **Select a data source** in the left sidebar — *Regression output* (upload) or *Simulated data*.
2. **Upload one or two files** if using upload mode. To compare two regressions, select both files simultaneously using Ctrl+click (Windows) or Cmd+click (Mac).
3. **Map columns** using the drag-and-drop interface, then click **Confirm column names**.
4. **Review the data table** in the *Review data* tab to verify the import.
5. **Adjust plot options** in the right-hand accordion panel (variables, elements, display, text).
6. **Export** as PNG or SVG using the buttons in the *Plot* tab.

---

## Known limitations

| Issue | Description |
|---|---|
| ISS-002 | Custom fonts require a one-time `extrafont::font_import()` step that is not automated. Falls back silently to base R fonts if skipped. |
| ISS-004 | No automated tests. Regressions in reactive logic or data processing will not be caught automatically. |
| ISS-011 | No `renv` lockfile. Package versions are not pinned — behaviour may differ across environments. |
| ISS-012 | The simulated dataset is regenerated on every cold start, adding startup latency. |

Full details in [`issues-register.md`](issues-register.md).

---

## Project structure

```
forest-plot-generator/
├── global.R              # Package loads, global objects
├── server.R              # All reactive logic
├── ui.R                  # Layout and inputs
├── data/
│   └── data_creation.R   # Synthetic dataset generation
├── Lato/                 # Bundled Lato font files
├── www/
│   └── styles.css        # Custom CSS
├── issues-register.md
└── app-changelog-decision-register.md
```

---

## Contributing

This is a private development repository. If you find a bug or want to propose a change:

1. Add an entry to [`issues-register.md`](issues-register.md) describing the problem.
2. Implement the fix following the project conventions below.
3. Record the change in [`app-changelog-decision-register.md`](app-changelog-decision-register.md).

**Conventions:**

- Use explicit `package::function()` notation throughout.
- Prefer `req()` over `is.null()` guards in reactives.
- Update both registers for every code change — no exceptions.
- Do not modify `forestHelperR` package files (separate repository).
- Do not modify `renv.lock` if present.

---

> **Organisation:** Cancer Alliance Queensland  
> **Contact:** Nathan Dunn — nathan.dunn@health.qld.gov.au
