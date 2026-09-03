# Bottom rail — DEC-005. Plain function (no NS()/moduleServer(), per DEC-004).
# Each item sets input$rail_key via Shiny.setInputValue on click; server/drawers.R
# toggles the matching drawer panel open/closed.
#
# FEAT-010 (DEC-005 Step 7): items may carry a badge slot — a server-rendered
# uiOutput("rail_badge_<key>") nested inside the button. The renderUI in
# server/drawers.R returns NULL (renders nothing) when there is nothing to
# flag, so unbadged buttons look identical to before. container = tags$span
# keeps the output from adding its own wrapping <div>, which would break the
# button's flex layout.
railUI <- function() {
  rail_button <- function(key, label, icon_name, action = FALSE, badge = FALSE) {
    tags$button(
      type = "button",
      class = paste("rail-item", if (action) "action"),
      "data-key" = key,
      onclick = sprintf("Shiny.setInputValue('rail_key', '%s', {priority: 'event'})", key),
      tags$span(class = "ico", icon(icon_name)),
      tags$span(class = "lbl", label),
      if (badge) uiOutput(paste0("rail_badge_", key), container = tags$span)
    )
  }

  div(
    class = "filter-rail",
    rail_button("data", "Data", "database"),
    rail_button("variables", "Variables", "list-check", badge = TRUE),
    rail_button("display", "Display", "sliders", badge = TRUE),
    rail_button("text", "Text", "font"),
    rail_button("order", "Order", "arrows-left-right"),
    div(class = "rail-grow"),
    rail_button("export", "Export", "download", action = TRUE)
  )
}
