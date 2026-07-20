# Minimal fallback stop-word list, used only when the 'stopwords' package isn't
# installed. Prefer stopwords::stopwords() (curated, multi-language).
.stopwords_fallback <- c(
  "the", "and", "for", "are", "but", "not", "you", "all", "any", "was", "our",
  "has", "have", "had", "with", "from", "they", "this", "that", "their", "them",
  "then", "than", "were", "been", "will", "would", "could", "there", "what",
  "which", "when", "your", "just", "more", "very", "some", "into", "also",
  "like", "because", "about"
)

# Resolve the stop-word set: a user-supplied vector, FALSE to disable, or
# (default, NULL) the 'stopwords' package when available, else the fallback.
resolve_stopwords <- function(stopwords = NULL) {
  if (isFALSE(stopwords)) {
    return(character(0))
  }
  if (is.character(stopwords)) {
    return(tolower(stopwords))
  }
  if (requireNamespace("stopwords", quietly = TRUE)) {
    return(stopwords::stopwords("en"))
  }
  .stopwords_fallback
}

# Internal: set the RNG seed and return a restore function for the caller's
# on.exit(); a NULL seed is a no-op.
push_seed <- function(seed) {
  if (is.null(seed)) {
    return(function() invisible(NULL))
  }
  old_seed <- if (exists(".Random.seed", envir = globalenv())) {
    get(".Random.seed", envir = globalenv())
  } else {
    NULL
  }
  set.seed(seed)
  function() {
    if (is.null(old_seed)) {
      rm(".Random.seed", envir = globalenv())
    } else {
      assign(".Random.seed", old_seed, envir = globalenv())
    }
    invisible(NULL)
  }
}

# Internal: tidy, filter and truncate the comment columns into one long table.
prep_comments <- function(data, cols, min_chars, max_chars, exclude) {
  if (length(cols) == 0L) {
    stop("Select at least one comment column.", call. = FALSE)
  }
  long <- data %>%
    dplyr::select(dplyr::all_of(cols)) %>%
    dplyr::mutate(dplyr::across(dplyr::everything(), as.character)) %>%
    tidyr::pivot_longer(dplyr::everything(),
                        names_to = "source",
                        values_to = "comment") %>%
    dplyr::mutate(comment = na_blank(.data$comment)) %>%
    dplyr::filter(!is.na(.data$comment),
                  nchar(.data$comment) > min_chars)

  if (!is.null(exclude) && length(exclude) > 0) {
    pattern <- paste(exclude, collapse = "|")
    long <- dplyr::filter(
      long,
      !stringr::str_detect(tolower(.data$comment), tolower(pattern))
    )
  }

  long %>%
    dplyr::mutate(
      comment = stringr::str_trunc(.data$comment, max_chars,
                                   side = "right", ellipsis = "..."),
      length = nchar(.data$comment)
    )
}

