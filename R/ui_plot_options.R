# Plot options — DEC-005 Step 3. The three accordion panels this file used to
# build for the right-hand sidebar column are now three drawer panel functions
# consumed by drawerUI(). No input IDs changed — every input is exactly the one
# the accordion version had, just laid out in a `.drawer-columns` responsive
# grid instead of a single-column accordion. `strong()` + `materialSwitch()`
# label pairs are wrapped in `.drawer-field` so they don't look ragged when a
# grid column is narrower than the accordion column was (restyle plan §9).

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
