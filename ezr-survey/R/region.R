# Internal: the spellings people actually type for the countries that dominate
# consumer research, plus their ISO 3166-1 codes. Nine thousand respondents
# wrote "United States" in the Ask a Manager salary survey and eight thousand
# wrote "USA", so a table keyed only on the formal name loses half a real
# country column. Keys are already normalised (see normalise_country); values
# are the country as `country_region` spells it. Extend it freely: one line per
# spelling is the whole maintenance burden.
country_aliases <- c(
  # the two that account for most of the misses
  "us" = "United States",
  "usa" = "United States",
  "u s" = "United States",
  "u s a" = "United States",
  "america" = "United States",
  "united states of america" = "United States",
  "states" = "United States",
  "uk" = "United Kingdom",
  "gb" = "United Kingdom",
  "gbr" = "United Kingdom",
  "britain" = "United Kingdom",
  "great britain" = "United Kingdom",
  "england" = "United Kingdom",
  "scotland" = "United Kingdom",
  "wales" = "United Kingdom",
  "northern ireland" = "United Kingdom",
  "united kingdom of great britain and northern ireland" = "United Kingdom",
  # endonyms, which arrive whenever a survey runs in more than one language
  "deutschland" = "Germany",
  "de" = "Germany", "deu" = "Germany", "ger" = "Germany",
  "holland" = "Netherlands",
  "nl" = "Netherlands", "nld" = "Netherlands",
  "espana" = "Spain", "es" = "Spain", "esp" = "Spain",
  "italia" = "Italy", "it" = "Italy", "ita" = "Italy",
  "suisse" = "Switzerland", "schweiz" = "Switzerland",
  "ch" = "Switzerland", "che" = "Switzerland",
  "osterreich" = "Austria", "at" = "Austria", "aut" = "Austria",
  "sverige" = "Sweden", "se" = "Sweden", "swe" = "Sweden",
  "norge" = "Norway", "no" = "Norway", "nor" = "Norway",
  "danmark" = "Denmark", "dk" = "Denmark", "dnk" = "Denmark",
  "suomi" = "Finland", "fi" = "Finland", "fin" = "Finland",
  "polska" = "Poland", "pl" = "Poland", "pol" = "Poland",
  "eire" = "Ireland", "republic of ireland" = "Ireland",
  "ie" = "Ireland", "irl" = "Ireland",
  "brasil" = "Brazil", "br" = "Brazil", "bra" = "Brazil",
  "nippon" = "Japan", "jp" = "Japan", "jpn" = "Japan",
  "turkiye" = "Turkey", "tr" = "Turkey", "tur" = "Turkey",
  "czechia" = "Czech Republic", "cz" = "Czech Republic",
  "cze" = "Czech Republic",
  "aotearoa" = "New Zealand", "nz" = "New Zealand", "nzl" = "New Zealand",
  # remaining alpha-2 / alpha-3 for the countries seen most often
  "fr" = "France", "fra" = "France",
  "ca" = "Canada", "can" = "Canada",
  "au" = "Australia", "aus" = "Australia",
  "be" = "Belgium", "bel" = "Belgium",
  "pt" = "Portugal", "prt" = "Portugal",
  "gr" = "Greece", "grc" = "Greece",
  "ro" = "Romania", "rou" = "Romania",
  "hu" = "Hungary", "hun" = "Hungary",
  "ua" = "Ukraine", "ukr" = "Ukraine",
  "ru" = "Russia", "rus" = "Russia",
  "russian federation" = "Russia",
  "cn" = "China", "chn" = "China",
  "peoples republic of china" = "China",
  "in" = "India", "ind" = "India",
  "mx" = "Mexico", "mex" = "Mexico",
  "ar" = "Argentina", "arg" = "Argentina",
  "cl" = "Chile", "chl" = "Chile",
  "co" = "Colombia", "col" = "Colombia",
  "za" = "South Africa", "zaf" = "South Africa",
  "rsa" = "South Africa",
  "ng" = "Nigeria", "nga" = "Nigeria",
  "ke" = "Kenya", "ken" = "Kenya",
  "eg" = "Egypt", "egy" = "Egypt",
  "il" = "Israel", "isr" = "Israel",
  "sg" = "Singapore", "sgp" = "Singapore",
  "hk" = "Hong Kong", "hkg" = "Hong Kong",
  "ph" = "Philippines", "phl" = "Philippines",
  "id" = "Indonesia", "idn" = "Indonesia",
  "my" = "Malaysia", "mys" = "Malaysia",
  "th" = "Thailand", "tha" = "Thailand",
  "vn" = "Vietnam", "vnm" = "Vietnam",
  "kr" = "South Korea", "kor" = "South Korea",
  "korea" = "South Korea", "republic of korea" = "South Korea",
  "uae" = "United Arab Emirates", "ae" = "United Arab Emirates",
  "are" = "United Arab Emirates"
)

# Internal: fold a typed country down to something matchable. Case, stray
# punctuation, accents and a leading "the" are all noise here.
normalise_country <- function(x) {
  out <- tolower(trimws(as.character(x)))
  out <- iconv(out, to = "ASCII//TRANSLIT")
  out <- gsub("[.,'`]", "", out)
  out <- gsub("[^a-z ]", " ", out)
  out <- trimws(gsub(" +", " ", out))
  sub("^the ", "", out)
}

# Internal: alpha-2 codes that are also ordinary English words. These are read
# as countries only when typed in capitals, so "NO" is Norway and "no" is
# somebody answering a different question. Every other code matches either way,
# which is what lets "Uk" and "us" through.
ambiguous_codes <- c("no", "it", "at", "be", "in", "my", "id")

