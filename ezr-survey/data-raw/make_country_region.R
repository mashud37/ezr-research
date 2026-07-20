# Builds the `country_region` lookup table shipped with ezrsurvey from the
# source CSV. Run from the package root: Rscript data-raw/make_country_region.R

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})

country_region <- read_csv("country_region.csv", show_col_types = FALSE) %>%
  # Keep a clean country -> region/subregion lookup; non-answer rows are handled
  # in recode_region() rather than carried as data.
  filter(region != "Prefer not to answer") %>%
  mutate(across(everything(), trimws)) %>%
  distinct(country, .keep_all = TRUE) %>%
  arrange(region, subregion, country) %>%
  tibble::as_tibble()

if (!dir.exists("data")) dir.create("data")
save(country_region, file = "data/country_region.rda", compress = "xz")
message("Wrote data/country_region.rda with ", nrow(country_region),
        " countries across ", dplyr::n_distinct(country_region$region),
        " regions.")
