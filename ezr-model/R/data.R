#' Simulated survey with an NPS target and its drivers
#'
#' A fictional consumer survey used throughout the ezrmodel examples and tests: an
#' `nps` outcome (0-10) driven by eight rated attributes, plus two categorical
#' segmenting variables. A latent satisfaction generates `nps` and the ratings
#' together, so [drivers()], [model_lm()] and [correlations()] find real signal
#' and [cluster()] finds structure.
#'
#' @format A [tibble][tibble::tibble] with 600 rows and 12 columns:
#' \describe{
#'   \item{respondent_id}{Respondent id (character).}
#'   \item{nps}{0-10 recommendation score (integer outcome).}
#'   \item{region, segment}{Categorical segmenting variables.}
#'   \item{value, quality, service, ease, support, trust, price, innovation}{
#'     1-5 attribute ratings (the candidate drivers).}
#' }
#' @source Simulated. See `data-raw/make_datasets.R`.
#' @family data
#' @examples
#' head(nps_drivers)
"nps_drivers"

#' Simulated ecommerce customer table
#'
#' A fictional customer table with latent segments (casual / regular / VIP /
#' lapsed), useful for clustering and dimensionality reduction. The numeric
#' RFM-style features (`recency_days`, `frequency`, `monetary`, `tenure_months`,
#' `returns`) carry the segment structure that [cluster()] and [reduce_dims()]
#' recover.
#'
#' @format A [tibble][tibble::tibble] with 800 rows and 7 columns:
#' \describe{
#'   \item{customer_id}{Customer id (character).}
#'   \item{recency_days}{Days since last purchase.}
#'   \item{frequency}{Number of orders.}
#'   \item{monetary}{Total spend.}
#'   \item{tenure_months}{Months since first purchase.}
#'   \item{returns}{Number of returned orders.}
#'   \item{region}{Region (character).}
#' }
#' @source Simulated. See `data-raw/make_datasets.R`.
#' @family data
#' @examples
#' head(ecommerce)
"ecommerce"

#' Simulated product reviews (open text)
#'
#' A small fictional corpus of product reviews with a star `rating` and free
#' `text`, used by the text helpers ([tokenize_text()], [term_freq()],
#' [topics()], [summarise_text()]).
#'
#' @format A [tibble][tibble::tibble] with 240 rows and 4 columns:
#' \describe{
#'   \item{review_id}{Review id (character).}
#'   \item{product}{Product name (character).}
#'   \item{rating}{1-5 star rating (integer).}
#'   \item{text}{Review text (character).}
#' }
#' @source Simulated. See `data-raw/make_datasets.R`.
#' @family data
#' @examples
#' head(reviews)
"reviews"

#' Simulated consumer personas (a clean clustering example)
#'
#' A fictional customer table built from explicit mathematical functions so that
#' every clustering technique in the package gives a textbook "what good looks
#' like" result. Five personas are drawn as well-separated Gaussian blobs (via
#' `MASS::mvrnorm`) in six informative dimensions -- the between-cluster distance
#' is far larger than the within-cluster spread -- so [cluster()] with `"kmeans"`,
#' `"hclust"` or `"pam"` all recover the same segments, the silhouette peaks at
#' the true `k = 5` (so `cluster(personas)` with `k = NULL` finds it), and
#' [reduce_dims()] (PCA / UMAP / t-SNE) shows clean structure. A redundant column
#' (`pages_viewed`, which tracks `browse_minutes`) gives PCA an obvious low-rank
#' structure without disturbing the segments. The ground-truth label is kept in
#' `persona` so you can check a recovered solution with [cluster_profile()].
#'
#' @format A [tibble][tibble::tibble] with 740 rows and 9 columns:
#' \describe{
#'   \item{customer_id}{Customer id (character).}
#'   \item{spend_index}{Monthly spend index (0-120).}
#'   \item{visit_freq}{Visits per month (integer).}
#'   \item{basket_size}{Average items per basket.}
#'   \item{discount_sensitivity}{Responsiveness to discounts (0-100).}
#'   \item{loyalty_score}{Loyalty-programme engagement (0-100).}
#'   \item{browse_minutes}{Average session length in minutes.}
#'   \item{pages_viewed}{Pages viewed per session (redundant with
#'     `browse_minutes`).}
#'   \item{persona}{Ground-truth segment label (character).}
#' }
#' @source Simulated. See `data-raw/make_datasets.R`.
#' @family data
#' @examplesIf requireNamespace("cluster", quietly = TRUE)
#' cl <- cluster(personas, vars = spend_index:browse_minutes)
#' cl
#' cluster_profile(cl, persona)
"personas"
