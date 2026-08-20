# Built-in defaults. getOption("ezrintelligence.<name>") overrides any of
# these, and a YAML profile (see load_ezrintelligence_profile()) sets those
# options at load time.
ezrintelligence_defaults <- function() {
  list(
    provider = "openai",     # default LLM provider passed to ai_chat()
    model = NULL,            # default model name (NULL = the provider default)
    template = "key_findings",  # default prompt template for ai_summarise()
    max_rows = 50,           # rows of a table included in a prompt
    confidence_z = 1.96      # z value behind the derived margin of error
  )
}

# Internal getter: option override first, then the built-in default.
ezrintelligence_default <- function(name) {
  opt <- getOption(paste0("ezrintelligence.", name), default = NULL)
  if (!is.null(opt)) {
    return(opt)
  }
  d <- ezrintelligence_defaults()
  if (!name %in% names(d)) {
    stop("Unknown ezrintelligence option '", name, "'.", call. = FALSE)
  }
  d[[name]]
}

#' Get or set ezrintelligence defaults
#'
#' ezrintelligence reads its defaults from R options (prefixed
#' `ezrintelligence.`), so you can pick a provider and model once instead of
#' repeating them on every call. Call with no arguments to see the current
#' effective values; call with `name = value` pairs to set them for the
#' session. Persist them across sessions with a YAML profile (see
#' [use_ezrintelligence_profile()]).
#'
#' Recognised options:
#' \describe{
#'   \item{`provider`}{Default provider for [ai_chat()] and [ai_summarise()]
#'     (default `"openai"`).}
#'   \item{`model`}{Default model name; `NULL` (default) uses the provider's
#'     own default.}
#'   \item{`template`}{Default prompt template for [ai_summarise()] (default
#'     `"key_findings"`).}
#'   \item{`max_rows`}{Rows of a table included in a prompt before the rest are
#'     summarised away as omitted (default `50`).}
#'   \item{`confidence_z`}{z value behind the margin of error [ai_context()]
#'     derives from a sample size (default `1.96`, a 95% interval).}
#' }
#'
#' @param ... Either nothing (to read all values) or named `option = value`
#'   pairs to set.
#'
#' @return When reading, a named list of all current values. When setting, the
#'   previous values, invisibly.
#'
#' @details
#' Options are ordinary R options under the `ezrintelligence.` prefix, so
#' anything you can do with [options()] works here too, and a setting lasts for
#' the session. Setting returns the previous values invisibly, so you can
#' restore them. To make settings permanent, write them to a YAML profile,
#' which is loaded automatically at package start-up.
#'
#' @family config
#' @seealso [use_ezrintelligence_profile()], [load_ezrintelligence_profile()],
#'   [reset_ezrintelligence_options()].
#' @examples
#' ezrintelligence_options()                    # view all defaults
#' ezrintelligence_options(provider = "anthropic")
#' ezrintelligence_options()$provider           # "anthropic"
#' reset_ezrintelligence_options()              # back to defaults
#' @export
ezrintelligence_options <- function(...) {
  args <- list(...)
  if (length(args) == 0L) {
    nm <- names(ezrintelligence_defaults())
    return(stats::setNames(lapply(nm, ezrintelligence_default), nm))
  }
  if (is.null(names(args)) || any(!nzchar(names(args)))) {
    stop("All arguments must be named, e.g. ",
         "ezrintelligence_options(provider = 'anthropic').", call. = FALSE)
  }
  known <- names(ezrintelligence_defaults())
  unknown <- setdiff(names(args), known)
  if (length(unknown)) {
    warning("Unknown ezrintelligence option(s): ",
            paste(unknown, collapse = ", "), call. = FALSE)
  }
  old <- stats::setNames(
    lapply(names(args), function(n) getOption(paste0("ezrintelligence.", n))),
    names(args)
  )
  newopts <- stats::setNames(args, paste0("ezrintelligence.", names(args)))
  options(newopts)
  invisible(old)
}

#' Reset all ezrintelligence options to their built-in defaults
#'
#' @return Invisibly `TRUE`.
#' @family config
#' @seealso [ezrintelligence_options()].
#' @examples
#' ezrintelligence_options(provider = "anthropic")
#' reset_ezrintelligence_options()
#' ezrintelligence_options()$provider           # "openai" again
#' @export
reset_ezrintelligence_options <- function() {
  nm <- paste0("ezrintelligence.", names(ezrintelligence_defaults()))
  options(stats::setNames(vector("list", length(nm)), nm))
  invisible(TRUE)
}

#' Profile file locations ezrintelligence looks in
#'
#' At load time ezrintelligence reads a YAML profile from each of these paths
#' in turn (later paths override earlier ones), if present: the per-user config
#' directory, your home directory, then the current project.
#'
#' @return A character vector of candidate profile paths.
#' @family config
#' @seealso [use_ezrintelligence_profile()], [load_ezrintelligence_profile()].
#' @examples
#' ezrintelligence_profile_paths()
#' @export
ezrintelligence_profile_paths <- function() {
  c(
    file.path(tools::R_user_dir("ezrintelligence", "config"),
              "ezrintelligence.yml"),
    path.expand("~/.ezrintelligence.yml"),
    file.path(getwd(), ".ezrintelligence.yml")
  )
}