# Internal: the country name to look up, after aliases.
canonical_country <- function(raw) {
  key <- normalise_country(raw)
  hit <- unname(country_aliases[key])
  # nchar(NA) is 2, so the missing values need excluding before the width test.
  risky <- !is.na(key) & key %in% ambiguous_codes
  typed_lower <- !is.na(raw) & raw != toupper(raw)
  hit[risky & typed_lower] <- NA_character_
  ifelse(is.na(hit), key, normalise_country(hit))
}

#' Look up the region or subregion for a country
#'
#' Vectorised lookup from country name to world `region` or finer `subregion`,
#' using the bundled [country_region] table. Matching is case-insensitive and
#' whitespace-tolerant, and understands the spellings people type as well as
#' ISO 3166-1 alpha-2 and alpha-3 codes, so `"USA"`, `"U.S."`, `"us"` and
#' `"United States"` all resolve alike; blanks and non-answers (see
#' [na_blank()]) become `NA`, and unmatched countries become `NA` with a
#' one-line warning so spelling mismatches are easy to spot.
#'
#' @param x A character vector of country names.
#' @param which `"region"` (default) or `"subregion"`.
#' @param quiet If `FALSE` (default), warn about unmatched countries. Set `TRUE`
#'   to silence the warning.
#'
#' @return A character vector of regions (or subregions), `NA` where unmatched.
#'
#' @details
#' A country column that people typed themselves is rarely tidy: in one real
#' open salary survey, nine thousand respondents wrote "United States" and
#' eight thousand wrote "USA". So the name is folded down before it is looked
#' up -- case, stray punctuation, accents and a leading "the" are all dropped
#' -- and then tried against the bundled [country_region] table (182
#' countries), then against a table of the spellings people actually use.
#' That table carries endonyms (`"Deutschland"`, `"Brasil"`), the constituent
#' countries of the United Kingdom, and ISO 3166-1 alpha-2 and alpha-3 codes
#' (`"US"`, `"USA"`, `"DE"`, `"DEU"`), so a column already coded to the
#' standard needs no preparation at all.
#'
#' A two-letter code is only read as a code when it was typed in capitals,
#' because `"NO"` is Norway but `"no"` is an answer to a different question.
#' Blanks and non-answers are blanked with [na_blank()] first, and anything
#' still unmatched returns `NA` with a warning listing the offenders, so a
#' spelling the table does not carry is easy to spot and add. Set
#' `quiet = TRUE` inside pipelines where you have already checked the coverage.
#' `region` is the coarse level (e.g. "Europe"); `subregion` is finer (e.g.
#' "Western Europe").
#'
#' @family recode
#' @seealso [add_region()], [country_region].
#' @examples
#' recode_region(c("Germany", "Japan", "Brazil"))
#'
#' # the spellings a free-text country question actually collects
#' recode_region(c("USA", "U.S.", "England", "Deutschland", "Holland"))
#'
#' # a column already coded to ISO 3166-1
#' recode_region(c("US", "GBR", "DE", "JPN"))
#'
#' recode_subregion(c("Germany", "Japan"))
#'
#' # unmatched -> NA (warning suppressed here)
#' recode_region(c("Germany", "Atlantis"), quiet = TRUE)
#' @export
recode_region <- function(x, which = c("region", "subregion"), quiet = FALSE) {
  which <- match.arg(which)
  lut <- country_region
  raw <- na_blank(as.character(x))
  idx <- match(canonical_country(raw), tolower(trimws(lut$country)))
  out <- lut[[which]][idx]

  if (!quiet) {
    missed <- unique(raw[!is.na(raw) & is.na(out)])
    if (length(missed) > 0) {
      warning(sprintf(
        "%d country value(s) did not match a region: %s%s",
        length(missed),
        paste(utils::head(missed, 5), collapse = ", "),
        if (length(missed) > 5) ", ..." else ""
      ), call. = FALSE)
    }
  }
  out
}

#' @rdname recode_region
#' @export
recode_subregion <- function(x, quiet = FALSE) {
  recode_region(x, which = "subregion", quiet = quiet)
}

#' Add region (and subregion) columns from a country column
#'
#' Convenience wrapper that appends a `region` column (and optionally a
#' `subregion`) to a data frame by looking up an existing country column with
#' [recode_region()].
#'
#' @param data A data frame.
#' @param country The country column (unquoted).
#' @param region_to Name of the region column to add. Defaults to `"region"`.
#' @param subregion If `TRUE`, also add a `subregion` column. Defaults to
#'   `FALSE`.
#' @param quiet Passed to [recode_region()].
#'
#' @return `data` with the new column(s) added.
#'
#' @details
#' This is the data-frame-friendly form of [recode_region()]: point it at an
#' existing country column and it appends a `region` column (named via
#' `region_to`) and, optionally, a `subregion`. Handy right after [read_folder()]
#' to enrich raw exports before grouping by region. The lookup, matching and
#' unmatched-country warning behave exactly as in [recode_region()].
#'
#' @family recode
#' @seealso [recode_region()], [country_region].
#' @examples
#' df <- tibble::tibble(demo_country = c("Germany", "Japan", "Brazil"))
#' add_region(df, demo_country, subregion = TRUE)
#' @export
add_region <- function(data = NULL, country, region_to = "region",
                       subregion = FALSE, quiet = FALSE) {
  data <- resolve_data(data)
  col <- rlang::as_name(rlang::ensym(country))
  if (!col %in% names(data)) {
    stop("Column '", col, "' not found in `data`.", call. = FALSE)
  }
  data[[region_to]] <- recode_region(data[[col]], "region", quiet = quiet)
  if (subregion) {
    data[["subregion"]] <- recode_region(data[[col]], "subregion", quiet = TRUE)
  }
  data
}
