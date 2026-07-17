  ## Misc
  ### a - update selected plotted variables based on regression variables
  observe({
    req(reg_table())

    variables <- unique(reg_table()$displayname)

    updateCheckboxGroupInput(
      session,
      "variables_displayed",
      choices = variables,
      selected = variables
    )
  })
  ### b - update order based on selected columns
  output$sortable_cols <- renderUI({
    req(input$reorder)

    options_cols <- input$elements %>%
      append("blank", after = 1)

    names <- elements[c(3,4,5,6,7)]

    to_remove <- setdiff(names, options_cols)

    if (length(to_remove) > 0) {
      names <- names[-which(names %in% to_remove)]
    }

    sortable::rank_list(
      input_id = "order",
      labels = names(names),
      orientation = "horizontal")
  })
  ### d - update by_group if more than one file uploaded
  observe({
    req(input$upload)

    if (nrow(input$upload) > 1) {
      updateMaterialSwitch(session,
                           inputId = "by_group",
                           value = TRUE)
    }

    if (length(input$group_var) > 0) {
      updateMaterialSwitch(session,
                           inputId = "by_group",
                           value = TRUE)
    }
  })
  ### e - sigfigs label toggle
  observe({
    if (input$sigfigs) {
      updateNumericInput(inputId = "digits", label = "Number of significant figures")
    } else {
      updateNumericInput(inputId = "digits", label = "Number of decimal places")
    }
  }) %>%
    bindEvent(input$sigfigs)
