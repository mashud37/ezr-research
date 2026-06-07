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
#' key from the system keyring or environment via [get_llm_key()]. Reuse it
#' across [generate_exercise()] calls to save setup.
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
#' @seealso [generate_exercise()], [set_llm_key()].
#' @examples
#' \dontrun{
#' chat <- ai_chat("openai", model = "gpt-4o-mini")
#' }
#' @export
ai_chat <- function(provider = ezrlearning_default("provider"), model = NULL,
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

# Internal: pull the first JSON object out of a model reply and parse it.
parse_exercise_json <- function(txt) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Parsing AI exercises needs the 'jsonlite' package. ",
         "Install it with install.packages('jsonlite').", call. = FALSE)
  }
  start <- regexpr("\\{", txt)
  end <- max(gregexpr("\\}", txt)[[1]])
  if (start < 1 || end < start) {
    stop("The model did not return a JSON object. Try again.", call. = FALSE)
  }
  jsonlite::fromJSON(substr(txt, start, end), simplifyVector = TRUE)
}

# Internal: turn a parsed JSON list into an ezrlearning_exercise.
json_to_exercise <- function(j, topic, difficulty) {
  type <- j$type %||% "mcq"
  id <- paste0("ai_", type, "_", substr(
    paste(sample(c(letters, 0:9), 6, TRUE), collapse = ""), 1, 6))
  chapter <- if (!is.null(j$chapter)) suppressWarnings(as.integer(j$chapter)) else
    NA_integer_
  if (type == "mcq") {
    new_exercise(id = id, type = "mcq", prompt = j$prompt, chapter = chapter,
                 topic = j$topic %||% topic, difficulty = difficulty,
                 options = as.character(j$options), answer = j$answer,
                 explanation = j$explanation %||% NA, hint = j$hint %||% NA,
                 source = "ai")
  } else {
    new_exercise(id = id, type = "code", prompt = j$prompt, chapter = chapter,
                 topic = j$topic %||% topic, difficulty = difficulty,
                 data = theme_park, data_name = "theme_park",
                 solution_code = j$solution_code %||% NA,
                 explanation = j$explanation %||% NA, hint = j$hint %||% NA,
                 source = "ai")
  }
}

#' Generate a fresh exercise with a language model
#'
#' Asks an LLM to write a new exercise about an ezr topic, in the same shape as
#' the built-in ones, so it slots into [check_answer()] / [reveal()] and quizzes.
#' The model is pinned to real ezr functions and the teaching dataset.
#'
#' @param topic What the exercise should be about (free text, e.g. `"NPS by
#'   group"` or a [list_topics()] topic).
#' @param type `"mcq"` or `"code"`. Default `"mcq"`.
#' @param difficulty `"easy"`, `"medium"` or `"hard"`. Defaults to the
#'   `difficulty` option.
#' @param template Prompt template (see [list_prompts()]). Defaults to the one
#'   matching `type`.
#' @param provider,model Passed to [ai_chat()] when `chat` is not supplied.
#' @param chat An existing [ai_chat()] object to reuse.
#' @param ... Passed to [ai_chat()].
#'
#' @return An `ezrlearning_exercise` with `source = "ai"`.
#'
#' @details
#' Generated **MCQs are auto-graded** (the model supplies the correct option), so
#' [check_answer()] works as usual. Generated **code tasks are self-graded**:
#' there is no precomputed reference value, so `check_answer()` will point you to
#' [reveal()] to compare against the model's solution. The system prompt restricts
#' the model to the real ezr function inventory and the `theme_park` dataset, but
#' always sanity-check AI output before handing it to learners. Requires the
#' suggested `ellmer` (and `jsonlite`) packages and a stored key (see
#' [set_llm_key()]).
#'
#' @family ai
#' @seealso [generate_quiz()], [draw_exercise()], [list_prompts()].
#' @examples
#' \dontrun{
#' set_llm_key("openai")
#' ex <- generate_exercise("NPS by region", type = "mcq")
#' ex
#' }
#' @export
generate_exercise <- function(topic, type = "mcq",
                              difficulty = ezrlearning_default("difficulty"),
                              template = NULL,
                              provider = ezrlearning_default("provider"),
                              model = NULL, chat = NULL, ...) {
  require_ellmer()
  type <- match.arg(type, c("mcq", "code"))
  template <- template %||% if (type == "mcq") "mcq" else "code_task"
  spec <- get_prompt(template)
  msg <- build_exercise_prompt(template, topic = topic, type = type,
                               difficulty = difficulty)
  if (is.null(chat)) {
    chat <- ai_chat(provider = provider, model = model,
                    system_prompt = spec$system, ...)
  }
  reply <- chat$chat(msg)
  json_to_exercise(parse_exercise_json(reply), topic = topic,
                   difficulty = difficulty)
}

#' Generate a quiz of fresh AI exercises
#'
#' Calls [generate_exercise()] `n` times and bundles the results into an
#' `ezrlearning_quiz`, so AI-authored questions reuse the same grading,
#' printing and [export_worksheet()] machinery as the built-in bank.
#'
#' @param n Number of exercises. Default `5`.
#' @param topic What the quiz should be about.
#' @param type `"mcq"`, `"code"`, or `"mix"` (alternate). Default `"mcq"`.
#' @param difficulty Passed to [generate_exercise()].
#' @param provider,model,... Passed to [generate_exercise()] (a single chat is
#'   reused across questions).
#'
#' @return An `ezrlearning_quiz` of AI exercises.
#'
#' @details
#' One [ai_chat()] connection is reused for all `n` questions. With `type =
#' "mix"`, question types alternate MCQ / code. As with [generate_exercise()],
#' the MCQs are auto-graded and the code tasks are self-graded; review the set
#' before using it with learners.
#'
#' @family ai
#' @seealso [generate_exercise()], [quiz()].
#' @examples
#' \dontrun{
#' generate_quiz(3, "clustering", provider = "openai")
#' }
#' @export
generate_quiz <- function(n = 5, topic = "the ezr family", type = "mcq",
                          difficulty = ezrlearning_default("difficulty"),
                          provider = ezrlearning_default("provider"),
                          model = NULL, ...) {
  require_ellmer()
  type <- match.arg(type, c("mcq", "code", "mix"))
  spec <- get_prompt("mcq")
  chat <- ai_chat(provider = provider, model = model,
                  system_prompt = spec$system, ...)
  exs <- lapply(seq_len(n), function(i) {
    this_type <- if (type == "mix") c("mcq", "code")[(i %% 2) + 1] else type
    generate_exercise(topic, type = this_type, difficulty = difficulty,
                      chat = chat)
  })
  structure(
    list(exercises = exs, n = length(exs),
         call = list(n = n, topic = topic, type = type, difficulty = difficulty,
                     seed = NA, source = "ai")),
    class = "ezrlearning_quiz"
  )
}
