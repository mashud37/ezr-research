# Built-in exercise generators. Each is a function(difficulty) that uses the RNG
# (seeded by draw_exercise()) to produce one randomised but reproducible
# `ezrlearning_exercise`, grounded in a real ezr function whose output is used as
# the reference answer. Registered with metadata in bank.R.

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- shared helpers ------------------------------------------------------

# A seeded random subsample of the teaching dataset (so counts vary by draw).
tp_sample <- function(n = NULL) {
  d <- theme_park
  n <- n %||% sample(160:300, 1)
  d[sort(sample(nrow(d), min(n, nrow(d)))), , drop = FALSE]
}

# Recode the worded rating items to a tidy numeric modelling frame.
parks_numeric <- function(d) {
  rc <- grep("^rating_", names(d), value = TRUE)
  out <- tibble::tibble(nps = as.numeric(d$nps))
  for (cc in rc) out[[sub("^rating_", "", cc)]] <- ezrsurvey::recode_likert(d[[cc]])
  out
}

# Run an NSE ezr verb with a dynamic column, without bare column symbols in
# source (keeps R CMD check quiet and the answer exact).
nps_of <- function(d, col = "nps") {
  eval(bquote(ezrsurvey::calc_nps(d, .(as.name(col)))))
}
nps_by <- function(d, col, by) {
  eval(bquote(ezrsurvey::calc_nps(d, .(as.name(col)), by = .(as.name(by)))))
}
pct_of <- function(d, col, by = NULL) {
  if (is.null(by)) eval(bquote(ezrsurvey::calc_percentage(d, .(as.name(col)))))
  else eval(bquote(ezrsurvey::calc_percentage(d, .(as.name(col)),
                                              by = .(as.name(by)))))
}

# Plausible wrong numbers near a correct integer/number.
num_distractors <- function(correct, k = 3, spread = NULL) {
  spread <- spread %||% max(2L, round(abs(correct) * 0.15) + 1L)
  pool <- correct + c(-1, 1) * rep(seq_len(spread * 3), each = 2)
  pool <- unique(pool[pool != correct])
  if (length(pool) < k) pool <- unique(c(pool, correct + seq_len(k * 2)))
  sample(pool, k)
}

# Build a multiple-choice exercise: shuffle correct + distractors, set the letter.
make_mcq <- function(id, chapter, topic, prompt, correct, distractors,
                     difficulty, explanation = NA, hint = NA, data = NULL,
                     data_name = "theme_park", source = "bank") {
  opts <- c(correct, distractors)
  ord <- sample(length(opts))
  opts <- opts[ord]
  # `correct` was index 1 before shuffling; find where it landed.
  answer <- LETTERS[which(ord == 1)]
  new_exercise(id = id, type = "mcq", prompt = prompt, chapter = chapter,
               topic = topic, difficulty = difficulty, data = data,
               data_name = data_name, options = as.character(opts),
               answer = answer, explanation = explanation, hint = hint,
               seed = NA, source = source)
}

# Build a code exercise.
make_code <- function(id, chapter, topic, prompt, solution_code,
                      solution_value = NULL, check = NULL, difficulty,
                      explanation = NA, hint = NA, data = NULL,
                      data_name = "theme_park", source = "bank") {
  new_exercise(id = id, type = "code", prompt = prompt, chapter = chapter,
               topic = topic, difficulty = difficulty, data = data,
               data_name = data_name, solution_code = solution_code,
               solution_value = solution_value, check = check,
               explanation = explanation, hint = hint, source = source)
}

# ---- chapter 2: the ezr way ----------------------------------------------

