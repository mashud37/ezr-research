# Built-in defaults. getOption("ezrmodel.<name>") overrides any of these, and a
# YAML profile (see load_ezrmodel_profile()) sets those options at load time.
ezrmodel_defaults <- function() {
  list(
    na_answers = "Prefer not to answer",  # strings treated as missing
    default_by = NULL,                     # default grouping column(s)
    seed = NULL,                           # seed for stochastic methods
    scale = TRUE                           # default scaling for cluster/PCA
  )
}

# Internal getter: option override first, then the built-in default.
ezrmodel_default <- function(name) {
  opt <- getOption(paste0("ezrmodel.", name), default = NULL)
  if (!is.null(opt)) {
    return(opt)
  }
  d <- ezrmodel_defaults()
  if (!name %in% names(d)) {
    stop("Unknown ezrmodel option '", name, "'.", call. = FALSE)
  }
  d[[name]]
}

#' Get or set ezrmodel defaults
#'
#' ezrmodel reads a handful of defaults from R options (prefixed `ezrmodel.`), so
#' you can tune behaviour once instead of repeating arguments. Call with no
#' arguments to see the current effective values; call with `name = value` pairs
#' to set them for the session. Persist them across sessions with a YAML profile
#' (see [use_ezrmodel_profile()]).
#'
#' Recognised options:
#' \describe{
#'   \item{`na_answers`}{Strings treated as non-answers by [na_blank()].}
#'   \item{`default_by`}{Default grouping column name(s) for grouped helpers.}
#'   \item{`seed`}{Seed applied by stochastic methods (kmeans, random forest)
#'     when set, for reproducibility.}
#'   \item{`scale`}{Whether [cluster()] / [reduce_dims()] standardise variables
#'     by default.}
#' }
#'
#' @param ... Either nothing (to read all values) or named `option = value`
#'   pairs to set.
#'
#' @return When reading, a named list of all current values. When setting, the
#'   previous values, invisibly.
#' @family config
#' @seealso [use_ezrmodel_profile()], [reset_ezrmodel_options()].
#' @examples
#' ezrmodel_options()                  # view all defaults
#' ezrmodel_options(seed = 42)
#' ezrmodel_options()$seed             # 42
#' reset_ezrmodel_options()            # back to defaults
#' @export
ezrmodel_options <- function(...) {
  args <- list(...)
  if (length(args) == 0L) {
    nm <- names(ezrmodel_defaults())
    return(stats::setNames(lapply(nm, ezrmodel_default), nm))
  }
  if (is.null(names(args)) || any(!nzchar(names(args)))) {
    stop("All arguments must be named, e.g. ezrmodel_options(seed = 42).",
         call. = FALSE)
  }
  known <- names(ezrmodel_defaults())
  unknown <- setdiff(names(args), known)
  if (length(unknown)) {
    warning("Unknown ezrmodel option(s): ", paste(unknown, collapse = ", "),
            call. = FALSE)
  }
  old <- stats::setNames(
    lapply(names(args), function(n) getOption(paste0("ezrmodel.", n))),
    names(args)
  )
  options(stats::setNames(args, paste0("ezrmodel.", names(args))))
  invisible(old)
}

#' Reset all ezrmodel options to their built-in defaults
#'
#' @return Invisibly `TRUE`.
#' @family config
#' @seealso [ezrmodel_options()].
#' @examples
#' ezrmodel_options(seed = 42)
#' reset_ezrmodel_options()
#' ezrmodel_options()$seed             # NULL again
#' @export
reset_ezrmodel_options <- function() {
  nm <- paste0("ezrmodel.", names(ezrmodel_defaults()))
  options(stats::setNames(vector("list", length(nm)), nm))
  invisible(TRUE)
}

#' Profile file locations ezrmodel looks in
#'
#' At load time ezrmodel reads a YAML profile from each of these paths in turn
#' (later paths override earlier ones), if present: the per-user config
#' directory, your home directory, then the current project.
#'
#' @return A character vector of candidate profile paths.
#' @family config
#' @seealso [use_ezrmodel_profile()], [load_ezrmodel_profile()].
#' @examples
#' ezrmodel_profile_paths()
#' @export
ezrmodel_profile_paths <- function() {
  c(
    file.path(tools::R_user_dir("ezrmodel", "config"), "ezrmodel.yml"),
    path.expand("~/.ezrmodel.yml"),
    file.path(getwd(), ".ezrmodel.yml")
  )
}

