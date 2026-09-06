# Drawer panel UI — DEC-005 Steps 3-5. The three accordion panels this file used
# to build for the right-hand sidebar column are now three drawer panel
# functions consumed by drawerUI() (Step 3); dataPanelUI() (Step 4) is the old
# left-hand page_sidebar() content, moved verbatim into the Data drawer panel;
# orderPanelUI()/exportPanelUI() (Step 5) are the former Plot-tab reorder
# control and the FEAT-009 export redesign. No input IDs changed anywhere
# except download_png/download_svg, which Step 5 retires for export_format +
# download_plot — every other input is exactly the one the sidebar/accordion/
# Plot-tab version had, just laid out in a `.drawer-columns` responsive grid.
# `strong()` + `materialSwitch()` label pairs are wrapped in `.drawer-field` so
# they don't look ragged when a grid column is narrower than the accordion
# column was (restyle plan §9).

# Title + content wrapper for a single drawer field: a bold title noticeably
# larger than its content (CSS: .drawer-field-title/-content), with content
# starting at a consistent vertical position across a row — requested
# specifically for the Data panel's four top-level fields (design/
# modal-progression-workflow review, 2026-09-04) and since extended to
# Variables, Display, Text, and Order (FEAT-011 follow-up, same day). Used
# both inside .drawer-row-divided (Data, Variables) and the plain
# .drawer-columns grid (Display, Text, Order) — see each panel's own comment
# for which and why. Deliberately not cards, per the original discussion —
# plain title-over-content blocks.
#
# `first` controls the leading divider in a .drawer-row-divided context
# (Data, Variables — see dataPanelUI()/variablesPanelUI()) explicitly rather
# than via a CSS :first-child/:not(:first-child) selector. That was the first
# approach, and it silently matched nothing for the sim-mode fields: Shiny's
# conditionalPanel() renders `display: contents` when shown (so its child is
# promoted into the parent flex row for *layout* purposes) but a
# `.drawer-row-divided > *` CSS selector still only sees the un-promoted DOM
# tree — the conditionalPanel div, not the drawerFieldUI() div nested inside
# it — so the divider rule never matched it (confirmed via devtools,
# 2026-09-04). Passing `first` explicitly sidesteps the mismatch entirely; on
# the plain grid (no .drawer-row-divided ancestor) it's a harmless no-op, so
# every call site can pass it consistently without checking context.
drawerFieldUI <- function(title, ..., first = FALSE) {
  div(
    class = paste("drawer-field-block", if (!first) "drawer-field-block--divided"),
    div(class = "drawer-field-title", title),
    div(class = "drawer-field-content", ...)
  )
}

# Panel heading: the matching rail icon + an uppercase title, both in the
# title's slate blue, sitting directly on the drawer's own background — no
# card, no box. Ties the drawer's heading back to the rail button that opened
# it. Chosen over a full left-hand icon "card" column (which would have meant
# restructuring every panel's layout from a vertical stack to a sidebar+
# content split, and re-deriving the Data panel's divider-centering math) —
# see the 2026-09-04 discussion. `icon_name` must match the icon passed to
# the corresponding rail_button() call in R/ui_rail.R.
drawerHeaderUI <- function(icon_name, title) {
  h4(class = "drawer-header", icon(icon_name), title)
}

