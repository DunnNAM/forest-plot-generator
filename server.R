server <- function(input, output, session) {
  
  ## step 1 - get data (data upload)
  ### i - get file directory and import
  data_uploaded <- reactive({
    req(input$upload, input$dataset_selected == "upload")
    
    if (nrow(input$upload) == 1) {
      ext <- tools::file_ext(input$upload$name)
      switch(
        ext,
        xlsx = readxl::read_xlsx(input$upload$datapath, trim_ws = TRUE),
        xls = readxl::read_xls(input$upload$datapath, trim_ws = TRUE),
        csv = vroom::vroom(input$upload$datapath, delim = ",",
                           show_col_types = FALSE),
        tsv = vroom::vroom(input$upload$datapath, delim = "\t",
                           show_col_types = FALSE),
        txt = vroom::vroom(input$upload$datapath, delim = ",",
                           show_col_types = FALSE),
        validate("Invalid file: please upload a .csv, .tsv or .txt file")) %>%
        dplyr::mutate(empty = NA)
    } else {
      ## ISS-003 fix: replaced for-loop (uninitialised temp, unindexed datapath,
      ## incorrect bind_rows accumulation) with lapply + dplyr::bind_rows.
      lapply(seq_len(nrow(input$upload)), function(i) {
        ext <- tools::file_ext(input$upload$name[i])
        switch(
          ext,
          xlsx = readxl::read_xlsx(input$upload$datapath[i], trim_ws = TRUE),
          xls  = readxl::read_xls(input$upload$datapath[i], trim_ws = TRUE),
          csv  = vroom::vroom(input$upload$datapath[i], delim = ",",
                              show_col_types = FALSE),
          tsv  = vroom::vroom(input$upload$datapath[i], delim = "\t",
                              show_col_types = FALSE),
          txt  = vroom::vroom(input$upload$datapath[i], delim = ",",
                              show_col_types = FALSE),
          validate("Invalid file: please upload a .csv, .tsv or .txt file")
        ) %>%
          dplyr::mutate(Group = i,
                        empty = NA)
      }) %>%
        dplyr::bind_rows()
    }
  })
  ### ii - check
  output$files <- DT::renderDataTable({
    req(input$upload)
    
    input$upload %>%
      dplyr::select(-datapath) %>%
      DT::datatable(rownames = FALSE,
                    colnames = c("File", "Size", "Type"),
                    options = list(dom = "t"))
  })
  
  ## step 2 - get in format required for plotting
  ### a - for uploaded data
  #### i - selecting correct colnames
  ## column names to choose from (ui updates from here)
  output$sortable <- renderUI({
    req(data_uploaded(), input$upload)
    
    colnames_upload <- colnames(data_uploaded())
    
    div(
      sortable::bucket_list(
        header = "If column labels vary, reassign column names below by dragging and dropping tiles.",
        orientation = "horizontal",
        group_name = "variable_labels_group",
        add_rank_list(
          input_id = "variable_name",
          text = "Variable",
          labels = ifelse(length(colnames_upload) >= 1,
                          colnames_upload[1],"empty")),
        add_rank_list(
          input_id = "level_name",
          text = "Level",
          labels =  ifelse(length(colnames_upload) >= 2,
                           colnames_upload[2],"empty")),
        add_rank_list(
          input_id = "estimate_name",
          text = "Estimate",
          labels =  ifelse(length(colnames_upload) >= 3,
                           colnames_upload[3],"empty")),
        add_rank_list(
          input_id = "lci_name",
          text = "Lower CI",
          labels =  ifelse(length(colnames_upload) >= 4,
                           colnames_upload[4],"empty")),
        add_rank_list(
          input_id = "uci_name",
          text = "Upper CI",
          labels =  ifelse(length(colnames_upload) >= 5,
                           colnames_upload[5],"empty")),
        add_rank_list(
          input_id = "n_name",
          text = "Count",
          labels =  ifelse(length(colnames_upload) >= 6,
                           colnames_upload[6],"empty")),
        add_rank_list(
          input_id = "p_name",
          text = "p-value",
          labels =  ifelse(length(colnames_upload) >= 7,
                           colnames_upload[7],"empty")),
        add_rank_list(
          input_id = "significance_name",
          text = "Significance",
          labels =  ifelse(length(colnames_upload) >= 8,
                           colnames_upload[8],"empty")),
        add_rank_list(
          input_id = "bin",
          text = "Not required",
          labels =  ifelse(length(colnames_upload) >= 9,
                           colnames_upload[9:length(colnames_upload)],
                           "empty")),
        add_rank_list(
          input_id = "group_var",
          text = "Group variable")
      ),
      div(
        class = "col-3",
        actionButton("cols", "Confirm column names")))
  })

  #### ii - column confirmation gate (ISS-020)
  # A reactiveVal counter is used instead of binding directly to input$cols.
  # This allows the confirmation to be explicitly reset when a new file is
  # uploaded, preventing the previous column mapping from silently applying
  # to new data before the user re-confirms.
  cols_confirmed <- reactiveVal(0)

  observeEvent(input$cols, {
    cols_confirmed(cols_confirmed() + 1)
  })

  observeEvent(input$upload, {
    cols_confirmed(0)
  })

  #### iii - selecting cols and cleaning data
  data_updated <- reactive({
    req(data_uploaded())
    # ISS-020: explicitly require confirmation has occurred since the last file
    # upload. cols_confirmed() is reset to 0 by observeEvent(input$upload),
    # so this req() suspends the reactive cleanly until the user re-confirms
    # the column mapping for the new file.
    req(cols_confirmed() > 0)
    
    validate(
      need(
        length(input$variable_name) != 0,
        "Please ensure a character variable column is provided."),
      need(
        input$variable_name[1] != "empty" ,
        "Please ensure a character variable column is provided."),
      need(
        length(input$level_name) != 0,
        "Please ensure a character level column is provided."),
      need(
        input$level_name[1] != "empty" ,
        "Please ensure a character level column is provided."),
      need(
        length(input$estimate_name) != 0,
        "Please ensure a character estimate column is provided."),
      need(
        input$estimate_name[1] != "empty" ,
        "Please ensure a character estimate column is provided."),
      need(
        length(input$lci_name) != 0,
        "Please ensure a character lower confidence interval column is provided."),
      need(
        input$lci_name[1] != "empty" ,
        "Please ensure a character lower confidence interval column is provided."),
      need(
        length(input$uci_name) != 0,
        "Please ensure a character upper confidence interval column is provided."),
      need(
        input$uci_name[1] != "empty" ,
        "Please ensure a character upper confidence interval column is provided."))
    
    
    rename_vec <- c(
      "displayname" = input$variable_name,
      "level" = input$level_name,
      "est" = input$estimate_name,
      "lci" = input$lci_name,
      "uci" = input$uci_name,
      "n" = input$n_name,
      "p" = input$p_name,
      "significance" = input$significance_name)
    
    n_included <- if (length(input$n_name) == 0) {
      FALSE
    } else if (input$n_name[1] == "empty") {
      FALSE
    } else {
      TRUE
    }
    p_included <- if (length(input$p_name) == 0) {
      FALSE
    } else if (input$p_name[1] == "empty") {
      FALSE
    } else {
      TRUE
    }
    significance_included <- if (length(input$significance_name) == 0) {
      FALSE
    } else if (input$significance_name[1] == "empty") {
      FALSE
    } else {
      TRUE
    }
    
    temp2 <- data_uploaded() %>%
      dplyr::select(
        any_of(rename_vec),
        "variable" = input$variable_name) %>%
      dplyr::select(displayname, variable, everything()) %>%
      dplyr::mutate(
        across(c("variable", "displayname", "level"), ~forcats::fct_inorder(.)),
        across(c("est", "lci", "uci"), ~as.numeric(.)))
    
    if (n_included) {
      temp2 <- temp2 %>%
        dplyr::mutate(
          n = as.numeric(n))
    }
    if (p_included) {
      temp2 <- temp2 %>%
        dplyr::mutate(
          p = as.numeric(p))
    }
    if (significance_included) {
      temp2 <- temp2 %>%
        dplyr::mutate(
          significance = case_when(
            is.na(significance) ~ "",
            TRUE ~ significance))
    }
    
    if (input$by_group) {
      if (length(input$group_var) > 0) {
        if (input$group_var_values != "" & input$group_var_name != "") {
          if (nrow(input$upload) == 1) {
            temp_values <- stringr::str_split_1(input$group_var_values, "\\s?,\\s?")
            temp2 <- temp2 %>%
              dplyr::rename("{input$group_var_name}" := !!sym(input$group_var)) %>%
              dplyr::mutate(across(all_of(c(input$group_var_name)),
                                   ~ factor(., levels = temp_values)))
          } else if (nrow(input$upload) > 1) {
            temp_values <- stringr::str_split_1(input$group_var_values, "\\s?,\\s?")
            temp2 <- temp2 %>%
              dplyr::rename("{input$group_var_name}" := !!sym(input$group_var)) %>%
              dplyr::mutate(across(all_of(c(input$group_var_name)),
                                   ~ factor(.,levels = 1:nrow(input$upload),
                                            labels = temp_values)))
          }
        }
      }
    }
    temp2
  }) %>%
    # ISS-020: bind to cols_confirmed counter rather than input$cols directly.
    # Resetting the counter on new file upload (observeEvent above) invalidates
    # this reactive. The req(cols_confirmed() > 0) above then suspends execution
    # until the user re-confirms, preventing the old mapping applying to new data.
    bindEvent(cols_confirmed(), ignoreInit = TRUE)
  
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
      if (!is.null(fit())) {
        
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
      }
    } else {
      if (!is.null(data_updated())) {
        data_updated() %>%
          as.data.frame() %>%
          dplyr::select(-where(is.logical))
      }
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
    
    # poisson", "Logistic" = "logistic", "Cox proportional hazards" = "cox"
    if (input$regression_type == "poisson") {
      "RR"
    } else if (input$regression_type == "logistic") {
      "OR"
    } else if (input$regression_type == "cox" & !input$inv) {
      "HR"
    } else if (input$regression_type == "cox" & input$inv) {
      "1/HR"
    } else {
      "Estimate"
    }
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
    
    expansion <- if (input$font %in% c("Lato", "Roboto", "Source Sans Pro", "Source Sans Pro")) {
      1.2
    } else {1}
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
  ### b - update to split out est and CI if est deselected
  observe({
    
    if (!("est" %in% input$elements)) {
      updateMaterialSwitch(
        session,
        "concatenate_est_ci",
        value = FALSE
      )
    }
  }) %>%
    bindEvent(input$elements)
  ### c - update order based on selected columns
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
  ### e - if deselect estimate or ci then deselected combine estimate and ci
  observe({
    if (!("est" %in% (input$elements)) | !("lci" %in% (input$elements))) {
      updateMaterialSwitch(session,
                           inputId = "concatenate_est_ci",
                           value = FALSE)
    }
  })
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
  ### h - options
  # display_option_update <- reactive({
  #   req(input$cols)
  #
  #   n_included <- if (length(input$n_name) == 0) {
  #     FALSE
  #   } else if (input$n_name[1] == "empty") {
  #     FALSE
  #   } else {
  #     TRUE
  #   }
  #   p_included <- if (length(input$p_name) == 0) {
  #     FALSE
  #   } else if (input$p_name[1] == "empty") {
  #     FALSE
  #   } else {
  #     TRUE
  #   }
  #   significance_included <- if (length(input$significance_name) == 0) {
  #     FALSE
  #   } else if (input$n_name[1] == "empty") {
  #     FALSE
  #   } else {
  #     TRUE
  #   }
  #   temp <- display_option
  #   if (n_included) {
  #     temp <- temp[-which(temp == "n")]
  #   }
  #   if (!p_included & !significance_included) {
  #     temp <- temp[-which(temp == "p")]
  #   }
  #   temp
  # })
  # ### i - when no significance provided
  # observe({
  #   updateCheckboxGroupInput(
  #     inputId = "elements",
  #     choices = display_option_update(),
  #     selected = unname(display_option_update())
  #   )
  # }) %>%
  #   bindEvent(display_option_update())
  
}
