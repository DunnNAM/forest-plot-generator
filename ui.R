
ui <- page_sidebar(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),
  title = "Forest Plot Builder",
  theme = bs_theme(version = 5, bootswatch = "flatly"),
  sidebar = sidebar(
    radioButtons("dataset_selected", "Data set",
                 choices = c("Regression output" = "upload", "Simulated data" = "sim"),
                 selected = "upload"),
    conditionalPanel(
      condition = "input.dataset_selected == 'upload'",
      hr(),
      strong("Comparison of two regressions"),
      materialSwitch("by_group", "", value = FALSE, status = "primary"),
      hr(),
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
  ),
  
  layout_columns(
    col_widths = c(9, 3),
    navset_card_tab(
      nav_panel(
        "Review data",
        br(),
        conditionalPanel(
          condition = "input.dataset_selected == 'upload'",
          uiOutput("sortable")),
        wellPanel(
          conditionalPanel(
            condition = "input.dataset_selected == 'sim'",
            radioButtons("preview_type", "Preview type",
                         choices = c("Extract of simulated data" = "head", "Regression output" = "reg_summary"),
                         selected = c("head")),
            DT::dataTableOutput("dat_summary", width = "100%"),
            verbatimTextOutput("regression_details"),
            conditionalPanel(
              condition = "input.robust_variance && input.regression_type == 'poisson'",
              strong("With robust variance"),
              verbatimTextOutput("robust"))),
          conditionalPanel(condition = "input.dataset_selected == 'upload'", DT::dataTableOutput("dat_upload")))),
      nav_panel(
        "Plot",
        fluidRow(
          column(
            4,
            div(
              style="display:inline-block; margin-right: 10px;",
              downloadButton("download_png", "Download png", icon = icon("download"))),
            div(
              style="display:inline-block;",
              downloadButton("download_svg", "Download svg", icon = icon("file-export"))))),
        fluidRow(
          column(
            6,
            strong("Reorder columns"),
            checkboxInput("reorder", "", value = FALSE),
            conditionalPanel(condition = "input.reorder==1", uiOutput("sortable_cols")))),
        fluidRow(plotOutput("forest")))),
    div(
      h4("Plot Options"),
      #open = "closed",
      position = "right",
      bslib::accordion(
        bslib::accordion_panel(
          "Variables and Elements",
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
            strong("Combine estimate and CI"),
            materialSwitch("concatenate_est_ci", "", value = TRUE, status = "primary")
          ),
          conditionalPanel(
            condition = "input.significance == 1",
            strong("Combine estimate and significance symbol"),
            materialSwitch("concatenate_est_sig", "", value = FALSE, status = "primary")
          ),
          strong("Include significance symbol"),
          materialSwitch("significance", "", value = TRUE, status = "primary"),
          conditionalPanel(
            condition = "input.regression_type == 'cox'",
            strong("Plot inverse hazard ratio"),
            materialSwitch("inv", "", value = FALSE, status = "primary")
          )
        ),
        bslib::accordion_panel(
          "Plot Display Options",
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
          strong("Table background transparent"),
          materialSwitch("transparent_table_bg", "", value = TRUE, status = "primary"),
          conditionalPanel(
            condition = "input.transparent_table_bg==0",
            colourpicker::colourInput("table_bg_colour", "Table background colour"),
            strong("Striped background"),
            materialSwitch("striped_bg", "", value = FALSE, status = "primary"),
            conditionalPanel(
              condition = "input.striped_bg==1",
              colourpicker::colourInput("bg_stripe", "Stripe colour", value = "#EBEBEB")
            )
          ),
          strong("Plot background transparent"),
          materialSwitch("transparent_plot_bg", "", value = TRUE, status = "primary"),
          conditionalPanel(
            condition = "input.transparent_plot_bg==0",
            colourpicker::colourInput("plot_bg_colour", "Plot background colour")
          ),
          strong("Space between variables"),
          sliderInput("gaps", "", value = 0.8, min = 0.5, max = 2, step = 0.1, ticks = FALSE),
          strong("Indent of levels"),
          sliderInput("indent", "", value = 0.5, min = 0, max = 2, step = 0.1, ticks = FALSE),
          materialSwitch("sigfigs", "Use significant figures", value = FALSE, status = "primary"),
          numericInput("digits", "Number of decimal places", value = 2, min = 1, max = 5, step = 1),
          selectizeInput(
            "right_justify", "Right-justify variables", multiple = TRUE,
            choices = elements[-c(1,2,4)], selected = c())
        ),
        bslib::accordion_panel(
          "Plot Text Options",
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
    )
  )
)