# Sub-group wrapper for a panel with too many fields to read as one flat list
# (Display panel, 2026-09-04 follow-up, revised same day per user feedback)
# — one GROUP is now the "field" as far as layout/dividers are concerned:
# each drawerGroupUI() call is a single .drawer-field-block (same class
# dataPanelUI()/variablesPanelUI() fields use) whose *content* is a vertical
# stack of the group's own fields, not one control. The whole panel becomes
# one .drawer-row-divided row of ~5 group-columns side by side — reusing
# Data/Variables' existing, proven single-row divider technique directly,
# rather than inventing a new one, since the item count in that row is now
# ~5 (groups) instead of 15+ (individual fields), which is exactly the
# "stays single-row at typical widths" case that technique was designed
# for. The first version of this (a horizontal row of fields *per* group,
# with dividers between individual fields and groups stacked as separate
# rows down the panel) put dividers in the wrong place (between fields
# within a group, not between groups) and, worse, meant 5 separately-
# wrapping rows instead of one — exactly the "still needs to scroll" outcome
# the user was trying to avoid. Fields inside a group use drawerSubfieldUI()
# below, not drawerFieldUI() — a lighter label, since the bold
# .drawer-field-title treatment now belongs to the group as a whole.
# `width`, added 2026-09-04 (fourth follow-up, user request): an explicit
# CSS percentage (e.g. "50%") overriding the row's default even flex growth
# (.drawer-row-divided .drawer-field-block { flex: 1 1 220px }) — inline
# style beats an external stylesheet rule's specificity automatically, no
# !important needed. Added because dropping Display's Number formatting
# group (freeing a column) only redistributed that space *evenly* across
# the remaining groups by default, when what was actually wanted was giving
# most of it to Plot sizing & axis specifically, whose sliders needed the
# room. NULL (the default) keeps the old even-growth behaviour for panels
# that don't need an explicit split (Data, Variables).
drawerGroupUI <- function(title, ..., first = FALSE, width = NULL) {
  div(
    class = paste("drawer-field-block", if (!first) "drawer-field-block--divided"),
    style = if (!is.null(width)) sprintf("flex: 0 0 %s; max-width: %s;", width, width),
    div(class = "drawer-field-title", title),
    div(class = "drawer-field-content drawer-group-stack", ...)
  )
}

# One field inside a drawerGroupUI() group — a smaller, less prominent label
# than drawerFieldUI()'s (which now marks the group itself), stacked above
# its control with a tight gap. checkboxInput() fields inside a group skip
# this wrapper entirely and go in bare (see displayPanelUI()).
drawerSubfieldUI <- function(label, ...) {
  div(class = "drawer-subfield",
      div(class = "drawer-subfield-label", label),
      ...)
}


