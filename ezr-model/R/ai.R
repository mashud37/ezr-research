require_ellmer <- function() {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("Package 'ellmer' is required for the AI helpers. ",
         "Install it with install.packages('ellmer').", call. = FALSE)
  }
}

# Map a provider name to its ellmer chat constructor.
ellmer_constructor <- function(provider) {
  name <- switch(
    provider,
    openai = "chat_openai",
    anthropic = "chat_anthropic",
    google = "chat_google_gemini",
    gemini = "chat_google_gemini",
    ollama = "chat_ollama",
    groq = "chat_groq",
    paste0("chat_", provider)
  )
  ns <- asNamespace("ellmer")
  if (!exists(name, envir = ns, inherits = FALSE)) {
    stop("ellmer has no constructor '", name, "' for provider '", provider,
         "'. See ?ellmer::chat_openai for supported providers.", call. = FALSE)
  }
  get(name, envir = ns, inherits = FALSE)
}

#' Open a chat connection to a commercial LLM
#'
#' Constructs an \pkg{ellmer} chat object for the given provider, pulling the API
#' key from the system keyring or environment via [get_llm_key()]. The returned
#' object can be reused across calls or passed to [ai_summarise()].
#'
#' @param provider One of `"openai"`, `"anthropic"`, `"google"` (alias
#'   `"gemini"`), `"ollama"`, `"groq"`, or any other provider ellmer exposes as
#'   `chat_<provider>()`.
#' @param model Optional model name; defaults to ellmer's provider default.
#' @param system_prompt Optional system-role instruction.
#' @param api_key Optional explicit key; if `NULL`, looked up with
#'   [get_llm_key()] (not needed for local `"ollama"`).
#' @param ... Passed to the underlying `ellmer::chat_*()` constructor.
#'
#' @return An ellmer `Chat` object.
#' @family ai
#' @seealso [ai_summarise()], [set_llm_key()].
#' @examples
#' \dontrun{
#' chat <- ai_chat("openai", model = "gpt-4o-mini")
#' chat$chat("Say hello in five words.")
#' }
#' @export
ai_chat <- function(provider = "openai", model = NULL, system_prompt = NULL,
                    api_key = NULL, ...) {
  require_ellmer()
  ctor <- ellmer_constructor(provider)

  if (is.null(api_key) && provider != "ollama") {
    api_key <- get_llm_key(provider)
  }

  args <- list(...)
  if (!is.null(system_prompt)) args$system_prompt <- system_prompt
  if (!is.null(model)) args$model <- model
  if (!is.null(api_key)) args$api_key <- api_key

  do.call(ctor, args)
}

#' Summarise a table with a commercial LLM
#'
#' Sends a summary data frame (e.g. the tidy output of [drivers()],
#' [correlations()] or [cluster()]) to an LLM together with a named prompt
#' template and returns the model's text. Only the table is sent -- reduce your
#' data to the figures you want summarised first.
#'
#' @param data A data frame / tibble to summarise.
#' @param instructions Optional extra, free-text instructions appended to the
#'   template's default instruction.
#' @param template Prompt template name (see [list_prompts()]). Defaults to
#'   `"key_findings"`.
#' @param provider,model Passed to [ai_chat()] when `chat` is not supplied.
#' @param chat An existing [ai_chat()] object to reuse. If `NULL` (default), a
#'   fresh chat is created using the template's system prompt.
#' @param title Optional context title for the table.
#' @param max_rows Maximum rows of `data` to include in the prompt. Defaults to
#'   `50`.
#' @param ... Passed to [ai_chat()].
#'
#' @return The model's response as a length-1 character string.
#'
#' @details
#' Only the summary table you pass is sent to the provider -- so summarise or
#' aggregate your data down to the figures you want described first, never the
#' raw respondent rows. The named `template` supplies a system prompt and a
#' default instruction (see [list_prompts()]); add free-text `instructions` to
#' steer a single call. A fresh chat is created per call unless you pass one via
#' `chat`. Requires the suggested `ellmer` package and a stored key (see
#' [set_llm_key()]).
#'
#' @family ai
#' @seealso [ai_report_sections()] to summarise many tables at once.
#' @examples
#' \dontrun{
#' tidy(drivers(nps_drivers, nps)) |>
#'   ai_summarise(template = "exec_summary", provider = "openai")
#' }
#' @export
ai_summarise <- function(data, instructions = NULL, template = "key_findings",
                         provider = "openai", model = NULL, chat = NULL,
                         title = NULL, max_rows = 50, ...) {
  require_ellmer()
  spec <- get_prompt(template)
  user_msg <- build_prompt(template, data = data, instructions = instructions,
                           max_rows = max_rows, title = title)

  if (is.null(chat)) {
    chat <- ai_chat(provider = provider, model = model,
                    system_prompt = spec$system, ...)
  }
  chat$chat(user_msg)
}

#' Summarise several tables in one pipeline
#'
#' Runs [ai_summarise()] over a named list of report sections, returning a named
#' list of summaries -- a convenient way to draft every section of a report at
#' once. Each section gets its own fresh chat so summaries stay independent.
#'
#' @param sections A named list. Each element is either a data frame (summarised
#'   with the default template) or a list with elements `data`, optional
#'   `template`, `instructions` and `title`.
#' @param provider,model,... Passed to [ai_summarise()].
#'
#' @return A named list of summary strings, one per section.
#' @family ai
#' @seealso [ai_summarise()].
#' @examples
#' \dontrun{
#' ai_report_sections(
#'   list(
#'     drivers = tidy(drivers(nps_drivers, nps)),
#'     correlations = list(data = tidy(correlations(nps_drivers, nps)),
#'                         template = "exec_summary")
#'   ),
#'   provider = "openai"
#' )
#' }
#' @export
ai_report_sections <- function(sections, provider = "openai", model = NULL, ...) {
  if (is.null(names(sections)) || any(!nzchar(names(sections)))) {
    stop("`sections` must be a named list.", call. = FALSE)
  }
  purrr::imap(sections, function(spec, name) {
    if (is.data.frame(spec)) spec <- list(data = spec)
    if (is.null(spec$data)) {
      stop("Section '", name, "' has no `data`.", call. = FALSE)
    }
    ai_summarise(
      spec$data,
      instructions = spec$instructions,
      template = spec$template %||% "key_findings",
      title = spec$title %||% name,
      provider = provider, model = model, ...
    )
  })
}
