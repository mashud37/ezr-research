# Service namespace under which all ezrmodel secrets live in the OS keyring.
.ezrmodel_service <- "ezrmodel"

# Conventional environment-variable name for each provider, used as a fallback
# when no key is stored in the keyring.
llm_env_var <- function(provider) {
  switch(
    provider,
    openai = "OPENAI_API_KEY",
    anthropic = "ANTHROPIC_API_KEY",
    google = "GOOGLE_API_KEY",
    gemini = "GEMINI_API_KEY",
    paste0(toupper(provider), "_API_KEY")
  )
}

require_keyring <- function() {
  if (!requireNamespace("keyring", quietly = TRUE)) {
    stop("Package 'keyring' is required for key management. ",
         "Install it with install.packages('keyring').", call. = FALSE)
  }
}

#' Store an LLM API key in the system keyring
#'
#' Saves a provider's API key to the OS credential store (via \pkg{keyring}),
#' namespaced under the `"ezrmodel"` service. Keys stored this way are picked up
#' automatically by [ai_chat()] and [ai_summarise()], so secrets never have to
#' live in your scripts.
#'
#' @param provider Provider name, e.g. `"openai"`, `"anthropic"`, `"google"`.
#'   Used as the keyring username.
#' @param key The API key. If `NULL` (default) and the session is interactive,
#'   you are prompted for it without echoing to the console.
#'
#' @return Invisibly `TRUE` on success.
#'
#' @details
#' Keys are saved in the operating system's credential store via the suggested
#' `keyring` package, namespaced under the `"ezrmodel"` service, so they never
#' appear in your scripts or history. [ai_chat()] and [ai_summarise()] look them
#' up automatically (falling back to the conventional environment variable, e.g.
#' `OPENAI_API_KEY`). In an interactive session, omit `key` to be prompted
#' without echoing it to the console.
#'
#' @family ai
#' @seealso [get_llm_key()], [has_llm_key()], [delete_llm_key()],
#'   [list_llm_keys()].
#' @examples
#' \dontrun{
#' set_llm_key("openai")                 # prompts securely
#' set_llm_key("anthropic", Sys.getenv("ANTHROPIC_API_KEY"))
#' }
#' @export
set_llm_key <- function(provider, key = NULL) {
  require_keyring()
  if (is.null(key)) {
    keyring::key_set(service = .ezrmodel_service, username = provider)
  } else {
    keyring::key_set_with_value(service = .ezrmodel_service,
                                username = provider, password = key)
  }
  invisible(TRUE)
}

#' Retrieve an LLM API key
#'
#' Looks up a provider's API key, first in the `"ezrmodel"` keyring service and
#' then in the conventional environment variable (e.g. `OPENAI_API_KEY`).
#'
#' @param provider Provider name (see [set_llm_key()]).
#' @param error If `TRUE` (default), error when no key is found; if `FALSE`,
#'   return `NA_character_`.
#'
#' @return The API key as a string, or `NA` (when `error = FALSE`).
#' @family ai
#' @seealso [set_llm_key()].
#' @examples
#' \dontrun{
#' get_llm_key("openai")
#' }
#' @export
get_llm_key <- function(provider, error = TRUE) {
  key <- NA_character_

  if (requireNamespace("keyring", quietly = TRUE)) {
    key <- tryCatch(
      keyring::key_get(service = .ezrmodel_service, username = provider),
      error = function(e) NA_character_
    )
  }

  if (is.na(key) || !nzchar(key)) {
    env <- Sys.getenv(llm_env_var(provider), unset = NA_character_)
    if (!is.na(env) && nzchar(env)) key <- env
  }

  if ((is.na(key) || !nzchar(key)) && error) {
    stop("No API key found for provider '", provider, "'. ",
         "Store one with set_llm_key('", provider, "') or set the ",
         llm_env_var(provider), " environment variable.", call. = FALSE)
  }
  key
}

#' Is an LLM API key available?
#'
#' @param provider Provider name (see [set_llm_key()]).
#' @return `TRUE` if a key is found in the keyring or environment, else `FALSE`.
#' @family ai
#' @seealso [get_llm_key()].
#' @examples
#' has_llm_key("openai")
#' @export
has_llm_key <- function(provider) {
  key <- get_llm_key(provider, error = FALSE)
  !is.na(key) && nzchar(key)
}

#' Delete a stored LLM API key
#'
#' @param provider Provider name (see [set_llm_key()]).
#' @return Invisibly `TRUE`.
#' @family ai
#' @seealso [set_llm_key()].
#' @examples
#' \dontrun{
#' delete_llm_key("openai")
#' }
#' @export
delete_llm_key <- function(provider) {
  require_keyring()
  tryCatch(
    keyring::key_delete(service = .ezrmodel_service, username = provider),
    error = function(e) invisible(FALSE)
  )
  invisible(TRUE)
}

#' List providers with a stored key
#'
#' @return A character vector of provider names stored under the `"ezrmodel"`
#'   keyring service (empty if none / keyring unavailable).
#' @family ai
#' @seealso [set_llm_key()].
#' @examples
#' \dontrun{
#' list_llm_keys()
#' }
#' @export
list_llm_keys <- function() {
  if (!requireNamespace("keyring", quietly = TRUE)) {
    return(character(0))
  }
  keys <- tryCatch(keyring::key_list(service = .ezrmodel_service),
                   error = function(e) NULL)
  if (is.null(keys) || nrow(keys) == 0L) {
    return(character(0))
  }
  keys$username
}
