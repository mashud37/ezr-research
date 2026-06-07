#' Look up the region or subregion for a country
#'
#' Vectorised lookup from country name to world `region` or finer `subregion`,
#' using the bundled [country_region] table. Matching is case-insensitive and
#' whitespace-tolerant; blanks and non-answers (see [na_blank()]) become `NA`,
#' and unmatched countries become `NA` with a one-line warning so spelling
#' mismatches are easy to spot.
#'
#' @param x A character vector of country names.
#' @param which `"region"` (default) or `"subregion"`.
#' @param quiet If `FALSE` (default), warn about unmatched countries. Set `TRUE`
#'   to silence the warning.
#'
#' @return A character vector of regions (or subregions), `NA` where unmatched.
#'
#' @details
#' Matching is done on a lower-cased, trimmed country name against the bundled
#' [country_region] table (182 countries), so case and stray whitespace don't
#' matter. Blanks and non-answers are blanked with [na_blank()] first, and any
#' country that doesn't match -- usually a spelling variant the table doesn't
#' carry -- returns `NA` with a warning listing the offenders, so you can spot
#' and fix them. Set `quiet = TRUE` inside pipelines where you have already
#' checked the coverage. `region` is the coarse level (e.g. "Europe");
#' `subregion` is finer (e.g. "Western Europe").
#'
#' @family recode
#' @seealso [add_region()], [country_region].
#' @examples
#' recode_region(c("Germany", "Japan", "Brazil"))
#' #> [1] "Europe"        "Asia"          "South America"
#'
#' recode_subregion(c("Germany", "Japan"))
#' #> [1] "Western Europe" "East Asia"
#'
#' # unmatched -> NA (warning suppressed here)
#' recode_region(c("Germany", "Atlantis"), quiet = TRUE)
#' #> [1] "Europe" NA
#' @export
recode_region <- function(x, which = c("region", "subregion"), quiet = FALSE) {
  which <- match.arg(which)
  lut <- country_region
  raw <- na_blank(as.character(x))
  key <- tolower(trimws(raw))
  idx <- match(key, tolower(trimws(lut$country)))
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
#' #> # A tibble: 3 x 3
#' #>   demo_country region        subregion
#' #>   <chr>        <chr>         <chr>
#' #> 1 Germany      Europe        Western Europe
#' #> 2 Japan        Asia          East Asia
#' #> 3 Brazil       South America South America
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
