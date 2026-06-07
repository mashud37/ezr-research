# ---- stop-words ----------------------------------------------------------
# Mirrors ez-survey: prefer the curated 'stopwords' package, fall back to a
# small built-in list so the tokeniser never hard-fails without it.

.stopwords_fallback <- c(
  "the", "and", "for", "are", "but", "not", "you", "all", "any", "was", "our",
  "has", "have", "had", "with", "from", "they", "this", "that", "their", "them",
  "then", "than", "were", "been", "will", "would", "could", "there", "what",
  "when", "your", "its", "it's", "i'm", "we're", "into", "out", "about", "just",
  "too", "very", "can", "get", "got", "did", "does", "done", "also", "still"
)

# Resolve the stop-word set: a user-supplied vector, FALSE to disable, or
# (default, NULL) the 'stopwords' package when available, else the fallback.
resolve_stopwords <- function(stopwords = NULL) {
  if (isFALSE(stopwords)) return(character(0))
  if (is.character(stopwords)) return(tolower(stopwords))
  if (requireNamespace("stopwords", quietly = TRUE)) {
    return(stopwords::stopwords("en"))
  }
  .stopwords_fallback
}

# Internal: lexical tokeniser (lower-case, drop punctuation / short tokens /
# stop-words). Returns a list of character vectors, one per document.
tokenize_strings <- function(x, stopset = character(0), min_chars = 3) {
  x <- tolower(as.character(x))
  x <- stringr::str_replace_all(x, "[^a-z0-9' ]", " ")
  toks <- stringr::str_split(stringr::str_squish(x), " ")
  lapply(toks, function(t) {
    t <- t[nchar(t) >= min_chars]
    setdiff(t, stopset)
  })
}

#' Tokenise a text column into a tidy term table
#'
#' Turns a free-text column into one row per word, lower-cased and cleaned, with
#' punctuation, very short tokens and stop-words removed. This is the building
#' block the rest of the text helpers ([term_freq()], [topics()]) sit on, but it
#' is useful on its own for a quick word count or to feed your own dplyr summary.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param text The text column (unquoted).
#' @param id Optional document id column (unquoted). If omitted, the row number
#'   is used.
#' @param stopwords Stop-word handling: `NULL` (default) uses the `stopwords`
#'   package when installed (English), otherwise a small built-in fallback; a
#'   character vector supplies your own list; `FALSE` disables removal. Pass e.g.
#'   `stopwords::stopwords("de")` for another language.
#' @param min_chars Drop tokens shorter than this many characters. Default `3`.
#'
#' @return An `ezrmodel_tokens` object wrapping a tidy `tibble` of `doc`/`term`
#'   (plus the id column). Has `print()`, `plot()` (top terms) and `tidy()`
#'   methods.
#'
#' @details
#' Cleaning is deliberately simple and dependency-free: lower-case, strip
#' anything that is not a letter, digit, space or apostrophe, split on
#' whitespace, drop tokens under `min_chars` and remove stop-words. Keep an `id`
#' so you can join term-level results back to respondent attributes (e.g. an NPS
#' group) for downstream analysis.
#'
#' @family text
#' @seealso [term_freq()], [topics()].
#' @examples
#' tk <- tokenize_text(reviews, text, review_id)
#' tk
#' tidy(tk)
#' @export
tokenize_text <- function(data = NULL, text, id = NULL, stopwords = NULL,
                          min_chars = 3) {
  data <- resolve_data(data)
  text_name <- rlang::as_name(rlang::ensym(text))
  if (!text_name %in% names(data)) {
    stop("Text column '", text_name, "' not found in `data`.", call. = FALSE)
  }
  id_q <- rlang::enquo(id)
  if (rlang::quo_is_null(id_q)) {
    id_name <- "doc"
    ids <- as.character(seq_len(nrow(data)))
  } else {
    id_name <- rlang::as_name(rlang::ensym(id))
    ids <- as.character(data[[id_name]])
  }

  txt <- as.character(data[[text_name]])
  keep <- !is.na(txt) & nzchar(stringr::str_squish(txt))
  ids <- ids[keep]
  txt <- txt[keep]

  toks <- tokenize_strings(txt, resolve_stopwords(stopwords), min_chars)
  lens <- vapply(toks, length, integer(1))
  out <- tibble::tibble(
    !!id_name := rep(ids, lens),
    term = unlist(toks, use.names = FALSE)
  )

  structure(
    list(tokens = out, id_col = id_name, text_col = text_name,
         n_docs = length(ids)),
    class = "ezrmodel_tokens"
  )
}

