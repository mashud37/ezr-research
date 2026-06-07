#' Simulated consumer-survey responses
#'
#' A fictional but realistic consumer-survey dataset used throughout the ezrsurvey
#' examples and tests -- the package's answer to `starwars` or the baseball data,
#' but survey-shaped. A latent satisfaction drives correlated feature ratings and
#' NPS, demographics follow plausible skews, and the multi-select, brand and
#' open-text columns mirror the shapes the helpers consume. Blanks and
#' "Prefer not to answer" responses are sprinkled in so cleaning helpers have
#' something to do.
#'
#' @format A [tibble][tibble::tibble] with 1,000 rows and 29 columns:
#' \describe{
#'   \item{respondent_id}{Unique respondent id (character).}
#'   \item{collector}{Survey source: email, panel, socials or in_app.}
#'   \item{demo_age}{Age in years (integer, 14-45).}
#'   \item{demo_gender}{Gender identity (some blank / "Prefer not to answer").}
#'   \item{demo_edu}{Highest education level.}
#'   \item{demo_country}{Country of residence.}
#'   \item{region}{World region derived from `demo_country`.}
#'   \item{demo_job}{Employment status.}
#'   \item{demo_sector}{Sector or field of study.}
#'   \item{nps_value}{0-10 "how likely to recommend" rating (integer).}
#'   \item{satis_return}{Likelihood of returning (Very unlikely .. Very likely).}
#'   \item{ratings_content, ratings_production, ratings_hosts, ratings_pacing,
#'     ratings_value}{Worded 1-5 feature ratings (Very bad .. Very good).}
#'   \item{motivations_entertainment, motivations_learn, motivations_social,
#'     motivations_brand, motivations_habit}{Multi-select motivations; each holds
#'     its option text when chosen, otherwise `""`.}
#'   \item{partner_recall_Acme, partner_recall_Globex, partner_recall_Initech}{
#'     Sponsor recall per brand (Sponsor / Not a sponsor / Don't know this
#'     brand).}
#'   \item{partner_likeability_Acme, partner_likeability_Globex,
#'     partner_likeability_Initech}{Brand likeability (Very likeable ..
#'     Very unlikeable).}
#'   \item{nps_com, show_com}{Open-text comments (mostly blank).}
#' }
#'
#' @source Simulated. See `data-raw/make_consumer_survey.R` for the generator.
#' @family data
#'
#' @examples
#' calc_percentage(consumer_survey, demo_gender, sort = "desc")
#' calc_nps(consumer_survey, nps_value)
"consumer_survey"

#' Country to region lookup
#'
#' A tidy lookup table mapping country names to a world `region` and a finer
#' `subregion`, used by [recode_region()] / [add_region()] to turn a country
#' column into regions.
#'
#' @format A [tibble][tibble::tibble] with 182 rows and 3 columns:
#' \describe{
#'   \item{country}{Country name.}
#'   \item{region}{World region (Africa, Asia, Europe, Middle East,
#'     North America, Oceania, South America).}
#'   \item{subregion}{Finer subregion (e.g. Western Europe, East Asia).}
#' }
#' @family data
#' @source Compiled from a standard country/region classification. See
#'   `data-raw/make_country_region.R`.
#' @seealso [recode_region()], [add_region()].
#' @examples
#' head(country_region)
#' recode_region("Germany")
"country_region"

#' Currency exchange-rate snapshot
#'
#' A dated, approximate reference table of exchange rates used by
#' [convert_currency()] / [add_currency()] when no custom rates are supplied.
#' Rates are expressed as units of the currency per 1 US dollar (base `USD`).
#' These are a convenience snapshot, **not** live rates -- pass your own `rates`
#' to the conversion helpers when accuracy matters.
#'
#' @format A [tibble][tibble::tibble] with one row per currency and columns:
#' \describe{
#'   \item{currency}{ISO 4217 code (e.g. `"EUR"`).}
#'   \item{name}{Currency name.}
#'   \item{per_usd}{Units of the currency per 1 US dollar.}
#' }
#' The snapshot date is stored in `attr(currency_rates, "snapshot_date")`.
#' @family data
#' @source Approximate reference snapshot. See
#'   `data-raw/make_currency_rates.R`.
#' @seealso [convert_currency()], [add_currency()], [list_currencies()].
#' @examples
#' head(currency_rates)
#' attr(currency_rates, "snapshot_date")
"currency_rates"
