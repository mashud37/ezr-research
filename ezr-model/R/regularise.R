# Internal: training R-squared for a numeric response.
r2_of <- function(y, pred) {
  ss_res <- sum((y - pred)^2)
  ss_tot <- sum((y - mean(y))^2)
  if (ss_tot == 0) NA_real_ else 1 - ss_res / ss_tot
}

# Internal: run the RNG with a temporary seed, restoring state afterwards.
with_seed <- function(seed, expr) {
  if (is.null(seed)) return(expr)
  if (exists(".Random.seed", envir = globalenv())) {
    old <- get(".Random.seed", envir = globalenv())
    on.exit(assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  }
  set.seed(seed)
  expr
}

#' Select predictors with stepwise or regularised regression
#'
#' Fits a regression that *chooses its own predictors*: stepwise selection by
#' AIC, or a penalised (lasso / ridge / elastic-net) fit that shrinks weak
#' coefficients -- in one line, returning the kept terms, their coefficients and
#' the fit, so you can see what survived.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param formula A model formula, e.g. `nps ~ value + quality + service`.
#' @param method One of `"stepwise"` (both-direction AIC selection on an
#'   `lm`/`glm`), `"lasso"`, `"ridge"` or `"elastic"` (penalised `glmnet` fit,
#'   with the penalty `lambda` chosen by cross-validation).
#' @param family Error family, as a string. Default `"gaussian"`. Use
#'   `"binomial"` for a 0/1 outcome.
#' @param alpha Elastic-net mixing for `method = "elastic"` (0 = ridge,
#'   1 = lasso). Default `0.5`. Ignored for the other methods.
#' @param nfolds Cross-validation folds for the penalised methods. Default `10`.
#'
#' @return An `ezrmodel_select` object: the `method`, the `coefficients`
#'   (kept/non-zero terms), the `selected` term names, a `glance` of fit, and the
#'   underlying model. Has `print()`, `plot()` (coefficients), `tidy()` and
#'   `augment()` methods.
#'
#' @details
#' Stepwise selection adds and drops terms to minimise AIC; it returns an
#' ordinary `lm`/`glm`, so the coefficient table keeps standard errors and
#' p-values. The penalised methods need the suggested `glmnet` package: they
#' standardise predictors, fit a path of `lambda` values, and report the
#' coefficients at the cross-validated `lambda.min`. **Lasso** zeroes out weak
#' predictors (so `selected` is short), **ridge** keeps all but shrinks them, and
#' **elastic-net** blends the two. Penalised coefficients have no p-values by
#' design. The cross-validation is seeded from the `seed` option for
#' reproducibility. To rank predictors by several importance methods instead of
#' selecting one model, see [drivers()]; to compare fitted models, see
#' [compare_models()].
#'
#' @family regression
#' @seealso [model_lm()], [drivers()], [compare_models()].
#' @examplesIf requireNamespace("glmnet", quietly = TRUE)
#' las <- model_select(nps_drivers,
#'   nps ~ value + quality + service + ease + support + trust + price + innovation,
#'   method = "lasso")
#' las
#' tidy(las)
#' @export
model_select <- function(data = NULL, formula,
                         method = c("stepwise", "lasso", "ridge", "elastic"),
                         family = "gaussian", alpha = 0.5, nfolds = 10) {
  data <- resolve_data(data)
  method <- match.arg(method)
  seed <- ezrmodel_default("seed")

  if (method == "stepwise") {
    full <- if (identical(family, "gaussian")) {
      stats::lm(formula, data = data)
    } else {
      stats::glm(formula, data = data, family = family)
    }
    sel <- stats::step(full, direction = "both", trace = 0)
    coefs <- tidy_coefs(sel)
    terms <- setdiff(names(stats::coef(sel)), "(Intercept)")
    glance <- glance_fit(sel)
    return(structure(
      list(method = method, family = family, formula = formula,
           coefficients = coefs, selected = terms, glance = glance,
           model = sel, alpha = NA_real_),
      class = "ezrmodel_select"
    ))
  }

  # Penalised path (glmnet).
  if (!requireNamespace("glmnet", quietly = TRUE)) {
    stop("Penalised regression needs the 'glmnet' package. ",
         "Install it with install.packages('glmnet').", call. = FALSE)
  }
  a <- switch(method, lasso = 1, ridge = 0, elastic = alpha)
  mf <- stats::model.frame(formula, data = data)
  y <- stats::model.response(mf)
  x <- stats::model.matrix(stats::terms(mf), mf)
  x <- x[, colnames(x) != "(Intercept)", drop = FALSE]

  cv <- with_seed(seed, glmnet::cv.glmnet(x, y, alpha = a, family = family,
                                          nfolds = nfolds))
  co <- as.matrix(stats::coef(cv, s = "lambda.min"))
  coefs <- tibble::tibble(term = rownames(co), estimate = as.numeric(co))
  terms <- coefs$term[coefs$term != "(Intercept)" & coefs$estimate != 0]
  pred <- as.numeric(stats::predict(cv, newx = x, s = "lambda.min"))
  glance <- tibble::tibble(
    nobs = nrow(x),
    r_squared = if (identical(family, "gaussian")) r2_of(as.numeric(y), pred)
                else NA_real_,
    rmse = sqrt(mean((as.numeric(y) - pred)^2)),
    lambda = cv$lambda.min,
    n_selected = length(terms)
  )

  structure(
    list(method = method, family = family, formula = formula,
         coefficients = coefs, selected = terms, glance = glance,
         model = cv, alpha = a, x = x, y = y),
    class = "ezrmodel_select"
  )
}

#' @export
print.ezrmodel_select <- function(x, ...) {
  cat(sprintf("%s regression: %s\n", x$method,
              paste(deparse(x$formula), collapse = " ")))
  g <- x$glance
  if (x$method == "stepwise") {
    if (!is.null(g$r_squared)) {
      cat(sprintf("  kept %d terms   R2 = %.3f   AIC = %.1f\n",
                  length(x$selected), g$r_squared, g$aic))
    } else {
      cat(sprintf("  kept %d terms   AIC = %.1f\n",
                  length(x$selected), g$aic))
    }
  } else {
    r2 <- if (is.na(g$r_squared)) "" else sprintf("   R2 = %.3f", g$r_squared)
    cat(sprintf("  kept %d / %d terms   lambda = %.4f%s\n",
                length(x$selected), nrow(x$coefficients) - 1L, g$lambda, r2))
  }
  if (length(x$selected)) {
    cat("  selected:", paste(utils::head(x$selected, 12), collapse = ", "),
        "\n")
  }
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_select <- function(x, ...) x$coefficients

#' @export
augment.ezrmodel_select <- function(x, ...) {
  if (x$method == "stepwise") {
    d <- tibble::as_tibble(stats::model.frame(x$model))
    d$.fitted <- as.numeric(stats::fitted(x$model))
    d$.resid <- as.numeric(stats::residuals(x$model))
    return(d)
  }
  pred <- as.numeric(stats::predict(x$model, newx = x$x, s = "lambda.min"))
  d <- tibble::as_tibble(as.data.frame(x$x))
  d$.fitted <- pred
  if (is.numeric(x$y)) d$.resid <- as.numeric(x$y) - pred
  d
}

#' @export
plot.ezrmodel_select <- function(x, ...) {
  co <- x$coefficients[x$coefficients$term != "(Intercept)", , drop = FALSE]
  co <- co[co$estimate != 0, , drop = FALSE]
  co <- co[order(co$estimate), , drop = FALSE]
  co$term <- factor(co$term, levels = co$term)
  ggplot2::ggplot(co, ggplot2::aes(.data$estimate, .data$term)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey60") +
    ggplot2::geom_col(fill = pal_sequential[4], width = .7) +
    ggplot2::labs(x = "coefficient", y = "",
                  title = paste0(x$method, " coefficients")) +
    theme_ezrmodel_x(transparent = TRUE)
}
