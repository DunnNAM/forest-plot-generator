  ## DEC-005 — rail/drawer open-close state
  rv_drawer <- reactiveVal(NULL)

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