dataPanelUI <- function() {
  tagList(
    drawerHeaderUI("database", "Data"),
    div(
      # .drawer-row-divided rather than .drawer-columns: this panel gets
      # vertical dividers between its fields, which needs the row to stretch
      # to fill the drawer's available height (see CSS) — a flex row, not a
      # grid, is what lets that work (2026-09-04 discussion). Also used by
      # variablesPanelUI() (FEAT-011 follow-up, same day) — both panels' base
      # fields stay in one row at typical widths. Display, Text, and Order
      # keep the plain grid: too many fields to stay single-row, and the
      # divider technique only positions correctly within one flex line.
      class = "drawer-row-divided",
      drawerFieldUI(
        "Data set",
        # Defaults to Simulated data, not Regression output — app-wide
        # default load state set 2026-09-04 (user request) so the app opens
        # with a working example rather than an empty upload prompt.
        radioButtons("dataset_selected", label = NULL,
                     choices = c("Regression output" = "upload", "Simulated data" = "sim"),
                     selected = "sim"),
        first = TRUE
      ),
      conditionalPanel(
        condition = "input.dataset_selected == 'upload'",
        drawerFieldUI(
          "Comparison mode",
          # materialSwitch() has no built-in on/off text, and this switch
          # originally got a static "On" caption to compensate (2026-09-04
          # discussion) — dropped (2026-09-04 follow-up, FEAT-011): the
          # caption never tracked the switch's actual state, so it read as
          # mislabeled the instant this switch (defaults FALSE) was seen
          # before being toggled — the title above already names the field,
          # and the switch's own on/off colour is the state indicator.
          materialSwitch("by_group", NULL, value = FALSE, status = "primary")
        )
      ),
      drawerFieldUI(
        "Regression type",
        tagList(
          # Alphabetical (Cox, Logistic, Poisson) so Robust variance — nested
          # under Poisson, the last option — never repositions Cox/Logistic
          # above it when it shows/hides. It used to be its own top-level
          # field; when "Simulated data" was selected, the sim-only
          # response/predictor block (tall — 11 checkboxes) shared its grid
          # row and stretched it, stranding Robust variance under Data set at
          # the bottom of the drawer instead of beside Regression type (user
          # report, 2026-09-04). Nesting it here removes that separate grid
          # item entirely, so there's nothing left to misplace.
          radioButtons("regression_type", label = NULL,
                       choices = c("Cox proportional hazards" = "cox", "Logistic" = "logistic", "Poisson" = "poisson"),
                       selected = "poisson"),
          conditionalPanel(
            condition = "input.regression_type == 'poisson'",
            checkboxInput("robust_variance", "Robust variance", value = TRUE)
          )
        )
      ),
      conditionalPanel(
        condition = "input.dataset_selected == 'upload' && input.by_group==1",
        textInput("group_var_name", "Group variable display name", value = "Group"),
        textInput("group_var_values", "Group variable levels", value = NULL,
                  placeholder = "(in order they appear, separated by ',')")
      ),
      conditionalPanel(
        condition = "input.dataset_selected == 'sim'",
        drawerFieldUI(
          "Response variable",
          # Defaults to Indicator 3 (value "IND_3") — 2026-09-04 default load
          # state request.
          selectInput("response_var", label = NULL, choices = responses, selected = "IND_3")
        )
      ),
      conditionalPanel(
        condition = "input.dataset_selected == 'sim'",
        drawerFieldUI(
          "Predictor variables",
          # Defaults to Sex, Age-group, Time period (values "Sex",
          # "AgeGroupAtDiagnosis", "DxYearGroup") — 2026-09-04 default load
          # state request.
          checkboxGroupInput("predictor_vars", label = NULL,
                             choices = predictors,
                             selected = c("Sex", "AgeGroupAtDiagnosis", "DxYearGroup"))
        )
      )
    ),
    # Upload + file table pulled out of .drawer-columns deliberately: sharing
    # a grid row with the short radio/switch fields above stretched that row
    # to the table's height, stranding "Data set" et al. under a wall of dead
    # space before the next row started (design/modal-progression-workflow
    # review, 2026-09-04). Full-width block below instead, same max-width/
    # centering as the grid via .drawer-fullwidth.
    conditionalPanel(
      condition = "input.dataset_selected == 'upload'",
      div(
        class = "drawer-fullwidth",
        fileInput("upload", "Upload one or two files with regression output (csv/tsv required). To compare two regressions, select both files at once using Ctrl+click (Windows) or Cmd+click (Mac).", multiple = TRUE),
        DT::dataTableOutput("files", width = "100%")
      )
    )
  )
}

