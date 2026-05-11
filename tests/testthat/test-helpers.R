# tests/testthat/test-helpers.R
# Unit tests for pure helper functions in R/helpers.R.
# Run with: testthat::test_file("tests/testthat/test-helpers.R")

library(here)

# is_col_included ---------------------------------------------------------

test_that("is_col_included: returns FALSE for zero-length input", {
  expect_false(is_col_included(character(0)))
  expect_false(is_col_included(list()))
})

test_that("is_col_included: returns FALSE when first element is 'empty'", {
  expect_false(is_col_included("empty"))
  expect_false(is_col_included(c("empty", "real_col")))
})

test_that("is_col_included: returns TRUE for a real column name", {
  expect_true(is_col_included("n"))
  expect_true(is_col_included("p_value"))
  expect_true(is_col_included(c("count", "empty")))
})

# get_est_type ------------------------------------------------------------

test_that("get_est_type: poisson returns RR", {
  expect_equal(get_est_type("poisson", FALSE), "RR")
  expect_equal(get_est_type("poisson", TRUE),  "RR")
})

test_that("get_est_type: logistic returns OR", {
  expect_equal(get_est_type("logistic", FALSE), "OR")
  expect_equal(get_est_type("logistic", TRUE),  "OR")
})

test_that("get_est_type: cox returns HR or 1/HR based on inv", {
  expect_equal(get_est_type("cox", FALSE), "HR")
  expect_equal(get_est_type("cox", TRUE),  "1/HR")
})

test_that("get_est_type: unknown type returns Estimate", {
  expect_equal(get_est_type("linear", FALSE), "Estimate")
  expect_equal(get_est_type("",       FALSE), "Estimate")
})

# get_font_expansion ------------------------------------------------------

test_that("get_font_expansion: wide fonts return 1.2", {
  expect_equal(get_font_expansion("Lato"),            1.2)
  expect_equal(get_font_expansion("Roboto"),          1.2)
  expect_equal(get_font_expansion("Open Sans"),       1.2)
  expect_equal(get_font_expansion("Source Sans Pro"), 1.2)
  expect_equal(get_font_expansion("Montserrat"),      1.2)
})

test_that("get_font_expansion: all other fonts return 1", {
  expect_equal(get_font_expansion("Arial"),           1)
  expect_equal(get_font_expansion("Times New Roman"), 1)
  expect_equal(get_font_expansion("Helvetica"),       1)
  expect_equal(get_font_expansion("unknown font"),    1)
  expect_equal(get_font_expansion(""),                1)
})

# serialise_plot_title ----------------------------------------------------

test_that("serialise_plot_title: empty string returns NULL", {
  expect_equal(serialise_plot_title(""), "NULL")
})

test_that("serialise_plot_title: non-empty string returns quoted value", {
  expect_equal(serialise_plot_title("My Plot"), '"My Plot"')
  expect_equal(serialise_plot_title("A"),       '"A"')
})

# serialise_by_var --------------------------------------------------------

test_that("serialise_by_var: by_group FALSE returns NA", {
  expect_equal(serialise_by_var(FALSE, "Group"), "NA")
  expect_equal(serialise_by_var(FALSE, ""),      "NA")
})

test_that("serialise_by_var: by_group TRUE returns quoted name", {
  expect_equal(serialise_by_var(TRUE, "Group"),     '"Group"')
  expect_equal(serialise_by_var(TRUE, "Treatment"), '"Treatment"')
})

# serialise_x_ticks -------------------------------------------------------

test_that("serialise_x_ticks: no ticks in range returns NULL", {
  expect_equal(serialise_x_ticks(c(5, 10),    c(0, 1)),  "NULL")
  expect_equal(serialise_x_ticks(numeric(0),  c(0, 2)),  "NULL")
})

test_that("serialise_x_ticks: ticks in range serialises full xticks vector", {
  expect_equal(serialise_x_ticks(c(0.5, 1, 2), c(0, 1.5)), "c(0.5, 1, 2)")
  expect_equal(serialise_x_ticks(c(1, 2, 3),   c(0, 4)),   "c(1, 2, 3)")
})

test_that("serialise_x_ticks: boundary ticks on xlim edges are included", {
  expect_equal(serialise_x_ticks(c(0, 1, 2), c(0, 2)), "c(0, 1, 2)")
})

# serialise_chr_vec -------------------------------------------------------

test_that("serialise_chr_vec: empty vector returns c()", {
  expect_equal(serialise_chr_vec(character(0)), "c()")
  expect_equal(serialise_chr_vec(c()),          "c()")
})

test_that("serialise_chr_vec: single element returns quoted c()", {
  expect_equal(serialise_chr_vec("a"), 'c("a")')
})

test_that("serialise_chr_vec: multiple elements returns quoted c()", {
  expect_equal(serialise_chr_vec(c("a", "b")), 'c("a", "b")')
  expect_equal(serialise_chr_vec(c("x", "y", "z")), 'c("x", "y", "z")')
})

# serialise_bg_stripe -----------------------------------------------------

test_that("serialise_bg_stripe: striped_bg FALSE returns NA", {
  expect_equal(serialise_bg_stripe(FALSE, "#ffffff"), "NA")
  expect_equal(serialise_bg_stripe(FALSE, ""),        "NA")
})

test_that("serialise_bg_stripe: striped_bg TRUE returns quoted colour", {
  expect_equal(serialise_bg_stripe(TRUE, "#eeeeee"), '"#eeeeee"')
  expect_equal(serialise_bg_stripe(TRUE, "grey90"),  '"grey90"')
})

# serialise_footnote ------------------------------------------------------

test_that("serialise_footnote: empty string returns empty quoted string", {
  expect_equal(serialise_footnote(""), '""')
})

test_that("serialise_footnote: non-empty string returns quoted value", {
  expect_equal(serialise_footnote("Source: X"), '"Source: X"')
})
