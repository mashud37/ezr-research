# Built-in defaults. getOption("ezrlearning.<name>") overrides any of these.
ezrlearning_defaults <- function() {
  list(
    difficulty = "easy",   # default exercise difficulty: easy | medium | hard
    seed = NULL,           # default seed for draws (NULL = random each call)
    provider = "openai",   # default LLM provider for generate_exercise()
    model = NULL           # default LLM model (NULL = provider default)
  )
}

# Internal getter: option override first, then the built-in default.
ezrlearning_default <- function(name) {
  opt <- getOption(paste0("ezrlearning.", name), default = NULL)
  if (!is.null(opt)) return(opt)
  d <- ezrlearning_defaults()
  if (!name %in% names(d)) {
    stop("Unknown ezrlearning option '", name, "'.", call. = FALSE)
  }
  d[[name]]
}

#' Get or set ezrlearning defaults
#'
#' ezrlearning reads a few defaults from R options (prefixed `ezrlearning.`) so
#' you can tune behaviour once instead of repeating arguments. Call with no
#' arguments to see the current effective values; call with `name = value` pairs
#' to set them for the session.
#'
#' Recognised options:
#' \describe{
#'   \item{`difficulty`}{Default difficulty for [draw_exercise()] / [quiz()]:
#'     `"easy"`, `"medium"` or `"hard"`.}
#'   \item{`seed`}{Default seed for draws; `NULL` means a fresh random draw each
#'     call.}
#'   \item{`provider`}{Default LLM provider for [generate_exercise()].}
#'   \item{`model`}{Default LLM model (`NULL` = the provider's default).}
#' }
#'
#' @param ... Either nothing (to read all values) or named `option = value`
#'   pairs to set.
#'
#' @return When reading, a named list of all current values. When setting, the
#'   previous values, invisibly.
#'
#' @details
#' Options let you set a house style once -- e.g. a default `difficulty` for a
#' cohort, or a `provider` for the AI helpers -- without threading the argument
#' through every call. Setting returns the previous values invisibly, so you can
#' restore them later. Use [reset_ezrlearning_options()] to clear everything back
#' to the built-in defaults.
#'
#' @family config
#' @seealso [reset_ezrlearning_options()].
#' @examples
#' ezrlearning_options()                 # view all defaults
#' ezrlearning_options(difficulty = "medium")
#' ezrlearning_options()$difficulty      # "medium"
#' reset_ezrlearning_options()
#' @export
ezrlearning_options <- function(...) {
  args <- list(...)
  if (length(args) == 0L) {
    nm <- names(ezrlearning_defaults())
    return(stats::setNames(lapply(nm, ezrlearning_default), nm))
  }
  if (is.null(names(args)) || any(!nzchar(names(args)))) {
    stop("All arguments must be named, e.g. ezrlearning_options(seed = 42).",
         call. = FALSE)
  }
  known <- names(ezrlearning_defaults())
  unknown <- setdiff(names(args), known)
  if (length(unknown)) {
    warning("Unknown ezrlearning option(s): ", paste(unknown, collapse = ", "),
            call. = FALSE)
  }
  old <- stats::setNames(
    lapply(names(args), function(n) getOption(paste0("ezrlearning.", n))),
    names(args)
  )
  options(stats::setNames(args, paste0("ezrlearning.", names(args))))
  invisible(old)
}

#' Reset all ezrlearning options to their built-in defaults
#'
#' @return Invisibly `TRUE`.
#' @family config
#' @seealso [ezrlearning_options()].
#' @examples
#' ezrlearning_options(difficulty = "hard")
#' reset_ezrlearning_options()
#' ezrlearning_options()$difficulty      # "easy" again
#' @export
reset_ezrlearning_options <- function() {
  nm <- paste0("ezrlearning.", names(ezrlearning_defaults()))
  options(stats::setNames(vector("list", length(nm)), nm))
  invisible(TRUE)
}
