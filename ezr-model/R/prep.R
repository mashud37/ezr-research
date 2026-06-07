#' Assemble a numeric model frame (target + predictors)
#'
#' Builds the tidy, complete-case numeric data frame the modelling helpers need:
#' a target column followed by its predictors, with text salvaged to numbers and
#' incomplete rows dropped. This is the shared first step of [drivers()],
#' [model_lm()] and [correlations()] -- exposed so you can inspect or reuse it.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param target The outcome column (unquoted).
#' @param predictors Predictor columns, using tidyselect. If `NULL` (default),
#'   every numeric column except `target` is used.
#' @param na_rm Drop rows with any missing value (complete cases). Default
#'   `TRUE`.
#'
#' @return A [tibble][tibble::tibble] with `target` first, then the numeric
#'   predictors.
#'
#' @details
#' When `predictors = NULL` only columns that are *already numeric* are taken, so
#' id and text columns are ignored automatically. When you name predictors
#' explicitly they are passed through [ensure_numeric()] (so a worded rating
#' column still works), and any that come out entirely `NA` are dropped. The
#' target is also coerced with [ensure_numeric()].
#'
#' @family prep
#' @seealso [to_matrix()], [drivers()], [model_lm()].
#' @examples
#' model_frame(nps_drivers, nps)
#' #> # A tibble: 600 x 9
#' #>     nps value quality service  ease support trust price innovation
#' #>   <dbl> <dbl>   <dbl>   <dbl> <dbl>   <dbl> <dbl> <dbl>      <dbl>
#' #> # ... region / segment (non-numeric) are dropped automatically
#' @export
model_frame <- function(data = NULL, target, predictors = NULL, na_rm = TRUE) {
  data <- resolve_data(data)
  target_name <- rlang::as_name(rlang::ensym(target))
  if (!target_name %in% names(data)) {
    stop("Target column '", target_name, "' not found in `data`.", call. = FALSE)
  }
  pred_q <- rlang::enquo(predictors)
  if (rlang::quo_is_null(pred_q)) {
    pred_names <- names(data)[vapply(data, is.numeric, logical(1))]
  } else {
    pred_names <- names(dplyr::select(data, {{ predictors }}))
  }
  pred_names <- setdiff(pred_names, target_name)
  if (length(pred_names) == 0L) {
    stop("No predictor columns found.", call. = FALSE)
  }

  out <- tibble::tibble(
    !!target_name := ensure_numeric(data[[target_name]], quiet = TRUE)
  )
  for (p in pred_names) {
    out[[p]] <- ensure_numeric(data[[p]], quiet = TRUE)
  }
  usable <- vapply(pred_names, function(p) any(!is.na(out[[p]])), logical(1))
  out <- out[, c(target_name, pred_names[usable]), drop = FALSE]
  if (na_rm) {
    out <- out[stats::complete.cases(out), , drop = FALSE]
  }
  tibble::as_tibble(out)
}

