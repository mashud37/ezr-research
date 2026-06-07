# Generates `consumer_survey`, the package's simulated consumer-survey dataset.
# Run with: Rscript data-raw/make_consumer_survey.R
#
# The data is fictional but built to behave like a real survey export: a latent
# "satisfaction" drives correlated feature ratings and NPS, demographics follow
# plausible skews, and multi-select / brand / open-text columns mirror the
# shapes the ezrsurvey helpers are designed to consume.

suppressPackageStartupMessages({
  library(tibble)
})

set.seed(42)
n <- 1000

# Latent satisfaction underlying ratings and NPS.
latent <- stats::rnorm(n)

rating_words <- c("Very bad", "Bad", "Ok", "Good", "Very good")

clamp <- function(x, lo, hi) pmin(hi, pmax(lo, x))

# Rating centred at 3 + `offset`, correlated with `latent` via `load`. Using a
# fixed centre (rather than per-feature quantiles) lets features genuinely
# differ in performance, which is what the IPM plot is there to show.
make_rating <- function(latent, load, offset = 0, noise = 0.9) {
  z <- offset + latent * load + stats::rnorm(n, 0, noise)
  idx <- clamp(round(3 + z), 1, 5)
  rating_words[idx]
}

pick <- function(values, probs) sample(values, n, replace = TRUE, prob = probs)

# A handful of blanks scattered through a vector to mimic item non-response.
blank_some <- function(x, p = 0.03) {
  x[stats::runif(length(x)) < p] <- ""
  x
}

country <- pick(
  c("United States", "United Kingdom", "Germany", "France", "Canada",
    "Brazil", "Australia", "Japan", "Sweden", "Mexico"),
  c(.34, .12, .10, .07, .07, .08, .05, .05, .03, .09)
)
region_lookup <- c(
  "United States" = "North America", "Canada" = "North America",
  "Mexico" = "North America", "Brazil" = "Latin America",
  "United Kingdom" = "Europe", "Germany" = "Europe", "France" = "Europe",
  "Sweden" = "Europe", "Australia" = "Oceania", "Japan" = "Asia"
)

consumer_survey <- tibble(
  respondent_id = sprintf("R%05d", seq_len(n)),
  collector = pick(c("email", "panel", "socials", "in_app"),
                   c(.30, .35, .20, .15)),

  # demographics
  demo_age = as.integer(clamp(round(stats::rnorm(n, 24, 6)), 14, 45)),
  demo_gender = blank_some(pick(
    c("As a man", "As a woman", "Non-binary person", "Prefer not to answer"),
    c(.66, .24, .06, .04))),
  demo_edu = blank_some(pick(
    c("Less than high school", "High school or equivalent",
      "Some college but no degree", "Associate degree",
      "Bachelor degree", "Masters degree or higher"),
    c(.05, .22, .25, .12, .26, .10))),
  demo_country = country,
  region = unname(region_lookup[country]),
  demo_job = blank_some(pick(
    c("Student", "Full-time", "Part-time", "Looking for work", "Other"),
    c(.34, .40, .12, .08, .06))),
  demo_sector = blank_some(pick(
    c("Technology", "Education", "Healthcare", "Finance", "Retail",
      "Manufacturing", "Creative", "Public sector", "Other"),
    c(.20, .14, .10, .09, .10, .08, .12, .07, .10))),

  # key outcome (skewed positive, as a healthy NPS sample should be)
  nps_value = as.integer(clamp(round(7.7 + latent * 1.6 + stats::rnorm(n, 0, 1.1)),
                               0, 10)),
  satis_return = make_rating(latent, 1.1, offset = 0.6),

  # feature ratings (worded 1-5): distinct performance offsets per feature, all
  # correlated with the latent satisfaction at varying strengths.
  ratings_content = make_rating(latent, 1.0, offset = 0.7),
  ratings_production = make_rating(latent, 0.9, offset = 0.3),
  ratings_hosts = make_rating(latent, 0.6, offset = -0.4),
  ratings_pacing = make_rating(latent, 0.7, offset = -0.1),
  ratings_value = make_rating(latent, 1.0, offset = 0.2)
)

# Recode satis_return wording to the "likely" scale it represents.
return_words <- c("Very unlikely", "Unlikely", "Not sure", "Likely", "Very likely")
consumer_survey$satis_return <- return_words[match(consumer_survey$satis_return,
                                                   rating_words)]

# Multi-select motivations: each option present (its label) or blank.
motivation_opts <- c(
  motivations_entertainment = "To be entertained",
  motivations_learn = "To learn something new",
  motivations_social = "To connect with others",
  motivations_brand = "Interest in the brands",
  motivations_habit = "Out of habit"
)
motivation_p <- c(.72, .40, .35, .18, .28)
for (i in seq_along(motivation_opts)) {
  col <- names(motivation_opts)[i]
  chosen <- stats::runif(n) < motivation_p[i]
  consumer_survey[[col]] <- ifelse(chosen, unname(motivation_opts[i]), "")
}

# Brand questions for three partner brands.
brands <- c("Acme", "Globex", "Initech")
recall_opts <- c("Sponsor", "Not a sponsor", "Don't know this brand")
like_opts <- c("Very likeable", "Likeable", "Unlikeable", "Very unlikeable")
for (b in brands) {
  consumer_survey[[paste0("partner_recall_", b)]] <-
    blank_some(pick(recall_opts, c(.42, .33, .25)), 0.05)
  consumer_survey[[paste0("partner_likeability_", b)]] <-
    blank_some(pick(like_opts, c(.22, .46, .22, .10)), 0.20)
}

# Open-text comments, mostly blank (as in real exports).
promoter_lines <- c(
  "Loved the production quality and the hosts kept it engaging throughout.",
  "Best broadcast yet, the pacing was spot on and I learned a lot.",
  "Really enjoyed it, felt like great value for my time.",
  "The content was fantastic and I will definitely watch again."
)
detractor_lines <- c(
  "Felt too long and the pacing dragged in the middle.",
  "Production was rough and I struggled to stay interested.",
  "Not much new here, hosts were hard to follow.",
  "Expected more, the value just was not there for me."
)
grp <- ifelse(consumer_survey$nps_value >= 9, "p",
              ifelse(consumer_survey$nps_value <= 6, "d", "x"))
nps_com <- vapply(grp, function(g) {
  if (g == "p" && stats::runif(1) < .5) sample(promoter_lines, 1)
  else if (g == "d" && stats::runif(1) < .5) sample(detractor_lines, 1)
  else ""
}, character(1))
consumer_survey$nps_com <- unname(nps_com)
consumer_survey$show_com <- blank_some(
  sample(c(promoter_lines, detractor_lines, rep("", 8)), n, replace = TRUE), 0)

consumer_survey <- tibble::as_tibble(consumer_survey)

# Save into the package's data/ directory (run from the package root).
if (!dir.exists("data")) dir.create("data")
save(consumer_survey, file = "data/consumer_survey.rda", compress = "xz")
message("Wrote data/consumer_survey.rda with ", nrow(consumer_survey), " rows and ",
        ncol(consumer_survey), " columns.")