variablesPanelUI <- function() {
  tagList(
    drawerHeaderUI("list-check", "Variables and Elements"),
    # .drawer-row-divided attempt #2 (FEAT-011 follow-up, 2026-09-04): unlike
    # Display/Text below, this panel's base fields (Variables plotted,
    # Elements included, Estimate Column Formatting) are few enough to stay
    # in one row at the drawer's usual width, so the divider technique — which
    # only positions correctly within a single flex line, see www/style.css —
    # is worth attempting here. It degrades to an oversized divider spanning
    # into the next line if enough conditional fields (Count display, Plot
    # inverse hazard ratio) are active at once to force a wrap; accepted as a
    # known limitation rather than solved, per the design/
    # modal-progression-workflow review. The three estimate-column toggles
    # were originally separate fields here and did force that wrap even in
    # the common case — combining them into one field (below) was the actual
    # fix, not just a formatting nicety.
    div(
      class = "drawer-row-divided",
      drawerFieldUI(
        "Variables plotted",
        checkboxGroupInput("variables_displayed", label = NULL, choices = c()),
        first = TRUE
      ),
      drawerFieldUI(
        "Elements included",
        checkboxGroupInput("elements", label = NULL,
                           choices = display_option,
                           selected = unname(display_option))
      ),
      conditionalPanel(
        condition = "input.elements.includes('n')",
        drawerFieldUI(
          "Count display",
          radioButtons("n_display", label = NULL, choices = c("n", "n/N", "% (n/N)"), selected = "n")
        )
      ),
      # Combined field (user request, 2026-09-04 review, revised same day):
      # originally three separate drawerFieldUI() items, then a first pass
      # merged them under one heading as two independent switches — this pass
      # replaces the two switches with a single three-way radioButtons(),
      # since "combine with significance" and "combine with CI" were always
      # mutually exclusive in practice (nothing downstream renders an
      # estimate cell with both crammed in) and a radio makes that exclusivity
      # the UI's own structure instead of two switches a user could
      # (nonsensically) both flip on. "Include significance symbol" keeps its
      # own switch — unlike the other two, it isn't a "combine with" choice,
      # it controls whether the symbol exists at all — but drops the strong()
      # wrapper around its label: nested inside this field's own bold title,
      # a second bold label directly below it read as double emphasis rather
      # than a normal field row.
      #
      # `combine_estimate_with` replaces the old `concatenate_est_ci` /
      # `concatenate_est_sig` *inputs*, but not forestHelperR's parameters of
      # the same names — those are the package's public API and aren't
      # touched. server/plot.R and server/export.R now derive both booleans
      # from this single radio's value at the point they call into the
      # package (`== "ci"` / `== "sig"`) instead of reading two independent
      # switch inputs.
      drawerFieldUI(
        "Estimate Column Formatting",
        tagList(
          # checkboxInput(), not materialSwitch() (2026-09-04 follow-up): the
          # switch + label pushed into a narrow .drawer-field-block column
          # wrapped "Include significance symbol" one word per line — a
          # checkbox is the same widget family as "Elements included" above
          # it, and its native layout puts the box first with the label
          # following as ordinary text, wrapping normally if it must rather
          # than stacking vertically. No .drawer-field wrapper needed —
          # that class existed to lay a label next to a switch; a plain
          # checkboxInput() already pairs box and label itself.
          checkboxInput("significance", "Include significance symbol", value = TRUE),
          # Nested drawerFieldUI() rather than a hand-styled div (2026-09-04
          # follow-up): a manual margin-top on radioButtons()'s own
          # .shiny-options-group landed on the wrong box — that class wraps
          # only the three radio rows, and Bootstrap's .radio items already
          # carry their own margin-top, so the override was colliding with
          # inter-item spacing instead of adding space above the group
          # (confirmed by inspecting radioButtons()'s generated HTML). Reusing
          # drawerFieldUI() gives this title the same .drawer-field-title
          # style and the same title-to-content gap (.drawer-field-block's
          # flex `gap`) that every other field in the drawer already uses —
          # consistent look, and the spacing comes from the pattern that's
          # already proven to work rather than a new one-off rule.
          # `first = TRUE` just skips the (harmless-but-pointless, since
          # there's no .drawer-row-divided ancestor here) divided class.
          drawerFieldUI(
            "Combine estimate with:",
            radioButtons("combine_estimate_with", label = NULL,
                         choices = c("Significance symbol" = "sig",
                                     "Confidence interval" = "ci",
                                     "Neither" = "neither"),
                         selected = "ci"),
            first = TRUE
          ),
          # Moved from the Display panel's Number formatting group
          # (2026-09-04, third follow-up, user request — a quick real-estate
          # reclaim: dropping that group entirely from Display frees up a
          # whole column in its own .drawer-row-divided row for Plot sizing
          # & axis, whose x-axis-ticks slider needed the room). Lands here
          # since it's now the only visible formatting option left for the
          # estimate/CI column — a natural fit alongside "Combine estimate
          # with:" rather than a stray field of its own. Same
          # .drawer-field-title-reuse pattern as "Combine estimate with:"
          # above, for the same reason (a proven title-to-content gap
          # instead of a new one-off rule). `first = TRUE` is required here,
          # not optional (bug fixed 2026-09-04, fourth follow-up): every
          # .drawer-field-block is a *descendant* of .drawer-row-divided
          # regardless of nesting depth, so its divider CSS
          # (.drawer-row-divided .drawer-field-block--divided) matched this
          # nested field too and added a 28px left padding meant for actual
          # row items — visually shifting this field right of its siblings
          # ("appears centred" in the user's report) instead of flush left.
          # "Combine estimate with:" above already passed first = TRUE for
          # the same reason; this one just needed the same treatment.
          drawerFieldUI(
            "Number of decimal places",
            numericInput("digits", label = NULL, value = 2, min = 1, max = 5, step = 1),
            first = TRUE
          )
        )
      ),
      conditionalPanel(
        condition = "input.regression_type == 'cox'",
        drawerFieldUI(
          "Plot inverse hazard ratio",
          materialSwitch("inv", NULL, value = FALSE, status = "primary")
        )
      )
    )
  )
}

