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

#' Open a chat connection to a language model
#'
#' Constructs an \pkg{ellmer} chat object for the given provider, pulling the API
#' key from the system keyring or environment via [get_llm_key()]. The returned
#' object can be reused across calls or passed to [ai_summarise()].
#'
#' @param provider One of `"openai"`, `"anthropic"`, `"google"` (alias
#'   `"gemini"`), `"ollama"`, `"groq"`, or any other provider ellmer exposes as
#'   `chat_<provider>()`. Defaults to the `provider` option, see
#'   [ezrintelligence_options()].
#' @param model Optional model name; defaults to the `model` option, and then
#'   to ellmer's provider default.
#' @param system_prompt Optional system-role instruction.
#' @param api_key Optional explicit key; if `NULL`, looked up with
#'   [get_llm_key()] (not needed for local `"ollama"`).
#' @param ... Passed to the underlying `ellmer::chat_*()` constructor.
#'
#' @return An ellmer `Chat` object.
#'
#' @details
#' Nothing here is specific to a commercial provider: `"ollama"` (and any other
#' constructor ellmer exposes) reaches a locally served open-weight model with
#' no key at all, which is the option to take when the tables must not leave
#' your machine.
#'
#' @family ai
#' @seealso [ai_summarise()], [set_llm_key()].
#' @examples
#' \dontrun{
#' chat <- ai_chat("openai", model = "gpt-4o-mini")
#' chat$chat("Say hello in five words.")
#' }
#' @export
ai_chat <- function(provider = ezrintelligence_default("provider"),
                    model = ezrintelligence_default("model"),
                    system_prompt = NULL, api_key = NULL, ...) {
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

#' Summarise a table with a language model
#'
#' Sends a summary data frame to a model together with a named prompt template
#' and returns the model's text. Only the table is sent -- format your data down
#' to the figures you want summarised first.
#'
#' @param data A data frame / tibble to summarise.
#' @param instructions Optional extra, free-text instructions appended to the
#'   template's default instruction.
#' @param template Prompt template name (see [list_prompts()]). Defaults to the
#'   `template` option, `"key_findings"`.
#' @param provider,model Passed to [ai_chat()] when `chat` is not supplied.
#' @param chat An existing [ai_chat()] object to reuse. If `NULL` (default), a
#'   fresh chat is created using the template's system prompt.
#' @param title Optional context title for the table.
#' @param context Optional study context from [ai_context()] (or a character
#'   vector), included in the prompt so the model can respect sample sizes and
#'   margins of error.
#' @param max_rows Maximum rows of `data` to include in the prompt. Defaults to
#'   the `max_rows` option, `50`.
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
#' answers <- data.frame(
#'   answer = c("Very satisfied", "Satisfied", "Neither", "Dissatisfied"),
#'   pct = c(31, 42, 18, 9)
#' )
#' ai_summarise(answers, template = "exec_summary")
#' }
#' @export
ai_summarise <- function(data, instructions = NULL,
                         template = ezrintelligence_default("template"),
                         provider = ezrintelligence_default("provider"),
                         model = ezrintelligence_default("model"),
                         chat = NULL, title = NULL, context = NULL,
                         max_rows = ezrintelligence_default("max_rows"), ...) {
  spec <- get_prompt(template)
  user_msg <- build_prompt(template, data = data, instructions = instructions,
                           max_rows = max_rows, title = title,
                           context = context)

  if (is.null(chat)) {
    require_ellmer()
    chat <- ai_chat(provider = provider, model = model,
                    system_prompt = spec$system, ...)
  }
  chat$chat(user_msg)
}

#' Summarise several tables in one pipeline
#'
#' Runs [ai_summarise()] over a named list of report sections, returning a named
#' list of summaries -- a convenient way to draft every section of a report at
#' once. By default each section gets its own fresh chat so summaries stay
#' independent; pass `chat` to reuse one connection for the whole run.
#'
#' @param sections A named list. Each element is either a data frame (summarised
#'   with the default template) or a list with elements `data`, optional
#'   `template`, `instructions`, `title` and `context`.
#' @param provider,model,... Passed to [ai_summarise()].
#' @param chat An existing [ai_chat()] object reused across all sections. If
#'   `NULL` (default), each section opens a fresh chat with its template's
#'   system prompt.
#' @param context Default study context from [ai_context()] applied to every
#'   section that does not carry its own.
#'
#' @return A named list of summary strings, one per section.
#'
#' @details
#' Sections are summarised in the order given. A fresh chat per section keeps
#' each summary independent of what the model wrote before it, which is usually
#' what a report wants; pass one `chat` when you would rather the sections read
#' as a single continuous narrative.
#'
#' @family ai
#' @seealso [ai_summarise()], [ai_context()].
#' @examples
#' \dontrun{
#' ai_report_sections(
#'   list(
#'     gender = data.frame(answer = c("Female", "Male"), pct = c(55, 45)),
#'     nps = list(data = data.frame(nps = 32), template = "exec_summary")
#'   ),
#'   context = ai_context(n = 1000)
#' )
#' }
#' @export
ai_report_sections <- function(sections,
                               provider = ezrintelligence_default("provider"),
                               model = ezrintelligence_default("model"),
                               chat = NULL, context = NULL, ...) {
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
      template = spec$template %||% ezrintelligence_default("template"),
      title = spec$title %||% name,
      context = spec$context %||% context,
      provider = provider, model = model, chat = chat, ...
    )
  })
}
