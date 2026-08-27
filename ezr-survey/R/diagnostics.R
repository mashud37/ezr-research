#' Standard error of a mean (point estimate)
#'
#' `sd(x) / sqrt(n)`, the sampling error of a mean such as an average 1-5
#' rating. Packages the inline `sem` calculation from the report appendix.
#'
#' @param x A numeric vector. `NA` values are ignored.
#'
#' @return A single numeric standard error, or `NA` if fewer than two non-missing
#'   values are present.
#'
#' @details
#' The standard error of the mean is the sample standard deviation divided by the
#' square root of the (non-missing) sample size, `sd(x) / sqrt(n)`. It shrinks as
#' the sample grows, and is the basis of the margin of error you quote for an
#' average rating. Fewer than two values gives `NA` (no spread to estimate).
#'
#' @family diagnostics
#' @seealso [se_prop()], [rse()], [margin_of_error()], [diagnose()].
#' @examples
#' se_mean(c(4, 5, 3, 4, 5, 2, 4))
#' #> [1] 0.4285714
#' @export
se_mean <- function(x) {
  x <- as.numeric(x)
  x <- x[!is.na(x)]
  n <- length(x)
  if (n < 2L) {
    return(NA_real_)
  }
  stats::sd(x) / sqrt(n)
}

#' Standard error of a proportion
#'
#' `sqrt(p * (1 - p) / n)`, the sampling error of a percentage. Packages the
#' inline proportion-error calculation from the report appendix.
#'
#' @param p The proportion, either as a fraction in `[0, 1]` or as a percentage
#'   in `(1, 100]` (values above 1 are divided by 100 automatically).
#' @param n The sample size (number of respondents).
#'
#' @return The standard error of the proportion, on the same `[0, 1]` scale as a
#'   fractional `p`. Multiply by 100 for percentage points.
#'
#' @details
#' For a percentage from a survey, the sampling error is `sqrt(p * (1 - p) / n)`.
#' It is largest when `p = 0.5` (a 50/50 split is the hardest to pin down) and
#' shrinks towards the extremes. The result is on the same 0--1 scale as a
#' fractional `p`; multiply by 100 to express it in percentage points, the form
#' used in report footnotes. Inputs above 1 are treated as percentages and
#' divided by 100, so `se_prop(33, n)` and `se_prop(0.33, n)` agree.
#'
#' @family diagnostics
#' @seealso [se_mean()], [rse()], [margin_of_error()], [diagnose()].
#' @examples
#' se_prop(0.33, 1184)
#' #> [1] 0.01366
#'
#' se_prop(0.33, 1184) * 100      # in percentage points
#' #> [1] 1.366
#' @export
se_prop <- function(p, n) {
  p <- as.numeric(p)
  p[!is.na(p) & p > 1] <- p[!is.na(p) & p > 1] / 100
  if (any(!is.na(p) & (p < 0 | p > 1))) {
    stop("`p` must be a proportion in [0, 1] (or a percentage in [0, 100]).",
         call. = FALSE)
  }
  sqrt(p * (1 - p) / n)
}

#' Relative standard error
#'
#' The standard error expressed as a percentage of the estimate,
#' `se / estimate * 100`. A common rule of thumb treats an RSE below ~5% as very
#' good precision.
#'
#' @param estimate The point estimate (mean or proportion).
#' @param se Its standard error, on the same scale as `estimate`.
#'
#' @return The relative standard error, in percent.
#'
#' @details
#' Dividing the standard error by the estimate makes precision comparable across
#' measures on different scales (a 1--5 rating vs a percentage). A common
#' rule of thumb treats an RSE under ~5% as very good precision, which is the
#' threshold [diagnose()] uses for its `precision` flag.
#'
#' @family diagnostics
#' @seealso [se_mean()], [se_prop()], [margin_of_error()], [diagnose()].
#' @examples
#' rse(estimate = 4.1, se = se_mean(c(4, 5, 3, 4, 5)))
#' #> [1] 9.611
#' @export
rse <- function(estimate, se) {
  se / estimate * 100
}

