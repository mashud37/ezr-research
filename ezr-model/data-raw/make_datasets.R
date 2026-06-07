# Generates the three datasets shipped with ezrmodel. Run from the package root:
#   Rscript data-raw/make_datasets.R
# All data is fictional, simulated with fixed seeds so it behaves like real
# consumer/behavioural data (a latent driver of NPS, latent customer segments).

suppressPackageStartupMessages(library(tibble))
clamp <- function(x, lo, hi) pmin(hi, pmax(lo, x))

# ---- nps_drivers: survey-style, an NPS target driven by rated attributes -----
set.seed(42)
n <- 600
latent <- stats::rnorm(n)

rate <- function(load, offset = 0) {
  as.integer(clamp(round(3 + offset + latent * load + stats::rnorm(n, 0, 0.8)),
                   1, 5))
}

nps_drivers <- tibble(
  respondent_id = sprintf("R%04d", seq_len(n)),
  nps = as.integer(clamp(round(6.6 + latent * 1.8 + stats::rnorm(n, 0, 1.2)),
                         0, 10)),
  region = sample(c("North America", "Europe", "Asia", "Latin America"),
                  n, replace = TRUE, prob = c(.4, .3, .2, .1)),
  segment = sample(c("New", "Returning", "Loyal", "At risk"),
                   n, replace = TRUE, prob = c(.25, .3, .3, .15)),
  value = rate(0.9, 0.2),
  quality = rate(1.0, 0.4),
  service = rate(0.7, -0.1),
  ease = rate(0.6, 0.1),
  support = rate(0.5, -0.3),
  trust = rate(0.8, 0.3),
  price = rate(0.4, -0.2),
  innovation = rate(0.6, 0.0)
)

# ---- ecommerce: customer table with latent segments (for clustering) ---------
set.seed(7)
m <- 800
seg <- sample(1:4, m, replace = TRUE, prob = c(.35, .3, .2, .15))
# segment archetypes: 1 = casual, 2 = regular, 3 = VIP, 4 = lapsed
recency_mu <- c(40, 20, 8, 120)[seg]
freq_mu <- c(2, 6, 18, 1.5)[seg]
mon_mu <- c(40, 120, 600, 30)[seg]
tenure_mu <- c(8, 20, 36, 30)[seg]

ecommerce <- tibble(
  customer_id = sprintf("C%05d", seq_len(m)),
  recency_days = as.integer(clamp(round(stats::rgamma(m, shape = 3,
                                                      scale = recency_mu / 3)),
                                  1, 400)),
  frequency = as.integer(clamp(round(stats::rgamma(m, shape = 2,
                                                   scale = freq_mu / 2)),
                               1, 80)),
  monetary = round(clamp(stats::rgamma(m, shape = 2, scale = mon_mu / 2),
                         5, 5000), 2),
  tenure_months = as.integer(clamp(round(stats::rnorm(m, tenure_mu, 6)), 1, 60)),
  returns = as.integer(clamp(stats::rpois(m, c(0.3, 0.8, 1.5, 0.2)[seg]), 0, 12)),
  region = sample(c("North America", "Europe", "Asia"), m, replace = TRUE,
                  prob = c(.45, .35, .2))
)

# ---- reviews: small open-text corpus (Phase 2 NLP) ---------------------------
set.seed(11)
pos <- c(
  "Great quality and fast delivery, would buy again.",
  "Excellent value for money and the support team was helpful.",
  "Easy to use and works exactly as described.",
  "Love the product, exceeded my expectations.",
  "Fantastic service from start to finish."
)
neg <- c(
  "Poor quality, broke after a week of use.",
  "Delivery was late and customer service ignored my emails.",
  "Overpriced for what you get, disappointed.",
  "Difficult to set up and the instructions were unclear.",
  "Returned it, did not match the description at all."
)
neutral <- c(
  "It is okay, does the job but nothing special.",
  "Average product, average price, average experience.",
  "Works fine so far, will see how it holds up."
)
k <- 240
rating <- sample(1:5, k, replace = TRUE, prob = c(.12, .13, .2, .3, .25))
text <- vapply(rating, function(r) {
  if (r >= 4) sample(pos, 1) else if (r <= 2) sample(neg, 1) else sample(neutral, 1)
}, character(1))
reviews <- tibble(
  review_id = sprintf("V%04d", seq_len(k)),
  product = sample(c("Alpha", "Bravo", "Comet"), k, replace = TRUE),
  rating = as.integer(rating),
  text = text
)

if (!dir.exists("data")) dir.create("data")
save(nps_drivers, file = "data/nps_drivers.rda", compress = "xz")
save(ecommerce, file = "data/ecommerce.rda", compress = "xz")
save(reviews, file = "data/reviews.rda", compress = "xz")
message("Wrote nps_drivers (", nrow(nps_drivers), "), ecommerce (",
        nrow(ecommerce), "), reviews (", nrow(reviews), ").")
