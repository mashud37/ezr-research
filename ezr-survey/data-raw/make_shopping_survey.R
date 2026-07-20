# Generates `shopping_survey`, a simulated *historical* shopping-behaviour
# survey: patrons of a turn-of-the-century (c. 1905) general emporium. Run with:
#   Rscript data-raw/make_shopping_survey.R
#
# The data is fictional and written in an Edwardian register for colour, but it
# behaves like a real survey export: a latent "satisfaction" drives the worded
# attribute ratings and the recommend score together, demographics use
# international-standard categories (ISO/IEC 5218 sex, ISO 3166 countries) plus
# period occupation and social-class items, and the multi-select and open-text
# columns mirror the shapes the ezrsurvey helpers consume. ASCII only.

suppressPackageStartupMessages({
  library(tibble)
})

set.seed(1905)
n <- 800

latent <- stats::rnorm(n)
rating_words <- c("Very bad", "Bad", "Ok", "Good", "Very good")
clamp <- function(x, lo, hi) pmin(hi, pmax(lo, x))

make_rating <- function(latent, load, offset = 0, noise = 0.9) {
  z <- offset + latent * load + stats::rnorm(n, 0, noise)
  rating_words[clamp(round(3 + z), 1, 5)]
}
pick <- function(values, probs) sample(values, n, replace = TRUE, prob = probs)
blank_some <- function(x, p = 0.03) {
  x[stats::runif(length(x)) < p] <- ""
  x
}

country <- pick(
  c("United Kingdom", "Ireland", "United States", "Canada", "Australia",
    "India"),
  c(.52, .12, .14, .09, .08, .05)
)
region_lookup <- c(
  "United Kingdom" = "Europe", "Ireland" = "Europe",
  "United States" = "North America", "Canada" = "North America",
  "Australia" = "Oceania", "India" = "Asia"
)

shopping_survey <- tibble(
  patron_id = sprintf("P%04d", seq_len(n)),

  # demographics -- standard sex/country plus period social items
  demo_age = as.integer(clamp(round(stats::rnorm(n, 42, 14)), 18, 80)),
  demo_gender = blank_some(pick(  # ISO/IEC 5218
    c("Female", "Male", "Prefer not to answer"), c(.62, .36, .02))),
  demo_country = country,
  region = unname(region_lookup[country]),
  social_class = blank_some(pick(
    c("Upper class", "Upper middle class", "Lower middle class",
      "Skilled working class", "Working class", "Poor"),
    c(.04, .12, .22, .28, .26, .08))),
  occupation = blank_some(pick(
    c("Clerk", "Domestic servant", "Mill worker", "Shopkeeper", "Labourer",
      "Governess", "Farmer", "Seamstress", "Schoolteacher"),
    c(.14, .16, .14, .10, .15, .06, .12, .07, .06))),
  household_size = as.integer(clamp(round(stats::rnorm(n, 5, 2.4)), 1, 14)),

  # spend in shillings per week (numeric, for calc_summary)
  weekly_spend = round(clamp(stats::rnorm(n, 18, 8) + latent * 3, 2, 80), 1),

  payment = pick(c("Cash", "On account", "Barter"), c(.58, .34, .08)),
  transport = pick(
    c("On foot", "Horse and cart", "Bicycle", "Omnibus", "Railway",
      "Motor-car"),
    c(.46, .20, .14, .10, .08, .02)),
  visit_frequency = pick(  # matches the "frequency" ordinal preset
    c("Never", "Rarely", "Sometimes", "Often", "Always"),
    c(.03, .12, .30, .38, .17)),

  # key outcome: would recommend the emporium to a neighbour (0-10)
  recommend = as.integer(clamp(round(6.8 + latent * 1.7 + stats::rnorm(n, 0, 1.2)),
                               0, 10)),

  # worded attribute ratings (1-5), correlated with the latent satisfaction
  ratings_goods = make_rating(latent, 1.0, offset = 0.4),
  ratings_service = make_rating(latent, 0.9, offset = 0.1),
  ratings_credit = make_rating(latent, 0.6, offset = -0.3),
  ratings_delivery = make_rating(latent, 0.7, offset = -0.4),
  ratings_value = make_rating(latent, 1.0, offset = -0.1)
)

# Multi-select reasons for patronage (each option present, or blank).
reason_opts <- c(
  reasons_price = "Fair prices",
  reasons_quality = "Quality of the goods",
  reasons_credit = "Generous credit terms",
  reasons_proximity = "Near to home",
  reasons_variety = "Variety on offer",
  reasons_service = "Obliging staff"
)
reason_p <- c(.55, .60, .30, .48, .40, .35)
for (i in seq_along(reason_opts)) {
  col <- names(reason_opts)[i]
  shopping_survey[[col]] <- ifelse(stats::runif(n) < reason_p[i],
                                   unname(reason_opts[i]), "")
}

# Period open-text comments, mostly blank (as in real exports). Every non-blank
# comment is a hand-written line drawn WITHOUT replacement from the per-sentiment
# banks in data-raw/comments/, so no line ever repeats within the column.
read_bank <- function(name) {
  lines <- trimws(readLines(file.path("data-raw", "comments", name), warn = FALSE))
  unique(lines[nzchar(lines)])
}

# Pop unique lines from a shuffled pool; once drained, yield "" (a few extra
# blanks, still realistic) rather than erroring.
make_popper <- function(pool) {
  pool <- sample(pool)
  i <- 0L
  function() {
    i <<- i + 1L
    if (i > length(pool)) "" else pool[i]
  }
}

promoter_pop <- make_popper(read_bank("shopping_promoter.txt"))
detractor_pop <- make_popper(read_bank("shopping_detractor.txt"))
neutral_pop <- make_popper(read_bank("shopping_neutral.txt"))

grp <- ifelse(shopping_survey$recommend >= 9, "p",
              ifelse(shopping_survey$recommend <= 6, "d", "x"))
shopping_survey$comment <- vapply(grp, function(g) {
  if (g == "p" && stats::runif(1) < .5) promoter_pop()
  else if (g == "d" && stats::runif(1) < .5) detractor_pop()
  else if (g == "x" && stats::runif(1) < .3) neutral_pop()
  else ""
}, character(1))

shopping_survey <- tibble::as_tibble(shopping_survey)

if (!dir.exists("data")) dir.create("data")
save(shopping_survey, file = "data/shopping_survey.rda", compress = "xz")
message("Wrote data/shopping_survey.rda with ", nrow(shopping_survey),
        " rows and ", ncol(shopping_survey), " columns.")
