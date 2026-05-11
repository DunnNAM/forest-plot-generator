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

    n_included            <- is_col_included(input$n_name)
    p_included            <- is_col_included(input$p_name)
    significance_included <- is_col_included(input$significance_name)

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
