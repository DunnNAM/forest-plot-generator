  ## Setup wizard — design/modal-progression-workflow experiment (FEAT-011,
  ## not yet accepted as a decision). Purely additive UI guidance layered on
  ## top of the DEC-005 rail/drawer: it never gates or duplicates any of the
  ## ~45 live plot-option inputs (restyle plan §3) — it only opens the right
  ## drawer at the right moment via rv_drawer (server/drawers.R, sourced
  ## first) and tracks a step counter.
  ##   0 = dismissed/done · 1 = awaiting data · 2 = awaiting variables review
  rv_wizard_step <- reactiveVal(0L)

  finish_wizard <- function() {
    rv_wizard_step(0L)
    shiny::removeModal()
    session$sendCustomMessage("wizard-seen", list())
  }

  ### a - client says this is a first visit (www/wizard.js, localStorage check)
  observeEvent(input$wizard_should_show, {
    if (rv_wizard_step() == 0L) {
      rv_wizard_step(1L)
      shiny::showModal(wizardWelcomeModal())
    }
  })

  ### b - "Start" on the welcome modal: open Data, then wait for real data
  observeEvent(input$wizard_start, {
    shiny::removeModal()
    rv_drawer("data")
  })

  ### c - auto-advance: once a plot-worthy table exists while awaiting data.
  ### reg_table() throws a silent req()-style condition when nothing is
  ### uploaded/selected yet (server/regression.R) — caught here the same way
  ### the FEAT-010 status chips do it, so this observer doesn't error out
  ### while waiting.
  observe({
    req(rv_wizard_step() == 1L)

    ready <- tryCatch(!is.null(reg_table()), error = function(e) FALSE)

    if (isTRUE(ready)) {
      rv_wizard_step(2L)
      rv_drawer("variables")
      shiny::showModal(wizardVariablesModal())
    }
  })

  ### d - "Finish setup" on the variables modal
  observeEvent(input$wizard_finish, {
    finish_wizard()
  })

  ### e - "Skip tour" from either modal
  observeEvent(input$wizard_skip, {
    finish_wizard()
  })

  ### f - "Restart tour" from the Help panel — for a user returning after a
  ### while, per the design discussion (session 2026-09-04).
  observeEvent(input$wizard_restart, {
    rv_wizard_step(1L)
    shiny::showModal(wizardWelcomeModal())
  })
