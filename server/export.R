  ## step 5 - export image
  ### a - download plot (DEC-005 FEAT-009: one handler, format from input$export_format;
  ### retires download_png/download_svg)
  output$download_plot <- downloadHandler(
    filename = function() {
      paste0("Forestplot.", input$export_format)
    },
    content = function(file) {
      if (input$export_format == "png") {
        ggplot2::ggsave(file,
               plot = forest_plot_object(),
               device = "png",
               bg = ifelse(input$transparent_plot_bg,
                           "transparent",
                           input$plot_bg_colour),
               width = dims()[1]*1.1,
               height = dims()[2],
               units = "in",
               dpi = 144)
      } else {
        ggplot2::ggsave(
          file,
          plot = forest_plot_object(),
          device = "svg",
          bg = ifelse(input$transparent_plot_bg,
                      "transparent",
                      input$plot_bg_colour),
          width = dims()[1]*1.1,
          height = dims()[2])
      }
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
      # Derived from combine_estimate_with, same as server/plot.R (FEAT-011
      # follow-up, 2026-09-04) — the generated code still calls forestPloter()
      # with its real concatenate_est_ci/concatenate_est_sig params, just
      # computed from the one radio input instead of two switch inputs.
      '  concatenate_est_ci       = ', identical(input$combine_estimate_with, "ci"), ',\n',
      '  concatenate_est_sig      = ', identical(input$combine_estimate_with, "sig"), ',\n',
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
