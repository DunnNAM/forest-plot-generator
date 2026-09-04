# Drawer panel UI — DEC-005 Steps 3-5. The three accordion panels this file used
# to build for the right-hand sidebar column are now three drawer panel
# functions consumed by drawerUI() (Step 3); dataPanelUI() (Step 4) is the old
# left-hand page_sidebar() content, moved verbatim into the Data drawer panel;
# orderPanelUI()/exportPanelUI() (Step 5) are the former Plot-tab reorder
# control and the FEAT-009 export redesign. No input IDs changed anywhere
# except download_png/download_svg, which Step 5 retires for export_format +
# download_plot — every other input is exactly the one the sidebar/accordion/
# Plot-tab version had, just laid out in a `.drawer-columns` responsive grid.
# `strong()` + `materialSwitch()` label pairs are wrapped in `.drawer-field` so
# they don't look ragged when a grid column is narrower than the accordion
# column was (restyle plan §9).

# Title + content wrapper for a single .drawer-columns field: a bold title
# noticeably larger than its content (CSS: .drawer-field-title/-content),
# with content starting at a consistent vertical position across a row —
# requested specifically for the Data panel's four top-level fields (design/
# modal-progression-workflow review, 2026-09-04). Deliberately not cards, per
# that discussion — plain title-over-content blocks inside the existing
# .drawer-columns grid.
#
# `first` controls the leading divider (Data panel's .drawer-row-divided
# only — see dataPanelUI()) explicitly rather than via a CSS :first-child/
# :not(:first-child) selector. That was the first approach, and it silently
# matched nothing for the sim-mode fields: Shiny's conditionalPanel() renders
# `display: contents` when shown (so its child is promoted into the parent
# flex row for *layout* purposes) but a `.drawer-row-divided > *` CSS
# selector still only sees the un-promoted DOM tree — the conditionalPanel
# div, not the drawerFieldUI() div nested inside it — so the divider rule
# never matched it (confirmed via devtools, 2026-09-04). Since exactly one
# field ("Data set") is ever first regardless of dataset_selected, passing it
# explicitly sidesteps the mismatch entirely.
drawerFieldUI <- function(title, ..., first = FALSE) {
  div(
    class = paste("drawer-field-block", if (!first) "drawer-field-block--divided"),
    div(class = "drawer-field-title", title),
    div(class = "drawer-field-content", ...)
  )
}

# Panel heading: the matching rail icon + an uppercase title, both in the
# title's slate blue, sitting directly on the drawer's own background — no
# card, no box. Ties the drawer's heading back to the rail button that opened
# it. Chosen over a full left-hand icon "card" column (which would have meant
# restructuring every panel's layout from a vertical stack to a sidebar+
# content split, and re-deriving the Data panel's divider-centering math) —
# see the 2026-09-04 discussion. `icon_name` must match the icon passed to
# the corresponding rail_button() call in R/ui_rail.R.
drawerHeaderUI <- function(icon_name, title) {
  h4(class = "drawer-header", icon(icon_name), title)
}

