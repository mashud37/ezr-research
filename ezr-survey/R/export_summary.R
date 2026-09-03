# Internal: the default single-series fill, matching plot_bars() -- the brand
# primary when a brand is set, else the neutral palette colour.
summary_fill <- function() {
  ezrsurvey_default("brand_color_primary") %||%
    ezrsurvey_default("brand_colors")[1] %||% pal_neutral
}

# Internal: the summary table for one variable -- a numeric summary for a numeric
# column, otherwise a percentage table.
summary_table <- function(data, v, by_q, numeric_var, sort, digits, weights) {
  if (numeric_var) {
    rlang::inject(
      calc_summary(data, !!rlang::sym(v), by = !!by_q, weights = weights)
    )
  } else {
    rlang::inject(
      calc_percentage(data, !!rlang::sym(v), by = !!by_q, sort = sort,
                      digits = digits, weights = weights)
    )
  }
}

# Internal: the companion chart for one variable -- a histogram for a numeric
# column, otherwise a bar chart of its percentages. Returns NULL when there is
# nothing to plot.
summary_chart <- function(data, v, numeric_var, sort, digits, weights) {
  if (numeric_var) {
    x <- ensure_numeric(data[[v]], quiet = TRUE)
    x <- x[!is.na(x)]
    if (!length(x)) return(NULL)
    ggplot2::ggplot(tibble::tibble(x = x), ggplot2::aes(.data$x)) +
      ggplot2::geom_histogram(bins = 20, fill = summary_fill()) +
      ggplot2::labs(x = v, y = "count", title = v) +
      theme_ezrsurvey()
  } else {
    ptab <- calc_percentage(data, !!rlang::sym(v), sort = sort, digits = digits,
                            weights = weights)
    if (!nrow(ptab)) return(NULL)
    val <- if ("wpct" %in% names(ptab)) rlang::sym("wpct") else rlang::sym("pct")
    rlang::inject(plot_bars(ptab, value = !!val, title = v))
  }
}

# Internal: table / chart for a multi-select block, tabulated across the whole
# battery at once (the base is respondents who picked any option).
multi_table <- function(data, prefix, by_q, sort, digits) {
  rlang::inject(
    calc_percentage_multi(data, prefix, by = !!by_q, sort = sort, digits = digits)
  )
}

multi_chart <- function(data, prefix, digits) {
  tab <- calc_percentage_multi(data, prefix, sort = "desc", digits = digits)
  if (!nrow(tab)) return(NULL)
  plot_bars(tab, title = multiselect_label(prefix))
}

# Internal: the ordered list of "questions" to write, one per sheet. Single
# columns and multi-select blocks (prefix-sharing check-all columns) are kept in
# column order. In auto mode (no explicit selection) identifier / free-text
# columns are dropped and returned as `skipped`.
export_questions <- function(data, sel_cols, auto) {
  multi <- detect_multiselect(data, sel_cols)
  singles <- setdiff(sel_cols, unlist(multi, use.names = FALSE))
  skipped <- character(0)
  if (auto) {
    keep <- vapply(singles, function(nm) {
      col_kind(data[[nm]])$kind %in% c("numeric", "categorical")
    }, logical(1))
    skipped <- singles[!keep]
    singles <- singles[keep]
  }
  at <- function(cols) min(match(cols, names(data)))
  specs <- c(
    lapply(singles, function(v) list(type = "single", label = v,
                                     pos = match(v, names(data)))),
    lapply(names(multi), function(p) list(type = "multi", prefix = p,
                                          label = multiselect_label(p),
                                          pos = at(multi[[p]])))
  )
  specs <- specs[order(vapply(specs, function(s) s$pos, numeric(1)))]
  list(specs = specs, skipped = skipped)
}

