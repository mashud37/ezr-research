# Internal: weighted p-th quantile (lower weighted percentile), matching the
# convention of wtd_median() in weights.R.
wtd_quantile <- function(x, w, p) {
  ok <- !is.na(x)
  x <- x[ok]; w <- w[ok]
  if (length(x) == 0L) return(NA_real_)
  o <- order(x); x <- x[o]; w <- w[o]
  cw <- cumsum(w) / sum(w)
  x[which(cw >= p)[1]]
}

# Internal: the requested summary statistics of a numeric vector, returned as a
# named numeric vector in `which` order. Weighted when `w` is supplied. `stats`
# here is the namespace; `which` is the caller's chosen statistic names.
banner_numeric_stats <- function(x, w, which, digits) {
  x <- ensure_numeric(x, quiet = TRUE)
  weighted <- !is.null(w)
  one <- function(s) {
    switch(
      s,
      mean = if (weighted) stats::weighted.mean(x, w, na.rm = TRUE)
             else mean(x, na.rm = TRUE),
      median = if (weighted) wtd_median(x, w) else stats::median(x, na.rm = TRUE),
      sd = if (weighted) wtd_sd(x, w) else stats::sd(x, na.rm = TRUE),
      p25 = if (weighted) wtd_quantile(x, w, 0.25)
            else stats::quantile(x, 0.25, na.rm = TRUE, names = FALSE),
      p75 = if (weighted) wtd_quantile(x, w, 0.75)
            else stats::quantile(x, 0.75, na.rm = TRUE, names = FALSE),
      stop("Unknown stat '", s, "'. Use any of ",
           "mean, median, sd, p25, p75.", call. = FALSE)
    )
  }
  stats::setNames(round(vapply(which, one, numeric(1)), digits), which)
}

# Internal: is this stub variable to be summarised as a numeric block?
banner_is_numeric <- function(data, v, cell) {
  if (cell == "mean") {
    if (!is.numeric(data[[v]])) {
      stop("cell = \"mean\" needs a numeric column, but '", v,
           "' is not numeric.", call. = FALSE)
    }
    return(TRUE)
  }
  if (cell %in% c("pct", "count")) return(FALSE)
  is.numeric(data[[v]])
}

# Internal: one categorical stub block in long form. Column percentages come
# straight from crosstab(cell = "col_pct"), so each banner column (and the
# Overall column, built against a constant group) sums to ~100 within the block.
# Empty (item x banner level) combinations that crosstab omits are filled with 0,
# so a percentage / count block is complete and its columns sum cleanly.
banner_block_cat <- function(data, d_all, v, col_vars, cell, na_rm, drop,
                             weights, digits, group_levels) {
  cmode <- if (cell == "count") "count" else "col_pct"
  groups <- c(".overall", col_vars)
  blocks <- list()
  item_levels <- NULL
  for (g in groups) {
    if (g != ".overall" && g == v) next
    gg <- if (g == ".overall") ".all" else g
    ct <- crosstab(d_all, !!rlang::sym(v), !!rlang::sym(gg), cell = cmode,
                   wide = FALSE, na_rm = na_rm, drop = drop, weights = weights,
                   digits = digits)
    if (is.null(item_levels)) {
      item_levels <- if (is.factor(ct[[v]])) levels(ct[[v]]) else
        unique(as.character(ct[[v]]))
    }
    lv <- if (g == ".overall") "Overall" else group_levels[[g]]
    grid <- tidyr::expand_grid(item = item_levels, group_item = lv)
    seen <- tibble::tibble(item = as.character(ct[[v]]),
                           group_item = if (g == ".overall") "Overall" else
                             as.character(ct[[gg]]),
                           value = ct$value)
    filled <- dplyr::left_join(grid, seen, by = c("item", "group_item"))
    filled$value[is.na(filled$value)] <- 0
    filled$variable <- v
    filled$group <- g
    blocks[[length(blocks) + 1L]] <- filled[c("variable", "item", "group",
                                               "group_item", "value")]
  }
  out <- dplyr::bind_rows(blocks)
  attr(out, "item_levels") <- item_levels
  out
}

