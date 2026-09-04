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

  ### a - client says whether this is a first visit (www/wizard.js,
  ### localStorage check). TRUE (first visit): show the welcome modal, as
  ### before. FALSE (returning user, 2026-09-04 follow-up, user request):
  ### skip the modal, but open the Data drawer by default rather than landing
  ### with no drawer open at all — Review data being the default main tab
  ### already falls out of navset_card_tab()'s own first-panel default, so
  ### this just gives that default tab a matching default drawer. Sets
  ### rv_drawer() directly rather than going through the rail-click path in
  ### server/drawers.R, so it does *not* trigger that path's Plot-tab
  ### anchoring — Review data stays the active main tab, as intended.
  observeEvent(input$wizard_should_show, {
    if (isTRUE(input$wizard_should_show)) {
      if (rv_wizard_step() == 0L) {
        rv_wizard_step(1L)
        shiny::showModal(wizardWelcomeModal())
      }
    } else {
      rv_drawer("data")
    }
  })

  ### b - "Start" on the welcome modal: open Data, then wait for real data
  observeEvent(input$wizard_start, {
    shiny::removeModal()
    rv_drawer("data")
  })

  ### b2 - "Proceed to plot styling" on the welcome modal (2026-09-04
  ### follow-up, user request): for someone happy with the example Simulated
  ### data already loaded — skips both wizard steps rather than making them
  ### click through a "Variables ready" modal for data they didn't just
  ### choose. Opens Display (not Data or Variables) since that's what
  ### "styling" refers to, and anchors the main tab to Plot itself —
  ### finish_wizard() alone wouldn't touch either, and rv_drawer("data") in
  ### §a above deliberately skips the tab anchor for the *returning-user*
  ### case, which doesn't apply here.
  observeEvent(input$wizard_proceed_styling, {
    finish_wizard()
    rv_drawer("display")
    bslib::nav_select("main_tabs", selected = "Plot", session = session)
  })

  ### c - auto-advance: once a plot-worthy table exists *as a result of the
  ### user changing something in the Data panel* while awaiting data.
  ### reg_table() throws a silent req()-style condition when nothing is
  ### uploaded/selected yet (server/regression.R) — caught here the same way
  ### the FEAT-010 status chips do it, so this observer doesn't error out
  ### while waiting.
  ###
  ### bindEvent()'d to the Data-panel inputs specifically (2026-09-04
  ### follow-up — real bug found while adding the default-load-state change):
  ### a plain observe() reading reg_table() re-fires on *any* reactive flush,
  ### including the very first one after "Start" is clicked — and since the
  ### app now defaults to Simulated data with a valid response/predictor
  ### selection already made, reg_table() was already valid at that first
  ### flush, so the welcome modal was replaced by the Variables modal almost
  ### instantly, before the user had done anything (confirmed via a
  ### shinytest2 "duplicate wizard_skip id" warning — both modals' footers
  ### were briefly in the DOM at once). Gating on an actual change to one of
  ### these inputs means step 1 only ever advances because of something the
  ### user did after entering it, not because the defaults already qualified.
  observe({
    req(rv_wizard_step() == 1L)

    ready <- tryCatch(!is.null(reg_table()), error = function(e) FALSE)

    if (isTRUE(ready)) {
      rv_wizard_step(2L)
      rv_drawer("variables")
      shiny::showModal(wizardVariablesModal())
    }
  }) %>%
    bindEvent(input$dataset_selected, input$upload, input$response_var,
             input$predictor_vars, input$regression_type,
             ignoreInit = TRUE)

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
