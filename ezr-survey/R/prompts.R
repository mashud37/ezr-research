# Mutable registry of prompt templates. Each entry has a `system` role string,
# a default `instruction`, an optional `output_contract` (a hard requirement on
# the shape of the answer), and a one-line `description`. Stored in an
# environment so register_prompt() can extend it at runtime.
.prompt_registry <- new.env(parent = emptyenv())

# Shared ground rules appended to every built-in system prompt. They encode the
# analyst discipline the templates rely on: no invented numbers, no
# overstatement, explicit uncertainty.
.prompt_ground_rules <- paste(
  "Ground rules you never break:",
  "(1) Quote only numbers that appear in the data provided; never estimate,",
  "extrapolate or invent figures.",
  "(2) When survey context gives a sample size or margin of error, treat",
  "differences smaller than the margin of error as noise and say so.",
  "(3) Name the base (who was asked, how many) when it is available and",
  "relevant.",
  "(4) Prefer plain business language over research jargon; write for a",
  "reader who will act on the findings, not audit them.",
  "(5) No filler, no throat-clearing, no restating the task."
)

.register_default_prompts <- function() {
  defaults <- list(
    key_findings = list(
      description = "3-5 bullet points of the most important findings.",
      system = paste(
        "You are a senior survey research analyst preparing findings for a",
        "business audience. You are rigorous about what the data does and does",
        "not show, and you write tight, decision-useful prose.",
        .prompt_ground_rules
      ),
      instruction = paste(
        "Summarise the most important findings from the data below in 3-5",
        "bullet points. Lead each bullet with its headline number, then say",
        "in the same sentence why it matters. Order bullets by importance to",
        "a decision-maker, not by row order. If two categories are close,",
        "describe them as comparable rather than ranking them. Do not",
        "speculate beyond the data."
      ),
      output_contract = paste(
        "Markdown bullets ('- '), 3-5 of them, one sentence each,",
        "no heading, no preamble."
      )
    ),
    exec_summary = list(
      description = "A short executive-summary paragraph.",
      system = paste(
        "You are a research director writing directly for senior",
        "stakeholders. You are concise and plain-spoken, you translate data",
        "into business meaning, and you never overstate the evidence.",
        .prompt_ground_rules
      ),
      instruction = paste(
        "Write a single executive-summary paragraph (4-6 sentences)",
        "capturing what this data means for the business. Open with the",
        "single most important number and its implication. Then cover the",
        "one or two secondary findings that change what the reader should",
        "do, and close with the main caveat or open question the data",
        "leaves. Quote only figures present in the data."
      ),
      output_contract = "One paragraph of plain prose. No bullets, no heading."
    ),
    drivers_barriers = list(
      description = "Split findings into drivers and barriers.",
      system = paste(
        "You are a survey analyst specialising in satisfaction and NPS",
        "driver analysis. You reason explicitly in terms of the",
        "importance-performance quadrant logic: importance says how much a",
        "feature moves the outcome, performance says how well it is",
        "delivered today.",
        .prompt_ground_rules
      ),
      instruction = paste(
        "From the importance/performance (or rating) data below, identify",
        "the drivers (high importance delivered well - protect these) and",
        "the barriers (high importance delivered poorly - fix these first).",
        "Within each list, order by importance. Ignore low-importance",
        "features unless one is so weak it poses a risk, and say so if you",
        "include it. For each entry give the figures that place it in its",
        "quadrant."
      ),
      output_contract = paste(
        "Two markdown sections titled 'Drivers' and 'Barriers', each with",
        "2-4 bullets. Nothing else."
      )
    ),
    slide_title = list(
      description = "A punchy slide title summarising the table.",
      system = paste(
        "You write headline-style presentation slide titles for research",
        "decks: the title states the takeaway (a so-what), not the topic.",
        "'Price sensitivity is concentrated among new customers' is a",
        "title; 'Price sensitivity results' is not.",
        .prompt_ground_rules
      ),
      instruction = paste(
        "Write one slide title (maximum 12 words) stating the single most",
        "important takeaway from the data below. Include the key figure",
        "only if it strengthens the message."
      ),
      output_contract = paste(
        "Plain text, one line, max 12 words, no quotation marks,",
        "no trailing period."
      )
    ),
    slide_bullets = list(
      description = "3-4 short takeaway bullets for a slide body.",
      system = paste(
        "You write the takeaway bullets that sit beside a chart on a",
        "presentation slide. Each bullet is a self-contained finding a",
        "presenter can say out loud; together they tell the audience what",
        "to conclude from the chart.",
        .prompt_ground_rules
      ),
      instruction = paste(
        "Write 3-4 takeaway bullets for a slide showing the data below.",
        "Maximum 12 words per bullet. Lead with the strongest finding.",
        "Include a number in a bullet only when it carries the point."
      ),
      output_contract = paste(
        "Markdown bullets ('- ') only, 3-4 lines, max 12 words each,",
        "no heading, no nesting."
      )
    ),
    thematic_analysis = list(
      description = "Named themes with illustrative quotes from open comments.",
      system = paste(
        "You are a qualitative researcher analysing open-text survey",
        "comments. You surface recurring themes, name them precisely, and",
        "always distinguish an illustrative quote from a measured",
        "frequency: a sample of comments shows what people say, not how",
        "many say it.",
        .prompt_ground_rules
      ),
      instruction = paste(
        "Identify the 3-6 clearest themes in the comments below. For each",
        "theme give: a short name (2-5 words), one sentence describing it,",
        "and one short verbatim quote (trimmed with '...' where needed)",
        "that illustrates it. Note any striking minority view separately.",
        "Close with a one-line caveat that these comments are an",
        "illustrative sample, not a count of how widely each theme is held."
      ),
      output_contract = paste(
        "One markdown bold heading per theme ('**Theme name**'), followed",
        "by its description sentence and the quote in italics, then the",
        "final caveat line."
      )
    ),
    segment_comparison = list(
      description = "The decision-relevant differences between segments.",
      system = paste(
        "You are a survey analyst comparing respondent segments. You know",
        "that most segment differences are noise: your craft is picking the",
        "few gaps large and reliable enough to act on, and being explicit",
        "when a gap is within the margin of error or based on a small",
        "segment.",
        .prompt_ground_rules
      ),
      instruction = paste(
        "The data below is broken down by segment. Identify the 3-5 most",
        "decision-relevant differences between segments, largest and most",
        "reliable first. For each, name the segments, quote the figures on",
        "both sides, and state the implication in the same bullet. Flag any",
        "comparison that rests on a small base or falls within the margin",
        "of error, and say if the segments broadly agree."
      ),
      output_contract = paste(
        "Markdown bullets ('- '), 3-5 of them, one comparison per bullet."
      )
    ),
    methodology = list(
      description = "Plain-language methodology and limitations passage.",
      system = paste(
        "You write the methodology and limitations section of survey",
        "reports for non-technical readers. You translate statistical",
        "diagnostics (sample sizes, standard errors, margins of error,",
        "relative standard errors) into what a reader may and may not",
        "conclude, without hedging everything into mush.",
        .prompt_ground_rules
      ),
      instruction = paste(
        "From the precision diagnostics below, write a short methodology",
        "and limitations passage (one or two paragraphs) for a report",
        "appendix. State the sample size and what margin of error it",
        "implies, name which reported measures are precise and which are",
        "indicative only, and give the reader one clear rule of thumb for",
        "reading small differences in this report."
      ),
      output_contract = "1-2 paragraphs of plain prose. No bullets."
    ),
    full_report = list(
      description = "A connected multi-section narrative from several tables.",
      system = paste(
        "You are a research director drafting the narrative of a survey",
        "report. You connect individual results into one storyline: what",
        "was asked, what stands out, what it means, what to do. Sections",
        "flow into each other rather than standing as isolated summaries.",
        .prompt_ground_rules
      ),
      instruction = paste(
        "Draft a connected report narrative from the data below. Open with",
        "a 3-4 sentence executive summary of the whole story. Then write",
        "one titled section per distinct topic in the data, each 2-4",
        "sentences anchored on its figures. Close with an implications",
        "section of 2-3 recommended actions that follow directly from the",
        "findings."
      ),
      output_contract = paste(
        "Markdown: '## Executive summary', then one '## <topic>' section",
        "per topic, ending with '## Implications'."
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
#' @return A list with `system`, `instruction`, `description` and (possibly
#'   `NULL`) `output_contract`.
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
#' @param output_contract Optional hard requirement on the shape of the answer
#'   (e.g. "Markdown bullets only"), appended to every prompt built from this
#'   template.
#'
#' @return Invisibly the template name.
#' @family ai
#' @seealso [list_prompts()].
#' @examples
#' register_prompt(
#'   "risks",
#'   system = "You are a cautious risk analyst.",
#'   instruction = "List the top risks implied by this table.",
#'   description = "Top risks implied by the data.",
#'   output_contract = "Markdown bullets, most severe first."
#' )
#' @export
register_prompt <- function(name, system, instruction, description = "",
                            output_contract = NULL) {
  assign(name,
         list(system = system, instruction = instruction,
              description = description, output_contract = output_contract),
         envir = .prompt_registry)
  invisible(name)
}

# Internal: render a data frame as a GitHub-style markdown pipe table --
# unambiguous for the model and cheap in tokens, unlike print() output.
format_table_for_llm <- function(data, max_rows = 50) {
  d <- as.data.frame(data)
  more <- nrow(d) - max_rows
  if (more > 0) d <- utils::head(d, max_rows)

  is_num <- vapply(d, is.numeric, logical(1))
  cells <- lapply(d, function(col) {
    out <- if (is.numeric(col)) {
      format(col, trim = TRUE, scientific = FALSE)
    } else {
      as.character(col)
    }
    out[is.na(col)] <- ""
    gsub("|", "/", out, fixed = TRUE)
  })

  header <- paste0("| ", paste(names(d), collapse = " | "), " |")
  sep <- paste0("|", paste(ifelse(is_num, " ---: ", " --- "), collapse = "|"),
                "|")
  rows <- if (nrow(d)) {
    apply(do.call(cbind, cells), 1L,
          function(r) paste0("| ", paste(r, collapse = " | "), " |"))
  } else {
    character(0)
  }

  txt <- paste(c(header, sep, rows), collapse = "\n")
  if (more > 0) {
    txt <- paste0(txt, "\n... (", more, " more rows omitted)")
  }
  txt
}

#' Describe the survey behind a table for AI summaries
#'
#' Bundles the survey facts a good analyst would want next to any table --
#' sample size, question wording, base, precision -- so [ai_summarise()] and
#' [report_deck()] can pass them to the model. With the raw survey `data`, the
#' sample size and precision bullets are derived for you.
#'
#' @param data Optional raw survey data (one row per respondent). Used only to
#'   derive `n` and, via [precision_summary()], the precision notes; the rows
#'   themselves are never sent to a provider.
#' @param n Sample size. Derived from `data` when omitted.
#' @param question The verbatim question wording behind the table(s).
#' @param base Who was asked, e.g. `"All respondents"` or
#'   `"Detractors only (n = 142)"`.
#' @param precision Character vector of precision notes. Derived from `data`
#'   via [precision_summary()] when omitted and `data` is given.
#' @param fieldwork Fieldwork description, e.g. `"12-19 May 2026, online panel"`.
#' @param notes Any further context worth giving the model.
#'
#' @return An `ezrsurvey_ai_context` list.
#'
#' @details
#' Context is what turns a generic summary into an analyst's summary: with a
#' sample size and margin of error present, the built-in templates flag
#' differences within the margin of error instead of narrating noise, and cite
#' the base alongside findings. Reuse one context object across every
#' [ai_summarise()] call and [report_deck()] build for the same survey.
#'
#' @family ai
#' @seealso [ai_summarise()], [ai_report_sections()], [precision_summary()].
#' @examples
#' ctx <- ai_context(
#'   podracing_survey,
#'   question = "How likely are you to recommend pod racing?",
#'   fieldwork = "Simulated data"
#' )
#' ctx
#' @export
ai_context <- function(data = NULL, n = NULL, question = NULL, base = NULL,
                       precision = NULL, fieldwork = NULL, notes = NULL) {
  if (!is.null(data)) {
    n <- n %||% nrow(data)
    if (is.null(precision)) {
      precision <- tryCatch(precision_summary(data)$bullets,
                            error = function(e) NULL)
    }
  }
  structure(
    list(n = n, question = question, base = base, precision = precision,
         fieldwork = fieldwork, notes = notes),
    class = "ezrsurvey_ai_context"
  )
}

#' @export
print.ezrsurvey_ai_context <- function(x, ...) {
  cat("Survey context for AI summaries\n")
  cat(format_context_for_llm(x), "\n", sep = "")
  invisible(x)
}

# Internal: render an ai_context() (or a plain string) as the prompt's
# "Survey context" block.
format_context_for_llm <- function(context) {
  if (is.character(context)) {
    return(paste0("Survey context:\n", paste(context, collapse = "\n")))
  }
  lines <- c(
    if (!is.null(context$n)) paste0("- Sample size: n = ", context$n),
    if (!is.null(context$question)) {
      paste0("- Question asked: ", context$question)
    },
    if (!is.null(context$base)) paste0("- Base: ", context$base),
    if (!is.null(context$fieldwork)) {
      paste0("- Fieldwork: ", context$fieldwork)
    },
    if (!is.null(context$precision)) {
      paste0("- Precision: ", context$precision)
    },
    if (!is.null(context$notes)) paste0("- Notes: ", context$notes)
  )
  if (!length(lines)) return(NULL)
  paste0("Survey context:\n", paste(lines, collapse = "\n"))
}

# Internal: assemble the user-message text from a template + data + optional
# extra instructions, context and title.
build_prompt <- function(template, data, instructions = NULL, max_rows = 50,
                         title = NULL, context = NULL) {
  spec <- get_prompt(template)
  ctx_block <- if (!is.null(context)) format_context_for_llm(context)
  parts <- c(
    spec$instruction,
    if (!is.null(instructions)) paste0("Additional instructions: ", instructions),
    if (!is.null(spec$output_contract)) {
      paste0("Required output format: ", spec$output_contract)
    },
    if (!is.null(title)) paste0("Context: this table is titled '", title, "'."),
    if (!is.null(ctx_block)) c("", ctx_block),
    "",
    "Data:",
    format_table_for_llm(data, max_rows = max_rows)
  )
  paste(parts, collapse = "\n")
}
