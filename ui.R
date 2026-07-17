
ui <- page_navbar(
  title = "Forest Plot Builder",
  theme = theme,
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css?v=dec005-2"),
    tags$script(src = "drawer.js")
  ),
  nav_panel(
    "Builder",
    div(
      class = "dashboard-body",
      div(
        class = "content-area",
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
            fluidRow(plotOutput("forest")))
        )
      ),
      drawerUI(),
      railUI()
    )
  )
)