# Internal: one numeric stub block in long form -- a mean/median/sd/p25/p75
# section computed for the whole sample (Overall) and within each banner column.
banner_block_num <- function(data, v, col_vars, which, na_rm, weights,
                             group_levels, digits) {
  w_all <- resolve_weights(data, weights)
  x <- data[[v]]
  ov <- banner_numeric_stats(x, w_all, which, digits)
  blocks <- list(tibble::tibble(
    variable = v, item = names(ov), group = ".overall",
    group_item = "Overall", value = as.numeric(ov)
  ))
  for (g in col_vars) {
    if (g == v) next
    gv <- as.character(na_blank(data[[g]]))
    for (gi in group_levels[[g]]) {
      idx <- which(gv == gi)
      wi <- if (is.null(w_all)) NULL else w_all[idx]
      s <- banner_numeric_stats(x[idx], wi, which, digits)
      blocks[[length(blocks) + 1L]] <- tibble::tibble(
        variable = v, item = names(s), group = g,
        group_item = gi, value = as.numeric(s)
      )
    }
  }
  out <- dplyr::bind_rows(blocks)
  attr(out, "item_levels") <- which
  out
}

# Internal: one multi-select (check-all-that-apply) stub block in long form. Each
# option is a row; the value is the share of respondents who selected it, based
# on the question-level sample size (respondents who picked any option) computed
# per banner column by calc_percentage_multi(). Percentages can sum past 100.
# Multi-select tabulation is unweighted (calc_percentage_multi has no weighting).
banner_block_multi <- function(data, prefix, col_vars, cell, na_rm, drop,
                               weights, digits, group_levels) {
  count_mode <- cell == "count"
  label <- multiselect_label(prefix)
  val_of <- function(tb) if (count_mode) tb$n else tb$pct
  ov <- calc_percentage_multi(data, prefix, drop = drop, digits = digits)
  item_levels <- as.character(ov$option)
  blocks <- list(tibble::tibble(
    variable = label, item = item_levels, group = ".overall",
    group_item = "Overall", value = val_of(ov)
  ))
  for (g in col_vars) {
    tb <- rlang::inject(
      calc_percentage_multi(data, prefix, by = !!rlang::sym(g), drop = drop,
                            digits = digits)
    )
    grid <- tidyr::expand_grid(item = item_levels,
                               group_item = group_levels[[g]])
    seen <- tibble::tibble(item = as.character(tb$option),
                           group_item = as.character(tb[[g]]),
                           value = val_of(tb))
    filled <- dplyr::left_join(grid, seen, by = c("item", "group_item"))
    filled$value[is.na(filled$value)] <- 0
    filled$variable <- label
    filled$group <- g
    blocks[[length(blocks) + 1L]] <- filled[c("variable", "item", "group",
                                               "group_item", "value")]
  }
  out <- dplyr::bind_rows(blocks)
  attr(out, "item_levels") <- item_levels
  out
}

# Internal: assemble the long banner into the wide master table, honouring the
# display order of rows (stub blocks) and columns (Overall then each banner
# variable's items). Column names are made unique for the tibble; the true
# (group, label) identity of every column is stored in the "banner_spanners"
# attribute so a two-row header can be rendered.
banner_assemble_wide <- function(long, row_keys, col_vars, group_levels,
                                 total) {
  specs <- list()
  if (total) {
    specs[[1L]] <- list(group = "Overall", label = "Overall",
                        values = long[long$group == ".overall",
                                      c("variable", "item", "value")])
  }
  for (g in col_vars) {
    for (gi in group_levels[[g]]) {
      sub <- long[long$group == g & long$group_item == gi,
                  c("variable", "item", "value")]
      specs[[length(specs) + 1L]] <- list(group = g, label = gi, values = sub)
    }
  }

  labels <- vapply(specs, function(s) s$label, character(1))
  col_names <- make.unique(labels, sep = " ")

  wide <- row_keys
  for (i in seq_along(specs)) {
    m <- dplyr::left_join(row_keys, specs[[i]]$values, by = c("variable", "item"))
    wide[[col_names[[i]]]] <- m$value
  }

  spanners <- tibble::tibble(
    col = col_names,
    group = vapply(specs, function(s) s$group, character(1)),
    label = labels
  )
  attr(wide, "banner_spanners") <- spanners
  wide
}