#' @export
print.ezrmodel_tokens <- function(x, ...) {
  tk <- x$tokens
  cat(sprintf("Tokens from '%s'  (%d docs, %d tokens, %d unique terms)\n",
              x$text_col, x$n_docs, nrow(tk), length(unique(tk$term))))
  top <- utils::head(sort(table(tk$term), decreasing = TRUE), 8)
  if (length(top)) {
    cat(paste0("  ", names(top), " (", as.integer(top), ")"), sep = "\n")
  }
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_tokens <- function(x, ...) x$tokens

#' @export
plot.ezrmodel_tokens <- function(x, top = 15, ...) {
  d <- x$tokens %>%
    dplyr::count(.data$term, sort = TRUE) %>%
    utils::head(top)
  d$term <- factor(d$term, levels = rev(d$term))
  ggplot2::ggplot(d, ggplot2::aes(.data$term, .data$n)) +
    ggplot2::geom_col(fill = pal_sequential[4], width = .7) +
    ggplot2::coord_flip() +
    ggplot2::labs(x = "", y = "count", title = "Most frequent terms") +
    theme_ezrmodel_x(transparent = TRUE)
}

#' Term frequencies and tf-idf
#'
#' Counts terms in a text column, optionally *per group*, and (when a grouping
#' is given) weights them by tf-idf so the terms that are distinctive to each
#' group rise to the top -- the everyday "what words set these comments apart?"
#' question.
#'
#' @param data A data frame. If omitted, the session default is used.
#' @param text The text column (unquoted).
#' @param by Optional grouping column (unquoted) -- each group is treated as a
#'   document for tf-idf (e.g. an NPS group, a product, a rating).
#' @param weight `"tfidf"` (default) when `by` is given, else `"count"`. Use
#'   `"count"` for plain frequencies.
#' @param top Keep only the top `top` terms (per group, when grouped). Default
#'   `NULL` (keep all).
#' @param stopwords Passed to [tokenize_text()].
#' @param min_chars Passed to [tokenize_text()]. Default `3`.
#'
#' @return An `ezrmodel_termfreq` object wrapping a tidy `tibble` with `term`,
#'   the grouping column (if any), the count `n`, and `tf`/`idf`/`tfidf` columns
#'   when weighted. Has `print()`, `plot()` and `tidy()` methods.
#'
#' @details
#' With no `by`, you get overall counts. With a `by` grouping, each group is a
#' document: `tf` is the within-group share of a term, `idf` is
#' `log(n_groups / n_groups_containing_term)`, and `tfidf = tf * idf`. A term
#' common to every group has `idf = 0` and drops out, leaving the words that
#' characterise each group. `plot()` shows the top terms, faceted by group when
#' grouped.
#'
#' @family text
#' @seealso [tokenize_text()], [topics()].
#' @examples
#' # Distinctive words by star rating
#' tf <- term_freq(reviews, text, by = rating, top = 8)
#' tf
#' tidy(tf)
#' @export
term_freq <- function(data = NULL, text, by = NULL, weight = NULL, top = NULL,
                      stopwords = NULL, min_chars = 3) {
  data <- resolve_data(data)
  text_name <- rlang::as_name(rlang::ensym(text))
  by_q <- rlang::enquo(by)
  grouped <- !rlang::quo_is_null(by_q)
  by_name <- if (grouped) rlang::as_name(rlang::ensym(by)) else NULL

  if (is.null(weight)) weight <- if (grouped) "tfidf" else "count"
  weight <- match.arg(weight, c("count", "tfidf"))
  if (weight == "tfidf" && !grouped) {
    stop("tf-idf needs a `by` grouping; use weight = \"count\" otherwise.",
         call. = FALSE)
  }

  # Tokenise, carrying the grouping column via the document row index.
  txt <- as.character(data[[text_name]])
  toks <- tokenize_strings(txt, resolve_stopwords(stopwords), min_chars)
  lens <- vapply(toks, length, integer(1))
  tk <- tibble::tibble(.row = rep(seq_len(nrow(data)), lens),
                       term = unlist(toks, use.names = FALSE))
  if (grouped) {
    tk[[by_name]] <- data[[by_name]][tk$.row]
    counts <- tk %>%
      dplyr::filter(!is.na(.data[[by_name]])) %>%
      dplyr::count(.data[[by_name]], .data$term, name = "n")
  } else {
    counts <- tk %>% dplyr::count(.data$term, name = "n")
  }

  if (weight == "tfidf") {
    n_groups <- dplyr::n_distinct(counts[[by_name]])
    df_term <- counts %>%
      dplyr::distinct(.data[[by_name]], .data$term) %>%
      dplyr::count(.data$term, name = ".df")
    out <- counts %>%
      dplyr::group_by(.data[[by_name]]) %>%
      dplyr::mutate(tf = .data$n / sum(.data$n)) %>%
      dplyr::ungroup() %>%
      dplyr::left_join(df_term, by = "term") %>%
      dplyr::mutate(idf = log(n_groups / .data$.df),
                    tfidf = .data$tf * .data$idf) %>%
      dplyr::select(-".df") %>%
      dplyr::arrange(.data[[by_name]], dplyr::desc(.data$tfidf))
    order_col <- "tfidf"
  } else {
    out <- dplyr::arrange(counts, dplyr::desc(.data$n))
    order_col <- "n"
  }

  if (!is.null(top)) {
    if (grouped) {
      out <- out %>%
        dplyr::group_by(.data[[by_name]]) %>%
        dplyr::slice_max(.data[[order_col]], n = top, with_ties = FALSE) %>%
        dplyr::ungroup()
    } else {
      out <- utils::head(out, top)
    }
  }

  structure(
    list(freq = tibble::as_tibble(out), weight = weight, by = by_name,
         text_col = text_name),
    class = "ezrmodel_termfreq"
  )
}

#' @export
print.ezrmodel_termfreq <- function(x, ...) {
  cat(sprintf("Term frequencies of '%s'  (%s%s)\n", x$text_col, x$weight,
              if (!is.null(x$by)) paste0(" by ", x$by) else ""))
  print(utils::head(x$freq, 10))
  invisible(x)
}

#' @export
tidy.ezrmodel_termfreq <- function(x, ...) x$freq

#' @export
plot.ezrmodel_termfreq <- function(x, top = 10, ...) {
  val <- if (x$weight == "tfidf") "tfidf" else "n"
  d <- x$freq
  if (!is.null(x$by)) {
    d <- d %>%
      dplyr::group_by(.data[[x$by]]) %>%
      dplyr::slice_max(.data[[val]], n = top, with_ties = FALSE) %>%
      dplyr::ungroup() %>%
      dplyr::mutate(.ord = dplyr::row_number())
  } else {
    d <- utils::head(d, top)
    d$.ord <- seq_len(nrow(d))
  }
  d$term <- stats::reorder(d$term, -d$.ord)
  p <- ggplot2::ggplot(d, ggplot2::aes(.data$term, .data[[val]])) +
    ggplot2::geom_col(fill = pal_sequential[4], width = .7) +
    ggplot2::coord_flip() +
    ggplot2::labs(x = "", y = val, title = "Top terms") +
    theme_ezrmodel_x(transparent = TRUE)
  if (!is.null(x$by)) {
    p <- p + ggplot2::facet_wrap(stats::as.formula(paste("~", x$by)),
                                 scales = "free_y")
  }
  p
}

#' Fit a topic model to a text column
#'
#' Discovers `k` latent topics in a corpus and returns, in one object, the top
#' terms that define each topic (the `beta` matrix) and each document's topic
#' mixture (the `gamma`/theta matrix) -- ready to read, plot or join back to
#' respondent attributes.
#'
#' @param data A data frame. If omitted, the session default is used.
#' @param text The text column (unquoted).
#' @param id Optional document id column (unquoted).
#' @param k Number of topics. Default `5`.
#' @param stopwords Passed to the tokeniser (see [tokenize_text()]).
#' @param min_count Drop terms appearing in fewer than this many documents
#'   (trims the long tail). Default `2`.
#' @param ... Passed to [stm::stm()].
#'
#' @return An `ezrmodel_topics` object: `beta` (term-topic weights), `gamma`
#'   (document-topic proportions), `top_terms` (the defining terms per topic),
#'   the fitted `stm` model and the term/document maps. Has `print()`, `plot()`
#'   (top terms per topic), `tidy()` (beta) and `augment()` (each document's
#'   most likely topic) methods.
#'
#' @details
#' Topic modelling needs the suggested `quanteda` and `stm` packages; without
#' them the function stops with an install hint. Text is tokenised and turned
#' into a document-feature matrix, rare terms are trimmed (`min_count`), and a
#' Structural Topic Model is fit with spectral initialisation (deterministic).
#' `beta` gives each term's weight in each topic; `gamma` gives each document's
#' share of each topic. Use [tidy()] for the term weights and [augment()] to
#' attach the dominant topic back to your rows.
#'
#' @family text
#' @seealso [term_freq()], [tokenize_text()].
#' @examplesIf requireNamespace("quanteda", quietly = TRUE) && requireNamespace("stm", quietly = TRUE)
#' \donttest{
#' tm <- topics(reviews, text, review_id, k = 3)
#' tm
#' tidy(tm)
#' }
#' @export
topics <- function(data = NULL, text, id = NULL, k = 5, stopwords = NULL,
                   min_count = 2, ...) {
  data <- resolve_data(data)
  if (!requireNamespace("quanteda", quietly = TRUE) ||
      !requireNamespace("stm", quietly = TRUE)) {
    stop("Topic modelling needs the 'quanteda' and 'stm' packages. ",
         "Install them with install.packages(c('quanteda', 'stm')).",
         call. = FALSE)
  }
  text_name <- rlang::as_name(rlang::ensym(text))
  id_q <- rlang::enquo(id)
  if (rlang::quo_is_null(id_q)) {
    ids <- as.character(seq_len(nrow(data)))
  } else {
    ids <- as.character(data[[rlang::as_name(rlang::ensym(id))]])
  }

  txt <- as.character(data[[text_name]])
  keep <- !is.na(txt) & nzchar(stringr::str_squish(txt))
  ids <- ids[keep]
  txt <- tolower(stringr::str_squish(txt[keep]))

  corp <- quanteda::corpus(txt, docnames = ids)
  toks <- quanteda::tokens(corp, remove_numbers = TRUE, remove_punct = TRUE,
                           remove_symbols = TRUE)
  dfm <- quanteda::dfm(toks)
  dfm <- quanteda::dfm_remove(dfm, resolve_stopwords(stopwords))
  if (!is.null(min_count)) {
    dfm <- quanteda::dfm_trim(dfm, min_docfreq = min_count)
  }
  conv <- quanteda::convert(dfm, to = "stm")

  fit <- stm::stm(conv$documents, conv$vocab, K = k, data = conv$meta,
                  init.type = "Spectral", verbose = FALSE, ...)

  # Extract beta (term-topic) and gamma (document-topic) straight from the
  # fitted model -- no tidytext dependency needed.
  lb <- fit$beta$logbeta[[1]]                 # K x V (log probabilities)
  K <- nrow(lb); V <- ncol(lb)
  beta <- tibble::tibble(
    topic = rep(seq_len(K), times = V),
    term = rep(fit$vocab, each = K),
    beta = as.vector(exp(lb))
  )
  th <- fit$theta                             # D x K
  D <- nrow(th)
  docnames <- names(conv$documents)
  gamma <- tibble::tibble(
    document = rep(docnames, times = K),
    topic = rep(seq_len(K), each = D),
    gamma = as.vector(th)
  )
  top_terms <- beta %>%
    dplyr::group_by(.data$topic) %>%
    dplyr::slice_max(.data$beta, n = 10, with_ties = FALSE) %>%
    dplyr::summarise(terms = paste(.data$term, collapse = ", "),
                     .groups = "drop")

  structure(
    list(k = k, stm = fit, beta = tibble::as_tibble(beta),
         gamma = tibble::as_tibble(gamma), top_terms = top_terms,
         docs = names(conv$documents), text_col = text_name),
    class = "ezrmodel_topics"
  )
}

#' @export
print.ezrmodel_topics <- function(x, ...) {
  cat(sprintf("Topic model of '%s'  (%d topics, %d documents)\n",
              x$text_col, x$k, length(x$docs)))
  tt <- x$top_terms
  cat(paste0("  Topic ", tt$topic, ": ", tt$terms), sep = "\n")
  cat("\n")
  invisible(x)
}

#' @export
tidy.ezrmodel_topics <- function(x, ...) x$beta

#' @export
augment.ezrmodel_topics <- function(x, ...) {
  x$gamma %>%
    dplyr::group_by(.data$document) %>%
    dplyr::slice_max(.data$gamma, n = 1, with_ties = FALSE) %>%
    dplyr::ungroup() %>%
    dplyr::rename(.topic = "topic", .gamma = "gamma")
}

#' @export
plot.ezrmodel_topics <- function(x, top = 8, ...) {
  d <- x$beta %>%
    dplyr::group_by(.data$topic) %>%
    dplyr::slice_max(.data$beta, n = top, with_ties = FALSE) %>%
    dplyr::ungroup() %>%
    dplyr::mutate(.ord = dplyr::row_number(),
                  term = stats::reorder(.data$term, -.data$.ord),
                  topic = paste("Topic", .data$topic))
  ggplot2::ggplot(d, ggplot2::aes(.data$term, .data$beta)) +
    ggplot2::geom_col(fill = pal_sequential[4], width = .7) +
    ggplot2::coord_flip() +
    ggplot2::facet_wrap(~ topic, scales = "free_y") +
    ggplot2::labs(x = "", y = expression(beta), title = "Top terms per topic") +
    theme_ezrmodel_x(transparent = TRUE)
}

#' Extractive summary of a text column
#'
#' Picks the most central sentences from a body of text (LexRank, a PageRank over
#' sentence similarity) -- a quick, faithful summary of "what are people saying?"
#' that uses the respondents' own words rather than a generative paraphrase.
#'
#' @param data A data frame. If omitted, the session default is used.
#' @param text The text column (unquoted).
#' @param n Number of sentences to return. Default `5`.
#' @param ... Passed to [lexRankr::lexRank()].
#'
#' @return A `tibble` of the top `n` sentences with their LexRank `score`,
#'   ordered most-central first.
#'
#' @details
#' Needs the suggested `lexRankr` package. All non-empty cells of `text` are
#' pooled, split into sentences, and ranked by how central each is to the others;
#' the top `n` are returned verbatim. This is *extractive* (it selects real
#' sentences), so unlike [ai_summarise()] it never invents wording and needs no
#' API key.
#'
#' @family text
#' @seealso [ai_summarise()] for a generative summary.
#' @examplesIf requireNamespace("lexRankr", quietly = TRUE)
#' \donttest{
#' summarise_text(reviews, text, n = 3)
#' }
#' @export
summarise_text <- function(data = NULL, text, n = 5, ...) {
  data <- resolve_data(data)
  if (!requireNamespace("lexRankr", quietly = TRUE)) {
    stop("Extractive summaries need the 'lexRankr' package. ",
         "Install it with install.packages('lexRankr').", call. = FALSE)
  }
  text_name <- rlang::as_name(rlang::ensym(text))
  txt <- as.character(data[[text_name]])
  txt <- txt[!is.na(txt) & nzchar(stringr::str_squish(txt))]
  # Dedupe identical comments so a repeated sentence cannot win several slots.
  txt <- unique(stringr::str_squish(txt))
  if (length(txt) == 0L) {
    stop("No non-empty text to summarise.", call. = FALSE)
  }
  top <- lexRankr::lexRank(txt, docId = rep(1, length(txt)), n = n,
                           returnTies = FALSE, ...)
  tibble::tibble(sentence = top$sentence,
                 score = top$value)[order(-top$value), ]
}
