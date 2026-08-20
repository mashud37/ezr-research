.onLoad <- function(libname, pkgname) {
  # Apply any user/project YAML profile defaults (no-op if 'yaml' is absent or
  # no profile exists). Wrapped so a malformed profile never blocks loading.
  tryCatch(load_ezrsurvey_profile(quiet = TRUE), error = function(e) NULL)
  invisible()
}
