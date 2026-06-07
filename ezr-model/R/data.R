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