gen_percentage_mcq <- function(difficulty = "easy") {
  d <- tp_sample()
  col <- sample(c("region", "visitor_type", "gender"), 1)
  tab <- pct_of(d, col)
  i <- sample(nrow(tab), 1)
  lvl <- tab[[col]][i]; correct <- tab$pct[i]
  make_mcq(
    "percentage_mcq", 2, "percentage",
    prompt = sprintf(
      "In the sample below (n = %d), what percentage of respondents have %s = '%s'? (rounded, as calc_percentage() reports it)",
      nrow(d), col, lvl),
    correct = paste0(correct, "%"),
    distractors = paste0(num_distractors(correct), "%"),
    difficulty = difficulty, data = d,
    explanation = sprintf(
      "calc_percentage(theme_park, %s) gives the share of each level; '%s' is %d%%.",
      col, lvl, correct),
    hint = "Use calc_percentage(theme_park, <column>) and read off the pct column.")
}

gen_percentage_code <- function(difficulty = "easy") {
  d <- tp_sample()
  col <- sample(c("region", "visitor_type", "gender"), 1)
  make_code(
    "percentage_code", 2, "percentage",
    prompt = sprintf(
      "For the data below, write one line of ezr code that returns the percentage breakdown of '%s'.",
      col),
    solution_code = sprintf("calc_percentage(theme_park, %s)", col),
    solution_value = pct_of(d, col), difficulty = difficulty, data = d,
    explanation = "calc_percentage() replaces count() + mutate(): it returns n and pct per level.",
    hint = sprintf("It is a single call: calc_percentage(theme_park, %s).", col))
}

gen_nps_mcq <- function(difficulty = "easy") {
  d <- tp_sample()
  correct <- nps_of(d, "nps")$nps
  make_mcq(
    "nps_mcq", 2, "nps",
    prompt = sprintf("For the sample below (n = %d), what is the overall NPS of the 'nps' column?",
                     nrow(d)),
    correct = as.character(correct),
    distractors = as.character(num_distractors(correct, spread = 6)),
    difficulty = difficulty, data = d,
    explanation = "calc_nps() returns promoters (9-10) minus detractors (0-6) as a percentage.",
    hint = "calc_nps(theme_park, nps) returns n and the nps score.")
}

gen_nps_code <- function(difficulty = "easy") {
  d <- tp_sample()
  by <- sample(c("region", "visitor_type"), 1)
  make_code(
    "nps_code", 2, "nps",
    prompt = sprintf("Write ezr code that returns the NPS of the 'nps' column broken down by %s.",
                     by),
    solution_code = sprintf("calc_nps(theme_park, nps, by = %s)", by),
    solution_value = nps_by(d, "nps", by), difficulty = difficulty, data = d,
    explanation = "Adding by = <column> to calc_nps() returns one NPS per group.",
    hint = sprintf("calc_nps(theme_park, nps, by = %s).", by))
}

gen_crosstab_code <- function(difficulty = "medium") {
  d <- tp_sample()
  make_code(
    "crosstab_code", 2, "crosstab",
    prompt = "Write ezr code for a count crosstab of visitor_type (rows) by region (columns).",
    solution_code = "crosstab(theme_park, visitor_type, region)",
    solution_value = ezrsurvey::crosstab(d, visitor_type, region),
    difficulty = difficulty, data = d,
    explanation = "crosstab() builds a wide contingency table in one call; cell = 'count' is the default.",
    hint = "crosstab(theme_park, visitor_type, region).")
}

gen_pivot_mcq <- function(difficulty = "easy") {
  make_mcq(
    "pivot_mcq", 2, "reshape",
    prompt = "Which tidyverse function reshapes data from wide format to long format?",
    correct = "pivot_longer()",
    distractors = c("pivot_wider()", "spread()", "gather()"),
    difficulty = difficulty,
    explanation = "pivot_longer() lengthens (wide -> long); pivot_wider() does the reverse. spread()/gather() are the retired predecessors.",
    hint = "Long format = more rows, fewer columns.", data = NULL)
}

# ---- chapter 3: data and graphs ------------------------------------------

gen_clean_likert_mcq <- function(difficulty = "easy") {
  make_mcq(
    "clean_likert_mcq", 3, "cleaning",
    prompt = "The rating_ columns hold worded answers like 'Very good'. Which ezr function turns a worded 5-point Likert vector into the numbers 1-5?",
    correct = "recode_likert()",
    distractors = c("ensure_numeric()", "nps_group()", "recode_age()"),
    difficulty = difficulty,
    explanation = "recode_likert() maps 'Very bad'..'Very good' to 1..5. ensure_numeric() only salvages digits already in the text.",
    hint = "It is named after the kind of scale it cleans.", data = NULL)
}

