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
