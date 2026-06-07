# Internal: prefix for embedding component columns.
embed_prefix <- function(method) {
  switch(method, pca = "PC", umap = "UMAP", tsne = "tSNE")
}

#' Reduce dimensions with PCA, UMAP or t-SNE
#'
#' One-line dimensionality reduction. `"pca"` returns the scores, variable
#' loadings and variance explained -- the complete linear picture. `"umap"` and
#' `"tsne"` return a low-dimensional embedding that preserves local structure,
#' ideal for visualising clusters in two dimensions.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param method `"pca"` (default, principal components), `"umap"` (uniform
#'   manifold approximation, needs `uwot`) or `"tsne"` (t-SNE, needs `Rtsne`).
#' @param n Number of components / embedding dimensions. For `"pca"`, `NULL`
#'   (default) keeps all; for `"umap"`/`"tsne"` the default is `2`.
#' @param vars Columns to reduce (tidyselect). Default: all numeric columns.
#' @param scale Standardise variables first. Default: the `scale` option
#'   (`TRUE`).
#' @param ... Passed to the engine ([stats::prcomp()], [uwot::umap()] or
#'   [Rtsne::Rtsne()]).
#'
#' @return An `ezrmodel_reduction` object: `scores` (the components / embedding),
#'   and for PCA also `loadings` and `variance`. Has `print()`, `plot()` (scree
#'   for PCA, a 2-D scatter for embeddings), `tidy()` and `augment()` methods.
#'
#' @details
#' Standardising (the default) means each variable contributes equally regardless
#' of its units. **PCA** is linear and interpretable: the `variance` table tells
#' you how many components are worth keeping and `loadings` say what each
#' component means. **UMAP** and **t-SNE** are non-linear and built for *seeing*
#' structure -- they place similar rows near each other in 2-D but their axes have
#' no global meaning, so use them to visualise (often coloured by a [cluster()]
#' assignment), not to interpret coordinates. Both are stochastic and seeded from
#' the `seed` option for reproducibility. `augment()` appends the kept dimensions
#' (`.PC1`, `.UMAP1`, ...) to the rows used.
#'
#' @family reduction
#' @seealso [cluster()], [to_matrix()].
#' @examples
#' r <- reduce_dims(ecommerce, vars = c(recency_days, frequency, monetary,
#'                                      tenure_months, returns))
#' r
#' tidy(r)
#' @export
reduce_dims <- function(data = NULL, method = "pca", n = NULL, vars = NULL,
                        scale = ezrmodel_default("scale"), ...) {
  data <- resolve_data(data)
  method <- match.arg(method, c("pca", "umap", "tsne"))

  vars_q <- rlang::enquo(vars)
  if (rlang::quo_is_null(vars_q)) {
    vnames <- names(data)[vapply(data, is.numeric, logical(1))]
  } else {
    s <- names(dplyr::select(data, {{ vars }}))
    vnames <- s[vapply(data[s], is.numeric, logical(1))]
  }
  if (length(vnames) < 2L) stop("Need at least 2 numeric variables.", call. = FALSE)

  m_full <- as.matrix(data[, vnames, drop = FALSE])
  ok <- stats::complete.cases(m_full)
  m <- m_full[ok, , drop = FALSE]

  if (method == "pca") return(reduce_pca(m, ok, n, vnames, data, scale, ...))

  if (scale) m <- scale(m)
  n_keep <- if (is.null(n)) 2L else n
  seed <- ezrmodel_default("seed")
  prefix <- embed_prefix(method)

  if (method == "umap") {
    if (!requireNamespace("uwot", quietly = TRUE)) {
      stop("UMAP needs the 'uwot' package. ",
           "Install it with install.packages('uwot').", call. = FALSE)
    }
    emb <- with_seed(seed, uwot::umap(m, n_components = n_keep, ...))
    model <- NULL
  } else {
    if (!requireNamespace("Rtsne", quietly = TRUE)) {
      stop("t-SNE needs the 'Rtsne' package. ",
           "Install it with install.packages('Rtsne').", call. = FALSE)
    }
    rt <- with_seed(seed, Rtsne::Rtsne(m, dims = n_keep,
                                       check_duplicates = FALSE, ...))
    emb <- rt$Y
    model <- rt
  }

  scores <- tibble::as_tibble(as.data.frame(emb))
  names(scores) <- paste0(prefix, seq_len(ncol(scores)))

  structure(
    list(method = method, model = model, n = n_keep, vars = vnames, ok = ok,
         data = data, scores = scores, loadings = NULL, variance = NULL),
    class = "ezrmodel_reduction"
  )
}

