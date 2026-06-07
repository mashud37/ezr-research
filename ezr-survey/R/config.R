# Built-in defaults. getOption("ezrsurvey.<name>") overrides any of these, and a
# YAML profile (see load_ezrsurvey_profile()) sets those options at load time.
ezrsurvey_defaults <- function() {
  list(
    pct_axis_unit = 25,        # rounding step for percentage y-axes
    pct_axis_max = NULL,       # fixed y-axis max (NULL = dynamic via nice_max)
    age_breaks = c(0, 18, 22, 26, 30, 35, Inf),
    age_labels = c("17 or younger", "18 to 21", "22 to 25",
                   "26 to 29", "30 to 34", "35+"),
    na_answers = "Prefer not to answer",
    generation_scheme = "pew",
    current_year = NULL,       # NULL = the system year
    default_by = NULL          # default grouping column(s) for calc_percentage
  )
}

# Internal getter: option override first, then the built-in default.
ezrsurvey_default <- function(name) {
  opt <- getOption(paste0("ezrsurvey.", name), default = NULL)
  if (!is.null(opt)) {
    return(opt)
  }
  d <- ezrsurvey_defaults()
  if (!name %in% names(d)) {
    stop("Unknown ezrsurvey option '", name, "'.", call. = FALSE)
  }
  d[[name]]
}

#' Get or set ezrsurvey defaults
#'
#' ezrsurvey reads a handful of defaults from R options (prefixed `ezrsurvey.`),
#' so you can tune behaviour once instead of repeating arguments. Call with no
#' arguments to see the current effective values; call with `name = value` pairs
#' to set them for the session. Persist them across sessions with a YAML profile
#' (see [use_ezrsurvey_profile()]).
#'
#' Recognised options:
#' \describe{
#'   \item{`pct_axis_unit`}{Rounding step for percentage y-axes (default `25`).}
#'   \item{`pct_axis_max`}{Fixed percentage y-axis maximum, e.g. `100`; `NULL`
#'     (default) means dynamic via [nice_max()].}
#'   \item{`age_breaks`, `age_labels`}{Default bands used by [recode_age()].}
#'   \item{`na_answers`}{Strings treated as non-answers by [na_blank()].}
#'   \item{`generation_scheme`}{Default scheme for [recode_generation()].}
#'   \item{`current_year`}{Reference year for age-to-cohort conversion; `NULL`
#'     uses the system year.}
#'   \item{`default_by`}{Default grouping column name(s) applied by
#'     [calc_percentage()] / [calc_percentage_multi()] when `by` is omitted;
#'     `NULL` (default) means no default grouping.}
#' }
#'
#' @param ... Either nothing (to read all values) or named `option = value`
#'   pairs to set.
#'
#' @return When reading, a named list of all current values. When setting, the
#'   previous values, invisibly.
#'
#' @details
#' Options are ordinary R options under the `ezrsurvey.` prefix, so anything you
#' can do with [options()] works here too, and a setting lasts for the session.
#' Reading (`ezrsurvey_options()` with no arguments) returns every recognised
#' option's current effective value; setting returns the previous values
#' invisibly, so you can restore them. To make settings permanent, write them to
#' a YAML profile -- edit it with [edit_ezrsurvey_profile()] or dump the current
#' session with [save_ezrsurvey_profile()] -- which is loaded automatically at
#' package start-up.
#'
#' @family config
#' @seealso [use_ezrsurvey_profile()], [load_ezrsurvey_profile()],
#'   [reset_ezrsurvey_options()].
#' @examples
#' ezrsurvey_options()                       # view all defaults
#' ezrsurvey_options(pct_axis_max = 100)
#' ezrsurvey_options()$pct_axis_max          # 100
#' reset_ezrsurvey_options()                 # back to defaults
#' @export
ezrsurvey_options <- function(...) {
  args <- list(...)
  if (length(args) == 0L) {
    nm <- names(ezrsurvey_defaults())
    return(stats::setNames(lapply(nm, ezrsurvey_default), nm))
  }
  if (is.null(names(args)) || any(!nzchar(names(args)))) {
    stop("All arguments must be named, e.g. ezrsurvey_options(pct_axis_max = 100).",
         call. = FALSE)
  }
  known <- names(ezrsurvey_defaults())
  unknown <- setdiff(names(args), known)
  if (length(unknown)) {
    warning("Unknown ezrsurvey option(s): ", paste(unknown, collapse = ", "),
            call. = FALSE)
  }
  old <- stats::setNames(
    lapply(names(args), function(n) getOption(paste0("ezrsurvey.", n))),
    names(args)
  )
  newopts <- stats::setNames(args, paste0("ezrsurvey.", names(args)))
  options(newopts)
  invisible(old)
}

