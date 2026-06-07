# ---- helpers -------------------------------------------------------------

# Internal: a plain-language band for a Cronbach's alpha value.
alpha_band <- function(a) {
  if (is.na(a)) return("undefined")
  if (a >= 0.9) "excellent" else if (a >= 0.8) "good" else
    if (a >= 0.7) "acceptable" else if (a >= 0.6) "questionable" else "poor"
}

# Internal: assemble a complete-case numeric data frame from tidyselected vars.
numeric_frame <- function(data, vars_q) {
  if (rlang::quo_is_null(vars_q)) {
    vnames <- names(data)[vapply(data, is.numeric, logical(1))]
  } else {
    sel <- names(dplyr::select(data, !!vars_q))
    vnames <- sel[vapply(data[sel], is.numeric, logical(1))]
  }
  if (length(vnames) < 2L) {
    stop("Need at least 2 numeric variables.", call. = FALSE)
  }
  m <- data[, vnames, drop = FALSE]
  ok <- stats::complete.cases(m)
  list(df = as.data.frame(m[ok, , drop = FALSE]), vars = vnames, ok = ok)
}

#' Scale reliability (Cronbach's alpha)
#'
#' Checks whether a set of items hang together well enough to be averaged into a
#' single scale, reporting Cronbach's alpha, a plain-language rating, and -- per
#' item -- the alpha you would get by dropping it (so you can spot a weak item).
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param items The item columns (tidyselect). Default: all numeric columns.
#'
#' @return An `ezrmodel_reliability` object: `alpha` (raw and standardised),
#'   `n_items`, `n`, a `rating` band, and an `items` table (item-rest
#'   correlation and alpha-if-dropped). Has `print()` and `tidy()` methods.
#'
#' @details
#' Needs the suggested `psych` package. Alpha runs 0-1 and rises with both the
#' number of items and their average inter-correlation; rough bands are
#' `>= 0.9` excellent, `0.8` good, `0.7` acceptable, `0.6` questionable, below
#' that poor. The per-item `alpha_if_dropped` flags an item whose removal would
#' *raise* alpha -- usually one that does not belong on the scale. A low item-rest
#' correlation (`r_drop`) is the same warning from a different angle.
#'
#' @family factors
#' @seealso [factors()] to find the underlying dimensions.
#' @examplesIf requireNamespace("psych", quietly = TRUE)
#' reliability(nps_drivers, items = c(value, quality, service, ease,
#'                                    support, trust, price, innovation))
#' @export
reliability <- function(data = NULL, items = NULL) {
  data <- resolve_data(data)
  if (!requireNamespace("psych", quietly = TRUE)) {
    stop("Reliability needs the 'psych' package. ",
         "Install it with install.packages('psych').", call. = FALSE)
  }
  nf <- numeric_frame(data, rlang::enquo(items))
  a <- suppressWarnings(suppressMessages(
    psych::alpha(nf$df, warnings = FALSE, check.keys = FALSE)))

  tot <- a$total
  items_tbl <- tibble::tibble(
    item = rownames(a$alpha.drop),
    r_drop = a$item.stats$r.drop,
    alpha_if_dropped = a$alpha.drop$raw_alpha
  )
  raw <- as.numeric(tot$raw_alpha)

  structure(
    list(alpha = raw, std_alpha = as.numeric(tot$std.alpha),
         n_items = length(nf$vars), n = nrow(nf$df),
         rating = alpha_band(raw), items = items_tbl),
    class = "ezrmodel_reliability"
  )
}