#' Load ezrmodel defaults from a YAML profile
#'
#' Reads a YAML file of `option: value` pairs and applies them with
#' [ezrmodel_options()]. Called automatically when the package loads (over the
#' standard [ezrmodel_profile_paths()]); call it manually to load a specific file.
#' Requires the suggested `yaml` package; without it, the function is a no-op.
#'
#' @param path Profile path(s). If `NULL` (default), the standard locations are
#'   tried in order (later files override earlier ones).
#' @param quiet If `TRUE` (default), load silently; if `FALSE`, message which
#'   file(s) were loaded.
#'
#' @return Invisibly `TRUE` if any profile was applied, else `FALSE`.
#' @family config
#' @seealso [use_ezrmodel_profile()] to create a template.
#' @examples
#' \dontrun{
#' load_ezrmodel_profile("~/.ezrmodel.yml", quiet = FALSE)
#' }
#' @export
load_ezrmodel_profile <- function(path = NULL, quiet = TRUE) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    if (!quiet) message("Install the 'yaml' package to use ezrmodel profiles.")
    return(invisible(FALSE))
  }
  paths <- if (is.null(path)) ezrmodel_profile_paths() else path
  loaded <- FALSE
  for (p in paths) {
    if (file.exists(p)) {
      cfg <- tryCatch(yaml::read_yaml(p), error = function(e) NULL)
      if (!is.null(cfg) && length(cfg)) {
        do.call(ezrmodel_options, cfg)
        loaded <- TRUE
        if (!quiet) message("Loaded ezrmodel profile: ", p)
      }
    }
  }
  invisible(loaded)
}

#' Create a starter ezrmodel profile
#'
#' Writes a commented YAML profile you can edit to set persistent options. By
#' default it is written to the per-user config directory
#' ([tools::R_user_dir()]), which is where ezrmodel looks first.
#'
#' @param path Destination path. If `NULL` (default), the per-user config file
#'   `ezrmodel.yml` is used.
#' @param overwrite Overwrite an existing file. Defaults to `FALSE`.
#'
#' @return Invisibly the path written.
#' @family config
#' @seealso [load_ezrmodel_profile()], [ezrmodel_options()].
#' @examples
#' \dontrun{
#' use_ezrmodel_profile()
#' }
#' @export
use_ezrmodel_profile <- function(path = NULL, overwrite = FALSE) {
  if (is.null(path)) {
    dir <- tools::R_user_dir("ezrmodel", "config")
    if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
    path <- file.path(dir, "ezrmodel.yml")
  } else {
    path <- path.expand(path)
  }
  if (file.exists(path) && !overwrite) {
    stop("'", path, "' already exists. Use overwrite = TRUE to replace it.",
         call. = FALSE)
  }
  lines <- c(
    "# ezrmodel profile -- set persistent defaults here.",
    "# Edit values and uncomment the lines you want to change.",
    "",
    "# seed: 42            # reproducible kmeans / random forest",
    "# scale: true         # standardise variables in cluster() / reduce_dims()",
    "# default_by: [region]",
    "# na_answers:",
    "#   - Prefer not to answer",
    "#   - Don't know"
  )
  writeLines(lines, path)
  message("Wrote ezrmodel profile template to ", path)
  invisible(path)
}

#' Open the ezrmodel profile for editing
#'
#' Opens your ezrmodel YAML profile in the editor, creating it from a template
#' first if it does not exist.
#'
#' @param path Profile path. If `NULL` (default), the first existing profile
#'   among [ezrmodel_profile_paths()] is used, or the per-user config file is
#'   created.
#'
#' @return Invisibly the path opened.
#' @family config
#' @seealso [use_ezrmodel_profile()], [save_ezrmodel_profile()].
#' @examples
#' \dontrun{
#' edit_ezrmodel_profile()
#' }
#' @export
edit_ezrmodel_profile <- function(path = NULL) {
  if (is.null(path)) {
    existing <- ezrmodel_profile_paths()
    existing <- existing[file.exists(existing)]
    path <- if (length(existing)) existing[[1]] else use_ezrmodel_profile()
  } else {
    path <- path.expand(path)
    if (!file.exists(path)) use_ezrmodel_profile(path)
  }
  if (interactive()) {
    utils::file.edit(path)
  } else {
    message("ezrmodel profile is at: ", path)
  }
  invisible(path)
}

#' Save current options to a profile
#'
#' Writes your current non-default [ezrmodel_options()] to a YAML profile, so they
#' persist across sessions. Requires the suggested `yaml` package.
#'
#' @param path Destination path. If `NULL` (default), the per-user config file
#'   is used.
#'
#' @return Invisibly the path written.
#' @family config
#' @seealso [load_ezrmodel_profile()], [edit_ezrmodel_profile()].
#' @examples
#' \dontrun{
#' ezrmodel_options(seed = 42)
#' save_ezrmodel_profile()
#' }
#' @export
save_ezrmodel_profile <- function(path = NULL) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Saving a profile needs the 'yaml' package. ",
         "Install it with install.packages('yaml').", call. = FALSE)
  }
  if (is.null(path)) {
    dir <- tools::R_user_dir("ezrmodel", "config")
    if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
    path <- file.path(dir, "ezrmodel.yml")
  } else {
    path <- path.expand(path)
  }
  defs <- ezrmodel_defaults()
  cfg <- list()
  for (nm in names(defs)) {
    cur <- ezrmodel_default(nm)
    if (!identical(cur, defs[[nm]])) cfg[[nm]] <- cur
  }
  yaml::write_yaml(cfg, path)
  message("Saved ezrmodel profile to ", path)
  invisible(path)
}