#' Build a numeric matrix for clustering or PCA
#'
#' Selects numeric columns into a matrix, optionally standardised and with row
#' names taken from an id column -- the input shape [cluster()] and
#' [reduce_dims()] expect.
#'
#' @param data A data frame. If omitted, the session default is used.
#' @param cols Columns to include, using tidyselect. If `NULL` (default), all
#'   numeric columns are used.
#' @param scale Standardise each column to mean 0 / sd 1. Default `TRUE` -- so
#'   variables on different scales (e.g. spend vs counts) contribute equally.
#' @param id Optional column to use as row names (unquoted).
#'
#' @return A numeric matrix.
#'
#' @details
#' Standardising matters: without it, a high-variance variable (like spend)
#' dominates the distances. Non-numeric columns among `cols` are dropped. Keep an
#' id via `id` so you can trace rows back after clustering.
#'
#' @family prep
#' @seealso [cluster()], [reduce_dims()].
#' @examples
#' m <- to_matrix(ecommerce, c(recency_days, frequency, monetary),
#'                id = customer_id)
#' dim(m)
#' #> [1] 800   3
#' @export
to_matrix <- function(data = NULL, cols = NULL, scale = TRUE, id = NULL) {
  data <- resolve_data(data)
  id_q <- rlang::enquo(id)
  rn <- NULL
  if (!rlang::quo_is_null(id_q)) {
    rn <- as.character(data[[rlang::as_name(rlang::ensym(id))]])
  }
  cols_q <- rlang::enquo(cols)
  if (rlang::quo_is_null(cols_q)) {
    num <- names(data)[vapply(data, is.numeric, logical(1))]
  } else {
    sel <- names(dplyr::select(data, {{ cols }}))
    num <- sel[vapply(data[sel], is.numeric, logical(1))]
  }
  if (length(num) == 0L) {
    stop("No numeric columns to put in the matrix.", call. = FALSE)
  }
  m <- as.matrix(data[, num, drop = FALSE])
  if (scale) {
    m <- scale(m)
    attr(m, "scaled:center") <- NULL
    attr(m, "scaled:scale") <- NULL
  }
  if (!is.null(rn)) rownames(m) <- rn
  m
}

#' Build a presence/absence matrix from a delimited column
#'
#' Turns a "check-all" / tags / resources column -- one row per record, several
#' comma-separated items per cell -- into a wide 0/1 table (one column per item),
#' the natural input for clustering items or records by co-occurrence.
#'
#' @param data A data frame. If omitted, the session default is used.
#' @param id The record id column (unquoted).
#' @param items The delimited column (unquoted).
#' @param delim Item separator. Default `","`.
#' @param min_count Optional minimum overall frequency: items appearing fewer
#'   than `min_count` times are dropped (useful to trim a long tail). Default
#'   `NULL` (keep all).
#'
#' @return A [tibble][tibble::tibble] with the id column plus one 0/1 column per
#'   item.
#'
#' @details
#' Items are split on `delim`, trimmed, counted, optionally frequency-filtered,
#' then pivoted wide with absent items filled `0`. Pass the result to
#' [to_matrix()] (with `scale = FALSE`) and then [cluster()] with a binary /
#' Jaccard distance to group records by what they share.
#'
#' @family prep
#' @seealso [to_matrix()], [cluster()].
#' @examples
#' df <- tibble::tibble(id = c("a", "b", "c"),
#'                      tags = c("x,y", "y,z", "x,z,w"))
#' presence_matrix(df, id, tags)
#' #> # A tibble: 3 x 5  (id, x, y, z, w as 0/1)
#' @export
presence_matrix <- function(data = NULL, id, items, delim = ",",
                            min_count = NULL) {
  data <- resolve_data(data)
  id_name <- rlang::as_name(rlang::ensym(id))
  items_name <- rlang::as_name(rlang::ensym(items))

  long <- data %>%
    dplyr::select(dplyr::all_of(c(id_name, items_name))) %>%
    dplyr::filter(!is.na(.data[[items_name]]), .data[[items_name]] != "") %>%
    tidyr::separate_longer_delim(dplyr::all_of(items_name), delim = delim) %>%
    dplyr::mutate(!!items_name := stringr::str_trim(.data[[items_name]])) %>%
    dplyr::filter(.data[[items_name]] != "") %>%
    dplyr::add_count(.data[[items_name]], name = ".item_n")

  if (!is.null(min_count)) {
    long <- dplyr::filter(long, .data$.item_n >= min_count)
  }

  long %>%
    dplyr::distinct(.data[[id_name]], .data[[items_name]]) %>%
    dplyr::mutate(.present = 1L) %>%
    tidyr::pivot_wider(names_from = dplyr::all_of(items_name),
                       values_from = ".present", values_fill = 0L) %>%
    tibble::as_tibble()
}