# Internal: render a banner tibble as a flextable with a two-row header (banner
# variable names spanning their items). Reads the "banner_spanners" attribute.
banner_flextable <- function(x) {
  require_flextable()
  sp <- attr(x, "banner_spanners")
  keys <- names(x)
  top <- stats::setNames(rep("", length(keys)), keys)
  bot <- stats::setNames(keys, keys)
  top[["variable"]] <- "Variable"; bot[["variable"]] <- "Variable"
  top[["item"]] <- "Item"; bot[["item"]] <- "Item"
  for (i in seq_len(nrow(sp))) {
    k <- sp$col[[i]]
    if (sp$group[[i]] == "Overall") {
      top[[k]] <- "Overall"; bot[[k]] <- "Overall"
    } else {
      top[[k]] <- sp$group[[i]]; bot[[k]] <- sp$label[[i]]
    }
  }
  mapping <- data.frame(col_keys = keys, h1 = unname(top[keys]),
                        h2 = unname(bot[keys]), stringsAsFactors = FALSE)
  ft <- flextable::flextable(x)
  ft <- flextable::set_header_df(ft, mapping = mapping, key = "col_keys")
  ft <- flextable::merge_h(ft, i = 1, part = "header")
  ft <- flextable::merge_v(ft, part = "header")
  ft <- flextable::theme_booktabs(ft)
  flextable::autofit(ft)
}

# Internal: pick the default rows / cols when the caller supplies only a data
# frame. Multi-select blocks are recognised first and become stub questions.
# Among the remaining columns, a categorical variable is banner-eligible (a stub
# or a grouping variable) when it has between 2 and `max_levels` distinct answers;
# numeric scales are always eligible as stub rows (a statistics block) but only a
# banner group when they too fit the cap. Identifier and free-text / high-
# cardinality columns fall out of every set and are reported as skipped.
banner_auto_select <- function(data, max_levels) {
  multi <- detect_multiselect(data)
  consumed <- unlist(multi, use.names = FALSE)
  singles <- setdiff(names(data), consumed)
  kinds <- lapply(singles, function(nm) c(list(name = nm), col_kind(data[[nm]])))
  small_cat <- function(k) k$kind == "categorical" && k$nd <= max_levels
  small_num <- function(k) k$kind == "numeric" && k$nd <= max_levels
  nm_of <- function(keep) vapply(Filter(keep, kinds),
                                 function(k) k$name, character(1))
  cols <- nm_of(function(k) small_cat(k) || small_num(k))
  rows <- nm_of(function(k) k$kind == "numeric" || small_cat(k))
  used <- union(consumed, union(cols, rows))
  list(rows = rows, cols = cols, multi = multi,
       skipped = setdiff(names(data), used))
}

