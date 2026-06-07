#' Test a value across groups
#'
#' Runs a hypothesis test for each level of a grouping variable in one call and
#' returns a tidy significance table -- either each group against a **benchmark**
#' `mu`, or each group against a **reference** group. Replaces the hand-written
#' loop of `t.test()` / `wilcox.test()` calls.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param value The numeric column to test (unquoted).
#' @param group The grouping column (unquoted).
#' @param mu Benchmark value for a one-sample test of each group. If both `mu`
#'   and `ref` are `NULL`, `mu` defaults to the overall mean.
#' @param ref Reference group level for a two-sample test of every other group
#'   against it. Overrides `mu`.
#' @param method `"t"` (Welch t-test, default) or `"wilcox"` (Mann-Whitney /
#'   signed-rank, rank-based).
#' @param alpha Significance threshold for the `signif` flag. Default `0.05`.
#'
#' @return An `ezrmodel_tests` object wrapping a tidy table (`group`,
#'   `comparison`, `n`, `estimate`, `statistic`, `p_value`, `signif`). Has
#'   `print()`, `tidy()` and `plot()` methods.
#'
#' @details
#' Use `mu` to ask "is this group above/below a target?" (e.g. an NPS benchmark),
#' and `ref` to ask "does this group differ from our baseline group?". The
#' `estimate` is the group mean minus the benchmark (one-sample) or minus the
#' reference-group mean (two-sample). Blanks / non-answers in `group` and missing
#' values are dropped; results are sorted by p-value. `"wilcox"` is the robust
#' choice for skewed or ordinal values.
#'
#' @family tests
#' @seealso [correlations()].
#' @examples
#' test_groups(nps_drivers, nps, region, mu = 6)
#' #> Tests of 'nps' across 'region' (t, vs mu = 6)
#' test_groups(nps_drivers, nps, region, ref = "Europe")
#' @export
test_groups <- function(data = NULL, value, group, mu = NULL, ref = NULL,
                        method = c("t", "wilcox"), alpha = 0.05) {
  data <- resolve_data(data)
  method <- match.arg(method)
  vname <- rlang::as_name(rlang::ensym(value))
  gname <- rlang::as_name(rlang::ensym(group))

  v <- ensure_numeric(data[[vname]], quiet = TRUE)
  g <- na_blank(as.character(data[[gname]]))
  keep <- !is.na(v) & !is.na(g)
  v <- v[keep]; g <- g[keep]
  groups <- sort(unique(g))
  if (length(groups) < 2L) stop("Need at least 2 groups.", call. = FALSE)

  if (!is.null(ref) && !ref %in% groups) {
    stop("Reference group '", ref, "' not found.", call. = FALSE)
  }
  if (is.null(mu) && is.null(ref)) mu <- mean(v)
  test_fn <- if (method == "t") stats::t.test else stats::wilcox.test

  rows <- lapply(groups, function(gi) {
    x <- v[g == gi]
    if (length(x) < 2L) return(NULL)
    if (!is.null(ref)) {
      if (gi == ref) return(NULL)
      y <- v[g == ref]
      tt <- suppressWarnings(test_fn(x, y))
      est <- mean(x) - mean(y)
      comp <- paste0(gi, " vs ", ref)
    } else {
      tt <- suppressWarnings(test_fn(x, mu = mu))
      est <- mean(x) - mu
      comp <- paste0(gi, " vs mu=", round(mu, 2))
    }
    tibble::tibble(group = gi, comparison = comp, n = length(x),
                   estimate = est, statistic = unname(tt$statistic),
                   p_value = tt$p.value)
  })
  out <- dplyr::bind_rows(rows)
  out$signif <- out$p_value < alpha
  out <- dplyr::arrange(out, .data$p_value)

  structure(list(value = vname, group = gname, method = method,
                 mu = mu, ref = ref, table = out),
            class = "ezrmodel_tests")
}

#' @export
print.ezrmodel_tests <- function(x, ...) {
  basis <- if (!is.null(x$ref)) paste0("vs ", x$ref) else
    paste0("vs mu = ", round(x$mu, 2))
  cat(sprintf("Tests of '%s' across '%s'  (%s, %s)\n",
              x$value, x$group, x$method, basis))
  t <- x$table
  t$estimate <- formatC(t$estimate, format = "f", digits = 2)
  t$p_value <- formatC(t$p_value, format = "f", digits = 3)
  print(as.data.frame(t[, c("comparison", "n", "estimate", "p_value",
                            "signif")]), row.names = FALSE)
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_tests <- function(x, ...) {
  x$table
}

#' @export
plot.ezrmodel_tests <- function(x, ...) {
  t <- x$table
  t$group <- factor(t$group, levels = t$group[order(t$estimate)])
  ggplot2::ggplot(t, ggplot2::aes(.data$estimate, .data$group,
                                  colour = .data$signif)) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey60") +
    ggplot2::geom_point(size = 3) +
    ggplot2::scale_colour_manual(values = c(`TRUE` = "#86A33B",
                                            `FALSE` = "grey70")) +
    ggplot2::labs(x = "difference", y = "", colour = "significant",
                  title = sprintf("'%s' by '%s'", x$value, x$group)) +
    theme_ezrmodel_x(transparent = TRUE) +
    ggplot2::theme(legend.position = "right")
}
