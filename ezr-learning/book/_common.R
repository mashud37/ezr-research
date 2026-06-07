# Shared setup for every chapter (sourced from index.Rmd).
knitr::opts_chunk$set(
  echo = TRUE,
  comment = "#>",
  collapse = TRUE,
  message = FALSE,
  warning = FALSE,
  fig.width = 7,
  fig.height = 4.2,
  fig.align = "center"
)

suppressPackageStartupMessages({
  library(ezrsurvey)
  library(ezrmodel)
  library(ezrlearning)
})

# A reproducible book build (seed the stochastic ezrmodel methods too).
set.seed(1)
ezrmodel::ezrmodel_options(seed = 1)