# Internal: the PCA branch (keeps the original behaviour).
reduce_pca <- function(m, ok, n, vnames, data, scale, ...) {
  pc <- stats::prcomp(m, scale. = scale, center = TRUE, ...)
  n_keep <- if (is.null(n)) ncol(pc$x) else min(n, ncol(pc$x))
  comp <- paste0("PC", seq_len(ncol(pc$x)))
  sdev <- pc$sdev
  prop <- sdev^2 / sum(sdev^2)
  variance <- tibble::tibble(component = comp, sd = sdev,
                             proportion = prop, cumulative = cumsum(prop))
  scores <- tibble::as_tibble(pc$x[, seq_len(n_keep), drop = FALSE])
  loadings <- tibble::as_tibble(pc$rotation[, seq_len(n_keep), drop = FALSE],
                                rownames = "variable")
  structure(
    list(method = "pca", model = pc, n = n_keep, vars = vnames, ok = ok,
         data = data, scores = scores, loadings = loadings,
         variance = variance),
    class = "ezrmodel_reduction"
  )
}

#' @export
print.ezrmodel_reduction <- function(x, ...) {
  if (x$method == "pca") {
    cat(sprintf("PCA of %d variables  (%d rows, %d components kept)\n",
                length(x$vars), sum(x$ok), x$n))
    v <- utils::head(x$variance, max(x$n, 3))
    cat(paste0("  ", v$component, ": ",
               formatC(v$proportion * 100, format = "f", digits = 1), "%  (cum ",
               formatC(v$cumulative * 100, format = "f", digits = 1), "%)"),
        sep = "\n")
  } else {
    label <- if (x$method == "tsne") "t-SNE" else "UMAP"
    cat(sprintf("%s embedding of %d variables  (%d rows, %d dimensions)\n",
                label, length(x$vars), sum(x$ok), x$n))
  }
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_reduction <- function(x, ...) {
  if (x$method == "pca") {
    return(tidyr::pivot_longer(x$loadings, cols = -"variable",
                               names_to = "component", values_to = "loading"))
  }
  x$scores
}

#' @export
augment.ezrmodel_reduction <- function(x, ...) {
  d <- tibble::as_tibble(x$data[x$ok, , drop = FALSE])
  sc <- x$scores
  names(sc) <- paste0(".", names(sc))
  dplyr::bind_cols(d, sc)
}

#' @export
plot.ezrmodel_reduction <- function(x, ...) {
  if (x$method == "pca") {
    v <- x$variance
    v$component <- factor(v$component, levels = v$component)
    return(
      ggplot2::ggplot(v, ggplot2::aes(.data$component, .data$proportion)) +
        ggplot2::geom_col(fill = pal_sequential[4], width = .7) +
        ggplot2::geom_line(ggplot2::aes(group = 1, y = .data$cumulative),
                           colour = "grey40") +
        ggplot2::geom_point(ggplot2::aes(y = .data$cumulative), colour = "grey40") +
        ggplot2::scale_y_continuous(
          labels = function(p) paste0(round(p * 100), "%")) +
        ggplot2::labs(x = "", y = "variance explained", title = "PCA scree") +
        theme_ezrmodel_y(transparent = TRUE)
    )
  }
  sc <- x$scores
  d1 <- names(sc)[1]; d2 <- names(sc)[min(2, ncol(sc))]
  label <- if (x$method == "tsne") "t-SNE" else "UMAP"
  ggplot2::ggplot(sc, ggplot2::aes(.data[[d1]], .data[[d2]])) +
    ggplot2::geom_point(colour = pal_sequential[4], alpha = .6) +
    ggplot2::labs(x = d1, y = d2, title = paste0(label, " embedding")) +
    theme_ezrmodel_xy(transparent = TRUE)
}