gen_clean_likert_code <- function(difficulty = "easy") {
  d <- tp_sample()
  col <- sample(grep("^rating_", names(d), value = TRUE), 1)
  make_code(
    "clean_likert_code", 3, "cleaning",
    prompt = sprintf("The column %s holds worded ratings. Write ezr code that converts theme_park$%s to the numbers 1-5.",
                     col, col),
    solution_code = sprintf("recode_likert(theme_park$%s)", col),
    solution_value = ezrsurvey::recode_likert(d[[col]]),
    difficulty = difficulty, data = d,
    explanation = "recode_likert() returns an integer vector on the 1-5 scale, ready to average or model.",
    hint = sprintf("recode_likert(theme_park$%s).", col))
}

gen_generation_mcq <- function(difficulty = "medium") {
  d <- tp_sample()
  gens <- ezrsurvey::recode_generation(d$age, input = "age")
  i <- sample(which(!is.na(gens)), 1)
  age_i <- d$age[i]; correct <- as.character(gens[i])
  pool <- setdiff(unique(as.character(gens[!is.na(gens)])), correct)
  make_mcq(
    "generation_mcq", 3, "generations",
    prompt = sprintf("Using recode_generation(), which generation does a %d-year-old respondent fall into?",
                     age_i),
    correct = correct,
    distractors = sample(pool, min(3, length(pool))),
    difficulty = difficulty,
    explanation = "recode_generation(age, input = 'age') maps each age to its birth cohort.",
    hint = "recode_generation(theme_park$age, input = 'age').", data = NULL)
}

gen_importance_code <- function(difficulty = "medium") {
  d <- tp_sample()
  make_code(
    "importance_code", 3, "importance",
    prompt = "Write ezr code that builds the importance-vs-performance table of the rating_ items against the 'nps' outcome.",
    solution_code = "ipm_model(theme_park, nps, \"rating_\")",
    solution_value = ezrsurvey::ipm_model(d, nps, "rating_"),
    difficulty = difficulty, data = d,
    explanation = "ipm_model() correlates each rating with the outcome (importance) and averages it (performance) -- the basis of the BAD/OK/GOOD chart.",
    hint = "ipm_model(theme_park, nps, \"rating_\").")
}

# ---- chapter 4: finding patterns -----------------------------------------

gen_drivers_mcq <- function(difficulty = "medium") {
  d <- tp_sample(300)
  parks <- parks_numeric(d)
  dr <- ezrmodel::drivers(parks, nps, methods = c("cor", "lm"))
  top <- dr$consensus$variable[1]
  pool <- setdiff(names(parks)[-1], top)
  make_mcq(
    "drivers_mcq", 4, "drivers",
    prompt = "Using drivers() on the numeric ratings table `parks`, which rating is the STRONGEST consensus driver of nps?",
    correct = top,
    distractors = sample(pool, min(3, length(pool))),
    difficulty = difficulty, data = parks, data_name = "parks",
    explanation = "drivers() ranks predictors by a consensus of several importance methods; the top of consensus is the strongest driver.",
    hint = "drivers(parks, nps) then look at the top of the consensus table.")
}

gen_correlations_code <- function(difficulty = "medium") {
  d <- tp_sample(300)
  parks <- parks_numeric(d)
  make_code(
    "correlations_code", 4, "correlations",
    prompt = "Using the numeric ratings table `parks`, write ezr code that returns the correlations of every predictor with the target nps.",
    solution_code = "correlations(parks, nps)",
    check = function(val, data) inherits(val, "ezrmodel_cor"),
    difficulty = difficulty, data = parks, data_name = "parks",
    explanation = "correlations(data, target) returns a tidy, target-focused correlation ranking.",
    hint = "correlations(parks, nps).")
}

