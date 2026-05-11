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