#' Reset all ezrsurvey options to their built-in defaults
#'
#' @return Invisibly `TRUE`.
#' @family config
#' @seealso [ezrsurvey_options()].
#' @examples
#' ezrsurvey_options(pct_axis_max = 100)
#' reset_ezrsurvey_options()
#' ezrsurvey_options()$pct_axis_max          # NULL again
#' @export
reset_ezrsurvey_options <- function() {
  nm <- paste0("ezrsurvey.", names(ezrsurvey_defaults()))
  options(stats::setNames(vector("list", length(nm)), nm))
  invisible(TRUE)
}

#' Profile file locations ezrsurvey looks in
#'
#' At load time ezrsurvey reads a YAML profile from each of these paths in turn
#' (later paths override earlier ones), if present: the per-user config
#' directory, your home directory, then the current project.
#'
#' @return A character vector of candidate profile paths.
#' @family config
#' @seealso [use_ezrsurvey_profile()], [load_ezrsurvey_profile()].
#' @examples
#' ezrsurvey_profile_paths()
#' @export
ezrsurvey_profile_paths <- function() {
  c(
    file.path(tools::R_user_dir("ezrsurvey", "config"), "ezrsurvey.yml"),
    path.expand("~/.ezrsurvey.yml"),
    file.path(getwd(), ".ezrsurvey.yml")
  )
}

#' Load ezrsurvey defaults from a YAML profile
#'
#' Reads a YAML file of `option: value` pairs and applies them with
#' [ezrsurvey_options()]. Called automatically when the package loads (over the
#' standard [ezrsurvey_profile_paths()]); call it manually to load a specific
#' file. Requires the suggested `yaml` package; without it, the function is a
#' no-op.
#'
#' @param path Profile path(s). If `NULL` (default), the standard locations are
#'   tried in order (later files override earlier ones).
#' @param quiet If `TRUE` (default), load silently; if `FALSE`, message which
#'   file(s) were loaded.
#'
#' @return Invisibly `TRUE` if any profile was applied, else `FALSE`.
#' @family config
#' @seealso [use_ezrsurvey_profile()] to create a template.
#' @examples
#' \dontrun{
#' load_ezrsurvey_profile("~/.ezrsurvey.yml", quiet = FALSE)
#' }
#' @export
load_ezrsurvey_profile <- function(path = NULL, quiet = TRUE) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    if (!quiet) message("Install the 'yaml' package to use ezrsurvey profiles.")
    return(invisible(FALSE))
  }
  paths <- if (is.null(path)) ezrsurvey_profile_paths() else path
  loaded <- FALSE
  for (p in paths) {
    if (file.exists(p)) {
      cfg <- tryCatch(yaml::read_yaml(p), error = function(e) NULL)
      if (!is.null(cfg) && length(cfg)) {
        # An `orders:` section registers reusable level orders; everything else
        # is treated as an option.
        if (!is.null(cfg$orders)) {
          apply_orders_config(cfg$orders)
          cfg$orders <- NULL
        }
        if (length(cfg)) do.call(ezrsurvey_options, cfg)
        loaded <- TRUE
        if (!quiet) message("Loaded ezrsurvey profile: ", p)
      }
    }
  }
  invisible(loaded)
}

