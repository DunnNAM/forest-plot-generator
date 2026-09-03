server <- function(input, output, session) {

  source(here::here("server", "upload.R"),     local = TRUE)
  source(here::here("server", "regression.R"), local = TRUE)
  source(here::here("server", "preview.R"),    local = TRUE)
  source(here::here("server", "plot.R"),       local = TRUE)
  source(here::here("server", "export.R"),     local = TRUE)
  source(here::here("server", "observers.R"),  local = TRUE)
  source(here::here("server", "drawers.R"),    local = TRUE)
  source(here::here("server", "wizard.R"),     local = TRUE)

}