#' Pick a random sample of open-text comments
#'
#' Pulls a tidy, presentation-ready sample of comments out of one or more
#' free-text columns, applying the usual clean-ups: drop blanks and very short
#' answers, optionally exclude comments matching unwanted terms, and truncate to
#' a maximum length. The result feeds straight into [plot_quotes_tree()].
#'
#' @param data A data frame.
#' @param ... One or more comment columns, using tidyselect (e.g. `nps_com`,
#'   `show_com`, or `ends_with("_com")`).
#' @param n Number of comments to sample. With `by_column = TRUE`, this is per
#'   column.
#' @param min_chars Drop comments with this many characters or fewer. Default
#'   `30`.
#' @param max_chars Truncate longer comments to this length. Default `400`.
#' @param exclude Optional character vector of (case-insensitive) regex terms;
#'   comments matching any are dropped (e.g. `c("friend", "recommend")`).
#' @param by_column If `TRUE` (default), sample `n` from each column; if `FALSE`,
#'   sample `n` from the pooled comments.
#' @param seed Optional integer for reproducible sampling (the RNG state is
#'   restored afterwards).
#'
#' @return A [tibble][tibble::tibble] with `source`, `comment` and `length`.
#'
#' @details
#' Verbatims need clean-up before they go on a slide: this drops blanks and very
#' short answers, optionally removes comments matching unwanted terms (`exclude`),
#' and truncates the long ones. With `by_column = TRUE` you get `n` from each
#' source column (e.g. an even split across `nps_com` and `show_com`); with
#' `FALSE`, `n` from the pooled set. The result feeds [plot_quotes_tree()]. For a
#' set that is varied rather than uniformly random, use [sample_comments_diverse()].
#'
#' @family comments
#' @seealso [sample_comments_diverse()] for a diversity-aware sample,
#'   [plot_quotes_tree()].
#' @examples
#' sample_comments(podracing_survey, nps_com, show_com, n = 3)
#' @export
sample_comments <- function(data = NULL, ..., n = 8, min_chars = 30,
                            max_chars = 400, exclude = NULL, by_column = TRUE,
                            seed = NULL) {
  rd <- resolve_data_dots(rlang::enquo(data), rlang::enquos(...))
  data <- rd$data
  restore_seed <- push_seed(seed)
  on.exit(restore_seed(), add = TRUE)
  cols <- names(dplyr::select(data, !!!rd$dots))
  long <- prep_comments(data, cols, min_chars, max_chars, exclude)
  if (nrow(long) == 0L) {
    return(long)
  }
  if (by_column) {
    long <- dplyr::group_by(long, .data$source)
  }
  long %>%
    dplyr::slice_sample(n = n) %>%
    dplyr::ungroup()
}

# Internal: lexical tokeniser (lower-case, drop punctuation / short tokens /
# stop-words).
tokenize_comments <- function(x, stopset = character(0)) {
  x <- tolower(x)
  x <- stringr::str_replace_all(x, "[^a-z0-9' ]", " ")
  toks <- stringr::str_split(stringr::str_squish(x), " ")
  lapply(toks, function(t) {
    t <- t[nchar(t) > 2]
    setdiff(t, stopset)
  })
}

# Internal: TF and L2-normalised TF-IDF matrices for a set of comments.
build_tfidf <- function(comments, stopset = character(0)) {
  tokens <- tokenize_comments(comments, stopset)
  vocab <- sort(unique(unlist(tokens)))
  if (length(vocab) == 0L) {
    return(NULL)
  }
  tf <- matrix(0, nrow = length(comments), ncol = length(vocab),
               dimnames = list(NULL, vocab))
  for (i in seq_along(tokens)) {
    if (length(tokens[[i]])) {
      counts <- table(factor(tokens[[i]], levels = vocab))
      tf[i, ] <- as.numeric(counts)
    }
  }
  df <- colSums(tf > 0)
  idf <- log((1 + nrow(tf)) / (1 + df)) + 1
  tfidf <- sweep(tf, 2, idf, `*`)
  norms <- sqrt(rowSums(tfidf^2))
  norms[norms == 0] <- 1
  list(tf = tf, tfidf = tfidf / norms)
}

# Internal: Shannon entropy (bits) of a term-frequency row.
shannon_bits <- function(tf_row) {
  p <- tf_row[tf_row > 0]
  if (length(p) == 0L) return(0)
  p <- p / sum(p)
  -sum(p * log2(p))
}

# Internal: maximal-marginal-relevance selection with a randomised pick, so the
# chosen comments are both informative and dissimilar to each other.
select_diverse <- function(tfidf, info, n, lambda) {
  nrec <- nrow(tfidf)
  sim <- tfidf %*% t(tfidf)            # cosine similarity (rows are normalised)
  rng <- diff(range(info))
  info_n <- if (rng == 0) rep(0.5, nrec) else (info - min(info)) / rng

  selected <- integer(0)
  remaining <- seq_len(nrec)
  while (length(selected) < min(n, nrec)) {
    if (length(selected) == 0L) {
      maxsim <- rep(0, length(remaining))
    } else {
      maxsim <- apply(sim[remaining, selected, drop = FALSE], 1, max)
    }
    score <- lambda * info_n[remaining] - (1 - lambda) * maxsim
    probs <- exp(score - max(score))
    probs <- probs / sum(probs)
    pick <- remaining[sample.int(length(remaining), 1, prob = probs)]
    selected <- c(selected, pick)
    remaining <- setdiff(remaining, pick)
  }
  selected
}

