  ## step 4 - plot information
  ### a - est_type and excluded variables
  est_type <- reactive({
    get_est_type(input$regression_type, input$inv)
  }) %>%
    bindEvent(input$regression_type, input$inv)

  variables_excluded <- reactive({

    temp <- setdiff(
      as.character(unique(reg_table()$displayname)),
      input$variables_displayed)

    if (length(temp) == 0) {c()} else {temp}
  }) %>%
    bindEvent(input$predictor_vars, input$variables_displayed)

  ### b - column order (consumed by forest_plot_object and r_code_string)
  order <- reactive({

    if (input$reorder) {
      unname(elements[match(input$order, names(elements))])
    } else {
      input$elements %>%
        append("blank", after = 1)
    }
  }) %>%
    bindEvent(input$reorder, input$elements, input$order)

  ### c - make plot
  forest_plot_object <- reactive({
    req(reg_table(), order(), input$variables_displayed)

    p <- forestHelperR::forestPloter(
      table = reg_table(),
      est_text = est_type(),
      plot_width = input$plotting_width,
      x_lims = input$xlims,
      variables_excluded = variables_excluded(),
      x_axis_text = input$xaxis_text,
      x_axis_ticks = if (length(input$xticks[between(input$xticks, min(input$xlims), max(input$xlims))]) != 0) {input$xticks} else {NULL},
      by_var = ifelse(input$by_group, input$group_var_name, NA),
      by_var_colours = c(input$ci_colour, input$ci_colour2),
      font = input$font,
      font_size = input$base_size,
      font_colour = input$base_font_colour,
      variable_font_face = input$variable_font_face,
      variable_font_colour = input$variable_font_colour,
      p_value_font_face = input$pval_font_face,
      plot_title = if (input$plot_title == "") {NULL} else {input$plot_title},
      plot_title_wrap = input$plot_title_wrap,
      plot_title_centre = input$plot_title_centre,
      footnote = input$plot_footnote,
      footnote_long = input$long_footnote,
      footnote_wrap = input$footnote_wrap,
      table_background_transparent = input$transparent_table_bg,
      table_background = input$table_bg_colour,
      plot_background_transparent = input$transparent_plot_bg,
      plot_background = input$plot_bg_colour,
      bg_stripe = ifelse(input$striped_bg, input$bg_stripe, NA),
      ci_colour = input$ci_colour,
      reference_colour = input$reference_colour,
      digits = input$digits,
      sigfigs = input$sigfigs,
      displayname_label_height = input$gaps,
      indent = input$indent,
      elements = order(),
      right_justify = input$right_justify,
      n_display = input$n_display,
      concatenate_est_ci = input$concatenate_est_ci,
      concatenate_est_sig = input$concatenate_est_sig,
      significance_symbol = input$significance)

    p

  }) %>%
    debounce(1000)

  ### d - get dimensions
  dims <- reactive({
    req(forest_plot_object())

    expansion <- get_font_expansion(input$font)
    dims <- forestploter::get_wh(
      forest_plot_object(),
      unit = "in")

    dims[1] <- dims[1]*expansion
    dims

  })

  ### e - show plot
  observe({
    req(forest_plot_object())

    output$forest <- renderPlot({
      forest_plot_object()
    },
    width = dims()[1]*72*1.5,
    height = dims()[2]*72*1.5,
    res = 72*1.5)
  })

  ### f - if estimate or CI deselected, unset concatenate_est_ci
  observe({
    if (!("est" %in% (input$elements)) | !("lci" %in% (input$elements))) {
      updateMaterialSwitch(session,
                           inputId = "concatenate_est_ci",
                           value = FALSE)
    }
  }) %>%
    bindEvent(input$elements)

  ### g - when significance deselected, unset concatenate_est_sig
  observe({
    if(!input$significance) {
      updateMaterialSwitch(
        session,
        "concatenate_est_sig",
        value = FALSE
      )
    }
  }) %>%
    bindEvent(input$significance)
