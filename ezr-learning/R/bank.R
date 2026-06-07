# Registry of built-in exercise generators. Each entry: meta (id, chapter,
# topic, type, difficulty, title) + fn(difficulty) -> ezrlearning_exercise.
.generator_registry <- new.env(parent = emptyenv())

# Internal: run an expression with a temporary RNG seed, restoring state after.
with_seed <- function(seed, expr) {
  if (exists(".Random.seed", envir = globalenv())) {
    old <- get(".Random.seed", envir = globalenv())
    on.exit(assign(".Random.seed", old, envir = globalenv()), add = TRUE)
  }
  set.seed(seed)
  expr
}

register_generator <- function(id, chapter, topic, type, difficulty, title, fn,
                               needs = character(0)) {
  assign(id, list(meta = list(id = id, chapter = chapter, topic = topic,
                              type = type, difficulty = difficulty,
                              title = title, needs = needs),
                  fn = fn),
         envir = .generator_registry)
  invisible(id)
}

# Internal: are a generator's optional packages installed?
generator_available <- function(meta) {
  needs <- meta$needs %||% character(0)
  length(needs) == 0L ||
    all(vapply(needs, requireNamespace, logical(1), quietly = TRUE))
}

.register_generators <- function() {
  g <- function(...) register_generator(...)
  g("percentage_mcq", 2, "percentage", "mcq", "easy",
    "Read a percentage off calc_percentage()", gen_percentage_mcq)
  g("percentage_code", 2, "percentage", "code", "easy",
    "Write calc_percentage()", gen_percentage_code)
  g("nps_mcq", 2, "nps", "mcq", "easy", "Read an NPS off calc_nps()", gen_nps_mcq)
  g("nps_code", 2, "nps", "code", "easy", "Write calc_nps() by group", gen_nps_code)
  g("crosstab_code", 2, "crosstab", "code", "medium", "Write a crosstab()",
    gen_crosstab_code)
  g("pivot_mcq", 2, "reshape", "mcq", "easy", "wide vs long reshaping",
    gen_pivot_mcq)
  g("clean_likert_mcq", 3, "cleaning", "mcq", "easy",
    "Pick the Likert cleaner", gen_clean_likert_mcq)
  g("clean_likert_code", 3, "cleaning", "code", "easy",
    "Write recode_likert()", gen_clean_likert_code)
  g("generation_mcq", 3, "generations", "mcq", "medium",
    "Age -> generation", gen_generation_mcq)
  g("importance_code", 3, "importance", "code", "medium",
    "Write ipm_model()", gen_importance_code, needs = "rwa")
  g("drivers_mcq", 4, "drivers", "mcq", "medium",
    "Read the top driver off drivers()", gen_drivers_mcq)
  g("correlations_code", 4, "correlations", "code", "medium",
    "Write correlations()", gen_correlations_code)
  g("modelselect_mcq", 4, "regression", "mcq", "hard",
    "lasso vs ridge selection", gen_modelselect_mcq)
  g("cluster_mcq", 5, "clustering", "mcq", "medium",
    "How cluster() chooses k", gen_cluster_mcq)
  g("reliability_code", 5, "reliability", "code", "hard",
    "Write reliability()", gen_reliability_code, needs = "psych")
  g("text_mcq", 6, "text", "mcq", "medium", "Which text verb?", gen_text_mcq)
  g("text_code", 6, "text", "code", "easy", "Write term_freq()", gen_text_code)
  g("export_mcq", 7, "reporting", "mcq", "easy", "export_xlsx() for tabs",
    gen_export_mcq)
}

# Internal: all generator metas as a list.
generator_metas <- function() {
  ids <- ls(envir = .generator_registry)
  lapply(ids, function(i) get(i, envir = .generator_registry)$meta)
}

