# Packages ----------------------------------------------------------------
# Explicit package loads (tidyverse replaced with individual packages to
# reduce startup overhead and avoid implicit dependencies — CHG-001)
library(dplyr)
library(forcats)
library(stringr)
library(tidyr)

library(vroom)       # file upload parsing (csv/tsv/txt) — declared explicitly (NEW-002)
library(readxl)      # file upload parsing (xls/xlsx) — declared explicitly (NEW-002)

library(here)        # portable path resolution — replaces setwd() block (ISS-001 / CHG-004)

library(bslib)
library(grid)
library(DT)
library(forestploter)
library(gridExtra)
library(extrafont)
# officer removed — no export handlers wired; add back when FEAT-004 is implemented (PDEC-004 / CHG-002)
library(shiny)
library(survival)
library(colourpicker)
library(broom)
library(lmtest)
library(sandwich)
library(sortable)
library(shinyWidgets)
library(forestHelperR)
library(glue)
library(clipr)


# Setup -------------------------------------------------------------------
# font_import()  # run once interactively on a new machine to register fonts

loadfonts(device = "all")

# setwd() block removed — here::here() resolves paths relative to the project
# root (.here sentinel file or .Rproj) on both local and server deployments.
# No manual working directory manipulation is required (ISS-001 / CHG-004).

# Load simulated data -----------------------------------------------------
# Use a cached .rds if present to avoid regenerating via mvtnorm::rmvnorm()
# on every cold start (ISS-012). To create the cache, run once interactively:
#   source(here::here("data", "data_creation.R"))
#   saveRDS(dat, here::here("data", "dat.rds"))
if (file.exists(here::here("data", "dat.rds"))) {
  dat <- readRDS(here::here("data", "dat.rds"))
} else {
  source(here::here("data", "data_creation.R"))
}


# functions/functions.R removed — all functions now provided by forestHelperR
# package. The legacy file has been deleted (PDEC-002 / CHG-003).


# Global objects ----------------------------------------------------------
responses <- colnames(dat)[which(stringr::str_detect(
  colnames(forestHelperR::dat), "IND_\\d$"))]
names(responses) <- stringr::str_replace(responses, "IND_", "Indicator ") %>% 
  stringr::str_remove_all("_bin")
predictors <- colnames(forestHelperR::dat)[-c(1,3,7,which(stringr::str_detect(
  colnames(forestHelperR::dat), "\\d")))]
names(predictors) <- c("Sex", "Age group at diagnosis", 
                       "First Nations peoples status",
                       "Socioeconomic status", "Comorbidities", 
                       "Residence at diagnosis", "Diagnosis time period", 
                       "ASA score", "Surgical facility type", "Stage", 
                       "Surgical admission status")
elements <- c("Variables" = "variable",
              "Levels" = "level",
              "Counts" = "n",
              "Plot" = "blank",
              "Estimate" = "est", 
              "95% CI" = "lci",
              "p-value" = "p")
labels_axis <- c("Less likely, More likely",
                 "Better survival, Poorer survival",
                 " , Better access")
fonts <- c(
  "Arial",
  "Helvetica",
  "Times New Roman",
  "Times",
  "Courier New",
  "Courier",
  "Verdana",
  "Georgia",
  "Palatino",
  "Garamond",
  "Bookman",
  "Lato",
  "Roboto",
  "Open Sans",
  "Source Sans Pro",
  "Montserrat"
)

log_scale = list("min" = list(0.05),
                 "10%" = list(0.0625, 0.01),
                 "20%" = list(0.125, 0.01),
                 "30%" = list(0.25, 0.05),
                 "40%" = list(0.5, 0.1),
                 "50%" = list(1, 0.1),
                 "60%" = list(2, 0.1),
                 "70%" = list(4, 0.5),
                 "80%" = list(8, 1),
                 "90%" = list(16,2), 
                 "max" = list(20))

## restrict fonts down to ones available on this machine
fonts <- fonts[fonts %in% names(grDevices::postscriptFonts())]

faces <- c("Plain" = "plain", "Italic" = "italic", "Bold" = "bold")
display_option <- c("Counts" = "n", "Estimate" = "est",
                    "Confidence interval" = "lci","p-value" = "p")
