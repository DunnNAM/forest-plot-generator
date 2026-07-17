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

dataPanelUI <- function() {
  tagList(
    h4(class = "drawer-header", "Data"),
    div(
      class = "drawer-columns",
      radioButtons("dataset_selected", "Data set",
                   choices = c("Regression output" = "upload", "Simulated data" = "sim"),
                   selected = "upload"),
      conditionalPanel(
        condition = "input.dataset_selected == 'upload'",
        div(class = "drawer-field",
            strong("Comparison of two regressions"),
            materialSwitch("by_group", "", value = FALSE, status = "primary")),
        fileInput("upload", "Upload one or two files with regression output (csv/tsv required). To compare two regressions, select both files at once using Ctrl+click (Windows) or Cmd+click (Mac).", multiple = TRUE),
        DT::dataTableOutput("files", width = "100%")
      ),
      radioButtons("regression_type", "Regression type selected",
                   choices = c("Poisson" = "poisson", "Logistic" = "logistic", "Cox proportional hazards" = "cox"),
                   selected = "poisson"),
      conditionalPanel(
        condition = "input.dataset_selected == 'upload' && input.by_group==1",
        textInput("group_var_name", "Group variable display name", value = "Group"),
        textInput("group_var_values", "Group variable levels", value = NULL,
                  placeholder = "(in order they appear, separated by ',')")
      ),
      conditionalPanel(
        condition = "input.dataset_selected == 'sim'",
        selectInput("response_var", "Response variable", choices = responses),
        checkboxGroupInput("predictor_vars", "Predictor variables",
                           choices = predictors, selected = c("AgeGroupAtDiagnosis"))
      ),
      conditionalPanel(
        condition = "input.regression_type == 'poisson'",
        materialSwitch("robust_variance", "Robust variance", value = TRUE, status = "primary")
      )
    )
  )
}

variablesPanelUI <- function() {
  tagList(
    h4(class = "drawer-header", "Variables and Elements"),
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
    h4(class = "drawer-header", "Plot Display Options"),
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
    h4(class = "drawer-header", "Plot Text Options"),
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
    h4(class = "drawer-header", "Order"),
    div(
      class = "drawer-columns",
      div(class = "drawer-field",
          strong("Reorder columns"),
          checkboxInput("reorder", "", value = FALSE)),
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
    h4(class = "drawer-header", "Export"),
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
