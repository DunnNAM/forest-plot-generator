# Drawer container — DEC-005. Scrim + a single drawer holding six statically
# rendered panel divs (one per rail item); the active panel is toggled via a CSS
# class by www/drawer.js in response to the "drawer-open" custom message, per the
# static-drawer approach in restyle-implementation-plan.md (all ~45 plot-option
# inputs must stay live in the DOM, not be staged/rebuilt per panel).
# Data/Variables/Display/Text/Order/Export (Steps 3-5) all have real content
# from R/ui_plot_options.R.
#
# Back/Next nav buttons (FEAT-012) are siblings of .filter-drawer-inner, not
# children of it — deliberately: .filter-drawer-inner's exact padding/height
# is load-bearing for the Data/Variables divided-row divider's measured
# absolute-position offset (see www/style.css's .drawer-row-divided
# .drawer-field-block--divided::before comment), so nesting a new row-flex
# wrapper inside it to make room for side buttons risked silently breaking
# that measurement. Positioned absolutely against .filter-drawer itself
# instead (already `position: fixed`, so a valid positioning context) — see
# www/style.css's .drawer-nav-btn rule. Visibility/target key are entirely
# client-side (www/drawer.js's updateDrawerNavButtons()), driven by the same
# "drawer-open" message that already toggles the active panel; clicking
# either button just fires the same `rail_key` input the rail buttons
# themselves use (server/drawers.R needs no changes at all).
drawerUI <- function() {
  # Minimalist chevron-only circles, not a labeled pill (2026-09-06 design
  # discussion, user's own follow-up idea after seeing the labeled version
  # live) — a small icon-only control is much easier to place close to a
  # panel's content without risking an overlap (see the .drawer-nav-btn CSS
  # comment) than a ~100-110px text pill would have been, and reads as
  # lighter-weight chrome rather than another labeled control competing with
  # the panel's own fields. No visible label text, so `aria-label` carries
  # the accessible name instead — the icon alone (icon()'s FA glyph is
  # `aria-hidden` by default) would otherwise announce nothing to a screen
  # reader.
  drawerNavButtonUI <- function(id, side, icon_name, aria_label) {
    tags$button(
      id = id,
      type = "button",
      # `btn` (Bootstrap's own base button class), not just the app-specific
      # `drawer-nav-btn` — gives padding/border/font-weight/cursor for free,
      # the same way exportPanelUI()'s buttons rely on actionButton()/
      # downloadButton() supplying `.btn` themselves. This button is hand-
      # rolled (tags$button(), not actionButton()) since it's a pure
      # client-side click (drawerNavClick(), no server round-trip needed —
      # see the comment above drawerUI()), so `.btn` has to be added
      # explicitly here instead of coming for free from a Shiny widget.
      class = paste("btn", "drawer-nav-btn", paste0("drawer-nav-btn--", side)),
      "aria-label" = aria_label,
      hidden = "hidden",
      disabled = "disabled",
      onclick = "drawerNavClick(this)",
      icon(icon_name)
    )
  }

  tagList(
    div(
      id = "drawer-scrim",
      class = "drawer-scrim",
      onclick = "Shiny.setInputValue('drawer_close', Math.random(), {priority: 'event'})"
    ),
    div(
      id = "filter-drawer",
      class = "filter-drawer",
      drawerNavButtonUI("drawer-nav-back", "back", "angle-left", "Previous panel"),
      drawerNavButtonUI("drawer-nav-next", "next", "angle-right", "Next panel"),
      div(
        class = "filter-drawer-inner",
        div(class = "drawer-panel", "data-key" = "data",
            dataPanelUI()),
        div(class = "drawer-panel", "data-key" = "variables",
            variablesPanelUI()),
        div(class = "drawer-panel", "data-key" = "display",
            displayPanelUI()),
        div(class = "drawer-panel", "data-key" = "text",
            textPanelUI()),
        div(class = "drawer-panel", "data-key" = "order",
            orderPanelUI()),
        div(class = "drawer-panel", "data-key" = "export",
            exportPanelUI())
      )
    )
  )
}
