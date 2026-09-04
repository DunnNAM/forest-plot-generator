  ## DEC-005 — rail/drawer open-close state
  rv_drawer <- reactiveVal(NULL)

  ### DEC-005 Steps 4-5 — output$files (Data panel), output$sortable_cols
  ### (Order panel), and the two download outputs (Export panel) now live
  ### inside drawer panels that are display:none until first opened. Without
  ### this, Shiny's suspend-when-hidden behaviour leaves downloadButtons
  ### rendered disabled with an empty href — confirmed directly: both
  ### download_plot and the pre-existing, unmodified download_r_code showed
  ### class="disabled" / href="" until this fix (restyle plan §3 / §9).
  outputOptions(output, "files", suspendWhenHidden = FALSE)
  outputOptions(output, "sortable_cols", suspendWhenHidden = FALSE)
  outputOptions(output, "download_plot", suspendWhenHidden = FALSE)
  outputOptions(output, "download_r_code", suspendWhenHidden = FALSE)
  # output$xticks_ui (Display panel, 2026-09-04 follow-up) — same reason as
  # the others: it's a renderUI() inside a normally-hidden drawer panel, and
  # needs to actually render (so input$xticks exists) even before the user
  # opens Display.
  outputOptions(output, "xticks_ui", suspendWhenHidden = FALSE)

  ### a - rail click: toggle semantics (clicking the open key closes it)
  #
  # Also anchors the main body tab to whichever drawer is open (FEAT-011
  # follow-up, 2026-09-04 user request, revised same day): Review data is
  # only useful while the Data drawer is the thing being edited, so opening
  # any other drawer switches the main body to Plot, and — per the revision —
  # returning to the Data drawer switches it back to Review data. Only fires
  # on opening a drawer, not on closing one (the close branch below): closing
  # a drawer via the rail (clicking its already-open key) leaves whichever
  # main tab is currently showing alone, since there's no drawer left to
  # anchor it to.
  observeEvent(input$rail_key, {
    current <- rv_drawer()
    key <- input$rail_key

    if (!is.null(current) && identical(current, key)) {
      rv_drawer(NULL)
    } else {
      rv_drawer(key)
      bslib::nav_select("main_tabs",
                        selected = if (identical(key, "data")) "Review data" else "Plot",
                        session = session)
    }
  })

  ### b - scrim click closes the drawer
  observeEvent(input$drawer_close, {
    rv_drawer(NULL)
  })

  ### c - push open/close + active key to the client
  observe({
    key <- rv_drawer()

    session$sendCustomMessage("drawer-open", list(
      drawerId = "filter-drawer",
      scrimId  = "drawer-scrim",
      open     = !is.null(key),
      key      = if (is.null(key)) "" else key
    ))
  })

  ## FEAT-010 (DEC-005 Step 7) — status-chip strip + rail badges. Additive:
  ## no existing input ID or reactive touched. Every input read below is a
  ## drawer-panel input, live in the DOM from app start (§3 of the restyle
  ## plan), so none of this needs req() gates the way data-derived reactives
  ## (fit(), reg_table()) do.

  ### d - status chip click: always opens its drawer (not a toggle, unlike
  ### the rail buttons themselves — a chip is a shortcut to a setting, not
  ### an open/close control for a drawer that's probably already closed).
  ### Same Plot-tab switch as the rail click above (FEAT-011 follow-up,
  ### 2026-09-04, revised same day) — a chip is just another way to open a
  ### drawer, so it anchors the main tab exactly like the rail click above.
  observeEvent(input$chip_open_key, {
    key <- input$chip_open_key
    rv_drawer(key)
    bslib::nav_select("main_tabs",
                      selected = if (identical(key, "data")) "Review data" else "Plot",
                      session = session)
  })

  ### e - chip strip content
  output$status_chips <- renderUI({
    chip <- function(key, label, value) {
      tags$button(
        type = "button",
        class = "filter-chip",
        onclick = sprintf("Shiny.setInputValue('chip_open_key', '%s', {priority: 'event'})", key),
        tags$strong(label), value
      )
    }

    dataset_label <- if (identical(input$dataset_selected, "sim")) {
      "Simulated data"
    } else {
      "Regression output"
    }

    regression_label <- switch(input$regression_type,
      poisson  = "Poisson",
      logistic = "Logistic",
      cox      = "Cox PH",
      input$regression_type
    )

    predictors_value <- if (identical(input$dataset_selected, "sim")) {
      length(input$predictor_vars)
    } else {
      tryCatch(length(unique(reg_table()$displayname)), error = function(e) NA)
    }

    div(
      class = "filter-chips",
      span(class = "chips-label", "Current setup"),
      chip("data", "Data: ", dataset_label),
      chip("data", "Regression: ", regression_label),
      if (!is.na(predictors_value)) chip("variables", "Variables: ", predictors_value),
      chip("text", "Font: ", input$font)
    )
  })

  ### f - rail badge: Variables — count of variables hidden from the plot
  output$rail_badge_variables <- renderUI({
    req(reg_table())

    total <- length(unique(reg_table()$displayname))
    hidden <- total - length(input$variables_displayed)

    if (isTRUE(hidden > 0)) {
      tags$span(class = "rail-badge", hidden)
    }
  })

  ### g - rail badge: Display — dot when any display setting is non-default
  ### right_justify's check fixed 2026-09-04 (sixth follow-up, user report):
  ### this compared against the *original* default (empty), but the actual
  ### default changed to c("n") earlier the same session (right-justify
  ### Counts by default) — `length(...) > 0` was true for that default too,
  ### so the badge showed a permanent false positive on Display regardless
  ### of whether the user had actually changed anything. Compares against
  ### the real current default instead. digits/sigfigs weren't touched here
  ### since their own defaults (2, FALSE) are unchanged — sigfigs is now
  ### hidden from the UI entirely (see R/ui_plot_options.R) but stays a real
  ### bound input fixed at FALSE, so this check still holds.
  output$rail_badge_display <- renderUI({
    non_default <- any(
      input$plotting_width != 120,
      input$ci_colour != "#444444",
      input$reference_colour != "#C43D4D",
      isFALSE(input$transparent_table_bg),
      isFALSE(input$transparent_plot_bg),
      input$gaps != 0.8,
      input$indent != 0.5,
      isTRUE(input$sigfigs),
      input$digits != 2,
      !setequal(input$right_justify, c("n"))
    )

    if (isTRUE(non_default)) {
      tags$span(class = "rail-badge dot")
    }
  })
