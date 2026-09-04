# Setup wizard modal content — design/modal-progression-workflow experiment
# (FEAT-011, not yet accepted as a decision). Two required-step modals:
# welcome (Data) and confirm (Variables). Deliberately instructional, not a
# duplicate copy of the real controls: DEC-005 already made the case against
# duplicating any of the ~45 live plot-option inputs (restyle plan §3), and a
# modal-embedded copy of e.g. dataset_selected would be exactly that. Each
# modal instead tells the user what to do and the server opens the matching
# drawer for them (server/wizard.R) — one live input, guided from two places.
# Three footer buttons (2026-09-04 follow-up, user request/revision): the app
# now loads with Simulated data already selected and pre-populated (2026-09-04
# default-load-state change), which is genuinely useful data to plot straight
# away — but most users are here to plot their *own* regression output, so
# the modal needs to serve both without assuming either. "Update data
# source/s" keeps the original wait-for-real-data flow (§b/§c in
# server/wizard.R) for that primary case; "Proceed to plot styling" is new,
# for someone happy with the example data, and skips straight past both
# wizard steps into styling rather than making them click through a
# "Variables ready" modal for data they didn't just choose. "Skip wizard"
# is unchanged — full opt-out, no drawer forced open either way.
wizardWelcomeModal <- function() {
  shiny::modalDialog(
    # tags$span(), not a plain string (2026-09-04 styling follow-up, user
    # request): a plain `title` renders inside Bootstrap's own unstyled
    # `.modal-title`, which looked like nothing else in the app. Reuses the
    # colour/weight/size (not the uppercase/letter-spacing/icon/border —
    # those are specific to a drawer *panel* heading, and read oddly stamped
    # on a full sentence) that the drawer panel titles already use, via the
    # new .wizard-modal-title class (www/style.css).
    title = tags$span(class = "wizard-modal-title", "Let's build your first plot"),
    p("This app has opened with example simulated data already plotted, so",
      " you can see it working straight away. If you want to plot your own",
      " regression output instead, choose \"Update data source/s\" below."),
    tags$ol(
      tags$li(strong("Data"), " — choose or upload the regression output to plot."),
      tags$li(strong("Variables"), " — choose which variables and elements to show.")
    ),
    # Built as one HTML() string, not separate strong()/text arguments
    # (2026-09-04 styling follow-up — real bug found and fixed, not a
    # cosmetic tweak): htmltools pretty-prints a multi-argument tag call onto
    # separate indented lines in the HTML it sends to the browser. That's
    # invisible for block-level children (tags$li() above), but between
    # *inline* elements the newline + indentation whitespace the pretty-
    # printer inserts collapses to a visible single space when the browser
    # renders it — so `strong("Display"), ", "` rendered as "Display , "
    # rather than "Display, " (confirmed: the comma's own leading `,`
    # character is correct in the source, the extra space came from
    # htmltools' own formatting between the two arguments, not from the
    # string content). A single HTML() string has no argument boundaries for
    # the pretty-printer to insert whitespace at.
    p(HTML(paste0(
      "Once those are set you're free to explore <strong>Display</strong>, ",
      "<strong>Text</strong>, <strong>Order</strong> and <strong>Export</strong> ",
      "whenever you like — there's no fixed order after that."
    ))),
    # One row (2026-09-04 styling follow-up, user request): shortened labels
    # (arrows dropped, "Go to plot styling" instead of "Proceed to...") plus
    # `.wizard-modal-footer` forcing `flex-wrap: nowrap` (www/style.css) —
    # Bootstrap's default `.modal-footer` wraps if the buttons don't fit,
    # which the original longer three-button labels did at typical modal
    # widths. Skip/Update/Go-to-styling, in that order, per the user.
    # wizard_skip gets the new .btn-wizard-skip treatment (solid maroon/
    # magenta from the theme's `danger` colour, cream text) — a real colour,
    # not Bootstrap's plain default button, so "skip" doesn't read as the
    # most neutral/safe choice next to the two primary-styled actions.
    # wizard_start and wizard_proceed_styling both carry btn-primary now —
    # equally weighted, since which one is "the" expected path depends on
    # whether this visitor already has their own data to upload.
    footer = div(
      class = "wizard-modal-footer",
      actionButton("wizard_skip", "Skip wizard", class = "btn-wizard-skip"),
      actionButton("wizard_start", "Update data source/s", class = "btn-primary"),
      actionButton("wizard_proceed_styling", "Go to plot styling", class = "btn-primary")
    ),
    easyClose = FALSE
  )
}

wizardVariablesModal <- function() {
  shiny::modalDialog(
    title = "Your data is ready",
    p("Now choose which variables and elements appear in the plot. Everything",
      " is pre-selected, so you only need to change what you don't want."),
    p("Open ", strong("Variables"), " on the rail below to adjust, then come",
      " back here when you're happy — or just close this and carry on."),
    footer = tagList(
      actionButton("wizard_skip", "Skip wizard"),
      actionButton("wizard_finish", "Finish setup", class = "btn-primary")
    ),
    easyClose = FALSE
  )
}
