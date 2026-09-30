# Builds the `country_region` lookup table shipped with ezrsurvey.
#
# The table maps a country to the coarse `region` and the finer `subregion`
# ezrsurvey reports on, and carries each country's ISO 3166-1 alpha-2 and
# alpha-3 codes so a result can be reported against the standard.
#
# Region and subregion come from the table as it already ships, because those
# groupings are the package's own and changing them would change every answer
# built on them. The codes come from data-raw/iso-3166-1.csv, the ISO 3166-1
# list published at github.com/lukes/ISO-3166-Countries-with-Regional-Codes.
#
# Run from the package root: Rscript data-raw/make_country_region.R

suppressPackageStartupMessages({
  library(dplyr)
})

pkgload::load_all(".", quiet = TRUE)
load("data/country_region.rda")

# ---- corrections ---------------------------------------------------------

# Three countries were misspelled, so they could never match an answer.
corrections <- c(
  "Ise of Man" = "Isle of Man",
  "America Samoa" = "American Samoa",
  "Kazakstan" = "Kazakhstan"
)
hit <- match(country_region$country, names(corrections))
country_region$country[!is.na(hit)] <- corrections[hit[!is.na(hit)]]
# The table already carried the correct spelling alongside the wrong one, so
# correcting leaves a duplicate behind.
country_region <- country_region[!duplicated(country_region$country), ]

# And Bermuda was missing entirely.
if (!"Bermuda" %in% country_region$country) {
  country_region <- rbind(
    country_region,
    data.frame(country = "Bermuda", region = "North America",
               subregion = "North America", stringsAsFactors = FALSE)
  )
}

# ---- ISO 3166-1 codes ----------------------------------------------------

# na.strings = "" matters: Namibia's alpha-2 code is "NA", which the default
# reading turns into a missing value.
iso <- utils::read.csv("data-raw/iso-3166-1.csv", stringsAsFactors = FALSE,
                       fileEncoding = "UTF-8", na.strings = "")
names(iso)[1:3] <- c("iso_name", "iso2", "iso3")

# Most names match the standard once folded. These are the ones that do not:
# common short names against ISO's official long ones, plus the handful of
# territories the standard names differently. Keyed by alpha-2, which is the
# one identifier that never moves.
bridge <- c(
  "Cape Verde" = "CV", "Gambia, The" = "GM", "Laos" = "LA",
  "Swaziland" = "SZ", "Korea" = "KR", "Korea, North" = "KP",
  "Korea, South" = "KR", "South Korea" = "KR", "Macau" = "MO",
  "Taiwan" = "TW", "Brunei" = "BN", "Burma" = "MM", "Vietnam" = "VN",
  "Czech Republic" = "CZ", "Czechia" = "CZ", "Macedonia" = "MK",
  "Moldova" = "MD", "Russia" = "RU", "Turkey" = "TR",
  "Holy See (Vatican City)" = "VA", "Isle of Man" = "IM",
  "Netherlands" = "NL", "United Kingdom" = "GB", "Virgin Islands" = "VI",
  "British Virgin Islands" = "VG", "Iran" = "IR", "Kazakhstan" = "KZ",
  "Syria" = "SY", "United States" = "US", "American Samoa" = "AS",
  "Pitcairn Islands" = "PN", "Bolivia" = "BO", "Venezuela" = "VE",
  "Gaza Strip" = "PS", "West Bank" = "PS", "France, Metropolitan" = "FR"
)
# Kosovo has no ISO 3166-1 code of its own, so it keeps NA rather than
# borrowing the user-assigned XK.

by_name <- match(canonical_country(country_region$country),
                 normalise_country(iso$iso_name))
# match(NA, x) finds an NA in x rather than failing, so a country absent from
# the bridge would silently take whichever row happens to be missing a code.
wanted <- bridge[country_region$country]
by_code <- ifelse(is.na(wanted), NA_integer_, match(wanted, iso$iso2))
idx <- ifelse(is.na(by_name), by_code, by_name)

country_region$iso2 <- iso$iso2[idx]
country_region$iso3 <- iso$iso3[idx]