#' Pick a diverse, information-rich sample of comments
#'
#' A smarter alternative to [sample_comments()]: instead of sampling uniformly,
#' it scores each comment and selects a set that is both **informative** and
#' **varied**, so a quote slide isn't five ways of saying the same thing. Scoring
#' is lexical -- comments are turned into TF-IDF vectors, an information score is
#' computed (Shannon entropy of the word distribution, or TF-IDF mass), and a
#' randomised maximal-marginal-relevance pass trades off informativeness against
#' similarity to already-picked comments.
#'
#' @inheritParams sample_comments
#' @param lambda Diversity/informativeness trade-off in `[0, 1]` for
#'   `method = "mmr"`: higher favours informative comments, lower favours
#'   dissimilar ones. Default `0.6`.
#' @param method `"mmr"` (default) for the diversity-aware greedy selection, or
#'   `"entropy"` to weight a random sample by each comment's information score.
#' @param score By which to measure information: `"entropy"` (default, Shannon
#'   bits) or `"tfidf"` (summed TF-IDF weight).
#' @param stopwords Stop-word handling: `NULL` (default) uses the `stopwords`
#'   package when installed (English), otherwise a small built-in fallback;
#'   a character vector supplies your own list; `FALSE` disables removal. Pass
#'   e.g. `stopwords::stopwords("de")` for another language.
#' @param seed Optional integer for reproducible sampling (the RNG state is
#'   restored afterwards).
#'
#' @return A [tibble][tibble::tibble] with `source`, `comment`, `length` and the
#'   `info` score, ordered by selection.
#' @family comments
#' @seealso [sample_comments()], [plot_quotes_tree()].
#' @examples
#' sample_comments_diverse(podracing_survey, nps_com, show_com, n = 5, seed = 1)
#' @export
sample_comments_diverse <- function(data = NULL, ..., n = 8, min_chars = 30,
                                    max_chars = 400, exclude = NULL,
                                    lambda = 0.6,
                                    method = c("mmr", "entropy"),
                                    score = c("entropy", "tfidf"),
                                    stopwords = NULL,
                                    seed = NULL) {
  rd <- resolve_data_dots(rlang::enquo(data), rlang::enquos(...))
  data <- rd$data
  method <- match.arg(method)
  score <- match.arg(score)

  restore_seed <- push_seed(seed)
  on.exit(restore_seed(), add = TRUE)

  cols <- names(dplyr::select(data, !!!rd$dots))
  long <- prep_comments(data, cols, min_chars, max_chars, exclude)
  # A quote slide should never show the same sentence twice.
  long <- dplyr::distinct(long, .data$comment, .keep_all = TRUE)
  if (nrow(long) <= n) {
    long$info <- NA_real_
    return(long)
  }

  mats <- build_tfidf(long$comment, resolve_stopwords(stopwords))
  if (is.null(mats)) {
    # Nothing scorable (e.g. all stop-words) -- fall back to a plain sample.
    out <- dplyr::slice_sample(long, n = n)
    out$info <- NA_real_
    return(out)
  }

  info <- if (score == "entropy") {
    apply(mats$tf, 1, shannon_bits)
  } else {
    rowSums(mats$tfidf)
  }

  idx <- if (method == "mmr") {
    select_diverse(mats$tfidf, info, n = n, lambda = lambda)
  } else {
    w <- info - min(info) + 1e-6
    sample.int(nrow(long), size = n, prob = w)
  }

  out <- long[idx, , drop = FALSE]
  out$info <- info[idx]
  tibble::as_tibble(out)
}
