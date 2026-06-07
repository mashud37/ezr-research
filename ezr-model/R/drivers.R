# ---- per-method importance helpers --------------------------------------
# Each returns a tibble(variable, importance) where larger = more important.

importance_cor <- function(mf, target, preds, method = "spearman") {
  imp <- vapply(preds, function(p) {
    suppressWarnings(stats::cor(mf[[p]], mf[[target]], method = method,
                                use = "complete.obs"))
  }, numeric(1))
  tibble::tibble(variable = preds, importance = abs(imp))
}

importance_lm <- function(mf, target, preds) {
  d <- as.data.frame(scale(mf[, c(target, preds), drop = FALSE]))
  fit <- stats::lm(stats::reformulate(preds, response = target), data = d)
  co <- summary(fit)$coefficients
  co <- co[rownames(co) != "(Intercept)", , drop = FALSE]
  tibble::tibble(variable = rownames(co),
                 importance = abs(co[, "Estimate"]))
}

importance_rwa <- function(mf, target, preds) {
  d <- mf[, c(target, preds), drop = FALSE]
  r <- rwa::rwa(d, outcome = target, predictors = preds)
  tibble::tibble(variable = r$result$Variables,
                 importance = r$result$Rescaled.RelWeight)
}

importance_rf <- function(mf, target, preds, seed = NULL) {
  if (!is.null(seed)) {
    if (exists(".Random.seed", envir = globalenv())) {
      old <- get(".Random.seed", envir = globalenv())
      on.exit(assign(".Random.seed", old, envir = globalenv()), add = TRUE)
    }
    set.seed(seed)
  }
  fit <- randomForest::randomForest(
    stats::reformulate(preds, response = target), data = mf)
  imp <- randomForest::importance(fit)
  col <- if ("IncNodePurity" %in% colnames(imp)) "IncNodePurity" else colnames(imp)[1]
  tibble::tibble(variable = rownames(imp), importance = as.numeric(imp[, col]))
}

importance_fa <- function(mf, target, preds) {
  f <- psych::fa(mf[, preds, drop = FALSE], nfactors = 1, rotate = "none",
                 warnings = FALSE)
  load <- abs(as.numeric(f$loadings[, 1]))
  tibble::tibble(variable = rownames(f$loadings), importance = load)
}

method_available <- function(m) {
  switch(m,
    cor = TRUE, lm = TRUE,
    rwa = requireNamespace("rwa", quietly = TRUE),
    rf = requireNamespace("randomForest", quietly = TRUE),
    fa = requireNamespace("psych", quietly = TRUE),
    FALSE)
}

