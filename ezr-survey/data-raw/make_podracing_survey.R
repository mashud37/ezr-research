# Generates `podracing_survey`, the package's simulated fan-survey dataset:
# consumer feedback from a Boonta Eve-style pod-racing meeting. Run with:
#   Rscript data-raw/make_podracing_survey.R
#
# The data is fictional (an affectionate Star Wars pod-racing parody) but built
# to behave like a real survey export: a latent "enjoyment" drives correlated
# attribute ratings and the recommend score, demographics follow plausible skews
# and use international-standard categories (ISO/IEC 5218 sex, ISCED education,
# ILO labour-force status, ISIC sectors, ISO 3166 countries), and the
# multi-select / sponsor / open-text columns mirror the shapes the ezrsurvey
# helpers consume. The open-text comments are deliberately diverse and name many
# drivers, places and races, so they exercise text / NER helpers. ASCII only.

suppressPackageStartupMessages({
  library(tibble)
})

set.seed(42)
n <- 1000

# Latent enjoyment underlying ratings and the recommend score.
latent <- stats::rnorm(n)

rating_words <- c("Very bad", "Bad", "Ok", "Good", "Very good")

clamp <- function(x, lo, hi) pmin(hi, pmax(lo, x))

# Rating centred at 3 + `offset`, correlated with `latent` via `load`. A fixed
# centre (not per-feature quantiles) lets attributes genuinely differ in
# performance, which is what the IPM plot is there to show.
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

podracing_survey <- tibble(
  respondent_id = sprintf("R%05d", seq_len(n)),
  collector = pick(c("email", "panel", "socials", "in_app"),
                   c(.30, .35, .20, .15)),

  # demographics -- international-standard categories
  demo_age = as.integer(clamp(round(stats::rnorm(n, 32, 12)), 16, 70)),
  demo_gender = blank_some(pick(  # ISO/IEC 5218, extended for non-binary
    c("Male", "Female", "Non-binary", "Prefer not to answer"),
    c(.55, .40, .03, .02))),
  demo_edu = blank_some(pick(     # ISCED 2011 (broad)
    c("Primary or less", "Lower secondary", "Upper secondary",
      "Short-cycle tertiary", "Bachelor or equivalent",
      "Master or equivalent", "Doctoral or equivalent"),
    c(.05, .12, .28, .12, .26, .13, .04))),
  demo_country = country,
  region = unname(region_lookup[country]),
  demo_job = blank_some(pick(     # ILO labour-force status
    c("Employed full-time", "Employed part-time", "Unemployed",
      "Student", "Not in labour force"),
    c(.48, .14, .07, .22, .09))),
  demo_sector = blank_some(pick(  # ISIC Rev.4 sections (abbreviated)
    c("Manufacturing", "Information and communication",
      "Financial and insurance", "Education",
      "Human health and social work", "Wholesale and retail trade",
      "Arts and entertainment", "Public administration", "Other services"),
    c(.12, .16, .09, .13, .10, .12, .12, .07, .09))),

  # event attendance (single-select; long labels exercise the auto bar layout)
  race_attended = pick(
    c("Boonta Eve Classic", "Vinta Harvest Classic", "Phoebos Memorial Run",
      "Andobi Mountain Run", "Mos Espa Circuit"),
    c(.40, .20, .16, .12, .12)),
  fav_driver = blank_some(pick(
    c("Anakin Skywalker", "Sebulba", "Ben Quadinaros", "Gasgano",
      "Ody Mandrell", "Ratts Tyerell", "Mawhonic", "Teemto Pagalies",
      "Dud Bolt", "Boles Roor"),
    c(.30, .18, .06, .09, .08, .05, .06, .07, .06, .05)), 0.04),

  # key outcome (skewed positive, as a healthy recommend sample should be)
  nps_value = as.integer(clamp(round(7.7 + latent * 1.6 + stats::rnorm(n, 0, 1.1)),
                               0, 10)),
  satis_return = make_rating(latent, 1.1, offset = 0.6),

  # attribute ratings (worded 1-5): distinct performance offsets per attribute,
  # all correlated with the latent enjoyment at varying strengths.
  ratings_atmosphere = make_rating(latent, 1.0, offset = 0.7),
  ratings_commentary = make_rating(latent, 0.6, offset = -0.4),
  ratings_safety = make_rating(latent, 0.7, offset = -0.1),
  ratings_speed = make_rating(latent, 0.9, offset = 0.6),
  ratings_value = make_rating(latent, 1.0, offset = -0.2),
  ratings_venue = make_rating(latent, 0.8, offset = 0.1)
)