dataPanelUI <- function() {
  tagList(
    drawerHeaderUI("database", "Data"),
    div(
      # .drawer-row-divided rather than .drawer-columns: this panel gets
      # vertical dividers between its fields, which needs the row to stretch
      # to fill the drawer's available height (see CSS) — a flex row, not a
      # grid, is what lets that work (2026-09-04 discussion). Scoped to the
      # Data panel only; the other five panels keep the plain grid.
      class = "drawer-row-divided",
      drawerFieldUI(
        "Data set",
        radioButtons("dataset_selected", label = NULL,
                     choices = c("Regression output" = "upload", "Simulated data" = "sim"),
                     selected = "upload"),
        first = TRUE
      ),
      conditionalPanel(
        condition = "input.dataset_selected == 'upload'",
        drawerFieldUI(
          "Comparison mode",
          # materialSwitch() has no built-in on/off text — with the "Comparison
          # of two regressions" description now living in the title above (not
          # beside the switch), a bare toggle had no visible cue what "on"
          # means, so it gets a static "On" caption (2026-09-04 discussion).
          materialSwitch("by_group", "On", value = FALSE, status = "primary")
        )
      ),
      drawerFieldUI(
        "Regression type",
        tagList(
          # Alphabetical (Cox, Logistic, Poisson) so Robust variance — nested
          # under Poisson, the last option — never repositions Cox/Logistic
          # above it when it shows/hides. It used to be its own top-level
          # field; when "Simulated data" was selected, the sim-only
          # response/predictor block (tall — 11 checkboxes) shared its grid
          # row and stretched it, stranding Robust variance under Data set at
          # the bottom of the drawer instead of beside Regression type (user
          # report, 2026-09-04). Nesting it here removes that separate grid
          # item entirely, so there's nothing left to misplace.
          radioButtons("regression_type", label = NULL,
                       choices = c("Cox proportional hazards" = "cox", "Logistic" = "logistic", "Poisson" = "poisson"),
                       selected = "poisson"),
          conditionalPanel(
            condition = "input.regression_type == 'poisson'",
            checkboxInput("robust_variance", "Robust variance", value = TRUE)
          )
        )
      ),
      conditionalPanel(
        condition = "input.dataset_selected == 'upload' && input.by_group==1",
        textInput("group_var_name", "Group variable display name", value = "Group"),
        textInput("group_var_values", "Group variable levels", value = NULL,
                  placeholder = "(in order they appear, separated by ',')")
      ),
      conditionalPanel(
        condition = "input.dataset_selected == 'sim'",
        drawerFieldUI(
          "Response variable",
          selectInput("response_var", label = NULL, choices = responses)
        )
      ),
      conditionalPanel(
        condition = "input.dataset_selected == 'sim'",
        drawerFieldUI(
          "Predictor variables",
          checkboxGroupInput("predictor_vars", label = NULL,
                             choices = predictors, selected = c("AgeGroupAtDiagnosis"))
        )
      )
    ),
    # Upload + file table pulled out of .drawer-columns deliberately: sharing
    # a grid row with the short radio/switch fields above stretched that row
    # to the table's height, stranding "Data set" et al. under a wall of dead
    # space before the next row started (design/modal-progression-workflow
    # review, 2026-09-04). Full-width block below instead, same max-width/
    # centering as the grid via .drawer-fullwidth.
    conditionalPanel(
      condition = "input.dataset_selected == 'upload'",
      div(
        class = "drawer-fullwidth",
        fileInput("upload", "Upload one or two files with regression output (csv/tsv required). To compare two regressions, select both files at once using Ctrl+click (Windows) or Cmd+click (Mac).", multiple = TRUE),
        DT::dataTableOutput("files", width = "100%")
      )
    )
  )
}

variablesPanelUI <- function() {
  tagList(
    drawerHeaderUI("list-check", "Variables and Elements"),
    div(
      class = "drawer-columns",
      checkboxGroupInput("variables_displayed", "Variables plotted", choices = c()),
      checkboxGroupInput("elements", "Elements included",
                         choices = display_option,
                         selected = unname(display_option)),
      conditionalPanel(
        condition = "input.elements.includes('n')",
        radioButtons("n_display", "Count display", choices = c("n", "n/N", "% (n/N)"), selected = "n")
      ),
      conditionalPanel(
        condition = "input.elements.includes('est')||input.elements.includes('lci')",
        div(class = "drawer-field",
            strong("Combine estimate and CI"),
            materialSwitch("concatenate_est_ci", "", value = TRUE, status = "primary"))
      ),
      conditionalPanel(
        condition = "input.significance == 1",
        div(class = "drawer-field",
            strong("Combine estimate and significance symbol"),
            materialSwitch("concatenate_est_sig", "", value = FALSE, status = "primary"))
      ),
      div(class = "drawer-field",
          strong("Include significance symbol"),
          materialSwitch("significance", "", value = TRUE, status = "primary")),
      conditionalPanel(
        condition = "input.regression_type == 'cox'",
        div(class = "drawer-field",
            strong("Plot inverse hazard ratio"),
            materialSwitch("inv", "", value = FALSE, status = "primary"))
      )
    )
  )
}

displayPanelUI <- function() {
  tagList(
    drawerHeaderUI("sliders", "Plot Display Options"),
    div(
      class = "drawer-columns",
      sliderInput("plotting_width", "Width of plotting area", min = 20, max = 250, value = 120, step = 1, ticks = TRUE),
      colourpicker::colourInput("ci_colour", "Confidence interval colour", value = "#444444"),
      conditionalPanel(
        condition = "input.by_group==1",
        colourpicker::colourInput("ci_colour2", "Group 2 confidence interval colour", value = "#E07653")
      ),
      colourpicker::colourInput("reference_colour", "Reference level colour", value = "#C43D4D"),
      shinyWidgets::noUiSliderInput("xlims", "Domain", range = log_scale,
                                    value = c(0.25, 4), min = 0.05, max = 20),
      shinyWidgets::noUiSliderInput("xticks", "x-axis ticks", range = log_scale,
                                    connect = FALSE, value = c(0.1, 0.25, 0.5, 2, 4, 10), min = 0.05, max = 20),
      div(class = "drawer-field",
          strong("Table background transparent"),
          materialSwitch("transparent_table_bg", "", value = TRUE, status = "primary")),
      conditionalPanel(
        condition = "input.transparent_table_bg==0",
        colourpicker::colourInput("table_bg_colour", "Table background colour"),
        div(class = "drawer-field",
            strong("Striped background"),
            materialSwitch("striped_bg", "", value = FALSE, status = "primary")),
        conditionalPanel(
          condition = "input.striped_bg==1",
          colourpicker::colourInput("bg_stripe", "Stripe colour", value = "#EBEBEB")
        )
      ),
      div(class = "drawer-field",
          strong("Plot background transparent"),
          materialSwitch("transparent_plot_bg", "", value = TRUE, status = "primary")),
      conditionalPanel(
        condition = "input.transparent_plot_bg==0",
        colourpicker::colourInput("plot_bg_colour", "Plot background colour")
      ),
      div(strong("Space between variables"),
          sliderInput("gaps", "", value = 0.8, min = 0.5, max = 2, step = 0.1, ticks = FALSE)),
      div(strong("Indent of levels"),
          sliderInput("indent", "", value = 0.5, min = 0, max = 2, step = 0.1, ticks = FALSE)),
      materialSwitch("sigfigs", "Use significant figures", value = FALSE, status = "primary"),
      numericInput("digits", "Number of decimal places", value = 2, min = 1, max = 5, step = 1),
      selectizeInput(
        "right_justify", "Right-justify variables", multiple = TRUE,
        choices = elements[-c(1,2,4)], selected = c())
    )
  )
}

