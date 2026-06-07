#' Generational-cohort definitions
#'
#' Returns the birth-year boundaries for a named generational scheme, for use by
#' [recode_generation()]. The default `"pew"` scheme follows the widely cited
#' Pew Research Center cohort definitions.
#'
#' @param scheme Scheme name. Currently `"pew"`.
#'
#' @return A [tibble][tibble::tibble] with `label`, `from` (first birth year) and
#'   `to` (last birth year; `Inf` for the open-ended youngest cohort).
#'
#' @details
#' The `"pew"` scheme uses the Pew Research Center boundaries: Silent (1928--45),
#' Baby Boomer (1946--64), Gen X (1965--80), Millennial (1981--96), Gen Z
#' (1997--2012) and Gen Alpha (2013+). To use different cut-offs, build your own
#' tibble with `from` and `label` columns and pass it to [recode_generation()]'s
#' `scheme` argument.
#'
#' @family recode
#' @seealso [recode_generation()].
#' @examples
#' generation_scheme("pew")
#' #> # A tibble: 6 x 3
#' #>   label        from   to
#' #>   <chr>       <dbl> <dbl>
#' #> 1 Silent       1928  1945
#' #> 2 Baby Boomer  1946  1964
#' #> # ... Gen X, Millennial, Gen Z, Gen Alpha
#' @export
generation_scheme <- function(scheme = c("pew")) {
  scheme <- match.arg(scheme)
  switch(
    scheme,
    pew = tibble::tibble(
      label = c("Silent", "Baby Boomer", "Gen X", "Millennial",
                "Gen Z", "Gen Alpha"),
      from = c(1928, 1946, 1965, 1981, 1997, 2013),
      to = c(1945, 1964, 1980, 1996, 2012, Inf)
    )
  )
}

#' Recode age or birth year into a generational cohort
#'
#' Maps either an **age** (converted to a birth year using a reference year) or a
#' **birth year** directly onto a generational cohort such as Millennial or
#' Gen Z. Text input like `"34 years"` is salvaged with [ensure_numeric()].
#'
#' @param x A numeric (or coercible) vector of ages or birth years.
#' @param input What `x` represents: `"age"` (default) or `"year"` (birth year).
#' @param year Reference year for the age-to-birth-year conversion. If `NULL`
#'   (default), uses the `current_year` option (see [ezrsurvey_options()]) or the
#'   system year.
#' @param scheme Either a scheme name passed to [generation_scheme()] (default
#'   from the `generation_scheme` option) or your own data frame with `from` and
#'   `label` columns.
#'
#' @return A character vector of cohort labels; values outside the scheme's range
#'   become `NA`.
#'
#' @details
#' When `input = "age"`, the birth year is `year - age`, where `year` defaults to
#' the `current_year` option or the system year -- so set
#' `ezrsurvey_options(current_year = 2026)` to keep results stable across runs.
#' When `input = "year"`, `x` is treated as the birth year directly. The birth
#' year is then bucketed into the scheme's cohorts (see [generation_scheme()]);
#' birth years before the earliest cohort return `NA`. Use this for
#' generational reporting; for simple age bands use [recode_age()].
#'
#' @family recode
#' @seealso [generation_scheme()], [recode_age()], [ezrsurvey_options()].
#' @examples
#' recode_generation(c(1990, 2001, 1968), input = "year")
#' #> [1] "Millennial" "Gen Z"      "Gen X"
#'
#' # from age, with an explicit reference year
#' recode_generation(c(36, 25), input = "age", year = 2026)
#' #> [1] "Millennial" "Gen Z"
#' @export
recode_generation <- function(x, input = c("age", "year"), year = NULL,
                              scheme = NULL) {
  input <- match.arg(input)
  vals <- ensure_numeric(x, quiet = TRUE)

  if (is.null(scheme)) scheme <- ezrsurvey_default("generation_scheme")
  sch <- if (is.character(scheme)) generation_scheme(scheme) else {
    if (!all(c("from", "label") %in% names(scheme))) {
      stop("A custom `scheme` needs `from` and `label` columns.", call. = FALSE)
    }
    scheme
  }
  # `cut()` needs ascending breaks; sort the bands by their start year.
  sch <- sch[order(sch$from), , drop = FALSE]

  if (input == "age") {
    ref <- year
    if (is.null(ref)) ref <- ezrsurvey_default("current_year")
    if (is.null(ref)) ref <- as.integer(format(Sys.Date(), "%Y"))
    birth <- ref - vals
  } else {
    birth <- vals
  }

  out <- cut(birth, breaks = c(sch$from, Inf), labels = sch$label,
             right = FALSE, include.lowest = TRUE)
  as.character(out)
}
