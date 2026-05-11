server <- function(input, output, session) {

  source(here::here("server", "upload.R"), local = TRUE)

  ### b - run regression
  #### i - fit regression
  fit <- reactive({
    req(isTruthy(input$dataset_selected == "sim"),
        isTruthy(length(input$predictor_vars) > 0))
    
    form <- paste0(" ~ ",
                   paste0(input$predictor_vars, collapse = " + "))
    if (input$regression_type == "poisson") {
      form2 <- as.formula(paste0(input$response_var, "_bin ", form))
      fit <- glm(form2,
                 family = "poisson"(link = "log"),
                 data = dat)
    } else if (input$regression_type == "logistic") {
      form2 <- as.formula(paste0(input$response_var, "_bin ", form))
      fit <- glm(form2,
                 family = "binomial"(link = "logit"),
                 data = dat)
    } else if (input$regression_type == "cox") {
      form2 <- as.formula(paste0("survival::Surv(",
                                 stringr::str_replace(input$response_var, "IND_", "Time_"),
                                 ",",input$response_var, "_bin) ", form))
      fit <- survival::coxph(form2,
                   data = dat)
    }
    fit
  }) %>%
    throttle(500)
  #### ii - combine into table
  predictors_selected <- reactive({
    req(input$predictor_vars)

    predictors_selected <- predictors[which(predictors %in% input$predictor_vars)]
    predictors_selected
  }) %>%
    debounce(1000)
  
  reg_table <- reactive({

    if (input$dataset_selected == "sim") {
      req(fit())

      forestHelperR::regTabler(
        fit = fit(),
        type = ifelse(!is.null(summary(fit())$family$family),
                      summary(fit())$family$family,"cox"),
        predictor = predictors_selected(),
        response = input$response_var,
        df = forestHelperR::dat,
        robust_variance_poisson = input$robust_variance,
        robust_variance_method = "HC0",
        inv_HR = input$inv)
    } else {
      req(data_updated())
      data_updated() %>%
        as.data.frame() %>%
        dplyr::select(-where(is.logical))
    }
  })
  
  ## step 3 - have table of data visible for checking
  ### a - uploaded data
  output$dat_upload <- DT::renderDataTable({
    req(data_updated())

    # ISS-021: (1) corrected LCI/UCI label order — was swapped (UCI then LCI)
    # relative to the actual column order in data_updated() (est, lci, uci).
    # (2) column label vector now built dynamically from colnames(data_updated())
    # so optional columns (n, p, significance) only contribute a label when
    # actually present, preventing a length mismatch error in DT::datatable().
    cols <- c("Variable", "Level", "Estimate", "LCI (95%CI)", "UCI (95%CI)")

    if ("n"            %in% colnames(data_updated())) cols <- c(cols, "n")
    if ("p"            %in% colnames(data_updated())) cols <- c(cols, "p")
    if ("significance" %in% colnames(data_updated())) cols <- c(cols, "Significance")

    if (input$by_group == TRUE & !is.null(input$group_var_name)) {
      cols <- append(cols, input$group_var_name)
    }
    
    if ("empty" %in% colnames(data_updated())) {
      remove <- c("displayname", "empty")
    } else {
      remove <- c("displayname")
    }
    
    temp <- data_updated() %>%
      dplyr::select(-all_of(remove)) %>%
      DT::datatable(rownames = FALSE,
                    colnames = cols,
                    options = list(dom = "pt")) %>%
      DT::formatRound(
        3:5,
        digits = 2)

    # Format optional columns by presence rather than input$*_name checks,
    # consistent with the dynamic cols vector above (ISS-021).
    if ("n" %in% colnames(data_updated())) {
      temp <- temp %>%
        DT::formatRound(6, mark = ",", digits = 0)
    }

    if ("p" %in% colnames(data_updated())) {
      temp <- temp %>%
        DT::formatRound(7, digits = 3)
    }

    temp
  })
  ### b - regression information
  #### i - regression output
  output$dat_summary <- DT::renderDataTable({
    req(input$dataset_selected == "sim")
    
    if (input$preview_type == "head") {
      dat %>%
        dplyr::select(input$response_var,
                      !!sym(stringr::str_replace(input$response_var, "IND", "Time")),
                      input$predictor_vars) %>%
        head(10) %>%
        DT::datatable(rownames = FALSE,
                      colnames =  c(names(responses[responses == input$response_var]),
                                    "Time-to-event or censor (months)",
                                    names(predictors[predictors %in% input$predictor_vars])),
                      options = list(pageLength = 10,
                                     dom = "t")) %>%
        DT::formatRound(columns = 2, mark = ",", digits = 1)
    } else {
      reg_table() %>%
        dplyr::select(-variable) %>%
        DT::datatable(rownames = FALSE,
                      colnames = c("Variable", "Level",
                                   case_when(input$regression_type == "poisson" ~ "RR",
                                             input$regression_type == "logistic" ~ "OR",
                                             input$regression_type == "cox"
                                             & !input$inv ~ "HR",
                                             input$regression_type == "cox"
                                             & input$inv ~ "1/HR"),
                                   "LCI (95%)", "UCI (95%)", "n", "p", "Significance"),
                      options = list(pageLength = nrow(reg_table()),
                                     dom = "t")) %>%
        DT::formatRound(columns = 3:5, mark = ",", digits = 1) %>%
        DT::formatRound(columns = 6, mark = ",", digits = 0) %>%
        DT::formatSignif(columns = 7, mark = ",", digits = 2)
    }
  })
  #### ii - regression details
  output$regression_details <- renderPrint({
    req(fit())
    
    summary(fit())
  })
  
  output$robust <- renderPrint({
    req(input$robust_variance, input$regression_type == 'poisson')
    
    table <- broom::tidy(fit(), conf.level = 0.95)
    ## NEW-001 fix: corrected vcov to vcov. (trailing dot) — lmtest::coeftest()
    ## and lmtest::coefci() require vcov. not vcov. Using vcov= was silently
    ## ignored, causing the preview to show non-robust standard errors.
    table[,c("std.error", "p.value")] <- lmtest::coeftest(
      fit(), df = Inf,
      vcov. = sandwich::vcovHC,
      type = "HC0")[, c("Std. Error", "Pr(>|z|)")]
    table[,c("lci", "uci")] <- lmtest::coefci(
      fit(),
      df = Inf,
      vcov. = sandwich::vcovHC,
      type = "HC0")
    table
  })
  
  ## step 4 - plot information
  # ### a - est_type text
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
  
  ### b - make plot
  forest_plot_object <- reactive({
    req(reg_table(), order(), input$variables_displayed) #make sure reg_table is done processing
    
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
  ### b - get dimensions
  dims <- reactive({
    req(forest_plot_object())
    
    expansion <- get_font_expansion(input$font)
    dims <- forestploter::get_wh(
      forest_plot_object(),
      unit = "in")
    
    dims[1] <- dims[1]*expansion
    dims
    
  })
  ### c - show plot
  observe({
    req(forest_plot_object())
    
    output$forest <- renderPlot({
      forest_plot_object()
    },
    width = dims()[1]*72*1.5,
    height = dims()[2]*72*1.5,
    res = 72*1.5)
  })
  
  ## step 5 - export image
  ### a - download png
  output$download_png <- downloadHandler(
    filename = "Forestplot.png",
    content = function(file) {
      ggsave(file,
             plot = forest_plot_object(),
             device = "png",
             bg = ifelse(input$transparent_plot_bg,
                         "transparent",
                         input$plot_bg_colour),
             width = dims()[1]*1.1,
             height = dims()[2],
             units = "in",
             dpi = 144)
    })
  ### download svg
  output$download_svg <- downloadHandler(
    filename = "Forestplot.svg",
    content = function(file) {
      ggsave(
        file,
        plot = forest_plot_object(),
        device = "svg",
        bg = ifelse(input$transparent_plot_bg,
                    "transparent",
                    input$plot_bg_colour),
        width = dims()[1]*1.1,
        height = dims()[2])
    })
  
  ### c - R code serialiser
  r_code_string <- reactive({
    req(reg_table())

    x_ticks_str    <- serialise_x_ticks(input$xticks, input$xlims)
    plot_title_str <- serialise_plot_title(input$plot_title)
    by_var_str     <- serialise_by_var(input$by_group, input$group_var_name)
    vars_excl_str  <- serialise_chr_vec(variables_excluded())
    elements_str   <- serialise_chr_vec(order())
    xlims_str      <- paste0("c(", paste(input$xlims, collapse = ", "), ")")
    by_col_str     <- paste0('c("', input$ci_colour, '", "', input$ci_colour2, '")')
    rj_str         <- serialise_chr_vec(input$right_justify)
    bg_stripe_str  <- serialise_bg_stripe(input$striped_bg, input$bg_stripe)
    footnote_str   <- serialise_footnote(input$plot_footnote)

    paste0(
      'forestHelperR::forestPloter(\n',
      '  table                    = your_data,\n',
      '  est_text                 = "', est_type(), '",\n',
      '  plot_width               = ', input$plotting_width, ',\n',
      '  x_lims                   = ', xlims_str, ',\n',
      '  variables_excluded       = ', vars_excl_str, ',\n',
      '  x_axis_text              = "', input$xaxis_text, '",\n',
      '  x_axis_ticks             = ', x_ticks_str, ',\n',
      '  by_var                   = ', by_var_str, ',\n',
      '  by_var_colours           = ', by_col_str, ',\n',
      '  font                     = "', input$font, '",\n',
      '  font_size                = ', input$base_size, ',\n',
      '  font_colour              = "', input$base_font_colour, '",\n',
      '  variable_font_face       = "', input$variable_font_face, '",\n',
      '  variable_font_colour     = "', input$variable_font_colour, '",\n',
      '  p_value_font_face        = "', input$pval_font_face, '",\n',
      '  plot_title               = ', plot_title_str, ',\n',
      '  plot_title_wrap          = ', input$plot_title_wrap, ',\n',
      '  plot_title_centre        = ', input$plot_title_centre, ',\n',
      '  footnote                 = ', footnote_str, ',\n',
      '  footnote_long            = ', input$long_footnote, ',\n',
      '  footnote_wrap            = ', input$footnote_wrap, ',\n',
      '  table_background_transparent = ', input$transparent_table_bg, ',\n',
      '  table_background         = "', input$table_bg_colour, '",\n',
      '  plot_background_transparent = ', input$transparent_plot_bg, ',\n',
      '  plot_background          = "', input$plot_bg_colour, '",\n',
      '  bg_stripe                = ', bg_stripe_str, ',\n',
      '  ci_colour                = "', input$ci_colour, '",\n',
      '  reference_colour         = "', input$reference_colour, '",\n',
      '  digits                   = ', input$digits, ',\n',
      '  sigfigs                  = ', input$sigfigs, ',\n',
      '  displayname_label_height = ', input$gaps, ',\n',
      '  indent                   = ', input$indent, ',\n',
      '  elements                 = ', elements_str, ',\n',
      '  right_justify            = ', rj_str, ',\n',
      '  n_display                = "', input$n_display, '",\n',
      '  concatenate_est_ci       = ', input$concatenate_est_ci, ',\n',
      '  concatenate_est_sig      = ', input$concatenate_est_sig, ',\n',
      '  significance_symbol      = ', input$significance, '\n',
      ')'
    )
  })

  observeEvent(input$copy_r_code, {
    tryCatch({
      clipr::write_clip(r_code_string())
      shiny::showNotification("R code copied to clipboard.", type = "message")
    }, error = function(e) {
      shiny::showNotification(
        "Could not copy to clipboard — clipboard unavailable on this server.",
        type = "warning"
      )
    })
  })

  output$download_r_code <- downloadHandler(
    filename = "forestplot_code.R",
    content = function(file) {
      writeLines(r_code_string(), file)
    }
  )

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
  ### e - if estimate or CI deselected, unset concatenate_est_ci
  observe({
    if (!("est" %in% (input$elements)) | !("lci" %in% (input$elements))) {
      updateMaterialSwitch(session,
                           inputId = "concatenate_est_ci",
                           value = FALSE)
    }
  }) %>%
    bindEvent(input$elements)
  ### f - select order and/or elements to include
  order <- reactive({
    
    if (input$reorder) {
      unname(elements[match(input$order, names(elements))])
    } else {
      input$elements %>%
        append("blank", after = 1)
    }
  }) %>%
    bindEvent(input$reorder, input$elements, input$order)
  ### g - when significance deselected
  observe ({
    if(!input$significance) {
      updateMaterialSwitch(
        session,
        "concatenate_est_sig",
        value = FALSE
      )
    }
  }) %>%
    bindEvent(input$significance)
  
  observe({
    if (input$sigfigs) {
      updateNumericInput(inputId = "digits", label = "Number of significant figures")
    } else {
      updateNumericInput(inputId = "digits", label = "Number of decimal places")
    }
  }) %>%
    bindEvent(input$sigfigs)

}