textPanelUI <- function() {
  tagList(
    drawerHeaderUI("font", "Plot Text Options"),
    div(
      class = "drawer-columns",
      textInput("plot_title", "Title", placeholder = "Plot title text"),
      conditionalPanel(
        condition = "input.plot_title != ''",
        fluidRow(
          materialSwitch("plot_title_centre", "Center title", value = FALSE,
                         status = "primary", width = "80px"),
          sliderInput("plot_title_wrap", "Title width before wrapping", min = 40,
                      max = 140, value = 80, step = 1, width = "200px",
                      ticks = FALSE))),
      selectInput("font", "Font", choices = fonts, selected = "Lato"),
      sliderInput("base_size", "Font size", min = 8, max = 18, value = 11, step = 1, post = "pt", ticks = FALSE),
      colourpicker::colourInput("base_font_colour", "Text colour", value = "#444444"),
      selectizeInput("xaxis_text", "x-axis label", choices = labels_axis, options = list(create = TRUE)),
      textInput("plot_footnote", "Footnote", placeholder = "Plot footnote text"),
      conditionalPanel(
        condition = "input.plot_footnote != ''",
        fluidRow(
          materialSwitch("long_footnote", "Long footnote", value = TRUE,
                         status = "primary", width = "80px"),
          sliderInput("footnote_wrap", "Footnote width before wrapping", min = 40,
                      max = 200, value = 120, step = 1, width = "200px",
                      ticks = FALSE))),
      colourpicker::colourInput("variable_font_colour", "Variable font colour", value = "#2047A7"),
      selectizeInput("variable_font_face", "Variable header font face", choices = faces, selected = "bold"),
      selectizeInput("pval_font_face", "p-value font face", choices = faces, selected = "plain")
    )
  )
}

orderPanelUI <- function() {
  tagList(
    drawerHeaderUI("arrows-left-right", "Order"),
    # .drawer-fullwidth rather than .drawer-columns: this panel has one real
    # control, so a multi-column grid just leaves the other columns empty.
    # The explanatory copy also addresses the panel reading as broken/empty
    # when reorder is off (design/modal-progression-workflow review,
    # 2026-09-04) — off is the common case, so it should look intentional.
    div(
      class = "drawer-fullwidth",
      div(class = "drawer-field",
          strong("Reorder columns"),
          checkboxInput("reorder", "", value = FALSE)),
      p(class = "text-muted",
        "Off by default — the plot uses the standard left-to-right column",
        " order. Turn this on to drag the plot's element columns",
        " (variables, counts, estimate, CI, p-value) into a custom order."),
      conditionalPanel(condition = "input.reorder==1", uiOutput("sortable_cols"))
    )
  )
}

# Export panel — FEAT-009 redesign, resolves ISS-031 (four-button layout wrapped
# with no spacing). Format radio + single download button for graph export;
# separate copy/download buttons for code export, since clipboard-copy and
# file-download are genuinely distinct actions that can't be merged. Sections
# are colour-separated (.export-section--graph/--code in www/style.css).
exportPanelUI <- function() {
  tagList(
    drawerHeaderUI("download", "Export"),
    div(
      class = "drawer-columns",
      div(
        class = "export-section export-section--graph",
        strong("Export graph"),
        radioButtons("export_format", NULL,
                     choices = c("PNG" = "png", "SVG" = "svg"),
                     selected = "png", inline = TRUE),
        downloadButton("download_plot", "Download", icon = icon("download"))
      ),
      div(
        class = "export-section export-section--code",
        strong("Export code"),
        div(
          class = "drawer-btnrow",
          actionButton("copy_r_code", "Copy R code", icon = icon("copy")),
          downloadButton("download_r_code", "Download .R script")
        )
      )
    )
  )
}
