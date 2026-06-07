# Internal: tidy a fitted lm/glm into a coefficient tibble.
tidy_coefs <- function(fit) {
  co <- summary(fit)$coefficients
  tibble::tibble(
    term = rownames(co),
    estimate = co[, 1],
    std_error = co[, 2],
    statistic = co[, 3],
    p_value = co[, 4],
    signif = co[, 4] < 0.05
  )
}

# Internal: one-row model fit summary.
glance_fit <- function(fit) {
  n <- length(stats::residuals(fit))
  if (inherits(fit, "glm")) {
    tibble::tibble(nobs = n, aic = stats::AIC(fit), bic = stats::BIC(fit),
                   null_deviance = fit$null.deviance,
                   deviance = fit$deviance)
  } else {
    s <- summary(fit)
    tibble::tibble(nobs = n, r_squared = s$r.squared,
                   adj_r_squared = s$adj.r.squared,
                   aic = stats::AIC(fit), bic = stats::BIC(fit))
  }
}

new_ezrmodel_fit <- function(fit, kind) {
  structure(
    list(fit = fit, kind = kind,
         coefficients = tidy_coefs(fit),
         glance = glance_fit(fit)),
    class = "ezrmodel_fit"
  )
}

#' Fit a linear or generalised linear model, tidily
#'
#' One-line `lm()` / `glm()` that returns a result object carrying the tidy
#' coefficient table, the fit summary and the model itself -- ready to `print()`,
#' `plot()` (a coefficient plot), `tidy()` and `augment()`.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used. (Note: because `formula` is the second argument, with a default
#'   dataset call `model_lm(formula = y ~ .)` or pipe the data in.)
#' @param formula A model formula, e.g. `nps ~ quality + value`.
#' @param ... Passed to [stats::lm()] / [stats::glm()].
#' @param family For `model_glm()`, the error family (e.g. `binomial()`).
#'   Defaults to `gaussian()`.
#'
#' @return An `ezrmodel_fit` object (`fit`, `coefficients`, `glance`).
#'
#' @details
#' The coefficient table flags significance at p < 0.05; `glance` reports
#' R-squared / adjusted R-squared (lm) or deviance (glm) plus AIC/BIC and the
#' sample size. `augment()` returns the data with `.fitted` and `.resid`
#' appended. For *ranking* many candidate predictors rather than fitting one
#' model, use [drivers()].
#'
#' @family regression
#' @seealso [drivers()], [correlations()].
#' @examples
#' fit <- model_lm(nps_drivers, nps ~ quality + value + service)
#' fit
#' tidy(fit)
#' @export
model_lm <- function(data = NULL, formula, ...) {
  data <- resolve_data(data)
  fit <- stats::lm(formula, data = data, ...)
  new_ezrmodel_fit(fit, "lm")
}

#' @rdname model_lm
#' @examples
#' # logistic model of "promoter" status
#' g <- model_glm(nps_drivers, I(nps >= 9) ~ quality + value,
#'                family = binomial())
#' tidy(g)
#' @export
model_glm <- function(data = NULL, formula, family = stats::gaussian(), ...) {
  data <- resolve_data(data)
  fit <- stats::glm(formula, data = data, family = family, ...)
  new_ezrmodel_fit(fit, "glm")
}

#' @export
print.ezrmodel_fit <- function(x, ...) {
  cat(sprintf("%s: %s\n", toupper(x$kind),
              paste(deparse(stats::formula(x$fit)), collapse = " ")))
  g <- x$glance
  if (!is.null(g$r_squared)) {
    cat(sprintf("  n = %d   R2 = %.3f   adj R2 = %.3f   AIC = %.1f\n",
                g$nobs, g$r_squared, g$adj_r_squared, g$aic))
  } else {
    cat(sprintf("  n = %d   deviance = %.1f   AIC = %.1f\n",
                g$nobs, g$deviance, g$aic))
  }
  co <- x$coefficients
  co$estimate <- formatC(co$estimate, format = "f", digits = 3)
  co$p_value <- formatC(co$p_value, format = "f", digits = 3)
  print(as.data.frame(co[, c("term", "estimate", "p_value", "signif")]),
        row.names = FALSE)
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_fit <- function(x, ...) {
  x$coefficients
}

#' @export
augment.ezrmodel_fit <- function(x, ...) {
  d <- tibble::as_tibble(stats::model.frame(x$fit))
  d$.fitted <- as.numeric(stats::fitted(x$fit))
  d$.resid <- as.numeric(stats::residuals(x$fit))
  d
}

#' @export
plot.ezrmodel_fit <- function(x, ...) {
  co <- x$coefficients[x$coefficients$term != "(Intercept)", , drop = FALSE]
  co$term <- factor(co$term, levels = rev(co$term))
  co$lo <- co$estimate - 1.96 * co$std_error
  co$hi <- co$estimate + 1.96 * co$std_error
  ggplot2::ggplot(co, ggplot2::aes(.data$estimate, .data$term)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey60") +
    ggplot2::geom_errorbar(ggplot2::aes(xmin = .data$lo, xmax = .data$hi),
                           orientation = "y", width = .2) +
    ggplot2::geom_point(size = 2) +
    ggplot2::labs(x = "estimate (95% CI)", y = "",
                  title = "Model coefficients") +
    theme_ezrmodel_x(transparent = TRUE)
}
