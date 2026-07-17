# Drawer container — DEC-005. Scrim + a single drawer holding six statically
# rendered panel divs (one per rail item); the active panel is toggled via a CSS
# class by www/drawer.js in response to the "drawer-open" custom message, per the
# static-drawer approach in restyle-implementation-plan.md (all ~45 plot-option
# inputs must stay live in the DOM, not be staged/rebuilt per panel).
# Variables/Display/Text (Step 3) have real content from R/ui_plot_options.R.
# Data (Step 4) and Order/Export (Step 5) are still placeholders.
drawerUI <- function() {
  tagList(
    div(
      id = "drawer-scrim",
      class = "drawer-scrim",
      onclick = "Shiny.setInputValue('drawer_close', Math.random(), {priority: 'event'})"
    ),
    div(
      id = "filter-drawer",
      class = "filter-drawer",
      div(
        class = "filter-drawer-inner",
        div(class = "drawer-panel", "data-key" = "data",
            h4(class = "drawer-header", "Data")),
        div(class = "drawer-panel", "data-key" = "variables",
            variablesPanelUI()),
        div(class = "drawer-panel", "data-key" = "display",
            displayPanelUI()),
        div(class = "drawer-panel", "data-key" = "text",
            textPanelUI()),
        div(class = "drawer-panel", "data-key" = "order",
            h4(class = "drawer-header", "Order")),
        div(class = "drawer-panel", "data-key" = "export",
            h4(class = "drawer-header", "Export"))
      )
    )
  )
}