displayPanelUI <- function() {
  tagList(
    drawerHeaderUI("sliders", "Plot Display Options"),
    # Restructured 2026-09-04, revised same day per user feedback: the first
    # version put 5 groups of *rows* stacked down the panel, each its own
    # wrapping flex line — dividers ended up between individual fields
    # within a group, and the panel as a whole still needed 5 separately-
    # wrapping rows (3/2/2/3/2 fields respectively), which didn't solve the
    # "needs no scrolling" goal at all. This version makes each GROUP a
    # single .drawer-field-block (drawerGroupUI()) — its fields stacked
    # vertically inside with no dividers between them — and puts all 5
    # groups in *one* .drawer-row-divided row, the same single-row divider
    # technique Data/Variables already use. ~5 items reliably stays single-
    # row at typical drawer widths (unlike the 15+ individual fields this
    # replaced), so the dividers now correctly separate the four/five
    # *groups* from each other, matching what was actually asked for.
    # Every materialSwitch() in the panel converted to checkboxInput() at
    # the same time — same reasoning as "Include significance symbol" in
    # variablesPanelUI() (a switch's label wrapped awkwardly in a narrow
    # column, and checkbox is the same widget family "Elements included"
    # already uses). Not applied elsewhere yet (by_group, inv still use
    # materialSwitch) — the user asked for *a* consistent widget approach
    # across drawers, not a mandate to convert every switch immediately.
    # Consolidated to 3 groups with an explicit 50/25/25 width split
    # (2026-09-04, fourth follow-up, user request): dropping the Number
    # formatting group (previous follow-up) only freed a column's width
    # *evenly* across the remaining 4 groups (.drawer-row-divided's default
    # flex: 1 1 220px grows every item equally), which wasn't actually
    # targeted at Plot sizing & axis — the one that needed the room for its
    # sliders (especially x-axis ticks, cramped at ~220-260px with up to 12
    # handles). Colours and Backgrounds merged into one "Colours &
    # Backgrounds" group (both are colour-related settings — table/plot
    # background colour and transparency sit naturally alongside CI/
    # reference colour) so there are only 3 groups to split explicitly,
    # rather than trying to weight 4. drawerGroupUI()'s new `width` param
    # sets the split directly.
    div(
      class = "drawer-row-divided",
      drawerGroupUI(
        "Plot sizing & axis",
        # noUiSliderInput(), not sliderInput() (2026-09-04, fifth follow-up,
        # user request): sliderInput()'s ionRangeSlider auto-generates grid
        # ticks at whatever interval divides the range into its own default
        # count, giving odd values like every 23 units for a 20-250 range —
        # there's no simple way to fix the *spacing* via sliderInput()'s own
        # ticks = TRUE. noUiSliderInput()'s `pips` option addresses that
        # directly (mode = "values" places pips at exactly the values given,
        # independent of the slider's own drag step) and also brings this
        # field's visual style in line with Domain/x-axis ticks below it,
        # which already use noUiSliderInput — three different-looking widgets
        # in one small group was the "styling should be closer together"
        # complaint. Range widened to 40-320 (was 20-250) specifically to
        # land on clean 40-unit pips (40, 80, ... 320) — the user's own
        # suggestion — while step = 1 keeps the actual draggable value
        # continuous/fine-grained, not snapped to multiples of 40; only the
        # displayed pips are at 40-unit intervals. input$plotting_width's
        # type/shape is unchanged (still a single numeric), so nothing
        # downstream (server/plot.R, server/export.R, the Display rail
        # badge) needed to change.
        drawerSubfieldUI("Width of plotting area",
          shinyWidgets::noUiSliderInput("plotting_width", label = NULL,
                                        min = 40, max = 320, value = 120, step = 1,
                                        pips = list(mode = "values", values = seq(40, 320, by = 40), density = 4))),
        drawerSubfieldUI("Domain",
          shinyWidgets::noUiSliderInput("xlims", label = NULL, range = log_scale,
                                        value = c(0.25, 4), min = 0.05, max = 20)),
        # xticks_count folded inline into the "x-axis ticks" subfield, not a
        # separate stacked subfield of its own (2026-09-04, second follow-up
        # — quick layout fix, user request): a full extra label + gap +
        # control was enough added height in this one group to push
        # .drawer-row-divided past the drawer's max-height, triggering an
        # unwanted internal scroll. Reuses the existing .drawer-field inline
        # row style (same one "Comparison mode" etc. use) rather than adding
        # new CSS. This is layout-only — xticks_count's id, the uiOutput()
        # it drives, and the server-side rebuild/mirror-pairing logic in
        # server/observers.R are all completely unchanged; see that file's
        # own comment for why a renderUI() is needed here at all
        # (updateNoUiSliderInput() can't add/remove handles) and why
        # server/drawers.R needs outputOptions(..., suspendWhenHidden =
        # FALSE) for output$xticks_ui. The tick slider's own min/max being
        # wired to the current domain (rather than the fixed full log_scale
        # range) is server-side, in the same renderUI() — see
        # server/observers.R.
        drawerSubfieldUI("x-axis ticks",
          div(class = "drawer-field",
              "Number of ticks:",
              numericInput("xticks_count", label = NULL, value = 6, min = 2, max = 12, step = 1, width = "70px")),
          uiOutput("xticks_ui")),
        first = TRUE,
        width = "50%"
      ),
      drawerGroupUI(
        "Colours & backgrounds",
        drawerSubfieldUI("Confidence interval colour",
          colourpicker::colourInput("ci_colour", label = NULL, value = "#444444")),
        conditionalPanel(
          condition = "input.by_group==1",
          drawerSubfieldUI("Group 2 confidence interval colour",
            colourpicker::colourInput("ci_colour2", label = NULL, value = "#E07653"))
        ),
        drawerSubfieldUI("Reference level colour",
          colourpicker::colourInput("reference_colour", label = NULL, value = "#C43D4D")),
        checkboxInput("transparent_table_bg", "Table background transparent", value = TRUE),
        conditionalPanel(
          condition = "input.transparent_table_bg==0",
          drawerSubfieldUI("Table background colour",
            colourpicker::colourInput("table_bg_colour", label = NULL)),
          checkboxInput("striped_bg", "Striped background", value = FALSE),
          conditionalPanel(
            condition = "input.striped_bg==1",
            drawerSubfieldUI("Stripe colour",
              colourpicker::colourInput("bg_stripe", label = NULL, value = "#EBEBEB"))
          )
        ),
        checkboxInput("transparent_plot_bg", "Plot background transparent", value = TRUE),
        conditionalPanel(
          condition = "input.transparent_plot_bg==0",
          drawerSubfieldUI("Plot background colour",
            colourpicker::colourInput("plot_bg_colour", label = NULL))
        ),
        width = "25%"
      ),
      drawerGroupUI(
        "Spacing & layout",
        width = "25%",
        drawerSubfieldUI("Space between variables",
          sliderInput("gaps", label = NULL, value = 0.8, min = 0.5, max = 2, step = 0.1, ticks = FALSE)),
        drawerSubfieldUI("Indent of levels",
          sliderInput("indent", label = NULL, value = 0.5, min = 0, max = 2, step = 0.1, ticks = FALSE)),
        # Defaults to Counts ("n") pre-selected (2026-09-04 follow-up, user
        # request) — the count column (n / n/N / n/N (%), per input$n_display)
        # reads better right-justified in the common case; still fully
        # removable, just no longer starting empty.
        drawerSubfieldUI("Right-justify variables",
          selectizeInput("right_justify", label = NULL, multiple = TRUE,
                         choices = elements[-c(1,2,4)], selected = c("n")))
      )
    ),
    # sigfigs kept in the DOM but hidden, not deleted (2026-09-04, third
    # follow-up, user request — "remove for now"): the Number formatting
    # group it lived in is dropped entirely to reclaim a column's width for
    # Plot sizing & axis (see the .drawer-row-divided block above), and
    # "Number of decimal places" moved into variablesPanelUI()'s Estimate
    # Column Formatting field. server/plot.R, server/export.R, and the
    # Display rail badge (server/drawers.R) all still read input$sigfigs
    # directly — deleting the input entirely would leave it NULL and break
    # those. A hidden checkboxInput() keeps it a real, bound Shiny input
    # (always FALSE, since it can't be toggled) with zero visible footprint,
    # so nothing downstream needed to change. Revisit alongside ISS-039 if
    # significant-figures mode is worth resurfacing.
    div(style = "display: none;",
        checkboxInput("sigfigs", NULL, value = FALSE))
  )
}

