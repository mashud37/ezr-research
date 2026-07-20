#' Simulated pod-racing fan survey
#'
#' A fictional consumer-feedback survey from a Boonta Eve-style pod-racing
#' meeting -- an affectionate Star Wars parody used throughout the ezrsurvey
#' examples and tests (the package's literal answer to `starwars`, but
#' survey-shaped). A latent enjoyment drives correlated attribute ratings and the
#' recommend score, the demographics use international-standard categories
#' (ISO/IEC 5218 sex, ISCED education, ILO labour-force status, ISIC sectors,
#' ISO 3166 countries), and the multi-select, sponsor and open-text columns mirror
#' the shapes the helpers consume. The open-text comments deliberately name many
#' drivers, places and races, so they exercise the text / NER helpers. Blanks and
#' "Prefer not to answer" responses are sprinkled in so cleaning helpers have
#' something to do.
#'
#' @format A [tibble][tibble::tibble] with 1,000 rows and 32 columns:
#' \describe{
#'   \item{respondent_id}{Unique respondent id (character).}
#'   \item{collector}{Survey source: email, panel, socials or in_app.}
#'   \item{demo_age}{Age in years (integer, 16-70).}
#'   \item{demo_gender}{Sex/gender: Male, Female, Non-binary (ISO/IEC 5218,
#'     extended), some blank / "Prefer not to answer".}
#'   \item{demo_edu}{Highest education level (ISCED 2011 broad categories).}
#'   \item{demo_country}{Country of residence (ISO 3166 names).}
#'   \item{region}{World region derived from `demo_country`.}
#'   \item{demo_job}{Labour-force status (ILO categories).}
#'   \item{demo_sector}{Industry sector (ISIC Rev.4 sections).}
#'   \item{race_attended}{Which meeting they attended (e.g. "Boonta Eve
#'     Classic"); long labels that exercise the auto bar layout.}
#'   \item{fav_driver}{Favourite pod-racer (e.g. "Anakin Skywalker", "Sebulba").}
#'   \item{nps_value}{0-10 "how likely to recommend attending" rating (integer).}
#'   \item{satis_return}{Likelihood of returning next season (Very unlikely ..
#'     Very likely).}
#'   \item{ratings_atmosphere, ratings_commentary, ratings_safety, ratings_speed,
#'     ratings_value, ratings_venue}{Worded 1-5 attribute ratings (Very bad ..
#'     Very good).}
#'   \item{motivations_speed, motivations_drivers, motivations_betting,
#'     motivations_social, motivations_tradition}{Multi-select reasons for
#'     attending; each holds its option text when chosen, otherwise `""`.}
#'   \item{partner_recall_PodTech, partner_recall_BanthaBrew,
#'     partner_recall_JawaJuice}{Sponsor recall per brand (Sponsor / Not a
#'     sponsor / Don't know this brand).}
#'   \item{partner_likeability_PodTech, partner_likeability_BanthaBrew,
#'     partner_likeability_JawaJuice}{Sponsor likeability (Very likeable ..
#'     Very unlikeable).}
#'   \item{nps_com, show_com}{Open-text comments (mostly blank).}
#' }
#'
#' @source Simulated. See `data-raw/make_podracing_survey.R` for the generator.
#' @family data
#'
#' @examples
#' calc_percentage(podracing_survey, demo_gender, sort = "desc")
#' calc_nps(podracing_survey, nps_value)
"podracing_survey"

#' Simulated historical shopping-behaviour survey
#'
#' A fictional survey of patrons of a turn-of-the-century (c. 1905) general
#' emporium, written in an Edwardian register for colour. It behaves like a real
#' survey export -- a latent satisfaction drives the worded attribute ratings and
#' the recommend score together, demographics use standard sex/country categories
#' alongside period social-class and occupation items, and the multi-select and
#' open-text columns mirror the shapes the helpers consume. A companion to
#' [podracing_survey] for examples that want a second, very different theme.
#'
#' @format A [tibble][tibble::tibble] with 800 rows and 25 columns:
#' \describe{
#'   \item{patron_id}{Unique patron id (character).}
#'   \item{demo_age}{Age in years (integer, 18-80).}
#'   \item{demo_gender}{Sex (Female / Male, some "Prefer not to answer").}
#'   \item{demo_country}{Country of residence (ISO 3166 names).}
#'   \item{region}{World region derived from `demo_country`.}
#'   \item{social_class}{Edwardian social class (Upper class .. Poor).}
#'   \item{occupation}{Period occupation (Clerk, Domestic servant, ...).}
#'   \item{household_size}{Number in the household (integer).}
#'   \item{weekly_spend}{Weekly spend at the emporium, in shillings (numeric).}
#'   \item{payment}{How they pay: Cash, On account or Barter.}
#'   \item{transport}{How they travel to the shop (On foot, Horse and cart, ...).}
#'   \item{visit_frequency}{How often they visit (Never .. Always).}
#'   \item{recommend}{0-10 "would recommend to a neighbour" rating (integer).}
#'   \item{ratings_goods, ratings_service, ratings_credit, ratings_delivery,
#'     ratings_value}{Worded 1-5 attribute ratings (Very bad .. Very good).}
#'   \item{reasons_price, reasons_quality, reasons_credit, reasons_proximity,
#'     reasons_variety, reasons_service}{Multi-select reasons for patronage; each
#'     holds its option text when chosen, otherwise `""`.}
#'   \item{comment}{Open-text comment (mostly blank).}
#' }
#'
#' @source Simulated. See `data-raw/make_shopping_survey.R` for the generator.
#' @family data
#'
#' @examples
#' calc_percentage(shopping_survey, social_class, sort = "desc")
#' calc_summary(shopping_survey, weekly_spend, by = payment)
"shopping_survey"

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
