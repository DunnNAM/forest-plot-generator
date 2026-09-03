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
#
# design/modal-progression-workflow (FEAT-011, draft): the "Tour" item is not
# a drawer at all — it re-triggers the setup wizard (server/wizard.R) — so it
# takes an explicit click_input/click_value pair instead of the default
# rail_key toggle. Styled `action = TRUE` like Export for the same reason:
# it's a one-shot action, not a settings panel to open and close.
railUI <- function() {
  rail_button <- function(key, label, icon_name, action = FALSE, badge = FALSE,
                           click_input = "rail_key", click_value = NULL) {
    value_js <- if (is.null(click_value)) sprintf("'%s'", key) else click_value
    tags$button(
      type = "button",
      class = paste("rail-item", if (action) "action"),
      "data-key" = key,
      onclick = sprintf("Shiny.setInputValue('%s', %s, {priority: 'event'})", click_input, value_js),
      tags$span(class = "ico", icon(icon_name)),
      tags$span(class = "lbl", label),
      if (badge) uiOutput(paste0("rail_badge_", key), container = tags$span)
    )
  }

  div(
    class = "filter-rail",
    rail_button("tour", "Tour", "compass", action = TRUE,
                click_input = "wizard_restart", click_value = "Math.random()"),
    rail_button("data", "Data", "database"),
    rail_button("variables", "Variables", "list-check", badge = TRUE),
    rail_button("display", "Display", "sliders", badge = TRUE),
    rail_button("text", "Text", "font"),
    rail_button("order", "Order", "arrows-left-right"),
    div(class = "rail-grow"),
    rail_button("export", "Export", "download", action = TRUE)
  )
}
