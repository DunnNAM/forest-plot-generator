# Bottom rail — DEC-005. Plain function (no NS()/moduleServer(), per DEC-004).
# Each item sets input$rail_key via Shiny.setInputValue on click; server/drawers.R
# toggles the matching drawer panel open/closed.
railUI <- function() {
  rail_button <- function(key, label, icon_name, action = FALSE) {
    tags$button(
      type = "button",
      class = paste("rail-item", if (action) "action"),
      "data-key" = key,
      onclick = sprintf("Shiny.setInputValue('rail_key', '%s', {priority: 'event'})", key),
      tags$span(class = "ico", icon(icon_name)),
      tags$span(class = "lbl", label)
    )
  }

  div(
    class = "filter-rail",
    rail_button("data", "Data", "database"),
    rail_button("variables", "Variables", "list-check"),
    rail_button("display", "Display", "sliders"),
    rail_button("text", "Text", "font"),
    rail_button("order", "Order", "arrows-left-right"),
    div(class = "rail-grow"),
    rail_button("export", "Export", "download", action = TRUE)
  )
}