gen_modelselect_mcq <- function(difficulty = "hard") {
  make_mcq(
    "modelselect_mcq", 4, "regression",
    prompt = "In model_select(), which method shrinks weak predictors' coefficients all the way to zero (dropping them)?",
    correct = "\"lasso\"",
    distractors = c("\"ridge\"", "\"stepwise\"", "\"elastic\" with alpha = 0"),
    difficulty = difficulty,
    explanation = "Lasso (L1) penalisation zeroes out weak coefficients; ridge (L2) only shrinks them.",
    hint = "One of these performs genuine variable selection.", data = NULL)
}

# ---- chapter 5: segments and structure -----------------------------------

gen_cluster_mcq <- function(difficulty = "medium") {
  make_mcq(
    "cluster_mcq", 5, "clustering",
    prompt = "When you call cluster() with k = NULL, which diagnostic does it use to choose the number of clusters automatically?",
    correct = "average silhouette width",
    distractors = c("the p-value of a t-test", "Cronbach's alpha",
                    "the adjusted R-squared"),
    difficulty = difficulty,
    explanation = "cluster() scans candidate k and keeps the one with the highest average silhouette width.",
    hint = "It is a cluster-separation measure, not a regression statistic.", data = NULL)
}

gen_reliability_code <- function(difficulty = "hard") {
  d <- tp_sample(300)
  parks <- parks_numeric(d)
  items <- names(parks)[-1]
  alpha <- round(ezrmodel::reliability(parks, items = dplyr::all_of(items))$alpha, 2)
  make_code(
    "reliability_code", 5, "reliability",
    prompt = "Using the numeric ratings table `parks`, write ezr code that returns Cronbach's alpha for the rating items, rounded to 2 decimals.",
    solution_code = sprintf("round(reliability(parks, c(%s))$alpha, 2)",
                            paste0('"', items, '"', collapse = ", ")),
    solution_value = alpha, difficulty = difficulty, data = parks,
    data_name = "parks",
    explanation = "reliability() returns an object whose $alpha is Cronbach's alpha; >= 0.8 is good.",
    hint = "reliability(parks, c(\"rides\", \"food\", ...))$alpha, then round().")
}

# ---- chapter 6: text -----------------------------------------------------

gen_text_mcq <- function(difficulty = "medium") {
  make_mcq(
    "text_mcq", 6, "text",
    prompt = "Which ezr function gives you, per group, the words that are most distinctive to that group (tf-idf)?",
    correct = "term_freq(data, text, by = group)",
    distractors = c("tokenize_text(data, text)", "topics(data, text)",
                    "summarise_text(data, text)"),
    difficulty = difficulty,
    explanation = "term_freq() with a `by` grouping weights terms by tf-idf, surfacing each group's distinctive words.",
    hint = "tf-idf needs a grouping to compare against.", data = NULL)
}

gen_text_code <- function(difficulty = "easy") {
  d <- tp_sample()
  make_code(
    "text_code", 6, "text",
    prompt = "Write ezr code that counts the terms in the free-text 'comment' column of the data below.",
    solution_code = "term_freq(theme_park, comment)",
    solution_value = ezrmodel::term_freq(d, comment),
    difficulty = difficulty, data = d,
    explanation = "term_freq() tokenises and counts; with no `by` you get plain term counts.",
    hint = "term_freq(theme_park, comment).")
}

# ---- chapter 7: automation and reporting ---------------------------------

gen_export_mcq <- function(difficulty = "easy") {
  make_mcq(
    "export_mcq", 7, "reporting",
    prompt = "Which ezr function writes several result tables to one Excel workbook, each on its own tab?",
    correct = "export_xlsx()",
    distractors = c("save_data()", "save_plot()", "write.csv()"),
    difficulty = difficulty,
    explanation = "export_xlsx(tab1 = ..., tab2 = ..., path = ...) puts each named table on its own worksheet.",
    hint = "Think 'one workbook, many tabs'.", data = NULL)
}
