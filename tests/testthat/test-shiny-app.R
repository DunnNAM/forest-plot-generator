library(shinytest2)

# Fixtures used across scenario tests
group_a <- here::here("tests", "fixtures", "group_a.csv")
group_b <- here::here("tests", "fixtures", "group_b.csv")

# When req() suspends an output, shinytest2 returns the silent validation error
# Shiny sends to the client rather than NULL. This helper treats both as
# "output not rendered".
is_suspended <- function(val) {
  is.null(val) || (is.character(val) && any(grepl("shiny.silent.error", val)))
}

# Scenario (a) — Column confirmation gate (data_updated() / cols_confirmed) ----

test_that("dat_upload is suspended before column names are confirmed", {
  app <- AppDriver$new(app_dir = here::here(), timeout = 15000)
  on.exit(app$stop())

  # dataset_selected now defaults to "sim" (2026-09-04, FEAT-011 follow-up),
  # not "upload" — the Review data upload panel and its "cols" button live
  # in a conditionalPanel gated on dataset_selected == "upload" and Shiny
  # suspends a hidden renderUI() by default, so the button never renders
  # without this explicit switch.
  app$set_inputs(dataset_selected = "upload")
  app$wait_for_idle()
  app$upload_file(upload = group_a)
  app$wait_for_idle()

  expect_true(is_suspended(app$get_value(output = "dat_upload")))
})

test_that("dat_upload renders after confirming column names", {
  app <- AppDriver$new(app_dir = here::here(), timeout = 15000)
  on.exit(app$stop())

  app$set_inputs(dataset_selected = "upload")
  app$wait_for_idle()
  app$upload_file(upload = group_a)
  app$wait_for_idle()
  app$click("cols")
  app$wait_for_idle()

  expect_false(is.null(app$get_value(output = "dat_upload")))
})

test_that("dat_upload reverts to NULL after a new file upload (ISS-020 regression guard)", {
  app <- AppDriver$new(app_dir = here::here(), timeout = 15000)
  on.exit(app$stop())

  app$set_inputs(dataset_selected = "upload")
  app$wait_for_idle()

  # Upload File A and confirm — establishes a known-good state
  app$upload_file(upload = group_a)
  app$wait_for_idle()
  app$click("cols")
  app$wait_for_idle()
  expect_false(is.null(app$get_value(output = "dat_upload")))

  # Upload File B — cols_confirmed resets to 0, table must clear
  app$upload_file(upload = group_b)
  app$wait_for_idle()

  expect_true(is_suspended(app$get_value(output = "dat_upload")))
})

# Scenario (b) — Two-file upload ----

test_that("uploading two files simultaneously sets by_group to TRUE", {
  app <- AppDriver$new(app_dir = here::here(), timeout = 15000)
  on.exit(app$stop())

  app$set_inputs(dataset_selected = "upload")
  app$wait_for_idle()
  app$upload_file(upload = c(group_a, group_b))
  app$wait_for_idle()

  expect_true(app$get_value(input = "by_group"))
})

test_that("two-file upload produces a non-suspended dat_upload after confirmation", {
  app <- AppDriver$new(app_dir = here::here(), timeout = 15000)
  on.exit(app$stop())

  app$set_inputs(dataset_selected = "upload")
  app$wait_for_idle()
  app$upload_file(upload = c(group_a, group_b))
  app$wait_for_idle()
  app$click("cols")
  app$wait_for_idle()

  expect_false(is_suspended(app$get_value(output = "dat_upload")))
})

# Scenario (c) — Regression type → estimate label ----

test_that("changing regression type updates estimate label in summary table", {
  app <- AppDriver$new(app_dir = here::here(), timeout = 20000)
  on.exit(app$stop())

  app$set_inputs(dataset_selected = "sim", preview_type = "reg_summary")
  app$wait_for_idle()

  # Default regression type is poisson → expect "RR" in table header
  expect_true(grepl("RR", app$get_html("#dat_summary")))

  # Switch to logistic → expect "OR"
  app$set_inputs(regression_type = "logistic")
  app$wait_for_idle()
  expect_true(grepl("OR", app$get_html("#dat_summary")))

  # Switch to cox → expect "HR"
  app$set_inputs(regression_type = "cox")
  app$wait_for_idle()
  expect_true(grepl("\\bHR\\b", app$get_html("#dat_summary")))
})