textPanelUI <- function() {
  tagList(
    drawerHeaderUI("font", "Plot Text Options"),
    # Titled fields on the plain grid, same reasoning as displayPanelUI(): too
    # many fields to stay single-row, so no .drawer-row-divided here. The two
    # wrap-control fluidRow()s stay un-wrapped in drawerFieldUI() — they're
    # secondary sub-controls of the field above them (Title/Footnote), not
    # fields in their own right, and already carry their own switch label
    # ("Center title"/"Long footnote"). FEAT-011 follow-up, 2026-09-04.
    div(
      class = "drawer-columns",
      drawerFieldUI("Title",
        textInput("plot_title", label = NULL, placeholder = "Plot title text")),
      conditionalPanel(
        condition = "input.plot_title != ''",
        fluidRow(
          materialSwitch("plot_title_centre", "Center title", value = FALSE,
                         status = "primary", width = "80px"),
          sliderInput("plot_title_wrap", "Title width before wrapping", min = 40,
                      max = 140, value = 80, step = 1, width = "200px",
                      ticks = FALSE))),
      drawerFieldUI("Font",
        selectInput("font", label = NULL, choices = fonts, selected = "Lato")),
      drawerFieldUI("Font size",
        sliderInput("base_size", label = NULL, min = 8, max = 18, value = 11, step = 1, post = "pt", ticks = FALSE)),
      drawerFieldUI("Text colour",
        colourpicker::colourInput("base_font_colour", label = NULL, value = "#444444")),
      drawerFieldUI("x-axis label",
        selectizeInput("xaxis_text", label = NULL, choices = labels_axis, options = list(create = TRUE))),
      drawerFieldUI("Footnote",
        textInput("plot_footnote", label = NULL, placeholder = "Plot footnote text")),
      conditionalPanel(
        condition = "input.plot_footnote != ''",
        fluidRow(
          materialSwitch("long_footnote", "Long footnote", value = TRUE,
                         status = "primary", width = "80px"),
          sliderInput("footnote_wrap", "Footnote width before wrapping", min = 40,
                      max = 200, value = 120, step = 1, width = "200px",
                      ticks = FALSE))),
      drawerFieldUI("Variable font colour",
        colourpicker::colourInput("variable_font_colour", label = NULL, value = "#2047A7")),
      drawerFieldUI("Variable header font face",
        selectizeInput("variable_font_face", label = NULL, choices = faces, selected = "bold")),
      drawerFieldUI("p-value font face",
        selectizeInput("pval_font_face", label = NULL, choices = faces, selected = "plain"))
    )
  )
}