# Recode satis_return wording to the "likely" scale it represents.
return_words <- c("Very unlikely", "Unlikely", "Not sure", "Likely", "Very likely")
podracing_survey$satis_return <- return_words[match(podracing_survey$satis_return,
                                                    rating_words)]

# Multi-select motivations: each option present (its label) or blank.
motivation_opts <- c(
  motivations_speed = "For the speed and the thrill",
  motivations_drivers = "To support a favourite driver",
  motivations_betting = "For the betting and the wupiupi",
  motivations_social = "A day out with friends and family",
  motivations_tradition = "Boonta Eve tradition"
)
motivation_p <- c(.78, .52, .30, .44, .35)
for (i in seq_along(motivation_opts)) {
  col <- names(motivation_opts)[i]
  chosen <- stats::runif(n) < motivation_p[i]
  podracing_survey[[col]] <- ifelse(chosen, unname(motivation_opts[i]), "")
}

# Sponsor questions for three (invented) pod-racing sponsor brands.
brands <- c("PodTech", "BanthaBrew", "JawaJuice")
recall_opts <- c("Sponsor", "Not a sponsor", "Don't know this brand")
like_opts <- c("Very likeable", "Likeable", "Unlikeable", "Very unlikeable")
for (b in brands) {
  podracing_survey[[paste0("partner_recall_", b)]] <-
    blank_some(pick(recall_opts, c(.42, .33, .25)), 0.05)
  podracing_survey[[paste0("partner_likeability_", b)]] <-
    blank_some(pick(like_opts, c(.22, .46, .22, .10)), 0.20)
}

# Open-text comments, mostly blank (as in real exports). Every non-blank comment
# is a hand-written line drawn WITHOUT replacement from the per-sentiment banks
# in data-raw/comments/, so no line ever repeats within a `_com` column or across
# them. The promoter/detractor pools are shared between nps_com and show_com:
# nps_com draws first, then show_com continues the same poppers, so a line used
# in one column can never reappear in the other.
read_bank <- function(name) {
  lines <- trimws(readLines(file.path("data-raw", "comments", name), warn = FALSE))
  unique(lines[nzchar(lines)])
}

# Pop unique lines from a shuffled pool; once the pool is drained, yield "" (a
# few extra blanks, still realistic) rather than erroring.
make_popper <- function(pool) {
  pool <- sample(pool)
  i <- 0L
  function() {
    i <<- i + 1L
    if (i > length(pool)) "" else pool[i]
  }
}

promoter_pop <- make_popper(read_bank("podracing_promoter.txt"))
detractor_pop <- make_popper(read_bank("podracing_detractor.txt"))
neutral_pop <- make_popper(read_bank("podracing_neutral.txt"))
# show_com is a general "anything goes" column: draw across all three sentiments.
show_pop <- function() {
  pickers <- c(promoter_pop, detractor_pop, neutral_pop)
  pickers[[sample.int(3L, 1L, prob = c(.4, .35, .25))]]()
}

grp <- ifelse(podracing_survey$nps_value >= 9, "p",
              ifelse(podracing_survey$nps_value <= 6, "d", "x"))
podracing_survey$nps_com <- vapply(grp, function(g) {
  if (g == "p" && stats::runif(1) < .5) promoter_pop()
  else if (g == "d" && stats::runif(1) < .5) detractor_pop()
  else ""
}, character(1))
podracing_survey$show_com <- vapply(seq_len(n), function(i) {
  if (stats::runif(1) < .45) show_pop() else ""
}, character(1))

podracing_survey <- tibble::as_tibble(podracing_survey)

# Save into the package's data/ directory (run from the package root).
if (!dir.exists("data")) dir.create("data")
save(podracing_survey, file = "data/podracing_survey.rda", compress = "xz")
message("Wrote data/podracing_survey.rda with ", nrow(podracing_survey),
        " rows and ", ncol(podracing_survey), " columns.")