#' Margin of error from a standard error
#'
#' `z * se`, the half-width of a confidence interval. The default `z = 1.96`
#' gives an approximate 95% interval; the survey reports used the `2 * se`
#' rule of thumb, which is `z = 2`.
#'
#' @param se A standard error (scalar or vector).
#' @param z The critical value / multiplier. Defaults to `1.96` (95%). Use `2`
#'   to reproduce the report's rule of thumb.
#'
#' @return The `+/-` margin of error, on the same scale as `se`.
#'
#' @details
#' A confidence interval is the estimate plus or minus this margin. `z = 1.96`
#' gives the standard 95% interval; `z = 2` reproduces the "two standard errors"
#' rule of thumb often quoted in survey reports; `z = 2.58` gives 99%. The result
#' is on the same scale as `se`, so for a proportion error in percentage points,
#' pass `se_prop(p, n) * 100`.
#'
#' @family diagnostics
#' @seealso [se_mean()], [se_prop()], [diagnose()].
#' @examples
#' margin_of_error(se_prop(0.33, 1184)) * 100   # 95% margin, percentage points
#' #> [1] 2.677
#'
#' margin_of_error(0.02, z = 2)
#' #> [1] 0.04
#' @export
margin_of_error <- function(se, z = 1.96) {
  z * se
}

#' Rate precision from a relative standard error
#'
#' Turns a relative standard error (RSE, in percent) into a plain-language
#' reliability rating, using a five-band scheme.
#'
#' @param rse Relative standard error(s), in percent (see [rse()]).
#'
#' @return A character vector of ratings.
#'
#' @details
#' The bands are: under 5% "high precision", under 10% "precise", under 15%
#' "satisfactory", under 25% "use with caution", and 25% or more "likely
#' reliability issues". Rating estimates by their relative standard error is the
#' approach used by national statistical agencies (notably the Australian Bureau
#' of Statistics) to signal when a survey number is solid enough to report; the
#' specific cut-offs here are tuned for consumer-survey work. This drives the
#' `precision` column of [diagnose()] and the overall verdict of
#' [precision_summary()].
#'
#' @family diagnostics
#' @seealso [rse()], [diagnose()], [precision_summary()].
#' @examples
#' rse_rating(c(3, 8, 12, 20, 40))
#' #> [1] "high precision"            "precise"
#' #> [3] "satisfactory"             "use with caution"
#' #> [5] "likely reliability issues"
#' @export
rse_rating <- function(rse) {
  dplyr::case_when(
    is.na(rse)  ~ NA_character_,
    rse < 5     ~ "high precision",
    rse < 10    ~ "precise",
    rse < 15    ~ "satisfactory",
    rse < 25    ~ "use with caution",
    TRUE        ~ "likely reliability issues"
  )
}

# Internal: diagnostics for a single vector.
diagnose_one <- function(x, type, z) {
  is_num <- is.numeric(x)
  kind <- if (type == "auto") (if (is_num) "mean" else "prop") else type

  if (kind == "mean") {
    xx <- ensure_numeric(x, quiet = TRUE)
    n <- sum(!is.na(xx))
    est <- mean(xx, na.rm = TRUE)
    se <- se_mean(xx)
    unit <- "points"
  } else {
    xc <- na_blank(as.character(x))
    xc <- xc[!is.na(xc)]
    n <- length(xc)
    p <- if (n == 0L) NA_real_ else {
      tab <- sort(table(xc), decreasing = TRUE)
      as.numeric(tab[[1]]) / n
    }
    se_p <- se_prop(p, n)
    est <- 100 * p          # report proportions as percentages
    se <- 100 * se_p        # ... and their error in percentage points
    unit <- "ppt"
  }

  rse_val <- se / est * 100
  tibble::tibble(
    type = kind,
    unit = unit,
    n = n,
    estimate = est,
    se = se,
    rse = rse_val,
    moe = z * se,
    precision = rse_rating(rse_val)
  )
}