#' @export
print.ezrmodel_reliability <- function(x, ...) {
  cat(sprintf("Reliability of %d items  (n = %d)\n", x$n_items, x$n))
  cat(sprintf("  Cronbach's alpha: %.2f  (%s)\n", x$alpha, x$rating))
  worst <- x$items[which.max(x$items$alpha_if_dropped), , drop = FALSE]
  if (nrow(worst) && worst$alpha_if_dropped > x$alpha) {
    cat(sprintf("  Dropping '%s' would raise alpha to %.2f\n",
                worst$item, worst$alpha_if_dropped))
  }
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_reliability <- function(x, ...) x$items

#' Exploratory factor analysis
#'
#' Finds the latent dimensions behind a set of correlated items: how many there
#' are, which items load on each, and how much variance they explain -- in one
#' object, with the number of factors chosen for you if you do not say.
#'
#' @param data A data frame. If omitted, the session default is used.
#' @param vars The item columns (tidyselect). Default: all numeric columns.
#' @param n Number of factors. If `NULL` (default), chosen by parallel analysis.
#' @param rotate Rotation passed to [psych::fa()]. Default `"oblimin"` (allows
#'   correlated factors).
#' @param scores Append factor scores via [augment()]? Default `TRUE`.
#'
#' @return An `ezrmodel_factors` object: `loadings` (item x factor), `variance`
#'   (proportion explained per factor), `fit` (TLI, RMSEA, RMSR), the fitted
#'   `psych` object and, when `scores = TRUE`, the factor `scores`. Has
#'   `print()`, `plot()` (loadings heatmap), `tidy()` and `augment()` methods.
#'
#' @details
#' Needs the suggested `psych` package. When `n = NULL`, [psych::fa.parallel()]
#' suggests the number of factors by comparing the data's eigenvalues to those of
#' random data. Loadings are the correlations between items and factors; read each
#' factor by its high-loading items. Oblimin rotation lets factors correlate,
#' which is usually realistic for survey constructs. Rough fit guides: TLI
#' `>= 0.95` and RMSEA `<= 0.06` are good. `augment()` appends each respondent's
#' factor scores (`.MR1`, `.MR2`, ...).
#'
#' @family factors
#' @seealso [reliability()], [reduce_dims()] for unsupervised PCA, [sem()].
#' @examplesIf requireNamespace("psych", quietly = TRUE)
#' f <- factors(nps_drivers, vars = c(value, quality, service, ease,
#'                                    support, trust, price, innovation), n = 2)
#' f
#' tidy(f)
#' @export
factors <- function(data = NULL, vars = NULL, n = NULL, rotate = "oblimin",
                    scores = TRUE) {
  data <- resolve_data(data)
  if (!requireNamespace("psych", quietly = TRUE)) {
    stop("Factor analysis needs the 'psych' package. ",
         "Install it with install.packages('psych').", call. = FALSE)
  }
  nf <- numeric_frame(data, rlang::enquo(vars))

  if (is.null(n)) {
    pa <- suppressWarnings(suppressMessages(utils::capture.output(
      fp <- psych::fa.parallel(nf$df, plot = FALSE, fa = "fa"))))
    n <- max(1L, as.integer(fp$nfact))
  }

  f <- suppressWarnings(suppressMessages(
    psych::fa(nf$df, nfactors = n, rotate = rotate,
              scores = if (scores) "regression" else "none", warnings = FALSE)))

  load <- unclass(f$loadings)
  loadings <- tibble::as_tibble(load[, , drop = FALSE], rownames = "variable")
  va <- f$Vaccounted
  prop_row <- if ("Proportion Var" %in% rownames(va)) "Proportion Var" else
    rownames(va)[2]
  variance <- tibble::tibble(
    factor = colnames(load),
    proportion = as.numeric(va[prop_row, ]),
    cumulative = cumsum(as.numeric(va[prop_row, ]))
  )
  fit <- list(
    tli = if (!is.null(f$TLI)) as.numeric(f$TLI) else NA_real_,
    rmsea = if (!is.null(f$RMSEA)) as.numeric(f$RMSEA[[1]]) else NA_real_,
    rmsr = if (!is.null(f$rms)) as.numeric(f$rms) else NA_real_
  )
  sc <- if (scores && !is.null(f$scores)) {
    tibble::as_tibble(f$scores)
  } else {
    NULL
  }

  structure(
    list(n = n, rotate = rotate, loadings = loadings, variance = variance,
         fit = fit, scores = sc, vars = nf$vars, ok = nf$ok, data = data,
         psych = f),
    class = "ezrmodel_factors"
  )
}

#' @export
print.ezrmodel_factors <- function(x, ...) {
  cat(sprintf("Exploratory factor analysis  (%d factors, %d items, %d rows)\n",
              x$n, length(x$vars), sum(x$ok)))
  v <- x$variance
  cat(paste0("  ", v$factor, ": ",
             formatC(v$proportion * 100, format = "f", digits = 1), "% var"),
      sep = "\n")
  cat(sprintf("  fit: TLI %.2f  RMSEA %.3f  RMSR %.3f\n",
              x$fit$tli, x$fit$rmsea, x$fit$rmsr))
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_factors <- function(x, ...) {
  tidyr::pivot_longer(x$loadings, cols = -"variable",
                      names_to = "factor", values_to = "loading")
}

#' @export
augment.ezrmodel_factors <- function(x, ...) {
  if (is.null(x$scores)) {
    stop("This fit has no scores; call factors(..., scores = TRUE).",
         call. = FALSE)
  }
  d <- tibble::as_tibble(x$data[x$ok, , drop = FALSE])
  sc <- x$scores
  names(sc) <- paste0(".", names(sc))
  dplyr::bind_cols(d, sc)
}

#' @export
plot.ezrmodel_factors <- function(x, ...) {
  d <- tidy(x)
  d$variable <- factor(d$variable, levels = rev(x$loadings$variable))
  ggplot2::ggplot(d, ggplot2::aes(.data$factor, .data$variable,
                                  fill = .data$loading)) +
    ggplot2::geom_tile(colour = "white") +
    ggplot2::geom_text(ggplot2::aes(label = formatC(.data$loading,
                                                    format = "f", digits = 2)),
                       size = 3) +
    scale_fill_diverging(limit = 1) +
    ggplot2::labs(x = "", y = "", fill = "loading",
                  title = "Factor loadings") +
    theme_ezrmodel(transparent = TRUE)
}

#' Confirmatory factor analysis / structural equation model
#'
#' Fits a measurement or structural model you specify in lavaan syntax and
#' returns the fit measures (with a plain-language read) and the standardised
#' paths in one object -- the confirmatory companion to [factors()].
#'
#' @param data A data frame. If omitted, the session default is used.
#' @param model A model description in
#'   \href{https://lavaan.ugent.be/tutorial/syntax1.html}{lavaan syntax}, e.g.
#'   `"trust =~ trust + service + support"`.
#' @param ... Passed to [lavaan::sem()].
#'
#' @return An `ezrmodel_sem` object: `fit_measures` (chi-square, CFI, TLI, RMSEA,
#'   SRMR, BIC), `paths` (standardised estimates with p-values), and the fitted
#'   `lavaan` object. Has `print()` and `tidy()` methods.
#'
#' @details
#' Needs the suggested `lavaan` package. Latent variables are declared with `=~`
#' (measured by), regressions with `~`, and covariances with `~~`. The reported
#' fit measures come with rough targets: CFI/TLI `>= 0.95`, RMSEA `<= 0.06` and
#' SRMR `<= 0.08` indicate good fit. `tidy()` returns the standardised paths so
#' coefficients are comparable across the model. Use [factors()] first to
#' discover a structure, then `sem()` to confirm it.
#'
#' @family factors
#' @seealso [factors()], [reliability()].
#' @examplesIf requireNamespace("lavaan", quietly = TRUE)
#' \donttest{
#' model <- "satisfaction =~ quality + value + service + ease +
#'                            support + trust + price + innovation"
#' sem(nps_drivers, model)
#' }
#' @export
sem <- function(data = NULL, model, ...) {
  data <- resolve_data(data)
  if (!requireNamespace("lavaan", quietly = TRUE)) {
    stop("SEM/CFA needs the 'lavaan' package. ",
         "Install it with install.packages('lavaan').", call. = FALSE)
  }
  fit <- lavaan::sem(model, data = as.data.frame(data), ...)

  measures <- c("chisq", "df", "cfi", "tli", "rmsea", "srmr", "bic")
  fm <- lavaan::fitMeasures(fit, measures)
  fit_measures <- tibble::tibble(measure = names(fm),
                                 value = as.numeric(fm))

  std <- lavaan::standardizedSolution(fit)
  paths <- tibble::tibble(
    lhs = std$lhs, op = std$op, rhs = std$rhs,
    estimate = std$est.std, se = std$se,
    p_value = std$pvalue
  )

  structure(
    list(fit_measures = fit_measures, paths = paths, lavaan = fit,
         model = model),
    class = "ezrmodel_sem"
  )
}

#' @export
print.ezrmodel_sem <- function(x, ...) {
  fm <- stats::setNames(x$fit_measures$value, x$fit_measures$measure)
  cat("Structural equation model\n")
  cat(sprintf("  chi-sq(%d) = %.1f   CFI %.3f   TLI %.3f   RMSEA %.3f   SRMR %.3f\n",
              round(fm[["df"]]), fm[["chisq"]], fm[["cfi"]], fm[["tli"]],
              fm[["rmsea"]], fm[["srmr"]]))
  good <- fm[["cfi"]] >= 0.95 && fm[["rmsea"]] <= 0.06 && fm[["srmr"]] <= 0.08
  cat(sprintf("  fit: %s\n", if (good) "good" else "check (see fit_measures)"))
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_sem <- function(x, ...) x$paths
