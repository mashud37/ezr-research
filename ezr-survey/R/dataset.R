# Internal: resolve the `data` argument -- an explicit data frame wins; NULL
# falls back to the active dataset; anything else is an error.
resolve_data <- function(data) {
  if (is.null(data)) {
    if (!has_dataset()) {
      stop("No `data` supplied and no default dataset set. Pass `data`, pipe ",
           "it in, or call use_dataset() at the top of your script.",
           call. = FALSE)
    }
    return(get_dataset())
  }
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  data
}

# Internal: the bare name a captured column quosure refers to (a symbol like
# `demo_gender` or a string like "motivations_"). Anything else is a mistake
# worth naming: an expression here usually means a vector was passed where a
# column of the data was meant.
col_label <- function(q) {
  expr <- rlang::quo_get_expr(q)
  if (!rlang::is_symbol(expr) && !is.character(expr)) {
    stop("Expected a column name, got `", rlang::as_label(expr), "`. ",
         "Pass an unquoted column of the data (and the data frame itself, or ",
         "set one with use_dataset()).", call. = FALSE)
  }
  rlang::as_name(expr)
}

# Internal: resolve the leading (data, columns...) so the column(s) may be
# passed positionally without `data` when a session default is set (see
# use_dataset()). `cols` is a list of the leading column quosures in order;
# `shift` is TRUE when the last of them was omitted at the call site -- the
# signal that the first positional argument is really a column, not the data.
# Returns list(data = <df>, cols = <list of quosures>).
resolve_data_columns <- function(data_q, cols, shift) {
  if (rlang::quo_is_null(data_q)) {
    return(list(data = resolve_data(NULL), cols = cols))
  }
  err <- NULL
  val <- tryCatch(rlang::eval_tidy(data_q),
                  error = function(e) {
                    err <<- e
                    NULL
                  })
  if (is.null(err) && is.data.frame(val)) {
    return(list(data = val, cols = cols))
  }
  if (shift) {
    if (!has_dataset()) {
      stop("No `data` supplied and no default dataset set. Pass `data`, pipe ",
           "it in, or call use_dataset() first.", call. = FALSE)
    }
    return(list(data = get_dataset(),
                cols = c(list(data_q), cols[-length(cols)])))
  }
  if (!is.null(err)) stop(err)
  list(data = resolve_data(val), cols = cols)
}

# Internal: the `...`-selection counterpart of resolve_data_columns(), for the
# helpers whose columns arrive through tidyselect `...`. When the first
# positional argument is not a data frame and a default is set, it is spliced
# back to the front of the selection.
resolve_data_dots <- function(data_q, dots) {
  if (rlang::quo_is_null(data_q)) {
    return(list(data = resolve_data(NULL), dots = dots))
  }
  err <- NULL
  val <- tryCatch(rlang::eval_tidy(data_q),
                  error = function(e) {
                    err <<- e
                    NULL
                  })
  if (is.null(err) && is.data.frame(val)) {
    return(list(data = val, dots = dots))
  }
  if (has_dataset()) {
    return(list(data = get_dataset(), dots = c(list(data_q), dots)))
  }
  if (!is.null(err)) stop(err)
  list(data = resolve_data(val), dots = dots)
}

#' Set a default dataset for the session
#'
#' Registers a data frame as the session's default, so the analysis helpers can
#' be called without repeating `data` every time. Set it once at the top of a
#' script or Quarto document and then omit `data` (or pass it by pipe).
#'
#' @param data A data frame to use as the default.
#'
#' @return `data`, invisibly (so it can sit in a pipe).
#'
#' @details
#' With a default set you can drop `data` entirely and name the column
#' positionally, the way you would in the tidyverse:
#'
#' * `calc_percentage(demo_gender)` -- data taken from the default;
#' * `podracing_survey %>% calc_percentage(demo_gender)` -- explicit pipe;
#' * `calc_percentage(other_survey, demo_gender)` -- an explicit data frame
#'   always wins over the default.
#'
#' The helpers tell a column from a data frame by looking at the first argument:
#' a data frame is used as the data; anything else (a bare column name) is taken
#' as the first column and the data comes from the default. Helpers that select
#' several columns through `...` (e.g. [diagnose()], [calc_percentage_batch()])
#' work the same way -- `diagnose(starts_with("ratings_"))` needs no `data`.
#'
#' The default applies to the analysis helpers that read a raw survey
#' (`calc_percentage()`, `calc_summary()`, `calc_nps()`, `diagnose()`,
#' `crosstab()`, `ipm_model()`, `sample_comments()`, ...). It does **not** apply
#' to plot/report helpers that consume an already-summarised table. The setting
#' lives only in the current R session; clear it with [clear_dataset()].
#'
#' @family config
#' @seealso [get_dataset()], [clear_dataset()], [has_dataset()].
#' @examples
#' use_dataset(podracing_survey)
#' calc_percentage(demo_gender)   # data taken from the default
#' calc_nps(nps_value)
#' clear_dataset()
#' @export
use_dataset <- function(data) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  options("ezr.dataset" = data)
  invisible(data)
}

#' Get, check or clear the default dataset
#'
#' Companions to [use_dataset()] for inspecting and resetting the session's
#' default dataset.
#'
#' @return `get_dataset()` returns the default data frame (error if none is set);
#'   `has_dataset()` returns a logical; `clear_dataset()` returns `TRUE`
#'   invisibly; `dataset_vars()` returns a character vector of column names.
#'
#' @details
#' `has_dataset()` is the safe way to check before calling `get_dataset()`, which
#' errors when nothing is set. `clear_dataset()` removes the default so that
#' subsequent calls require an explicit `data` again -- useful at the end of a
#' script or between analyses of different datasets.
#'
#' @family config
#' @seealso [use_dataset()].
#' @examples
#' has_dataset()
#' #> [1] FALSE
#'
#' use_dataset(podracing_survey)
#' has_dataset()
#' #> [1] TRUE
#'
#' nrow(get_dataset())
#' #> [1] 1000
#'
#' clear_dataset()
#' @rdname dataset_default
#' @export
get_dataset <- function() {
  if (!has_dataset()) {
    stop("No default dataset set; call use_dataset() first.", call. = FALSE)
  }
  getOption("ezr.dataset")
}

#' @rdname dataset_default
#' @export
has_dataset <- function() {
  !is.null(getOption("ezr.dataset"))
}

#' @rdname dataset_default
#' @export
clear_dataset <- function() {
  options("ezr.dataset" = NULL)
  invisible(TRUE)
}

#' @rdname dataset_default
#' @export
dataset_vars <- function() {
  if (!has_dataset()) {
    stop("No default dataset set; call use_dataset() first.", call. = FALSE)
  }
  names(get_dataset())
}