#' Survey precision diagnostics for one or more columns
#'
#' The headline diagnostics wrapper: for each selected column it auto-detects
#' whether it is a point estimate (numeric, e.g. a 1-5 rating) or a proportion
#' (categorical), and returns a tidy table of sample size, estimate, standard
#' error, relative standard error and margin of error -- i.e. the whole appendix
#' "Data info" block as one call.
#'
#' For categorical columns the reported estimate is the **largest answer
#' category's** share, which gives a concrete `+/-` percentage-point margin to
#' quote in a report footnote.
#'
#' @param data A data frame.
#' @param ... Columns to diagnose, using tidyselect (e.g.
#'   `starts_with("ratings_")`, `demo_gender`).
#' @param type Force the estimate type: `"auto"` (default, detect per column),
#'   `"mean"` or `"prop"`.
#' @param by Optional grouping column(s); diagnostics are computed within group.
#' @param z Margin-of-error multiplier passed to [margin_of_error()]. Defaults
#'   to `1.96` (95%).
#' @param digits Decimal places for the numeric output columns. Defaults to `2`.
#'
#' @return A [tibble][tibble::tibble] with one row per column (per group), with
#'   columns `variable`, `type`, `unit`, `n`, `estimate`, `se`, `rse`, `moe` and
#'   `precision`. For `type == "mean"`, `unit` is `"points"`; for proportions it
#'   is `"ppt"` (percentage points) and `estimate` is a percentage.
#'
#' @details
#' Each column is classified (or forced via `type`) as a point estimate or a
#' proportion. For numeric columns the estimate is the mean and the error is in
#' rating points; for categorical columns the estimate is the **largest answer
#' category's** share, which gives a single concrete `+/-` percentage-point
#' margin to quote (the largest category is also the worst case among the
#' observed categories, so it is a sensible headline). The `precision` column is
#' the five-band rating from [rse_rating()]. This is the per-variable form of the
#' report-appendix "Data info" block; for the narrative bullet-point version see
#' [precision_summary()].
#'
#' @family diagnostics
#' @seealso [precision_summary()], [rse_rating()], [se_mean()], [se_prop()].
#' @examples
#' diagnose(podracing_survey, demo_gender, nps_value)
#' #> # A tibble: 2 x 9
#' #>   variable    type  unit      n estimate    se   rse   moe precision
#' #>   <chr>       <chr> <chr> <int>    <dbl> <dbl> <dbl> <dbl> <chr>
#' #> 1 demo_gender prop  ppt     951     55.2  1.61  2.92  3.16 high precision
#' #> 2 nps_value   mean  points 1000      7.56 0.06  0.74  0.11 high precision
#'
#' diagnose(podracing_survey, starts_with("ratings_"))
#' @export
diagnose <- function(data = NULL, ..., type = c("auto", "mean", "prop"),
                     by = NULL, z = 1.96, digits = 2) {
  rd <- resolve_data_dots(rlang::enquo(data), rlang::enquos(...))
  data <- rd$data
  type <- match.arg(type)
  vars <- names(dplyr::select(data, !!!rd$dots))
  if (length(vars) == 0L) {
    stop("Select at least one column to diagnose.", call. = FALSE)
  }
  by_q <- rlang::enquo(by)
  has_by <- !rlang::quo_is_null(by_q)

  run_one <- function(df) {
    run <- progress_start(length(vars))
    out <- purrr::map_dfr(seq_along(vars), function(i) {
      v <- vars[[i]]
      progress_item(run, i, v)
      dplyr::bind_cols(
        tibble::tibble(variable = v),
        diagnose_one(df[[v]], type = type, z = z)
      )
    })
    progress_done(run)
    out
  }

  if (has_by) {
    keys <- data %>%
      dplyr::group_by(dplyr::pick({{ by }})) %>%
      dplyr::group_keys()
    groups <- data %>%
      dplyr::group_by(dplyr::pick({{ by }})) %>%
      dplyr::group_split()
    out <- purrr::map2_dfr(groups, seq_len(nrow(keys)), function(g, i) {
      dplyr::bind_cols(keys[i, , drop = FALSE], run_one(g))
    })
  } else {
    out <- run_one(data)
  }

  num_cols <- intersect(c("estimate", "se", "rse", "moe"), names(out))
  dplyr::mutate(out, dplyr::across(dplyr::all_of(num_cols), ~ round(.x, digits)))
}

# Internal: is a column categorical enough to treat as a proportion (i.e. not a
# free-text or near-unique id column)?
is_categorical_like <- function(x) {
  if (is.numeric(x)) return(FALSE)
  xc <- na_blank(as.character(x))
  xc <- xc[!is.na(xc)]
  n <- length(xc)
  if (n == 0L) return(FALSE)
  if (mean(nchar(xc)) > 30) return(FALSE)   # looks like free text, not categories
  u <- length(unique(xc))
  u >= 2 && u <= max(15, 0.25 * n)
}

