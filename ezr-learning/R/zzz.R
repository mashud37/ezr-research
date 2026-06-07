.onLoad <- function(libname, pkgname) {
  # Populate the built-in exercise-prompt templates and generators on load.
  .register_default_prompts()
  .register_generators()
  invisible()
}
