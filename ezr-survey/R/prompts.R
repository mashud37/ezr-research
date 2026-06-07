# Mutable registry of prompt templates. Each entry has a `system` role string, a
# default `instruction`, and a one-line `description`. Stored in an environment
# so register_prompt() can extend it at runtime.
.prompt_registry <- new.env(parent = emptyenv())

.register_default_prompts <- function() {
  defaults <- list(
    key_findings = list(
      description = "3-5 bullet points of the most important findings.",
      system = paste(
        "You are a meticulous survey research analyst.",
        "You write tight, neutral, decision-useful summaries for a business",
        "audience. You never invent numbers and only describe what the data",
        "shows."
      ),
      instruction = paste(
        "Summarise the most important findings from the table below in 3-5",
        "concise bullet points. Lead with the headline number in each bullet.",
        "Do not speculate beyond the data."
      )
    ),
    exec_summary = list(
      description = "A short executive-summary paragraph.",
      system = paste(
        "You are a research director writing for senior stakeholders.",
        "You are concise, plain-spoken and never overstate the evidence."
      ),
      instruction = paste(
        "Write a single executive-summary paragraph (3-4 sentences) capturing",
        "what this table means for the business. Quote only figures present in",
        "the data."
      )
    ),
    drivers_barriers = list(
      description = "Split findings into drivers and barriers.",
      system = paste(
        "You are a survey analyst specialising in NPS and satisfaction drivers."
      ),
      instruction = paste(
        "From the importance/performance (or rating) table below, list the top",
        "drivers (high importance, strong performance) and the key barriers",
        "(high importance, weak performance) as two short bullet lists titled",
        "'Drivers' and 'Barriers'."
      )
    ),
    slide_title = list(
      description = "A punchy slide title summarising the table.",
      system = "You write punchy, accurate presentation slide titles.",
      instruction = paste(
        "Write one short, specific slide title (max 12 words) that captures the",
        "single most important takeaway from the table. Return only the title."
      )
    )
  )
  for (nm in names(defaults)) {
    assign(nm, defaults[[nm]], envir = .prompt_registry)
  }
}

#' List available prompt templates
#'
#' @return A [tibble][tibble::tibble] with `name` and `description` for every
#'   registered prompt template (built-in plus any you have registered).
#' @family ai
#' @seealso [get_prompt()], [register_prompt()], [ai_summarise()].
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
#' get_prompt("key_findings")
#' @export
get_prompt <- function(name) {
  if (!exists(name, envir = .prompt_registry, inherits = FALSE)) {
    stop("Unknown prompt template '", name, "'. See list_prompts().",
         call. = FALSE)
  }
  get(name, envir = .prompt_registry, inherits = FALSE)
}

#' Register a custom prompt template
#'
#' Adds (or overwrites) a reusable prompt template that [ai_summarise()] and
#' [ai_report_sections()] can refer to by name.
#'
#' @param name Template name.
#' @param system The system-role instruction defining the assistant's behaviour.
#' @param instruction The default task instruction prepended to the data.
#' @param description One-line description shown by [list_prompts()].
#'
#' @return Invisibly the template name.
#' @family ai
#' @seealso [list_prompts()].
#' @examples
#' register_prompt(
#'   "risks",
#'   system = "You are a cautious risk analyst.",
#'   instruction = "List the top risks implied by this table.",
#'   description = "Top risks implied by the data."
#' )
#' @export
register_prompt <- function(name, system, instruction, description = "") {
  assign(name,
         list(system = system, instruction = instruction,
              description = description),
         envir = .prompt_registry)
  invisible(name)
}

# Internal: render a data frame compactly for inclusion in a prompt.
format_table_for_llm <- function(data, max_rows = 50) {
  d <- as.data.frame(data)
  more <- nrow(d) - max_rows
  if (more > 0) d <- utils::head(d, max_rows)
  txt <- paste(utils::capture.output(print(d, row.names = FALSE)),
               collapse = "\n")
  if (more > 0) {
    txt <- paste0(txt, "\n... (", more, " more rows omitted)")
  }
  txt
}

# Internal: assemble the user-message text from a template + data + extra
# instructions.
build_prompt <- function(template, data, instructions = NULL, max_rows = 50,
                         title = NULL) {
  spec <- get_prompt(template)
  parts <- c(
    spec$instruction,
    if (!is.null(instructions)) paste0("Additional instructions: ", instructions),
    if (!is.null(title)) paste0("Context: this table is titled '", title, "'."),
    "",
    "Data:",
    format_table_for_llm(data, max_rows = max_rows)
  )
  paste(parts, collapse = "\n")
}
