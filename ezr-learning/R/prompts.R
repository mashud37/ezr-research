# Mutable registry of prompt templates used by the AI exercise generator. Each
# entry has a `system` role string, a default `instruction`, and a one-line
# `description`. Stored in an environment so register_prompt() can extend it.
.prompt_registry <- new.env(parent = emptyenv())

# A compact inventory of the real ezr functions the model is allowed to use, so
# generated exercises stay grounded in the family rather than inventing helpers.
ezr_function_inventory <- function() {
  paste(
    "ezrsurvey (survey analysis):",
    "  use_dataset(); calc_percentage(data, column, by); calc_nps(data, value, by);",
    "  nps_group(x); recode_likert(x); ensure_numeric(x); recode_generation(x);",
    "  recode_age(x); crosstab(data, x, y); calc_summary(data, column, by);",
    "  calc_importance(data, outcome, predictors); ipm_model(data, outcome, rating_prefix);",
    "  plot_nps(); plot_stacked_rating(); plot_ipm(); export_xlsx(); save_plot().",
    "ezrmodel (modelling):",
    "  drivers(data, target); correlations(data, target); model_lm(data, formula);",
    "  model_select(data, formula, method); compare_models(...); cluster(data, k);",
    "  reduce_dims(data, method); reliability(data, items); factors(data, vars);",
    "  tokenize_text(data, text); term_freq(data, text, by); topics(data, text).",
    sep = "\n"
  )
}

# The JSON shape we ask the model to return for a single exercise.
exercise_schema_text <- function() {
  paste(
    "Return ONE exercise as a single JSON object, no prose around it.",
    "For a multiple-choice question use:",
    '  {"type":"mcq","prompt":"...","options":["...","...","...","..."],',
    '   "answer":"B","explanation":"...","hint":"...","topic":"...","chapter":4}',
    "For a code-writing task use:",
    '  {"type":"code","prompt":"...","solution_code":"calc_nps(theme_park, nps)",',
    '   "explanation":"...","hint":"...","topic":"...","chapter":2}',
    "Rules: options must be 3-4 plausible choices; answer is the LETTER of the",
    "correct option; solution_code must call only real ezr functions listed",
    "above and be runnable against the 'theme_park' teaching dataset.",
    sep = "\n"
  )
}

.register_default_prompts <- function() {
  base_system <- paste(
    "You are an R instructor for the 'ezr' family of packages (ezrsurvey and",
    "ezrmodel). You write clear, friendly practice exercises for research and",
    "insights analysts with limited coding experience. You ONLY use real ezr",
    "functions from the inventory you are given, never invented ones, and you",
    "never reference data columns that were not provided. You return strictly",
    "valid JSON in the requested shape and nothing else."
  )
  defaults <- list(
    mcq = list(
      description = "A multiple-choice question about an ezr concept.",
      system = base_system,
      instruction = paste(
        "Write one multiple-choice question that tests understanding of the",
        "given topic. Make the distractors plausible but clearly wrong to",
        "someone who knows the material."
      )
    ),
    code_task = list(
      description = "A 'write the ezr code' task.",
      system = base_system,
      instruction = paste(
        "Write one short task asking the learner to produce a single line (or a",
        "short pipe) of ezr code that answers a concrete question about the",
        "'theme_park' teaching dataset. Provide the reference solution."
      )
    ),
    revision_set = list(
      description = "A mixed revision set covering a topic.",
      system = base_system,
      instruction = paste(
        "Write a balanced revision exercise (multiple choice or code) that",
        "consolidates the key idea of the topic, suitable for spaced revision."
      )
    )
  )
  for (nm in names(defaults)) assign(nm, defaults[[nm]], envir = .prompt_registry)
}

#' List available exercise-prompt templates
#'
#' @return A [tibble][tibble::tibble] with `name` and `description` for every
#'   registered prompt template (built-in plus any you have registered).
#' @family ai
#' @seealso [get_prompt()], [register_prompt()], [generate_exercise()].
#' @examples
#' list_prompts()
#' @export
list_prompts <- function() {
  names <- ls(envir = .prompt_registry, sorted = TRUE)
  tibble::tibble(
    name = names,
    description = vapply(names,
                         function(n) get(n, envir = .prompt_registry)$description,
                         character(1))
  )
}

#' Get a prompt template specification
#'
#' @param name Template name (see [list_prompts()]).
#' @return A list with `system`, `instruction` and `description`.
#' @family ai
#' @seealso [list_prompts()].
#' @examples
#' get_prompt("mcq")
#' @export
get_prompt <- function(name) {
  if (!exists(name, envir = .prompt_registry, inherits = FALSE)) {
    stop("Unknown prompt template '", name, "'. See list_prompts().",
         call. = FALSE)
  }
  get(name, envir = .prompt_registry, inherits = FALSE)
}

#' Register a custom exercise-prompt template
#'
#' Adds (or overwrites) a reusable prompt template that [generate_exercise()] can
#' refer to by name.
#'
#' @param name Template name.
#' @param system The system-role instruction defining the assistant's behaviour.
#' @param instruction The default task instruction.
#' @param description One-line description shown by [list_prompts()].
#'
#' @return Invisibly the template name.
#' @family ai
#' @seealso [list_prompts()].
#' @examples
#' register_prompt(
#'   "tricky",
#'   system = "You are an exacting R examiner.",
#'   instruction = "Write a deliberately tricky multiple-choice question.",
#'   description = "A harder-than-usual MCQ."
#' )
#' @export
register_prompt <- function(name, system, instruction, description = "") {
  assign(name,
         list(system = system, instruction = instruction,
              description = description),
         envir = .prompt_registry)
  invisible(name)
}

# Internal: assemble the user-message text for one generated exercise.
build_exercise_prompt <- function(template, topic, type = NULL,
                                  difficulty = "easy", example = NULL) {
  spec <- get_prompt(template)
  want_type <- if (is.null(type)) "" else
    paste0("The exercise type must be '", type, "'.")
  parts <- c(
    spec$instruction,
    paste0("Topic: ", topic, ". Difficulty: ", difficulty, ". ", want_type),
    "",
    "Available ezr functions you may use:",
    ezr_function_inventory(),
    "",
    exercise_schema_text(),
    if (!is.null(example)) c("", "Here is an example of the JSON shape:", example)
  )
  paste(parts, collapse = "\n")
}