# ---- the countries the table never had -----------------------------------

# The table shipped with 180 of the 249 entries in ISO 3166-1, and the ones it
# was missing were not obscure: Ghana, Ethiopia, Senegal, Rwanda and Yemen all
# came back NA from a correctly spelled answer. The rest of the standard is
# added here, grouped the way the package groups countries rather than the way
# the UN does, because the existing 180 rows use that vocabulary and changing
# it would change every answer already built on it.
#
# Middle East is a region of its own here, and the Americas are split north and
# south, so ISO's five regions do not carry over. These two tables say how the
# UN M49 groupings map onto the package's.
by_sub_region <- data.frame(
  sub_region = c(
    "Australia and New Zealand",
    "Melanesia",
    "Micronesia",
    "Polynesia",
    "Central Asia",
    "Eastern Asia",
    "South-eastern Asia",
    "Southern Asia",
    "Western Asia",
    "Eastern Europe",
    "Northern Europe",
    "Southern Europe",
    "Western Europe",
    "Northern Africa",
    "Sub-Saharan Africa",
    "Northern America"
  ),
  new_region = c(
    "Oceania",
    "Oceania",
    "Oceania",
    "Oceania",
    "Asia",
    "Asia",
    "Asia",
    "Asia",
    "Middle East",
    "Europe",
    "Europe",
    "Europe",
    "Europe",
    "Africa",
    "Africa",
    "North America"
  ),
  new_subregion = c(
    "Australia New Zealand",
    "Pacific Islands",
    "Pacific Islands",
    "Pacific Islands",
    "Central Asia",
    "East Asia",
    "South East Asia",
    "South Asia",
    "Middle East",
    "Eastern Europe",
    "Northern Europe",
    "Western Europe",
    "Western Europe",
    "Africa",
    "Africa",
    "North America"
  ),
  stringsAsFactors = FALSE
)

# ISO puts the whole of Latin America and the Caribbean in one sub-region,
# which this package splits three ways, so those rows are read from the finer
# intermediate region instead.
by_intermediate <- data.frame(
  intermediate = c("Caribbean", "Central America", "South America"),
  new_region = c("North America", "North America", "South America"),
  new_subregion = c("Caribbean", "North America", "South America"),
  stringsAsFactors = FALSE
)

# A code already in the table means the standard simply spells that country
# differently, which is a job for the alias list in R/region.R, not a new row.
absent <- iso[!iso$iso3 %in% country_region$iso3, ]
absent <- absent[!is.na(absent$sub.region), ]

added <- merge(absent, by_sub_region, by.x = "sub.region",
               by.y = "sub_region", all.x = TRUE)
finer <- match(added$intermediate.region, by_intermediate$intermediate)
added$new_region <- ifelse(is.na(finer), added$new_region,
                           by_intermediate$new_region[finer])
added$new_subregion <- ifelse(is.na(finer), added$new_subregion,
                              by_intermediate$new_subregion[finer])

unplaced <- added$iso_name[is.na(added$new_region)]
if (length(unplaced)) {
  stop("No region mapping for: ", paste(unplaced, collapse = ", "))
}

country_region <- rbind(
  country_region[, c("country", "iso2", "iso3", "region", "subregion")],
  data.frame(country = added$iso_name, iso2 = added$iso2, iso3 = added$iso3,
             region = added$new_region, subregion = added$new_subregion,
             stringsAsFactors = FALSE)
)

country_region <- country_region %>%
  select(country, iso2, iso3, region, subregion) %>%
  arrange(region, subregion, country) %>%
  tibble::as_tibble()

# ---- report and save -----------------------------------------------------

missing_code <- country_region$country[is.na(country_region$iso2)]
if (length(missing_code)) {
  message("No ISO code for: ", paste(missing_code, collapse = ", "))
}

save(country_region, file = "data/country_region.rda", compress = "xz")
message("Wrote data/country_region.rda with ", nrow(country_region),
        " countries across ", dplyr::n_distinct(country_region$region),
        " regions; ", sum(!is.na(country_region$iso2)), " carry an ISO code.")
