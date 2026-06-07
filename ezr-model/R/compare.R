# Internal: one row of comparison metrics for a fitted lm/glm.
cmp_from_lmglm <- function(m, name) {
  res <- stats::residuals(m)
  is_lm <- inherits(m, "lm") && !inherits(m, "glm")
  tibble::tibble(
    model = name,
    n = length(res),
    df = length(stats::coef(m)),
    r2 = if (is_lm) summary(m)$r.squared else
      if (!is.null(m$null.deviance)) 1 - m$deviance / m$null.deviance else
        NA_real_,
    adj_r2 = if (is_lm) summary(m)$adj.r.squared else NA_real_,
    aic = stats::AIC(m),
    bic = stats::BIC(m),
    rmse = sqrt(mean(res^2))
  )
}

# Internal: one row of comparison metrics for any supported object.
cmp_row <- function(obj, name) {
  if (inherits(obj, "ezrmodel_fit")) return(cmp_from_lmglm(obj$fit, name))
  if (inherits(obj, "ezrmodel_select")) {
    if (inherits(obj$model, "lm") || inherits(obj$model, "glm")) {
      return(cmp_from_lmglm(obj$model, name))
    }
    g <- obj$glance                       # penalised (glmnet) fit
    return(tibble::tibble(
      model = name, n = g$nobs, df = length(obj$selected) + 1L,
      r2 = g$r_squared, adj_r2 = NA_real_, aic = NA_real_, bic = NA_real_,
      rmse = g$rmse))
  }
  if (inherits(obj, "lm") || inherits(obj, "glm")) {
    return(cmp_from_lmglm(obj, name))
  }
  stop("Don't know how to compare an object of class '",
       paste(class(obj), collapse = "/"), "'.", call. = FALSE)
}

#' Compare fitted models side by side
#'
#' Lines up several models in one table of comparable fit statistics -- sample
#' size, degrees of freedom, R-squared, AIC, BIC and RMSE -- and marks the best
#' on your chosen metric, so picking between candidates is a glance rather than a
#' hunt through separate summaries.
#'
#' @param ... Two or more fitted models: [model_lm()] / [model_glm()] results,
#'   [model_select()] results, or raw `lm` / `glm` objects. Name them to label
#'   the rows (e.g. `simple = fit1, full = fit2`).
#' @param metric The metric to sort by and judge "best": `"aic"` (default),
#'   `"bic"`, `"rmse"` (all lower-is-better) or `"r2"` (higher-is-better).
#'
#' @return An `ezrmodel_comparison` object wrapping a `table` (one row per model)
#'   ordered best-first. Has `print()`, `plot()` and `tidy()` methods.
#'
#' @details
#' Metrics are computed on a common footing: R-squared is the usual one for `lm`
#' and a deviance-based pseudo-R-squared for `glm`; RMSE is the root-mean-square
#' residual; AIC/BIC come from the model likelihood (and are `NA` for penalised
#' `glmnet` fits, which have no comparable likelihood -- compare those on RMSE or
#' R-squared). AIC and BIC reward fit while penalising complexity, BIC more
#' harshly; agreement across metrics is reassuring. Compare models fit to the
#' *same rows* for the numbers to mean anything.
#'
#' @family compare
#' @seealso [model_lm()], [model_select()].
#' @examples
#' a <- model_lm(nps_drivers, nps ~ quality + value)
#' b <- model_lm(nps_drivers, nps ~ quality + value + service + trust)
#' compare_models(simple = a, fuller = b)
#' @export
compare_models <- function(..., metric = c("aic", "bic", "rmse", "r2")) {
  metric <- match.arg(metric)
  dots <- list(...)
  if (length(dots) < 2L) {
    stop("Provide at least two models to compare.", call. = FALSE)
  }
  nms <- names(dots)
  if (is.null(nms)) nms <- rep("", length(dots))
  nms[!nzchar(nms)] <- paste0("model", seq_along(dots))[!nzchar(nms)]

  tab <- do.call(rbind, Map(cmp_row, dots, nms))
  desc <- metric == "r2"
  ord <- order(tab[[metric]], decreasing = desc, na.last = TRUE)
  tab <- tab[ord, , drop = FALSE]
  tab$best <- seq_len(nrow(tab)) == 1L

  structure(list(table = tibble::as_tibble(tab), metric = metric),
            class = "ezrmodel_comparison")
}

#' @export
print.ezrmodel_comparison <- function(x, ...) {
  cat(sprintf("Model comparison  (best by %s)\n", toupper(x$metric)))
  d <- x$table
  num <- vapply(d, is.numeric, logical(1))
  d[num] <- lapply(d[num], function(v) round(v, 3))
  d$best <- ifelse(d$best, "*", "")
  print(as.data.frame(d), row.names = FALSE)
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_comparison <- function(x, ...) x$table

#' @export
plot.ezrmodel_comparison <- function(x, ...) {
  d <- x$table
  d <- d[!is.na(d[[x$metric]]), , drop = FALSE]
  d$model <- factor(d$model, levels = rev(d$model))
  ggplot2::ggplot(d, ggplot2::aes(.data$model, .data[[x$metric]],
                                  fill = .data$best)) +
    ggplot2::geom_col(width = .7) +
    ggplot2::scale_fill_manual(values = c(`TRUE` = pal_sequential[5],
                                          `FALSE` = pal_sequential[3]),
                               guide = "none") +
    ggplot2::coord_flip() +
    ggplot2::labs(x = "", y = x$metric, title = "Model comparison") +
    theme_ezrmodel_x(transparent = TRUE)
}
