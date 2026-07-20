# Internal: distance object. "binary" is asymmetric binary = Jaccard for 0/1
# presence/absence data.
distances <- function(x, method = "euclidean") {
  stats::dist(x, method = method)
}

# Internal: pick k by average silhouette (needs 'cluster'); else fall back.
choose_k <- function(m, k_max = 8, seed = NULL) {
  k_max <- min(k_max, nrow(m) - 1L)
  if (k_max < 2L) return(2L)
  if (!requireNamespace("cluster", quietly = TRUE)) {
    message("Install the 'cluster' package for automatic k; using k = 3.")
    return(3L)
  }
  d <- distances(m)
  ks <- 2:k_max
  sil <- vapply(ks, function(k) {
    if (!is.null(seed)) set.seed(seed)
    cl <- stats::kmeans(m, centers = k, nstart = 5)$cluster
    mean(cluster::silhouette(cl, d)[, 3])
  }, numeric(1))
  ks[which.max(sil)]
}

#' Cluster the rows of a dataset, with diagnostics and profiles
#'
#' One-line clustering that returns not just the assignments but the **quality
#' diagnostics** (silhouette, within-sum-of-squares) and the **cluster profiles**
#' (what each cluster looks like on every variable) -- everything you need to read
#' a segmentation.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param k Number of clusters. If `NULL` (default), chosen automatically by
#'   silhouette (needs the `cluster` package).
#' @param method `"kmeans"` (default), `"hclust"` or `"pam"` (PAM needs the
#'   `cluster` package).
#' @param vars Columns to cluster on (tidyselect). Default: all numeric columns.
#' @param scale Standardise variables first. Default: the `scale` option (`TRUE`).
#' @param dist Distance for `hclust`/`pam`: `"euclidean"` (default),
#'   `"manhattan"`, `"maximum"`, or `"binary"` (Jaccard, for 0/1 data).
#'
#' @return An `ezrmodel_clusters` object: `assignments`, `sizes`, `centers`,
#'   `profile` (per-cluster means), `diagnostics` (avg silhouette, within-SS
#'   ratio) and the inputs. Has `print()`, `plot()`, `tidy()` and `augment()`.
#'
#' @details
#' Variables are standardised by default so that a high-variance column does not
#' dominate the distances. Rows with missing values on the clustering variables
#' are dropped. `print()` shows the sizes and the average silhouette width (a
#' rough guide: > 0.5 strong, 0.25-0.5 reasonable, < 0.25 weak). `plot()` draws
#' the clusters on the first two principal components; `augment()` appends a
#' `.cluster` column to the kept rows; `cluster_profile()` crosses the clusters
#' against another variable.
#'
#' @family clustering
#' @seealso [cluster_profile()], [to_matrix()], [reduce_dims()].
#' @examplesIf requireNamespace("cluster", quietly = TRUE)
#' cl <- cluster(ecommerce, k = 4,
#'               vars = c(recency_days, frequency, monetary, tenure_months))
#' cl
#'
#' # `personas` is built to cluster cleanly; k is found automatically
#' cluster(personas, vars = spend_index:browse_minutes)
#' @export
cluster <- function(data = NULL, k = NULL,
                    method = c("kmeans", "hclust", "pam"),
                    vars = NULL, scale = ezrmodel_default("scale"),
                    dist = "euclidean") {
  data <- resolve_data(data)
  method <- match.arg(method)
  seed <- ezrmodel_default("seed")

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
  if (scale) m <- scale(m)
  if (nrow(m) < 4L) stop("Too few complete rows to cluster.", call. = FALSE)

  if (is.null(k)) k <- choose_k(m, seed = seed)

  if (method == "kmeans") {
    if (!is.null(seed)) set.seed(seed)
    km <- stats::kmeans(m, centers = k, nstart = 10)
    assign <- km$cluster
    centers <- km$centers
    within_ratio <- km$tot.withinss / km$totss
  } else if (method == "hclust") {
    hc <- stats::hclust(distances(m, dist), method = "complete")
    assign <- stats::cutree(hc, k = k)
    centers <- NULL
    within_ratio <- NA_real_
  } else {
    if (!requireNamespace("cluster", quietly = TRUE)) {
      stop("method = 'pam' needs the 'cluster' package.", call. = FALSE)
    }
    pm <- cluster::pam(distances(m, dist), k = k)
    assign <- pm$clustering
    centers <- NULL
    within_ratio <- NA_real_
  }

  avg_sil <- NA_real_
  if (requireNamespace("cluster", quietly = TRUE)) {
    avg_sil <- mean(cluster::silhouette(assign, distances(m, dist))[, 3])
  }

  sizes <- tibble::tibble(cluster = sort(unique(assign)))
  sizes$n <- as.integer(table(assign)[as.character(sizes$cluster)])

  # profiles: means on the original (unscaled) variables
  prof <- as.data.frame(m_full[ok, , drop = FALSE])
  prof$.cluster <- assign
  profile <- prof %>%
    dplyr::group_by(.data$.cluster) %>%
    dplyr::summarise(dplyr::across(dplyr::all_of(vnames), ~ mean(.x)),
                     .groups = "drop") %>%
    dplyr::rename(cluster = ".cluster")

  structure(
    list(method = method, k = k, vars = vnames, scaled = scale,
         assignments = assign, ok = ok, data = data,
         sizes = sizes, centers = centers, profile = profile,
         matrix = m,
         diagnostics = list(avg_silhouette = avg_sil,
                            within_ss_ratio = within_ratio)),
    class = "ezrmodel_clusters"
  )
}

