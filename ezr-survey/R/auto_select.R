# Shared column classification for the automatic "do it for every question"
# selection in crosstab_banner() and export_summary_xlsx().

# Internal: the leading prefix of a column name up to and including the final
# underscore ("motivations_speed" -> "motivations_"); "" when there is none.
col_prefix <- function(x) ifelse(grepl("_", x), sub("[^_]+$", "", x), "")

# Internal: classify a single column. Numeric columns are scales; a
# character/factor column is "constant" (one answer after blanking), "freetext"
# (a near-unique open-ended field) or an ordinary "categorical" question.
col_kind <- function(x) {
  if (is.numeric(x)) {
    return(list(kind = "numeric", nd = dplyr::n_distinct(x, na.rm = TRUE)))
  }
  v <- na_blank(x)
  nb <- sum(!is.na(v))
  nd <- dplyr::n_distinct(v, na.rm = TRUE)
  if (nd < 2L) return(list(kind = "constant", nd = nd))
  if (nb > 0 && nd >= 0.5 * nb) return(list(kind = "freetext", nd = nd))
  list(kind = "categorical", nd = nd)
}

# Internal: detect check-all-that-apply (multi-select) blocks among `cols`:
# columns sharing a prefix that each hold a single option label or blank (so
# every member looks constant on its own, but together they form one question).
# Returns a named list prefix -> member column names.
detect_multiselect <- function(data, cols = names(data)) {
  indicator <- function(col) {
    v <- na_blank(data[[col]])
    dplyr::n_distinct(v, na.rm = TRUE) == 1L && anyNA(v)
  }
  pref <- col_prefix(cols)
  out <- list()
  for (p in unique(pref[nzchar(pref)])) {
    members <- cols[pref == p]
    if (length(members) >= 2L && all(vapply(members, indicator, logical(1)))) {
      out[[p]] <- members
    }
  }
  out
}

# Internal: a readable question label for a multi-select prefix
# ("motivations_" -> "motivations").
multiselect_label <- function(prefix) sub("_+$", "", prefix)