orderPanelUI <- function() {
  tagList(
    drawerHeaderUI("arrows-left-right", "Order"),
    # .drawer-fullwidth rather than .drawer-columns: this panel has one real
    # control, so a multi-column grid just leaves the other columns empty.
    # The explanatory copy also addresses the panel reading as broken/empty
    # when reorder is off (design/modal-progression-workflow review,
    # 2026-09-04) — off is the common case, so it should look intentional.
    div(
      class = "drawer-fullwidth",
      # drawerFieldUI() for the same title-over-content look as the other
      # panels (FEAT-011 follow-up, 2026-09-04). Dividers don't apply here —
      # there's only ever one field — so `first` is a no-op outside
      # .drawer-row-divided, kept for consistency with the other call sites.
      drawerFieldUI(
        "Reorder columns",
        checkboxInput("reorder", label = NULL, value = FALSE),
        first = TRUE
      ),
      p(class = "text-muted",
        "Off by default — the plot uses the standard left-to-right column",
        " order. Turn this on to drag the plot's element columns",
        " (variables, counts, estimate, CI, p-value) into a custom order."),
      conditionalPanel(condition = "input.reorder==1", uiOutput("sortable_cols"))
    )
  )
}

# Export panel — FEAT-009 redesign, resolves ISS-031 (four-button layout wrapped
# with no spacing). Format radio + single download button for graph export;
# separate copy/download buttons for code export, since clipboard-copy and
# file-download are genuinely distinct actions that can't be merged. A single
# thin divider (matching the Data/Variables drawers' own vertical rule)
# separates the two panels — 2026-09-04 user request, replacing the earlier
# per-panel coloured left borders. Each panel's button(s) are wrapped in the
# same .drawer-btnrow class specifically so www/style.css can give both a
# shared `margin-top: auto`, bottom-aligning "Download" with "Copy R
# code"/"Download .R script" regardless of the graph panel's extra format
# radio pushing its own button down — see the .export-section CSS comment.
# The format radio lives *inside* .drawer-btnrow, stacked above the Download
# button (2026-09-06 follow-up, user report), not above it as a sibling: it
# used to sit outside the bottom-pinned block, stranded near the panel's top
# while the code panel's "Copy R code" sat much lower (inside its own
# bottom-pinned, stacked block) — the two panels' top rows didn't line up.
# Moving the radio inside the same .drawer-btnrow mirrors the code panel's
# own stacked-pair structure exactly, so both panels' top rows (radio /
# "Copy R code") and bottom rows (Download / "Download .R script") land on
# the same lines, with the same 8px gap between them (see
# .export-section--graph .drawer-btnrow in www/style.css).
exportPanelUI <- function() {
  tagList(
    drawerHeaderUI("download", "Export"),
    div(
      class = "drawer-columns export-columns",
      div(
        class = "export-section export-section--graph",
        strong("Export graph"),
        div(
          class = "drawer-btnrow",
          radioButtons("export_format", NULL,
                       choices = c("PNG" = "png", "SVG" = "svg"),
                       selected = "png", inline = TRUE),
          downloadButton("download_plot", "Download", icon = icon("download"))
        )
      ),
      div(
        class = "export-section export-section--code",
        strong("Export code"),
        div(
          class = "drawer-btnrow",
          actionButton("copy_r_code", "Copy R code", icon = icon("copy")),
          downloadButton("download_r_code", "Download .R script")
        )
      )
    )
  )
}
