# Setup wizard modal content — design/modal-progression-workflow experiment
# (FEAT-011, not yet accepted as a decision). Two required-step modals:
# welcome (Data) and confirm (Variables). Deliberately instructional, not a
# duplicate copy of the real controls: DEC-005 already made the case against
# duplicating any of the ~45 live plot-option inputs (restyle plan §3), and a
# modal-embedded copy of e.g. dataset_selected would be exactly that. Each
# modal instead tells the user what to do and the server opens the matching
# drawer for them (server/wizard.R) — one live input, guided from two places.
wizardWelcomeModal <- function() {
  shiny::modalDialog(
    title = "Let's build your first plot",
    p("This app has two required steps, then four optional refinements you",
      " can explore in any order from the rail at the bottom of the screen."),
    tags$ol(
      tags$li(strong("Data"), " — choose or upload the regression output to plot."),
      tags$li(strong("Variables"), " — choose which variables and elements to show.")
    ),
    p("Once those are set you're free to explore ", strong("Display"), ", ",
      strong("Text"), ", ", strong("Order"), " and ", strong("Export"),
      " whenever you like — there's no fixed order after that."),
    footer = tagList(
      actionButton("wizard_skip", "Skip tour"),
      actionButton("wizard_start", "Start: choose data →", class = "btn-primary")
    ),
    easyClose = FALSE
  )
}

wizardVariablesModal <- function() {
  shiny::modalDialog(
    title = "Your data is ready",
    p("Now choose which variables and elements appear in the plot. Everything",
      " is pre-selected, so you only need to change what you don't want."),
    p("Open ", strong("Variables"), " on the rail below to adjust, then come",
      " back here when you're happy — or just close this and carry on."),
    footer = tagList(
      actionButton("wizard_skip", "Skip tour"),
      actionButton("wizard_finish", "Finish setup", class = "btn-primary")
    ),
    easyClose = FALSE
  )
}