#' @export
print.ezrmodel_clusters <- function(x, ...) {
  cat(sprintf(
    "%s clustering  k = %d  |  %d rows  |  %d variables\n",
    x$method, x$k, sum(x$ok), length(x$vars)
  ))
  sz <- x$sizes
  cat("sizes:   ", paste(sprintf("c%d=%d", sz$cluster, sz$n), collapse = "  "),
      "\n", sep = "")
  diag_parts <- character(0)
  if (!is.na(x$diagnostics$avg_silhouette))
    diag_parts <- c(diag_parts,
                    sprintf("silhouette %.2f  (>0.5 strong, 0.25-0.5 reasonable)",
                            x$diagnostics$avg_silhouette))
  if (!is.na(x$diagnostics$within_ss_ratio))
    diag_parts <- c(diag_parts,
                    sprintf("within/total SS %.2f", x$diagnostics$within_ss_ratio))
  if (length(diag_parts))
    cat("quality: ", paste(diag_parts, collapse = "  "), "\n", sep = "")

  cat("\nVariable profiles (means, * = notably high, · = notably low):\n")
  prof  <- x$profile
  vars  <- x$vars
  k_ids <- sz$cluster
  cw    <- 9L
  nw    <- max(nchar(vars)) + 2L

  m_raw <- as.matrix(x$data[x$ok, vars, drop = FALSE])
  ovr   <- colMeans(m_raw, na.rm = TRUE)
  sds   <- apply(m_raw, 2L, stats::sd, na.rm = TRUE)

  hdr <- formatC("", width = nw)
  for (k in k_ids) hdr <- paste0(hdr, formatC(paste0("c", k), width = cw))
  cat(hdr, formatC("all", width = cw), "\n", sep = "")

  for (v in vars) {
    line <- formatC(v, width = nw, flag = "-")
    cms  <- prof[[v]]
    for (i in seq_along(k_ids)) {
      mu  <- cms[[i]]
      z   <- if (sds[[v]] > 0) (mu - ovr[[v]]) / sds[[v]] else 0
      mrk <- if (z > 0.5) "*" else if (z < -0.5) "·" else " "
      line <- paste0(line, formatC(sprintf("%.1f%s", mu, mrk), width = cw))
    }
    line <- paste0(line, formatC(sprintf("%.1f", ovr[[v]]), width = cw))
    cat(line, "\n", sep = "")
  }

  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_clusters <- function(x, ...) {
  tidyr::pivot_longer(x$profile, cols = dplyr::all_of(x$vars),
                      names_to = "variable", values_to = "mean")
}

#' @export
augment.ezrmodel_clusters <- function(x, ...) {
  d <- tibble::as_tibble(x$data[x$ok, , drop = FALSE])
  d$.cluster <- factor(x$assignments)
  d
}

#' @export
plot.ezrmodel_clusters <- function(x, ...) {
  pc <- stats::prcomp(x$matrix)$x[, 1:2, drop = FALSE]
  d <- tibble::tibble(PC1 = pc[, 1], PC2 = pc[, 2],
                      cluster = factor(x$assignments))
  ggplot2::ggplot(d, ggplot2::aes(.data$PC1, .data$PC2,
                                  colour = .data$cluster)) +
    ggplot2::geom_point(alpha = .7) +
    scale_colour_cluster() +
    ggplot2::labs(title = sprintf("%s clusters (k = %d)", x$method, x$k)) +
    theme_ezrmodel_xy(transparent = TRUE) +
    ggplot2::theme(legend.position = "right")
}

#' Cross clusters against another variable
#'
#' Composes a cluster solution against a categorical variable as a percentage
#' crosstab -- e.g. "what share of each region falls in each cluster?" -- to give
#' the clusters a real-world reading.
#'
#' @param clusters An [cluster()] result (`ezrmodel_clusters`).
#' @param by The variable to cross against (unquoted), from the clustered data.
#' @param digits Decimal places for the percentages. Default `0`.
#'
#' @return A [tibble][tibble::tibble] with one row per `by` level and one column
#'   per cluster, holding column percentages.
#'
#' @details
#' Percentages are computed within each `by` level (each row sums to ~100), so
#' you read "of this segment, X% are in cluster k". Blanks / non-answers in `by`
#' are dropped.
#'
#' @family clustering
#' @seealso [cluster()].
#' @examplesIf requireNamespace("cluster", quietly = TRUE)
#' cl <- cluster(ecommerce, k = 3,
#'               vars = c(recency_days, frequency, monetary))
#' cluster_profile(cl, region)
#' @export
cluster_profile <- function(clusters, by, digits = 0) {
  if (!inherits(clusters, "ezrmodel_clusters")) {
    stop("`clusters` must be an ezrmodel_clusters object from cluster().",
         call. = FALSE)
  }
  by_name <- rlang::as_name(rlang::ensym(by))
  d <- clusters$data[clusters$ok, , drop = FALSE]
  if (!by_name %in% names(d)) {
    stop("Column '", by_name, "' not found in the clustered data.",
         call. = FALSE)
  }
  d$.cluster <- paste0("c", clusters$assignments)
  d[[by_name]] <- na_blank(as.character(d[[by_name]]))
  d %>%
    dplyr::filter(!is.na(.data[[by_name]])) %>%
    dplyr::count(.data[[by_name]], .data$.cluster) %>%
    dplyr::group_by(.data[[by_name]]) %>%
    dplyr::mutate(pct = round(.data$n / sum(.data$n) * 100, digits)) %>%
    dplyr::ungroup() %>%
    dplyr::select(-"n") %>%
    tidyr::pivot_wider(names_from = ".cluster", values_from = "pct",
                       values_fill = 0) %>%
    tibble::as_tibble()
}
