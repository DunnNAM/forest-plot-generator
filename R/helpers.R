# Pure helper functions extracted from server.R for testability.
# Shiny auto-sources all files in R/ before starting the app.

# Returns TRUE when a sortable bucket-list input contains a real column name:
# FALSE if the input is zero-length (bucket empty) or the placeholder "empty".
is_col_included <- function(col_name) {
  if (length(col_name) == 0) FALSE
  else if (col_name[1] == "empty") FALSE
  else TRUE
}

# Returns the estimate label for the forest plot header given the regression
# type and whether the hazard ratio is inverted.
get_est_type <- function(regression_type, inv) {
  if (regression_type == "poisson")          "RR"
  else if (regression_type == "logistic")    "OR"
  else if (regression_type == "cox" && !inv) "HR"
  else if (regression_type == "cox" && inv)  "1/HR"
  else                                       "Estimate"
}

# Returns 1.2 for fonts with wider character metrics that need extra plot width;
# returns 1 for all others.
get_font_expansion <- function(font) {
  if (font %in% c("Lato", "Roboto", "Open Sans", "Source Sans Pro", "Montserrat")) 1.2
  else 1
}

# r_code_string serialisation helpers -------------------------------------

# Empty plot_title maps to NULL (no title); non-empty is quoted.
serialise_plot_title <- function(plot_title) {
  if (plot_title == "") "NULL" else paste0('"', plot_title, '"')
}

# When by_group is FALSE no grouping variable is passed (NA); otherwise quoted.
serialise_by_var <- function(by_group, group_var_name) {
  if (!by_group) "NA" else paste0('"', group_var_name, '"')
}

# Returns NULL when no xticks fall within xlims; otherwise serialises the full
# xticks vector — mirrors the filter used inside forest_plot_object().
serialise_x_ticks <- function(xticks, xlims) {
  ticks_in_range <- xticks[xticks >= min(xlims) & xticks <= max(xlims)]
  if (length(ticks_in_range) == 0) "NULL"
  else paste0("c(", paste(xticks, collapse = ", "), ")")
}

# Serialises a character vector to an R c() expression.
# Used for variables_excluded, elements, and right_justify.
serialise_chr_vec <- function(vec) {
  if (length(vec) == 0) "c()"
  else paste0('c("', paste(vec, collapse = '", "'), '")')
}

# bg_stripe is NA when striping is off; otherwise the quoted colour string.
serialise_bg_stripe <- function(striped_bg, bg_stripe) {
  if (!striped_bg) "NA" else paste0('"', bg_stripe, '"')
}

# Empty footnote serialises to "" (empty string arg); non-empty is quoted.
# Distinct from serialise_plot_title: an empty footnote passes "" not NULL.
serialise_footnote <- function(footnote) {
  if (footnote == "") '""' else paste0('"', footnote, '"')
}