#' Load ezrintelligence defaults from a YAML profile
#'
#' Reads a YAML file of `option: value` pairs and applies them with
#' [ezrintelligence_options()]. Called automatically when the package loads
#' (over the standard [ezrintelligence_profile_paths()]); call it manually to
#' load a specific file. Requires the suggested `yaml` package; without it, the
#' function is a no-op.
#'
#' @param path Profile path(s). If `NULL` (default), the standard locations are
#'   tried in order (later files override earlier ones).
#' @param quiet If `TRUE` (default), load silently; if `FALSE`, message which
#'   file(s) were loaded.
#'
#' @return Invisibly `TRUE` if any profile was applied, else `FALSE`.
#' @family config
#' @seealso [use_ezrintelligence_profile()] to create a template.
#' @examples
#' \dontrun{
#' load_ezrintelligence_profile("~/.ezrintelligence.yml", quiet = FALSE)
#' }
#' @export
load_ezrintelligence_profile <- function(path = NULL, quiet = TRUE) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    if (!quiet) {
      message("Install the 'yaml' package to use ezrintelligence profiles.")
    }
    return(invisible(FALSE))
  }
  paths <- if (is.null(path)) ezrintelligence_profile_paths() else path
  loaded <- FALSE
  for (p in paths) {
    if (file.exists(p)) {
      cfg <- tryCatch(yaml::read_yaml(p), error = function(e) NULL)
      if (!is.null(cfg) && length(cfg)) {
        do.call(ezrintelligence_options, cfg)
        loaded <- TRUE
        if (!quiet) message("Loaded ezrintelligence profile: ", p)
      }
    }
  }
  invisible(loaded)
}

#' Create a starter ezrintelligence profile
#'
#' Writes a commented YAML profile you can edit to set persistent options. By
#' default it is written to the per-user config directory
#' ([tools::R_user_dir()]), which is where ezrintelligence looks first.
#'
#' @param path Destination path. If `NULL` (default), the per-user config file
#'   `ezrintelligence.yml` is used.
#' @param overwrite Overwrite an existing file. Defaults to `FALSE`.
#'
#' @return Invisibly the path written.
#' @family config
#' @seealso [load_ezrintelligence_profile()], [ezrintelligence_options()].
#' @examples
#' \dontrun{
#' use_ezrintelligence_profile()
#' use_ezrintelligence_profile("~/.ezrintelligence.yml")
#' }
#' @export
use_ezrintelligence_profile <- function(path = NULL, overwrite = FALSE) {
  path <- path %||% default_profile_path()
  path <- path.expand(path)
  if (file.exists(path) && !overwrite) {
    stop("'", path, "' already exists. Use overwrite = TRUE to replace it.",
         call. = FALSE)
  }
  lines <- c(
    "# ezrintelligence profile -- set persistent defaults here.",
    "# Edit values and uncomment the lines you want to change.",
    "",
    "# provider: anthropic     # default provider for ai_chat()",
    "# model: claude-sonnet-4-5   # default model name",
    "# template: exec_summary  # default prompt template",
    "# max_rows: 50            # table rows sent in a prompt",
    "# confidence_z: 1.96      # z value behind the derived margin of error",
    "",
    "# API keys never belong in this file. Store them with",
    "# set_llm_key('openai'), or set the OPENAI_API_KEY environment variable."
  )
  writeLines(lines, path)
  message("Wrote ezrintelligence profile template to ", path)
  invisible(path)
}

#' Open the ezrintelligence profile for editing
#'
#' Opens your ezrintelligence YAML profile in the editor (like
#' [utils::file.edit()] on `.Rprofile`), creating it from a template first if
#' it does not exist. After saving, reload it with
#' [load_ezrintelligence_profile()] or by restarting the session.
#'
#' @param path Profile path. If `NULL` (default), the first existing profile
#'   among [ezrintelligence_profile_paths()] is used, or the per-user config
#'   file is created.
#'
#' @return Invisibly the path opened.
#' @family config
#' @seealso [use_ezrintelligence_profile()], [save_ezrintelligence_profile()],
#'   [load_ezrintelligence_profile()].
#' @examples
#' \dontrun{
#' edit_ezrintelligence_profile()
#' }
#' @export
edit_ezrintelligence_profile <- function(path = NULL) {
  if (is.null(path)) {
    existing <- ezrintelligence_profile_paths()
    existing <- existing[file.exists(existing)]
    path <- if (length(existing)) {
      existing[[1]]
    } else {
      use_ezrintelligence_profile()
    }
  } else {
    path <- path.expand(path)
    if (!file.exists(path)) use_ezrintelligence_profile(path)
  }
  if (interactive()) {
    utils::file.edit(path)
  } else {
    message("ezrintelligence profile is at: ", path)
  }
  invisible(path)
}

#' Save current options to a profile
#'
#' Writes your current non-default [ezrintelligence_options()] to a YAML
#' profile, so they persist across sessions. Requires the suggested `yaml`
#' package. API keys are never written: they live in the credential store, see
#' [set_llm_key()].
#'
#' @param path Destination path. If `NULL` (default), the per-user config file
#'   is used.
#'
#' @return Invisibly the path written.
#' @family config
#' @seealso [load_ezrintelligence_profile()], [edit_ezrintelligence_profile()].
#' @examples
#' \dontrun{
#' ezrintelligence_options(provider = "anthropic")
#' save_ezrintelligence_profile()
#' }
#' @export
save_ezrintelligence_profile <- function(path = NULL) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Saving a profile needs the 'yaml' package. ",
         "Install it with install.packages('yaml').", call. = FALSE)
  }
  path <- path.expand(path %||% default_profile_path())

  cfg <- list()
  defs <- ezrintelligence_defaults()
  for (nm in names(defs)) {
    cur <- ezrintelligence_default(nm)
    if (!identical(cur, defs[[nm]])) cfg[[nm]] <- cur
  }

  yaml::write_yaml(cfg, path)
  message("Saved ezrintelligence profile to ", path)
  invisible(path)
}

# Internal: the per-user config file, creating its directory on first use.
default_profile_path <- function() {
  dir <- tools::R_user_dir("ezrintelligence", "config")
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  file.path(dir, "ezrintelligence.yml")
}
