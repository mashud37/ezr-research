# Registry of named ordinal level orders, each optionally linked to variable
# names and/or column-name prefixes. Functions look up an applicable order by
# the column they are about to plot/tabulate and apply it automatically.
.order_registry <- new.env(parent = emptyenv())

#' Register a reusable ordinal level order
#'
#' Survey scales (education, Likert, frequency, ...) have a natural order that is
#' tedious to retype as `levels = c(...)` every time. Register an order once,
#' link it to the variable names and/or column prefixes it applies to, and the
#' tabulating helpers (e.g. [calc_percentage()]) will look it up and apply it
#' automatically. Persist your orders in a profile with [save_ezrsurvey_profile()].
#'
#' @param name Short name for the order (e.g. `"education"`).
#' @param levels Character vector of the levels in ascending order.
#' @param vars Optional exact column names this order applies to (e.g.
#'   `"demo_edu"`).
#' @param prefixes Optional column-name prefixes this order applies to (e.g.
#'   `"edu_"`). A variable matches if its name starts with any prefix.
#' @param overwrite Overwrite an existing order of the same name. Default `TRUE`.
#'
#' @return Invisibly the order `name`.
#'
#' @details
#' An order links a set of `levels` to the columns it applies to, by exact name
#' (`vars`) and/or by prefix (`prefixes`). Once registered, [calc_percentage()],
#' [calc_percentage_multi()] and [crosstab()] look it up automatically (via
#' [order_for()]) whenever you don't pass an explicit `levels`/`sort`, so a
#' question always comes out in the right order without retyping it. Register
#' interactively for the session, or store orders in a profile with
#' [save_ezrsurvey_profile()] so they load every session.
#'
#' @family config
#' @seealso [order_for()], [apply_order()], [list_orders()],
#'   [register_order_presets()].
#' @examples
#' register_order(
#'   "education",
#'   levels = c("Less than high school", "High school or equivalent",
#'              "Some college but no degree", "Associate degree",
#'              "Bachelor degree", "Masters degree or higher"),
#'   vars = "demo_edu"
#' )
#' calc_percentage(consumer_survey, demo_edu)   # rows now in education order
#' remove_order("education")
#' @export
register_order <- function(name, levels, vars = NULL, prefixes = NULL,
                           overwrite = TRUE) {
  if (!overwrite && exists(name, envir = .order_registry, inherits = FALSE)) {
    stop("Order '", name, "' already exists; set overwrite = TRUE.",
         call. = FALSE)
  }
  assign(name,
         list(levels = as.character(levels),
              vars = vars, prefixes = prefixes),
         envir = .order_registry)
  invisible(name)
}

#' List registered orders
#'
#' @return A [tibble][tibble::tibble] with `name`, `n_levels`, `vars` and
#'   `prefixes` (the last two comma-joined).
#' @family config
#' @seealso [register_order()].
#' @examples
#' register_order("yesno", c("No", "Yes"), vars = "agree")
#' list_orders()
#' remove_order("yesno")
#' @export
list_orders <- function() {
  nms <- ls(envir = .order_registry, sorted = TRUE)
  collapse <- function(x) if (is.null(x)) NA_character_ else paste(x, collapse = ", ")
  tibble::tibble(
    name = nms,
    n_levels = vapply(nms, function(n) length(get(n, .order_registry)$levels),
                      integer(1), USE.NAMES = FALSE),
    vars = vapply(nms, function(n) collapse(get(n, .order_registry)$vars),
                  character(1), USE.NAMES = FALSE),
    prefixes = vapply(nms, function(n) collapse(get(n, .order_registry)$prefixes),
                      character(1), USE.NAMES = FALSE)
  )
}

#' Get the levels of a registered order
#'
#' @param name Order name.
#' @return The character vector of levels.
#' @family config
#' @seealso [register_order()].
#' @examples
#' register_order("yesno", c("No", "Yes"))
#' get_order("yesno")
#' remove_order("yesno")
#' @export
get_order <- function(name) {
  if (!exists(name, envir = .order_registry, inherits = FALSE)) {
    stop("Unknown order '", name, "'. See list_orders().", call. = FALSE)
  }
  get(name, envir = .order_registry, inherits = FALSE)$levels
}

#' Remove a registered order
#'
#' @param name Order name.
#' @return Invisibly `TRUE`.
#' @family config
#' @seealso [register_order()].
#' @examples
#' register_order("yesno", c("No", "Yes"))
#' remove_order("yesno")
#' @export
remove_order <- function(name) {
  if (exists(name, envir = .order_registry, inherits = FALSE)) {
    rm(list = name, envir = .order_registry)
  }
  invisible(TRUE)
}

