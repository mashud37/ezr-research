# Generates the teaching dataset shipped with ezrlearning. Run from the package
# root:  Rscript data-raw/make_data.R
# All data is fictional, simulated with a fixed seed so it behaves like a real
# theme-park customer-satisfaction survey: a latent "enjoyment" drives the NPS
# score and the (deliberately worded) rating items together.

suppressPackageStartupMessages(library(tibble))
set.seed(2025)
clamp <- function(x, lo, hi) pmin(hi, pmax(lo, x))
n <- 500

latent <- stats::rnorm(n)

# Worded Likert rating from a latent loading (teaches cleaning before analysis).
worded <- function(load, offset = 0) {
  z <- 3 + offset + latent * load + stats::rnorm(n, 0, 0.8)
  lvl <- clamp(round(z), 1, 5)
  c("Very bad", "Bad", "Ok", "Good", "Very good")[lvl]
}

pos <- c(
  "Loved the rides and the staff were so friendly.",
  "Great day out, clean park and short queues.",
  "Fantastic value, the kids had an amazing time.",
  "Best theme park visit we have had, will come back."
)
neg <- c(
  "The queues were far too long and the food was cold.",
  "Overpriced tickets and the staff seemed stressed.",
  "Rides kept breaking down, very disappointing day.",
  "Dirty bathrooms and rude staff, would not return."
)
neutral <- c(
  "It was fine, nothing special but the kids enjoyed it.",
  "Average park, decent rides but pricey food.",
  "An okay day, some good rides and some long waits."
)

nps <- as.integer(clamp(round(8.0 + latent * 1.4 + stats::rnorm(n, 0, 1.0)), 0, 10))
comment <- vapply(nps, function(v) {
  if (v >= 9) sample(pos, 1) else if (v <= 6) sample(neg, 1) else sample(neutral, 1)
}, character(1))

theme_park <- tibble(
  respondent_id = sprintf("R%04d", seq_len(n)),
  visitor_type = sample(c("First-timer", "Returning", "Annual Pass"), n,
                        replace = TRUE, prob = c(.45, .4, .15)),
  gender = sample(c("Male", "Female", "Non-binary"), n,
                  replace = TRUE, prob = c(.48, .48, .04)),
  age = as.integer(clamp(round(stats::rnorm(n, 34, 12)), 12, 75)),
  region = sample(c("North America", "Europe", "Asia", "Oceania", "Latin America"),
                  n, replace = TRUE, prob = c(.42, .3, .14, .08, .06)),
  spend = round(clamp(stats::rnorm(n, 120, 45) + latent * 15, 20, 400), 2),
  nps = nps,
  rating_rides = worded(1.0, 0.3),
  rating_food = worded(0.6, -0.3),
  rating_staff = worded(0.8, 0.2),
  rating_cleanliness = worded(0.7, 0.1),
  rating_value = worded(0.5, -0.4),
  rating_queue = worded(0.6, -0.2),
  comment = comment
)

if (!dir.exists("data")) dir.create("data")
save(theme_park, file = "data/theme_park.rda", compress = "xz")
message("Wrote theme_park (", nrow(theme_park), " rows, ", ncol(theme_park),
        " cols).")