#' Build a master banner (cross-tab) table
#'
#' Produces the market-research "banner" table: one master table with a stack of
#' question variables down the side (`rows`) and one or more grouping variables
#' across the top (`cols`), plus an **Overall** column for the whole sample.
#' Categorical questions become column-percentage blocks (each banner column sums
#' to ~100 within the block); numeric questions become a mean / median / sd /
#' quartile block. It generalises [crosstab()] from a single pair to a whole
#' table, and picks the cell content per question automatically.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()]) is
#'   used.
#' @param rows Stub variables, down the side (tidyselect, e.g.
#'   `c(satis_return, demo_edu)` or `starts_with("ratings_")`). If omitted, every
#'   eligible variable is used (see `max_levels` and Details).
#' @param cols Banner / grouping variables, across the top (tidyselect). Pass
#'   several to get several spanning column groups. If omitted, every eligible
#'   variable is used, giving a full variable-by-variable banner.
#' @param max_levels When `rows` / `cols` are omitted, the largest number of
#'   distinct answers a categorical variable may have to be used automatically
#'   (default `20`). Bigger categorical variables, identifier columns and
#'   free-text are skipped; numeric scales are always kept as stub rows.
#' @param cell What each body cell holds: `"auto"` (default) uses column
#'   percentages for categorical questions and a statistics block for numeric
#'   ones; `"pct"` forces column percentages; `"count"` uses (weighted) counts;
#'   `"mean"` forces a numeric mean (errors on a categorical question); `"diff"`
#'   shows each cell's difference from the Overall column (percentage points, or
#'   mean difference for numeric questions).
#' @param stats For numeric questions, which statistics form the block. Any of
#'   `"mean"`, `"median"`, `"sd"`, `"p25"`, `"p75"`. Default all five.
#' @param total Include the whole-sample **Overall** column. Default `TRUE`.
#' @param digits Decimal places. `NULL` (default) uses `0` for percentages /
#'   counts and `2` for numeric statistics; a value overrides both.
#' @param na_rm Drop blanks / non-answers in the questions and banner variables.
#'   Default `TRUE`.
#' @param drop Answer values to remove before tabulating (see [drop_items()]),
#'   passed to the underlying [crosstab()] calls. Defaults to the `drop_answers`
#'   option.
#' @param weights Survey weighting: `NULL` (default) uses the session scheme from
#'   [set_weights()] if set; `FALSE` forces unweighted; or pass an ad-hoc scheme.
#'   When weighting is active the cells are weighted (weighted percentages,
#'   counts, means and quartiles).
#' @param long If `TRUE`, return the tidy long form (`variable`, `item`, `group`,
#'   `group_item`, `value`) instead of the wide master table. Default `FALSE`.
#' @param flextable If `TRUE`, return a [flextable][flextable::flextable] with the
#'   two-row banner header ready for a slide or Word report. Default `FALSE`.
#'   Requires the suggested `flextable` package.
#'
#' @return By default a wide [tibble][tibble::tibble]: `variable`, `item`,
#'   `Overall`, then one column per banner item. The banner grouping (which
#'   column belongs to which top-row variable) is stored in the
#'   `"banner_spanners"` attribute, which `flextable = TRUE` turns into a
#'   spanning two-row header. With `long = TRUE`, the tidy long form.
#'
#' @details
#' A tibble has a single header row, so the two-row banner header (each grouping
#' variable's name spanning its items) cannot be stored in the data itself: the
#' wide return carries the grouping in the `"banner_spanners"` attribute and
#' `flextable = TRUE` renders the real spanning header. Column percentages are
#' computed *within* each banner column, so every column (Overall included) sums
#' to about 100 down each question block. Registered orders ([register_order()])
#' set the item and banner-column ordering automatically. Passing the same
#' selection to `rows` and `cols` gives the full every-question-by-every-question
#' matrix (a variable is never crossed with itself). Supplying only the data
#' frame does this automatically: every variable with at most `max_levels`
#' distinct answers becomes both a stub and a banner group, numeric scales are
#' added as stub statistics blocks, and identifier / free-text columns are
#' skipped (and named in a message). Check-all-that-apply blocks (columns sharing
#' a prefix that each hold one option or blank, such as `motivations_*`) are
#' recognised as a single multi-select stub question and tabulated with
#' [calc_percentage_multi()], whose base is the respondents who picked any option
#' (so those rows can sum past 100). Multi-select blocks appear as stubs only, not
#' banner groups, and are unweighted.
#'
#' @family summaries
#' @seealso [crosstab()] for a single pair, [calc_percentage_batch()] for stacked
#'   one-variable percentages, [export_summary_xlsx()], [register_order()].
#' @examples
#' # full variable-by-variable banner: just pass the data frame
#' crosstab_banner(podracing_survey)
#'
#' # gender and region banner over two questions (column percentages)
#' crosstab_banner(podracing_survey,
#'                 rows = c(satis_return, demo_edu),
#'                 cols = c(demo_gender, region))
#'
#' # numeric questions become a mean / median / sd / quartile block
#' crosstab_banner(podracing_survey,
#'                 rows = c(nps_value, demo_age),
#'                 cols = demo_gender)
#'
#' # each cell as its difference from the Overall column
#' crosstab_banner(podracing_survey, rows = satis_return,
#'                 cols = region, cell = "diff")
#' @export
crosstab_banner <- function(data = NULL, rows, cols,
                            cell = c("auto", "pct", "count", "mean", "diff"),
                            stats = c("mean", "median", "sd", "p25", "p75"),
                            total = TRUE, digits = NULL, na_rm = TRUE,
                            drop = NULL, weights = NULL, max_levels = 20,
                            long = FALSE, flextable = FALSE) {
  data <- resolve_data(data)
  cell <- match.arg(cell)
  stats <- match.arg(stats, several.ok = TRUE)

  # With no rows / cols, cross every eligible variable against every other.
  auto <- missing(rows) || missing(cols)
  sel <- if (auto) banner_auto_select(data, max_levels) else NULL
  if (missing(rows)) {
    row_singles <- sel$rows
    multi <- sel$multi
  } else {
    raw <- names(dplyr::select(data, {{ rows }}))
    multi <- detect_multiselect(data, raw)
    row_singles <- setdiff(raw, unlist(multi, use.names = FALSE))
  }
  col_vars <- if (missing(cols)) sel$cols else names(dplyr::select(data, {{ cols }}))
  if (auto && length(sel$skipped)) {
    message("crosstab_banner: skipped ", length(sel$skipped),
            " identifier / free-text / high-cardinality column(s): ",
            paste(sel$skipped, collapse = ", "),
            ". Raise max_levels or name them in rows/cols to include them.")
  }
  if (!length(row_singles) && !length(multi)) {
    stop("No `rows` variables (none selected or eligible). Name some in ",
         "`rows` or raise `max_levels`.", call. = FALSE)
  }
  if (!length(col_vars)) {
    stop("No `cols` variables (none selected or eligible). Name some in ",
         "`cols` or raise `max_levels`.", call. = FALSE)
  }

  pct_digits <- digits %||% 0
  num_digits <- digits %||% 2

  d_all <- data
  d_all[[".all"]] <- "Overall"

  group_levels <- stats::setNames(lapply(col_vars, function(g) {
    gp <- crosstab(d_all, !!rlang::sym(g), !!rlang::sym(".all"),
                   cell = "count", wide = FALSE, na_rm = na_rm, drop = drop)
    if (is.factor(gp[[g]])) levels(gp[[g]]) else unique(as.character(gp[[g]]))
  }), col_vars)

  # Stub questions, kept in column order: single variables and multi-select
  # blocks (each a group of prefix-sharing columns tabulated as one question).
  at <- function(cols) min(match(cols, names(data)))
  specs <- c(
    lapply(row_singles, function(v) list(type = "single", label = v,
                                         pos = match(v, names(data)))),
    lapply(names(multi), function(p) list(type = "multi", label = p,
                                          pos = at(multi[[p]])))
  )
  specs <- specs[order(vapply(specs, function(s) s$pos, numeric(1)))]

  blocks <- list()
  row_keys <- list()
  for (s in specs) {
    blk <- if (s$type == "multi") {
      banner_block_multi(data, s$label, col_vars, cell, na_rm, drop, weights,
                         pct_digits, group_levels)
    } else if (banner_is_numeric(data, s$label, cell)) {
      banner_block_num(data, s$label, col_vars, stats, na_rm, weights,
                       group_levels, num_digits)
    } else {
      banner_block_cat(data, d_all, s$label, col_vars, cell, na_rm, drop,
                       weights, pct_digits, group_levels)
    }
    il <- attr(blk, "item_levels")
    if (!length(il)) next
    row_keys[[length(row_keys) + 1L]] <- tibble::tibble(
      variable = blk$variable[[1]], item = il
    )
    blocks[[length(blocks) + 1L]] <- blk
  }
  long_df <- dplyr::bind_rows(blocks)
  row_keys <- dplyr::bind_rows(row_keys)

  if (cell == "diff") {
    ov <- long_df[long_df$group == ".overall", c("variable", "item", "value")]
    names(ov)[names(ov) == "value"] <- ".ov"
    long_df <- dplyr::left_join(long_df, ov, by = c("variable", "item"))
    long_df$value <- ifelse(long_df$group == ".overall", long_df$value,
                            long_df$value - long_df$.ov)
    long_df$.ov <- NULL
  }

  if (long) {
    long_df$group[long_df$group == ".overall"] <- "Overall"
    if (!total) long_df <- long_df[long_df$group != "Overall", , drop = FALSE]
    return(tibble::as_tibble(long_df))
  }

  wide <- banner_assemble_wide(long_df, row_keys, col_vars, group_levels, total)
  if (flextable) return(banner_flextable(wide))
  wide
}
