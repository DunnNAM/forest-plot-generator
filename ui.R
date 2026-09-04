
ui <- page_navbar(
  title = "Forest Plot Builder",
  theme = theme,
  # fillable = FALSE (2026-09-04, user request/review): page_navbar()
  # defaults to TRUE, which makes bslib's card JS (data-bslib-card-init)
  # measure available viewport space and set an explicit pixel height on
  # navset_card_tab's card, scrolling its content internally rather than
  # letting the card grow — on a high-res display this left dead space below
  # the card when the plot was shorter than the fill-computed height, and
  # forced an inner scrollbar on the plot itself when it was taller.
  # Disabling fill lets the card take its natural content height and the
  # browser scroll the page normally instead — either way the user scrolls
  # somewhere once the plot exceeds the viewport, so there's no version of
  # this without scrolling; window-level scrolling is just the better one.
  # Safe to disable globally: the rail and drawer (railUI()/drawerUI()) are
  # pinned with plain CSS `position: fixed`, not bslib's fill system, so
  # neither depends on this.
  fillable = FALSE,
  header = tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "style.css?v=feat011-10"),
    tags$script(src = "drawer.js"),
    tags$script(src = "wizard.js")
  ),
  nav_panel(
    "Builder",
    div(
      class = "dashboard-body",
      div(
        class = "content-area",
        uiOutput("status_chips"),
        # id lets server/drawers.R drive this tabset programmatically
        # (bslib::nav_select) — added FEAT-011 follow-up, 2026-09-04, so
        # opening any drawer other than Data switches the main body to Plot.
        navset_card_tab(
          id = "main_tabs",
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
            # fill = FALSE, height left at plotOutput()'s own default
            # (2026-09-04, user request/follow-up): passing height = "auto"
            # here (a first attempt) broke Shiny's own client-side plot-
            # resize JS — confirmed by inspecting the actual rendered <img>
            # tag, which came back with a literal height="[object Object]"
            # attribute instead of a real value, so the browser fell back to
            # the image's raw intrinsic pixel height while width stayed
            # forced to 100%, stretching it unevenly (the reported "zoomed
            # in, lost clarity" symptom). The fixed 400px container height
            # this leaves in the HTML is overridden purely in CSS instead
            # (www/style.css, .content-area .bslib-card selector block,
            # extended to include .shiny-plot-output) — that doesn't touch
            # Shiny's JS at all, so it can't trigger the same bug. fill =
            # FALSE on its own is unrelated to the bug and still wanted, to
            # keep this output out of bslib's fill-item system.
            fluidRow(plotOutput("forest", fill = FALSE)))
        )
      ),
      drawerUI(),
      railUI()
    )
  ),
  nav_panel(
    "Help",
    helpPanelUI()
  )
)