#' Plain-language survey precision summary
#'
#' Distils a whole survey's sampling precision into a few bullet points -- the
#' narrative "Data info" paragraph from the report appendix, generated
#' automatically. It scans the dataset, assesses the numeric (point-scale) and
#' categorical (proportion) variables, and reports the typical sampling margins
#' and an overall reliability verdict.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param ... Optional columns to restrict the assessment to (tidyselect). If
#'   omitted, all suitable columns are used: every numeric column, and every
#'   categorical column that is not free text or an identifier.
#' @param z Confidence multiplier for the margins of error. Default `1.96`
#'   (95%).
#'
#' @return An object of class `ezrsurvey_precision` (a list with `n`, the
#'   per-variable `table`, `overall_rse`, `rating` and the `bullets`). Printing it
#'   shows the bullet points.
#'
#' @details
#' Rather than make you choose which variables to quote precision for, this picks
#' them: numeric columns become point estimates (margins in rating points) and
#' categorical columns become proportions (margins in percentage points), with
#' free-text and id-like columns skipped. It then reports the **typical** and
#' **worst** margins across each group, plus an overall verdict from the median
#' relative standard error via [rse_rating()]. For proportions it also gives the
#' worst-case `+/-` percentage-point margin at a 50/50 split, which is the widest
#' any percentage in the study can be. See `vignette("ezrsurvey")` for the
#' rationale behind the relative-standard-error reliability bands.
#'
#' @family diagnostics
#' @seealso [diagnose()], [rse_rating()].
#' @examples
#' precision_summary(podracing_survey)
#' @export
precision_summary <- function(data = NULL, ..., z = 1.96) {
  rd <- resolve_data_dots(rlang::enquo(data), rlang::enquos(...))
  data <- rd$data
  vars <- names(dplyr::select(data, !!!rd$dots))
  if (length(vars) == 0L) vars <- names(data)

  keep <- vapply(vars, function(v) {
    is.numeric(data[[v]]) || is_categorical_like(data[[v]])
  }, logical(1))
  vars <- vars[keep]
  if (length(vars) == 0L) {
    stop("No numeric or categorical variables found to assess.", call. = FALSE)
  }

  d <- diagnose(data, dplyr::all_of(vars), z = z)
  conf <- round((2 * stats::pnorm(z) - 1) * 100)
  n_total <- nrow(data)
  point <- d[d$type == "mean", , drop = FALSE]
  prop <- d[d$type == "prop", , drop = FALSE]
  med_rse <- stats::median(d$rse, na.rm = TRUE)
  rating <- rse_rating(med_rse)

  bullets <- sprintf(
    "Based on %s total responses (per-question base of %s to %s).",
    format(n_total, big.mark = ","), format(min(d$n), big.mark = ","),
    format(max(d$n), big.mark = ",")
  )
  if (nrow(point) > 0) {
    bullets <- c(bullets, sprintf(
      paste0("Point ratings carry a sampling margin of about +/-%.2f points ",
             "(up to +/-%.2f) at %g%% confidence."),
      stats::median(point$moe, na.rm = TRUE), max(point$moe, na.rm = TRUE), conf
    ))
  }
  if (nrow(prop) > 0) {
    worst <- z * se_prop(0.5, stats::median(prop$n)) * 100
    bullets <- c(bullets, sprintf(
      paste0("Percentages carry a sampling margin of about +/-%.1f percentage ",
             "points (worst case +/-%.1f at a 50/50 split)."),
      stats::median(prop$moe, na.rm = TRUE), worst
    ))
  }
  bullets <- c(bullets, sprintf(
    "Overall relative standard error of about %.1f%% -- %s.", med_rse, rating
  ))

  structure(
    list(n = n_total, table = d, overall_rse = med_rse,
         rating = rating, bullets = bullets),
    class = "ezrsurvey_precision"
  )
}

#' @export
print.ezrsurvey_precision <- function(x, ...) {
  cat("Survey precision summary\n")
  cat(paste0("- ", x$bullets), sep = "\n")
  cat("\n")
  invisible(x)
}
