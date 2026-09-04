# Help nav panel — FEAT-010 (DEC-005 Step 7). Static content only: no reactive
# inputs, no server-side rendering, so this is a plain function returning a
# fixed UI tree, unlike the drawer panel functions in R/ui_plot_options.R.
# MDT's How-to-Use pattern (.htu-*) was explicitly dropped from the ported
# stylesheet (restyle plan §7) since it doesn't apply to a single-page app, so
# this reuses the .card/.card-header rules that were kept instead.
# The page title uses its own .help-title class rather than .drawer-header
# (2026-09-04, user report): .drawer-header is centered within a 1280px
# max-width to line up with the filter drawer's own content, which made it
# sit inset from — not flush with — this page's cards on a wide viewport.
# .help-panel scopes the card-header styling (slate blue/uppercase, matching
# .help-title) to just this page's cards, since bslib::card_header() isn't
# used anywhere else in the app.
helpPanelUI <- function() {
  section <- function(title, ...) {
    bslib::card(
      bslib::card_header(title),
      bslib::card_body(...)
    )
  }

  div(
    class = "content-area help-panel",
    h4(class = "help-title", "How to use Forest Plot Builder"),
    p("The plot updates live as you change settings below — there is no",
      strong(" Apply"), " button. Open a drawer from the bottom rail, adjust",
      " its controls, and close it (rail icon again, or click outside the",
      " drawer) to see the full plot."),
    p("New here, or coming back after a while? Click ", strong("Tour"), " —",
      " the first icon on the rail below — to restart the guided setup at",
      " any time."),
    section(
      "1. Data",
      p("Choose a data set: upload your own regression output (CSV/TSV),",
        " or use the bundled simulated data set. To compare two regressions",
        " side by side, select both files at once in the file picker",
        " (Ctrl+click / Cmd+click) and turn on ", strong("Comparison of two",
        " regressions"), "."),
      p("Uploaded files go through a one-time column mapping step in the",
        strong(" Review data"), " tab — confirm the mapping there before",
        " the plot can render.")
    ),
    section(
      "2. Variables & Elements",
      p("Choose which variables are plotted and which elements (counts,",
        " estimate, confidence interval, p-value) appear alongside them.",
        " The ", strong("Variables"), " rail icon shows a count badge when",
        " one or more variables from the regression are currently hidden.")
    ),
    section(
      "3. Display & Text",
      p("Display controls cover plot geometry — axis domain and ticks,",
        " colours, backgrounds, spacing. Text controls cover the title,",
        " footnote, font, and font sizing. A dot badge on the ", strong("Display"),
        " rail icon means at least one display setting has been changed",
        " from its default.")
    ),
    section(
      "4. Order & Export",
      p("Turn on ", strong("Reorder columns"), " to drag the plot's element",
        " columns into a custom left-to-right order."),
      p("Export a PNG or SVG of the finished plot, or copy/download the R",
        " code that reproduces it — useful for a reproducible analysis",
        " script or for handing the plot off to someone without this app.")
    ),
    p(class = "text-muted",
      "Questions or issues: see the project's ",
      code("issues-register.md"), " or raise a new item there.")
  )
}
