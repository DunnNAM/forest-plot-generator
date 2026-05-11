
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
              style="display:inline-block; margin-right: 10px;",
              downloadButton("download_svg", "Download svg", icon = icon("file-export"))),
            div(
              style="display:inline-block; margin-right: 10px;",
              actionButton("copy_r_code", "Copy R code", icon = icon("copy"))),
            div(
              style="display:inline-block;",
              downloadButton("download_r_code", "Download .R script")))),
        fluidRow(
          column(
            6,
            strong("Reorder columns"),
            checkboxInput("reorder", "", value = FALSE),
            conditionalPanel(condition = "input.reorder==1", uiOutput("sortable_cols")))),
        fluidRow(plotOutput("forest")))),
    plotOptionsUI()
  )
)