#' Find the drivers of a target variable
#'
#' The signature ezrmodel helper: in one line, rank how strongly each predictor
#' relates to a `target`, by **several methods at once**, and combine them into a
#' consensus. Different methods see different things (linear vs non-linear,
#' marginal vs partial, shared factor), so agreement across them is a robust
#' signal of what really drives the outcome.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param target The outcome column (unquoted).
#' @param predictors Predictor columns (tidyselect). Default: all numeric columns
#'   except `target`.
#' @param methods Which importance methods to combine, any of `"cor"`
#'   (correlation), `"lm"` (standardised regression coefficients), `"rwa"`
#'   (relative weights), `"rf"` (random-forest importance), `"fa"` (single-factor
#'   loading). Defaults to all five. Methods whose package is not installed are
#'   skipped with a message.
#'
#' @return An `ezrmodel_drivers` object: a list with the `target`, the `methods`
#'   used, a long `importance` table (variable x method, with per-method rank),
#'   and a `consensus` table (mean rank and mean normalised importance per
#'   variable). Has `print()`, `plot()` and `tidy()` methods.
#'
#' @details
#' Each method scores every predictor; scores are turned into per-method ranks
#' (1 = strongest) and a normalised 0-1 importance. The **consensus** orders
#' variables by their mean rank across the available methods -- a variable that
#' is near the top everywhere rises, one that only one method likes does not. The
#' built-in methods cover complementary views: `cor` (simple monotonic
#' association), `lm` (unique linear contribution), `rwa` (variance shared out
#' between correlated predictors), `rf` (non-linear / interaction importance) and
#' `fa` (loading on the common factor). Optional methods (`rwa`/`rf`/`fa`) need
#' their Suggested package; without it they are dropped.
#'
#' @family drivers
#' @seealso [model_lm()], [correlations()], [model_frame()].
#' @examples
#' d <- drivers(nps_drivers, nps, methods = c("cor", "lm"))
#' d
#' tidy(d)
#' @export
drivers <- function(data = NULL, target, predictors = NULL,
                    methods = c("cor", "lm", "rwa", "rf", "fa")) {
  data <- resolve_data(data)
  target_name <- rlang::as_name(rlang::ensym(target))
  methods <- intersect(methods, c("cor", "lm", "rwa", "rf", "fa"))
  if (length(methods) == 0L) stop("No valid `methods` selected.", call. = FALSE)

  # numeric model frame (inlined so target can be dynamic)
  pred_q <- rlang::enquo(predictors)
  if (rlang::quo_is_null(pred_q)) {
    preds <- names(data)[vapply(data, is.numeric, logical(1))]
  } else {
    preds <- names(dplyr::select(data, !!pred_q))
  }
  preds <- setdiff(preds, target_name)
  mf <- data.frame(stats::setNames(
    lapply(c(target_name, preds), function(p) ensure_numeric(data[[p]], quiet = TRUE)),
    c(target_name, preds)),
    check.names = FALSE)
  usable <- vapply(preds, function(p) any(!is.na(mf[[p]])), logical(1))
  preds <- preds[usable]
  mf <- mf[stats::complete.cases(mf[, c(target_name, preds)]), , drop = FALSE]
  if (length(preds) < 2L || nrow(mf) < 10L) {
    stop("Need at least 2 numeric predictors and 10 complete rows.",
         call. = FALSE)
  }

  avail <- methods[vapply(methods, method_available, logical(1))]
  skipped <- setdiff(methods, avail)
  if (length(skipped)) {
    message("Skipping unavailable method(s): ", paste(skipped, collapse = ", "),
            " (install the matching package).")
  }
  if (length(avail) == 0L) stop("No usable methods available.", call. = FALSE)

  seed <- ezrmodel_default("seed")
  parts <- lapply(avail, function(m) {
    imp <- switch(m,
      cor = importance_cor(mf, target_name, preds),
      lm = importance_lm(mf, target_name, preds),
      rwa = importance_rwa(mf, target_name, preds),
      rf = importance_rf(mf, target_name, preds, seed = seed),
      fa = importance_fa(mf, target_name, preds))
    imp$method <- m
    imp$rank <- rank(-imp$importance, ties.method = "min")
    rng <- diff(range(imp$importance, na.rm = TRUE))
    imp$score <- if (rng == 0) 0.5 else
      (imp$importance - min(imp$importance, na.rm = TRUE)) / rng
    imp
  })
  long <- tibble::as_tibble(do.call(rbind, parts))

  consensus <- long %>%
    dplyr::group_by(.data$variable) %>%
    dplyr::summarise(mean_rank = mean(.data$rank),
                     score = mean(.data$score), .groups = "drop") %>%
    dplyr::arrange(.data$mean_rank)

  structure(
    list(target = target_name, methods = avail, n = nrow(mf),
         importance = long[, c("variable", "method", "importance", "rank",
                               "score")],
         consensus = consensus),
    class = "ezrmodel_drivers"
  )
}

#' @export
print.ezrmodel_drivers <- function(x, ...) {
  cat(sprintf("Drivers of '%s'  (n = %d, methods: %s)\n",
              x$target, x$n, paste(x$methods, collapse = ", ")))
  top <- utils::head(x$consensus, 10)
  labels <- format(paste0(seq_len(nrow(top)), ". ", top$variable))
  cat(paste0("  ", labels, "   mean rank ",
             formatC(top$mean_rank, format = "f", digits = 1)),
      sep = "\n")
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_drivers <- function(x, ...) {
  x$importance
}

#' @export
plot.ezrmodel_drivers <- function(x, ...) {
  d <- x$consensus
  d$variable <- factor(d$variable, levels = rev(d$variable))
  ggplot2::ggplot(d, ggplot2::aes(.data$variable, .data$score)) +
    ggplot2::geom_col(fill = pal_sequential[4], width = .7) +
    ggplot2::coord_flip() +
    ggplot2::labs(x = "", y = "consensus importance",
                  title = paste0("Drivers of '", x$target, "'")) +
    theme_ezrmodel_x(transparent = TRUE)
}