#' The catalogue of built-in exercises
#'
#' Lists every built-in exercise generator with its chapter, topic, type and
#' difficulty -- the menu [draw_exercise()] and [quiz()] draw from.
#'
#' @return A [tibble][tibble::tibble] with one row per generator: `id`,
#'   `chapter`, `topic`, `type` (`"mcq"`/`"code"`), `difficulty` and a short
#'   `title`.
#'
#' @details
#' Each row is a *template*, not a fixed question: drawing it with a different
#' `seed` produces a different concrete instance (different sample, target column
#' or shuffled options). Filter on `topic`/`chapter`/`type`/`difficulty` to scope
#' a practice session, then pass the same filters to [draw_exercise()] or
#' [quiz()].
#'
#' @family bank
#' @seealso [draw_exercise()], [quiz()], [list_topics()].
#' @examples
#' exercise_bank()
#' @export
exercise_bank <- function() {
  metas <- generator_metas()
  tibble::tibble(
    id = vapply(metas, `[[`, character(1), "id"),
    chapter = vapply(metas, `[[`, numeric(1), "chapter"),
    topic = vapply(metas, `[[`, character(1), "topic"),
    type = vapply(metas, `[[`, character(1), "type"),
    difficulty = vapply(metas, `[[`, character(1), "difficulty"),
    title = vapply(metas, `[[`, character(1), "title")
  ) %>% dplyr::arrange(.data$chapter, .data$topic)
}

#' List the practice topics
#'
#' @return A [tibble][tibble::tibble] of `topic`, its `chapter`, and the number
#'   of generators (`n`) behind it.
#' @family bank
#' @seealso [exercise_bank()], [draw_exercise()].
#' @examples
#' list_topics()
#' @export
list_topics <- function() {
  exercise_bank() %>%
    dplyr::group_by(.data$topic, .data$chapter) %>%
    dplyr::summarise(n = dplyr::n(), .groups = "drop") %>%
    dplyr::arrange(.data$chapter, .data$topic)
}

# Internal: filter candidate generators.
filter_candidates <- function(topic, chapter, type, difficulty) {
  metas <- generator_metas()
  keep <- vapply(metas, function(m) {
    (is.null(topic) || m$topic %in% topic) &&
      (is.null(chapter) || m$chapter %in% chapter) &&
      (is.null(type) || m$type %in% type) &&
      (is.null(difficulty) || m$difficulty %in% difficulty) &&
      generator_available(m)
  }, logical(1))
  ids <- vapply(metas, `[[`, character(1), "id")[keep]
  lapply(ids, function(i) get(i, envir = .generator_registry))
}

#' Draw a practice exercise
#'
#' Picks one built-in exercise (optionally filtered by topic, chapter, type or
#' difficulty) and instantiates a randomised version of it. The draw is
#' reproducible: the same `seed` always yields the same exercise, different seeds
#' yield different ones.
#'
#' @param topic Topic(s) to draw from (see [list_topics()]). `NULL` = any.
#' @param chapter Book chapter number(s) to draw from. `NULL` = any.
#' @param type `"mcq"`, `"code"`, or `NULL` for either.
#' @param difficulty `"easy"`, `"medium"`, `"hard"`, or `NULL` for any. Defaults
#'   to the `difficulty` option only as a tie-break when set explicitly; `NULL`
#'   here means "do not filter".
#' @param seed Optional integer. If `NULL`, a random seed is chosen (and stored
#'   on the exercise as `$seed` so you can reproduce it).
#'
#' @return An `ezrlearning_exercise` (with `print()`; answer it with
#'   [check_answer()], get a [hint()] or [reveal()] it).
#'
#' @details
#' Generators are templates: each draw sub-samples the teaching data and varies
#' the target column or option order, so a learner can keep drilling the same
#' topic without memorising one fixed answer. Because the whole draw (which
#' template, and the instance) is seeded, a teacher can hand out
#' `draw_exercise(topic = "nps", seed = 42)` and everyone gets the identical
#' question. The exercise records its `seed`.
#'
#' @family bank
#' @seealso [quiz()], [check_answer()], [exercise_bank()].
#' @examples
#' x <- draw_exercise(topic = "nps", seed = 1)
#' x
#' check_answer(x, "A")
#' @export
draw_exercise <- function(topic = NULL, chapter = NULL, type = NULL,
                          difficulty = NULL, seed = NULL) {
  cands <- filter_candidates(topic, chapter, type, difficulty)
  if (length(cands) == 0L) {
    stop("No exercises match those filters. See exercise_bank().", call. = FALSE)
  }
  seed <- seed %||% ezrlearning_default("seed") %||%
    sample.int(.Machine$integer.max, 1)
  ex <- with_seed(seed, {
    g <- cands[[sample(length(cands), 1)]]
    g$fn(g$meta$difficulty)
  })
  ex$seed <- seed
  ex
}
