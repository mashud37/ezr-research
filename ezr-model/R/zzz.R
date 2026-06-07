.onLoad <- function(libname, pkgname) {
  # Populate the built-in prompt templates when the package loads.
  .register_default_prompts()
  # Apply any user/project YAML profile defaults (no-op if 'yaml' is absent or
  # no profile exists). Wrapped so a malformed profile never blocks loading.
  tryCatch(load_ezrmodel_profile(quiet = TRUE), error = function(e) NULL)
  invisible()
}