#' Find the order that applies to a variable
#'
#' Looks up the registered order for a column: an exact `vars` match wins,
#' otherwise the first matching `prefixes` entry. Used internally by
#' [calc_percentage()] to apply orders automatically; exposed so you can check
#' what would be applied.
#'
#' @param var A column name.
#' @return The matching level vector, or `NULL` if none is registered.
#' @family config
#' @seealso [register_order()], [apply_order()].
#' @examples
#' register_order("edu", c("low", "mid", "high"), prefixes = "edu_")
#' order_for("edu_level")
#' remove_order("edu")
#' @export
order_for <- function(var) {
  if (is.null(var) || length(var) != 1L || is.na(var) || !nzchar(var)) {
    return(NULL)
  }
  nms <- ls(envir = .order_registry)
  # Exact variable match takes precedence.
  for (n in nms) {
    o <- get(n, .order_registry)
    if (!is.null(o$vars) && var %in% o$vars) {
      return(o$levels)
    }
  }
  # Then prefix match.
  for (n in nms) {
    o <- get(n, .order_registry)
    if (!is.null(o$prefixes)) {
      for (pfx in o$prefixes) {
        if (startsWith(var, pfx)) return(o$levels)
      }
    }
  }
  NULL
}

#' Apply a registered order to a vector
#'
#' Turns a vector into an ordered factor using a registered order, selected
#' either by order `name` or by looking up the order linked to a variable name.
#'
#' @param x A vector.
#' @param name Order name (see [register_order()]). Takes precedence over `var`.
#' @param var A variable name to look up via [order_for()].
#'
#' @return A factor with the registered levels, or `x` unchanged if no order is
#'   found.
#' @family config
#' @seealso [register_order()], [order_for()].
#' @examples
#' register_order("size", c("S", "M", "L"))
#' apply_order(c("L", "S", "M"), name = "size")
#' remove_order("size")
#' @export
apply_order <- function(x, name = NULL, var = NULL) {
  levels <- if (!is.null(name)) get_order(name) else order_for(var)
  if (is.null(levels)) {
    return(x)
  }
  factor(as.character(x), levels = levels)
}

#' Register a set of common ordinal scales
#'
#' A convenience that registers a handful of frequently used orders, linked to
#' sensible default variable names/prefixes, so common surveys work out of the
#' box. Override any of them afterwards with [register_order()].
#'
#' Registers: `likert_bad_good`, `likert_agree`, `frequency`, `likelihood` and
#' `education_us`.
#'
#' @return Invisibly the names registered.
#' @family config
#' @seealso [register_order()].
#' @examples
#' register_order_presets()
#' list_orders()
#' @export
register_order_presets <- function() {
  register_order("likert_bad_good",
                 c("Very bad", "Bad", "Ok", "Good", "Very good"),
                 prefixes = "ratings_")
  register_order("likert_agree",
                 c("Strongly disagree", "Disagree", "Neither agree nor disagree",
                   "Agree", "Strongly agree"))
  register_order("frequency",
                 c("Never", "Rarely", "Sometimes", "Often", "Always"))
  register_order("likelihood",
                 c("Very unlikely", "Unlikely", "Not sure", "Likely",
                   "Very likely"),
                 vars = "satis_return")
  register_order("education_us",
                 c("Less than high school", "High school or equivalent",
                   "Some college but no degree", "Associate degree",
                   "Bachelor degree", "Masters degree or higher"),
                 vars = c("demo_edu", "education"), prefixes = "edu_")
  invisible(c("likert_bad_good", "likert_agree", "frequency",
              "likelihood", "education_us"))
}

# Internal: register orders supplied as a config list (from a YAML profile).
apply_orders_config <- function(orders) {
  if (is.null(orders)) return(invisible(FALSE))
  for (nm in names(orders)) {
    o <- orders[[nm]]
    register_order(nm, levels = o$levels, vars = o$vars, prefixes = o$prefixes)
  }
  invisible(TRUE)
}

# Internal: dump the registry to a plain list for YAML serialisation.
orders_to_list <- function() {
  nms <- ls(envir = .order_registry, sorted = TRUE)
  out <- lapply(nms, function(n) {
    o <- get(n, .order_registry)
    spec <- list(levels = o$levels)
    if (!is.null(o$vars)) spec$vars <- o$vars
    if (!is.null(o$prefixes)) spec$prefixes <- o$prefixes
    spec
  })
  stats::setNames(out, nms)
}
