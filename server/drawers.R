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

  ### a - rail click: toggle semantics (clicking the open key closes it)
  observeEvent(input$rail_key, {
    current <- rv_drawer()
    key <- input$rail_key

    if (!is.null(current) && identical(current, key)) {
      rv_drawer(NULL)
    } else {
      rv_drawer(key)
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
