  ## DEC-005 — rail/drawer open-close state
  rv_drawer <- reactiveVal(NULL)

  ### DEC-005 Step 4 — output$files now lives inside the Data drawer panel,
  ### which is display:none until first opened. Without this, Shiny's
  ### suspend-when-hidden behaviour can skip rendering it while the panel is
  ### never visible (restyle plan §3 / §9).
  outputOptions(output, "files", suspendWhenHidden = FALSE)

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
