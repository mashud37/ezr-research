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
# Every non-blank review is a hand-written line drawn WITHOUT replacement from
# the per-sentiment banks in data-raw/comments/, so no line ever repeats in the
# corpus. Some rows are left blank, as in a real export where not every rating
# carries written feedback.
read_bank <- function(name) {
  lines <- trimws(readLines(file.path("data-raw", "comments", name), warn = FALSE))
  unique(lines[nzchar(lines)])
}
make_popper <- function(pool) {
  pool <- sample(pool)
  i <- 0L
  function() {
    i <<- i + 1L
    if (i > length(pool)) "" else pool[i]
  }
}
pos_pop <- make_popper(read_bank("reviews_pos.txt"))
neg_pop <- make_popper(read_bank("reviews_neg.txt"))
neutral_pop <- make_popper(read_bank("reviews_neutral.txt"))
k <- 240
rating <- sample(1:5, k, replace = TRUE, prob = c(.12, .13, .2, .3, .25))
text <- vapply(rating, function(r) {
  if (r >= 4) { if (stats::runif(1) < .6) pos_pop() else "" }
  else if (r <= 2) { if (stats::runif(1) < .6) neg_pop() else "" }
  else { if (stats::runif(1) < .4) neutral_pop() else "" }
}, character(1))
reviews <- tibble(
  review_id = sprintf("V%04d", seq_len(k)),
  product = sample(c("Alpha", "Bravo", "Comet"), k, replace = TRUE),
  rating = as.integer(rating),
  text = text
)

# ---- personas: math-generated segments, clean for every clustering method ----
# Five consumer personas drawn as well-separated Gaussian blobs in six
# informative dimensions (between-cluster distance >> within-cluster spread), so
# kmeans, hclust and pam all recover them and the silhouette peaks at the true
# k = 5. A redundant column (`pages_viewed`, which tracks browsing time) is added
# so PCA / scree show a clean low-rank structure without disturbing the segments.
# MASS::mvrnorm draws each blob; the ground-truth label is kept in `persona` for
# validating recovered clusters.
set.seed(123)
persona_names <- c("Premium loyalist", "Bargain hunter", "Occasional browser",
                   "Family shopper", "New minimalist")
features <- c("spend_index", "visit_freq", "basket_size",
              "discount_sensitivity", "loyalty_score", "browse_minutes")
centroids <- matrix(
  c(85,  8, 22, 15, 90, 12,
    35, 14,  9, 88, 30, 28,
    20,  3,  5, 45, 20, 55,
    65, 18, 30, 55, 60,  8,
    42,  5,  7, 28, 38, 18),
  nrow = 5, byrow = TRUE, dimnames = list(persona_names, features)
)
within_sd <- c(spend_index = 6, visit_freq = 1.4, basket_size = 2.2,
               discount_sensitivity = 6, loyalty_score = 5, browse_minutes = 3.8)
sizes <- c(190, 165, 150, 130, 105)

blocks <- lapply(seq_len(nrow(centroids)), function(i) {
  X <- MASS::mvrnorm(sizes[i], mu = centroids[i, ], Sigma = diag(within_sd^2))
  as.data.frame(X)
})
mat <- do.call(rbind, blocks)
persona <- rep(persona_names, sizes)

personas <- tibble(
  customer_id = sprintf("P%04d", seq_len(nrow(mat))),
  spend_index = round(clamp(mat$spend_index, 0, 120), 1),
  visit_freq = as.integer(clamp(round(mat$visit_freq), 1, 40)),
  basket_size = round(clamp(mat$basket_size, 1, 60), 1),
  discount_sensitivity = round(clamp(mat$discount_sensitivity, 0, 100), 1),
  loyalty_score = round(clamp(mat$loyalty_score, 0, 100), 1),
  browse_minutes = round(clamp(mat$browse_minutes, 0, 120), 1),
  # redundant: pages viewed tracks browsing time (correlated; little extra info)
  pages_viewed = as.integer(clamp(round(0.9 * mat$browse_minutes +
                                        stats::rnorm(nrow(mat), 4, 3)), 1, 120)),
  persona = persona
)
# Shuffle so the blocks are not in cluster order, then renumber the ids.
personas <- personas[sample(nrow(personas)), ]
personas$customer_id <- sprintf("P%04d", seq_len(nrow(personas)))
personas <- tibble::as_tibble(personas)

if (!dir.exists("data")) dir.create("data")
save(nps_drivers, file = "data/nps_drivers.rda", compress = "xz")
save(ecommerce, file = "data/ecommerce.rda", compress = "xz")
save(reviews, file = "data/reviews.rda", compress = "xz")
save(personas, file = "data/personas.rda", compress = "xz")
message("Wrote nps_drivers (", nrow(nps_drivers), "), ecommerce (",
        nrow(ecommerce), "), reviews (", nrow(reviews), "), personas (",
        nrow(personas), ").")
