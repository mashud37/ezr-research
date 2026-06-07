#' Simulated theme-park satisfaction survey (teaching dataset)
#'
#' A fictional customer-satisfaction survey used throughout the ezrlearning book
#' and exercises. A latent "enjoyment" factor drives the `nps` score and the six
#' rating items together, so the survey helpers ([ezrsurvey::calc_nps()],
#' [ezrsurvey::ipm_model()]) and the modelling helpers
#' ([ezrmodel::drivers()], [ezrmodel::cluster()]) all find real signal. The
#' rating items are stored as **worded** Likert text on purpose, so learners
#' practise cleaning them with [ezrsurvey::recode_likert()] /
#' [ezrsurvey::ensure_numeric()] before analysis.
#'
#' @format A [tibble][tibble::tibble] with 500 rows and 14 columns:
#' \describe{
#'   \item{respondent_id}{Respondent id (character).}
#'   \item{visitor_type}{First-timer / Returning / Annual Pass.}
#'   \item{gender}{Male / Female / Non-binary.}
#'   \item{age}{Age in years (integer).}
#'   \item{region}{World region (character).}
#'   \item{spend}{Spend on the day, in local currency (numeric).}
#'   \item{nps}{0-10 recommendation score (integer outcome).}
#'   \item{rating_rides, rating_food, rating_staff, rating_cleanliness,
#'     rating_value, rating_queue}{Worded 5-point Likert ratings ("Very bad" to
#'     "Very good") -- clean these to numbers before modelling.}
#'   \item{comment}{Free-text open comment (character).}
#' }
#' @source Simulated. See `data-raw/make_data.R`.
#' @family data
#' @examples
#' head(theme_park)
"theme_park"
