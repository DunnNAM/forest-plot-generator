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
  ### e - sigfigs label toggle — removed 2026-09-04 (FEAT-011 follow-up,
  ### user request). This used to updateNumericInput()'s own native label to
  ### switch between "Number of decimal places" and "Number of significant
  ### figures" — a real, useful distinction — but once the Display panel
  ### adopted the drawerFieldUI() titled-field convention (a static
  ### "Number of decimal places" title above the same input), the two
  ### labels showed simultaneously, duplicated. Dropped the dynamic native
  ### label rather than the static title, since every other field in the
  ### panel now carries one consistently. The wording distinction itself is
  ### lost for now — flagged to the user as a possible follow-up (e.g. a
  ### reactive field title) if it's worth restoring.

  ### f - x-axis ticks: rebuild on count/domain change, mirror-pair while
  ### dragging (2026-09-04 follow-up, user request). Default `log_scale`
  ### (global.R) and `xlims` (0.25, 4) both straddle 1 — the RR/OR/HR "no
  ### effect" line, the whole reason a log axis is used here — so "evenly
  ### log-spaced" and "symmetric pairs around 1" are the same thing for the
  ### values this axis is normally showing.
  ###
  ### xticks_default(): generates n tick values. When the domain straddles 1
  ### (the common case), anchors the spread symmetrically around 1 using
  ### whichever domain bound is *closer* to 1 in log-space (so it never
  ### proposes a tick outside the current domain) — points come out as clean
  ### v / 1/v mirror pairs by construction. When the domain doesn't straddle
  ### 1 (e.g. xlims moved to something like (2, 8)), there's no "centre
  ### line" to mirror around, so it falls back to plain even log-spacing
  ### between the two bounds and the pairing behaviour below is skipped for
  ### as long as that's true.
  xticks_default <- function(n, domain) {
    lo <- domain[1]; hi <- domain[2]
    a <- log(lo); b <- log(hi)
    straddles <- a < 0 && b > 0
    if (n <= 1) {
      logs <- if (straddles) 0 else (a + b) / 2
    } else if (straddles) {
      r <- min(-a, b)
      logs <- seq(-r, r, length.out = n)
    } else {
      logs <- seq(a, b, length.out = n)
    }
    round(exp(logs), 4)
  }

  # Generates a log_scale()-shaped (global.R) noUiSlider "non-linear steps"
  # range object scoped to an arbitrary (lo, hi) instead of the fixed
  # (0.05, 20) log_scale is hardcoded to (2026-09-04, fourth follow-up, user
  # request: it doesn't make sense for the tick slider's own draggable range
  # to extend past the currently-selected domain). A plain c(min, max)
  # range would work but makes noUiSlider fall back to *linear* dragging —
  # equal drag distance would no longer mean equal ratio change, a real
  # step down from the domain slider's own log feel. This reconstructs the
  # same 10%-step non-linear breakpoint shape log_scale uses, generically,
  # for whatever the current domain is — confirmed to reproduce log_scale's
  # own breakpoints closely when handed its same (0.05, 20) bounds.
  make_log_range <- function(lo, hi) {
    pcts <- seq(10, 90, by = 10)
    a <- log(lo); b <- log(hi)
    vals <- exp(a + (pcts / 100) * (b - a))
    range_list <- list("min" = list(round(lo, 4)))
    prev <- lo
    for (i in seq_along(pcts)) {
      step <- round((vals[i] - prev) / 5, 4)
      if (step <= 0) step <- 0.0001
      range_list[[paste0(pcts[i], "%")]] <- list(round(vals[i], 4), step)
      prev <- vals[i]
    }
    range_list[["max"]] <- list(round(hi, 4))
    range_list
  }

  rv_xticks_prev <- reactiveVal(NULL)

  output$xticks_ui <- renderUI({
    req(input$xticks_count, input$xlims)
    domain <- input$xlims
    vals <- xticks_default(input$xticks_count, domain)
    rv_xticks_prev(vals)
    shinyWidgets::noUiSliderInput("xticks", label = NULL,
                                  range = make_log_range(domain[1], domain[2]),
                                  connect = FALSE, value = vals,
                                  min = domain[1], max = domain[2])
  }) %>%
    bindEvent(input$xticks_count, input$xlims)

  ### g - x-axis ticks: while dragging one handle, move its mirror partner
  ### to 1/value so both stay equidistant from 1 on the log scale (index i
  ### pairs with index n+1-i in the sorted handle list — true by
  ### construction for xticks_default()'s own output, and preserved from
  ### there on as long as the user only ever moves one handle at a time,
  ### which is all a slider drag can do). Skipped entirely when the domain
  ### no longer straddles 1 (see xticks_default()) — there's no meaningful
  ### mirror partner in that case, so handles move independently.
  observeEvent(input$xticks, {
    new_vals <- sort(input$xticks)
    old_vals <- rv_xticks_prev()
    n <- length(new_vals)

    # A count/domain change just rebuilt the widget (§f) — that's a new
    # baseline, not a user drag to react to.
    if (is.null(old_vals) || length(old_vals) != n) {
      rv_xticks_prev(new_vals)
      return()
    }

    domain <- input$xlims
    straddles <- !is.null(domain) && domain[1] < 1 && domain[2] > 1
    if (!straddles) {
      rv_xticks_prev(new_vals)
      return()
    }

    diffs <- abs(new_vals - old_vals)
    changed <- which(diffs > 1e-4)
    if (length(changed) == 1) {
      idx <- changed[1]
      partner <- n + 1 - idx
      if (partner != idx) {
        # Clamped to the *current domain*, not the old fixed (0.05, 20) —
        # the slider's own range is domain-scoped now too (§f), so a
        # mirrored value outside it would be invalid.
        mirrored <- round(1 / new_vals[idx], 4)
        mirrored <- min(max(mirrored, domain[1]), domain[2])
        final_vals <- sort(replace(new_vals, partner, mirrored))
        shinyWidgets::updateNoUiSliderInput(session, "xticks", value = final_vals)
        rv_xticks_prev(final_vals)
        return()
      }
    }
    rv_xticks_prev(new_vals)
  }, ignoreInit = TRUE)