#' Export a per-question summary workbook (table + chart per sheet)
#'
#' Writes one Excel workbook with a worksheet per question, each holding that
#' question's summary table and its chart. Numeric questions get a
#' [calc_summary()] table and a histogram; categorical questions get a
#' [calc_percentage()] table and a [plot_bars()] chart; check-all-that-apply
#' blocks get a [calc_percentage_multi()] table (based on the respondents who
#' picked any option) and a bar chart. This is the "hand the client a tabbed
#' workbook" counterpart to the slide/Word builders ([report_deck()]). Requires
#' the suggested `openxlsx2` package (the only xlsx writer here that can embed
#' images).
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()]) is
#'   used.
#' @param ... Variables to summarise, using tidyselect (e.g.
#'   `starts_with("ratings_")` or `demo_gender, satis_return`). One worksheet per
#'   question. If omitted, every question is written: each eligible column plus
#'   any multi-select block, skipping identifier and free-text columns.
#' @param path Output `.xlsx` path. `NULL` (default) writes `summary.xlsx`.
#'   A bare file name lands in `ezrsurvey-outputs/` (created on demand); a path
#'   naming a directory (`"./x.xlsx"`, `"charts/x.xlsx"`, anything absolute) is used
#'   exactly as given. See the `output_dir` option.
#' @param by Optional grouping column(s) for the tables (passed to
#'   [calc_percentage()] / [calc_summary()] / [calc_percentage_multi()]). The
#'   chart is always the ungrouped distribution.
#' @param chart Include the chart beneath each table. Default `TRUE`.
#' @param sort Level ordering for categorical tables, passed to
#'   [calc_percentage()]: `"none"` (default, respecting any registered order),
#'   `"desc"` or `"asc"`. The chart always auto-lays-out its bars.
#' @param digits Decimal places for percentages. Default `0`.
#' @param weights Survey weighting, passed to the table and chart helpers (see
#'   [calc_percentage()]). `NULL` (default) uses the session scheme if set.
#'   Multi-select blocks are always unweighted.
#' @param width,height Chart size in inches. Default `6 x 3.4`.
#' @param confirm When no variables are named, show which questions were chosen
#'   and which were skipped, and wait for a yes before writing. `NULL` (default)
#'   follows the `confirm` option, which asks in an interactive session and never
#'   asks in a script; `TRUE` or `FALSE` force it either way. Answering no writes
#'   nothing and returns `NULL`.
#'
#' @return Invisibly the `path` written.
#'
#' @details
#' Worksheets are named from each question (cleaned to valid, unique Excel names).
#' The table is written from cell `A1`; the chart, when included, is rendered to a
#' temporary PNG and embedded a few rows below it. A numeric column (after
#' [ensure_numeric()]) is treated as a scale question (summary + histogram);
#' columns that share a prefix and each hold a single option or blank (e.g.
#' `motivations_*`) are treated as one check-all-that-apply question; anything
#' else is categorical (percentages + bar chart). With no `...`, every question in
#' the data is written and identifier / free-text columns are skipped (and named
#' in a message). For a single table or a pre-named list of tables in one workbook
#' without charts, see [export_xlsx()] / [save_data()].
#'
#' @family save
#' @seealso [export_xlsx()], [save_data()], [report_deck()],
#'   [calc_percentage_batch()].
#' @examples
#' \donttest{
#' # named questions
#' tmp <- tempfile(fileext = ".xlsx")
#' export_summary_xlsx(podracing_survey, demo_gender, satis_return, nps_value,
#'                     path = tmp)
#'
#' # or every question at once (identifier / free-text columns are skipped)
#' tmp2 <- tempfile(fileext = ".xlsx")
#' export_summary_xlsx(podracing_survey, path = tmp2)
#' }
#' @export
export_summary_xlsx <- function(data = NULL, ..., path = NULL, by = NULL,
                                chart = TRUE, sort = c("none", "desc", "asc"),
                                digits = 0, weights = NULL,
                                width = 6, height = 3.4, confirm = NULL) {
  if (!requireNamespace("openxlsx2", quietly = TRUE)) {
    stop("Exporting a summary workbook needs the 'openxlsx2' package. ",
         "Install it with install.packages('openxlsx2').", call. = FALSE)
  }
  r <- resolve_data_dots(rlang::enquo(data), rlang::enquos(...))
  data <- r$data
  sort <- match.arg(sort)
  auto <- length(r$dots) == 0L
  sel_cols <- if (auto) names(data) else names(dplyr::select(data, !!!r$dots))
  q <- export_questions(data, sel_cols, auto)
  specs <- q$specs
  if (!length(specs)) {
    stop("Select at least one variable to summarise.", call. = FALSE)
  }
  labels <- vapply(specs, function(s) s$label, character(1))
  if (auto && !confirm_on(confirm) && length(q$skipped)) {
    message("export_summary_xlsx: skipped ", length(q$skipped),
            " identifier / free-text column(s): ",
            paste(q$skipped, collapse = ", "), ".")
  }
  if (auto) {
    proceed <- confirm_selection(
      paste0("Questions chosen automatically: ", length(specs),
             " worksheet(s)."),
      c(confirm_lines("Questions", labels),
        confirm_lines("Skipped", q$skipped),
        "Name the variables yourself to change this."),
      confirm
    )
    if (!proceed) {
      message("Cancelled. Nothing was written.")
      return(invisible(NULL))
    }
  }
  by_q <- rlang::enquo(by)
  path <- resolve_output_path(path %||% default_output_path("summary", "xlsx"))
  sheet_names <- sanitize_sheet_names(labels)
  total <- length(specs)

  wb <- openxlsx2::wb_workbook()
  pngs <- character(0)
  on.exit(unlink(pngs), add = TRUE)

  progress_plan(paste0("Summary workbook: ", total, " question(s)"),
                vapply(specs, function(s) s$label, character(1)))
  run <- progress_start(total)
  on.exit(progress_done(run), add = TRUE)

  for (i in seq_along(specs)) {
    s <- specs[[i]]
    sh <- sheet_names[[i]]
    progress_item(run, i, s$label)
    if (s$type == "multi") {
      tab <- multi_table(data, s$prefix, by_q, sort, digits)
      p <- if (chart) multi_chart(data, s$prefix, digits) else NULL
    } else {
      numeric_var <- is.numeric(data[[s$label]])
      tab <- summary_table(data, s$label, by_q, numeric_var, sort, digits,
                           weights)
      p <- if (chart) {
        summary_chart(data, s$label, numeric_var, sort, digits, weights)
      } else {
        NULL
      }
    }
    wb <- openxlsx2::wb_add_worksheet(wb, sheet = sh)
    wb <- openxlsx2::wb_add_data(wb, sheet = sh, x = as.data.frame(tab),
                                 start_col = 1, start_row = 1)
    if (!is.null(p)) {
      png <- tempfile(fileext = ".png")
      pngs <- c(pngs, png)
      ggplot2::ggsave(png, p, width = width, height = height, dpi = 150,
                      bg = "white")
      wb <- openxlsx2::wb_add_image(
        wb, sheet = sh, file = png,
        dims = openxlsx2::wb_dims(rows = nrow(tab) + 3L, cols = 1L),
        width = width, height = height
      )
    }
  }

  save_workbook(wb, path)
  invisible(path)
}

# Internal: is a zip tool named but absent? openxlsx2 zips the workbook with an
# external tool whenever R_ZIPCMD is set or "zip" is on the PATH, and errors if
# the tool it names is not installed. On Windows R sets R_ZIPCMD=zip under
# `R CMD` whether or not a zip.exe exists, so this is the common case: a name
# with nothing behind it.
named_zip_tool_missing <- function() {
  tool <- Sys.getenv("R_ZIPCMD", unset = "")
  if (!nzchar(tool)) {
    tool <- unname(Sys.which("zip"))
  }
  nzchar(tool) && !nzchar(Sys.which(tool))
}

# Internal: write the workbook, sending openxlsx2 to its own zipping code when
# the external tool it would otherwise reach for is not really there.
save_workbook <- function(wb, path) {
  if (named_zip_tool_missing()) {
    old <- options(openxlsx2.no_utils_zip = TRUE)
    on.exit(options(old), add = TRUE)
  }
  openxlsx2::wb_save(wb, file = path, overwrite = TRUE)
}
