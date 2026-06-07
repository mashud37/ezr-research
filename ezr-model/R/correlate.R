#' Correlations among numeric variables (optionally vs a target)
#'
#' Computes a correlation matrix over the numeric columns in one line, and -- when
#' you name a `target` -- a ranked table of how each variable correlates with it.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param target Optional outcome column (unquoted) to focus on; the result then
#'   ranks variables by their correlation with it.
#' @param method `"spearman"` (default, rank-based and robust), `"pearson"` or
#'   `"kendall"`.
#' @param select Columns to include (tidyselect). Default: all numeric columns.
#'
#' @return An `ezrmodel_cor` object: the correlation `matrix`, the `method`, and
#'   (if a target was given) a ranked `target_cor` table. Has `print()`,
#'   `plot()` (heatmap) and `tidy()` methods.
#'
#' @details
#' Spearman is the default because survey and behavioural variables are often
#' ordinal or skewed, and rank correlation does not assume linearity. Missing
#' values are handled pairwise. With a `target`, `print()` and `tidy()` give the
#' focused ranking that usually answers "what moves with the outcome?"; without
#' one you get the full matrix and its strongest pairs.
#'
#' @family correlation
#' @seealso [drivers()], [model_lm()].
#' @examples
#' correlations(nps_drivers, nps)
#' #> Correlations with 'nps' (spearman, 8 variables)
#' #>   quality  0.51
#' #>   value    0.46
#' #>   ...
#' @export
correlations <- function(data = NULL, target = NULL,
                         method = c("spearman", "pearson", "kendall"),
                         select = NULL) {
  data <- resolve_data(data)
  method <- match.arg(method)
  target_q <- rlang::enquo(target)
  has_target <- !rlang::quo_is_null(target_q)
  tname <- if (has_target) rlang::as_name(rlang::ensym(target)) else NULL

  sel_q <- rlang::enquo(select)
  if (rlang::quo_is_null(sel_q)) {
    num <- names(data)[vapply(data, is.numeric, logical(1))]
  } else {
    s <- names(dplyr::select(data, {{ select }}))
    num <- s[vapply(data[s], is.numeric, logical(1))]
  }
  if (has_target) num <- union(tname, num)
  if (length(num) < 2L) {
    stop("Need at least 2 numeric columns to correlate.", call. = FALSE)
  }

  m <- stats::cor(data[, num, drop = FALSE], method = method,
                  use = "pairwise.complete.obs")

  target_cor <- NULL
  if (has_target) {
    others <- setdiff(rownames(m), tname)
    target_cor <- tibble::tibble(variable = others,
                                 correlation = as.numeric(m[others, tname])) %>%
      dplyr::arrange(dplyr::desc(abs(.data$correlation)))
  }

  structure(list(matrix = m, method = method, target = tname,
                 target_cor = target_cor),
            class = "ezrmodel_cor")
}

#' @export
print.ezrmodel_cor <- function(x, ...) {
  if (!is.null(x$target)) {
    cat(sprintf("Correlations with '%s' (%s, %d variables)\n",
                x$target, x$method, nrow(x$target_cor)))
    top <- utils::head(x$target_cor, 10)
    cat(paste0("  ", format(top$variable), "  ",
               formatC(top$correlation, format = "f", digits = 2)),
        sep = "\n")
  } else {
    cat(sprintf("Correlation matrix (%s, %d variables)\n",
                x$method, nrow(x$matrix)))
    print(round(x$matrix, 2))
  }
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_cor <- function(x, ...) {
  if (!is.null(x$target_cor)) return(x$target_cor)
  m <- x$matrix
  out <- expand.grid(var1 = rownames(m), var2 = colnames(m),
                     stringsAsFactors = FALSE)
  out$correlation <- as.numeric(m)
  tibble::as_tibble(out[out$var1 != out$var2, ])
}

#' @export
plot.ezrmodel_cor <- function(x, ...) {
  m <- x$matrix
  d <- expand.grid(var1 = rownames(m), var2 = colnames(m),
                   stringsAsFactors = FALSE)
  d$correlation <- as.numeric(m)
  d$var1 <- factor(d$var1, levels = rownames(m))
  d$var2 <- factor(d$var2, levels = rev(colnames(m)))
  ggplot2::ggplot(d, ggplot2::aes(.data$var1, .data$var2,
                                  fill = .data$correlation)) +
    ggplot2::geom_tile() +
    scale_fill_diverging() +
    ggplot2::labs(x = "", y = "", fill = "r",
                  title = paste0("Correlations (", x$method, ")")) +
    theme_ezrmodel(transparent = TRUE) +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1),
                   legend.position = "right")
}