#' Create a starter ezrsurvey profile
#'
#' Writes a commented YAML profile (pre-filled with the current defaults) you can
#' edit to set persistent options. By default it is written to the per-user
#' config directory ([tools::R_user_dir()]), which is where ezrsurvey looks first.
#'
#' @param path Destination path. If `NULL` (default), the per-user config file
#'   `ezrsurvey.yml` is used.
#' @param overwrite Overwrite an existing file. Defaults to `FALSE`.
#'
#' @return Invisibly the path written.
#' @family config
#' @seealso [load_ezrsurvey_profile()], [ezrsurvey_options()].
#' @examples
#' \dontrun{
#' use_ezrsurvey_profile()                    # ~/.../R/ezrsurvey/config/ezrsurvey.yml
#' use_ezrsurvey_profile("~/.ezrsurvey.yml")
#' }
#' @export
use_ezrsurvey_profile <- function(path = NULL, overwrite = FALSE) {
  if (is.null(path)) {
    dir <- tools::R_user_dir("ezrsurvey", "config")
    if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
    path <- file.path(dir, "ezrsurvey.yml")
  } else {
    path <- path.expand(path)
  }
  if (file.exists(path) && !overwrite) {
    stop("'", path, "' already exists. Use overwrite = TRUE to replace it.",
         call. = FALSE)
  }
  lines <- c(
    "# ezrsurvey profile -- set persistent defaults here.",
    "# Edit values and uncomment the lines you want to change.",
    "",
    "# pct_axis_unit: 25       # rounding step for percentage y-axes",
    "# pct_axis_max: 100       # fix every percentage y-axis at 100",
    "# generation_scheme: pew  # cohort scheme for recode_generation()",
    "# current_year: 2026      # reference year for age -> cohort",
    "# na_answers:",
    "#   - Prefer not to answer",
    "#   - Don't know",
    "",
    "# Reusable level orders, linked to variable names and/or prefixes.",
    "# orders:",
    "#   education:",
    "#     levels:",
    "#       - Less than high school",
    "#       - High school or equivalent",
    "#       - Bachelor degree",
    "#       - Masters degree or higher",
    "#     vars: [demo_edu]",
    "#   likert_bad_good:",
    "#     levels: [Very bad, Bad, Ok, Good, Very good]",
    "#     prefixes: [ratings_]"
  )
  writeLines(lines, path)
  message("Wrote ezrsurvey profile template to ", path)
  invisible(path)
}

#' Open the ezrsurvey profile for editing
#'
#' Opens your ezrsurvey YAML profile in the editor (like
#' [usethis::edit_r_profile()] for `.Rprofile`), creating it from a template
#' first if it does not exist. After saving, reload it with
#' [load_ezrsurvey_profile()] or by restarting the session.
#'
#' @param path Profile path. If `NULL` (default), the first existing profile
#'   among [ezrsurvey_profile_paths()] is used, or the per-user config file is
#'   created.
#'
#' @return Invisibly the path opened.
#' @family config
#' @seealso [use_ezrsurvey_profile()], [save_ezrsurvey_profile()],
#'   [load_ezrsurvey_profile()].
#' @examples
#' \dontrun{
#' edit_ezrsurvey_profile()
#' }
#' @export
edit_ezrsurvey_profile <- function(path = NULL) {
  if (is.null(path)) {
    existing <- ezrsurvey_profile_paths()
    existing <- existing[file.exists(existing)]
    path <- if (length(existing)) existing[[1]] else use_ezrsurvey_profile()
  } else {
    path <- path.expand(path)
    if (!file.exists(path)) use_ezrsurvey_profile(path)
  }
  if (interactive()) {
    utils::file.edit(path)
  } else {
    message("ezrsurvey profile is at: ", path)
  }
  invisible(path)
}

#' Save current options and orders to a profile
#'
#' Writes your current non-default [ezrsurvey_options()] and all registered
#' orders (see [register_order()]) to a YAML profile, so they persist across
#' sessions. Requires the suggested `yaml` package.
#'
#' @param path Destination path. If `NULL` (default), the per-user config file
#'   is used.
#' @param include_options Write changed options. Default `TRUE`.
#' @param include_orders Write registered orders. Default `TRUE`.
#'
#' @return Invisibly the path written.
#' @family config
#' @seealso [load_ezrsurvey_profile()], [edit_ezrsurvey_profile()],
#'   [register_order()].
#' @examples
#' \dontrun{
#' register_order("education", c("low", "mid", "high"), vars = "demo_edu")
#' ezrsurvey_options(pct_axis_max = 100)
#' save_ezrsurvey_profile()
#' }
#' @export
save_ezrsurvey_profile <- function(path = NULL, include_options = TRUE,
                                  include_orders = TRUE) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Saving a profile needs the 'yaml' package. ",
         "Install it with install.packages('yaml').", call. = FALSE)
  }
  if (is.null(path)) {
    dir <- tools::R_user_dir("ezrsurvey", "config")
    if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
    path <- file.path(dir, "ezrsurvey.yml")
  } else {
    path <- path.expand(path)
  }

  cfg <- list()
  if (include_options) {
    defs <- ezrsurvey_defaults()
    for (nm in names(defs)) {
      cur <- ezrsurvey_default(nm)
      if (!identical(cur, defs[[nm]])) cfg[[nm]] <- cur
    }
  }
  if (include_orders) {
    orders <- orders_to_list()
    if (length(orders)) cfg$orders <- orders
  }

  yaml::write_yaml(cfg, path)
  message("Saved ezrsurvey profile to ", path)
  invisible(path)
}
