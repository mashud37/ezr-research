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
#' Because `data` is the first argument of the helpers and R evaluates it before
#' the function runs, a *bare* positional call like `drivers(nps)` cannot fall
#' back to the default -- R would try to treat `nps` as the data. So, with a
#' default set, call the helpers in one of these equivalent ways:
#'
#' * pipe the data in once: `nps_drivers %>% drivers(nps)`;
#' * name the argument: `drivers(target = nps)`;
#' * or just keep passing `data` explicitly.
#'
#' The default applies to the analysis helpers that read a raw dataset
#' (`drivers()`, `cluster()`, `correlations()`, `model_lm()`, `reduce_dims()`,
#' `test_groups()`, ...). It does **not** apply to helpers that consume an
#' already-computed result object. The setting lives only in the current R
#' session; clear it with [clear_dataset()].
#'
#' @family config
#' @seealso [get_dataset()], [clear_dataset()], [has_dataset()].
#' @examples
#' use_dataset(nps_drivers)
#' correlations(target = nps)            # data taken from the default
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
#' use_dataset(nps_drivers)
#' has_dataset()
#' #> [1] TRUE
#'
#' nrow(get_dataset())
#' #> [1] 600
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
