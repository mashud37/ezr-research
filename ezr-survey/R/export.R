# Internal: lower-case file extension without the dot.
file_ext <- function(path) tolower(tools::file_ext(path))

# Internal: the name used when the caller gives no path at all.
default_output_path <- function(name, ext) {
  paste0(name, ".", ext)
}

# Internal: where a file actually gets written. A bare file name goes into the
# project-local outputs folder, so a session's results collect in one place
# instead of scattering through the working directory; the folder is created if
# it is missing, and is never the session temp directory. A path that names a
# directory ("./out.pptx", "charts/x.png", anything absolute) is taken exactly as
# written, which is how the caller overrides that.
resolve_output_path <- function(path) {
  folder <- ezrsurvey_default("output_dir")
  bare <- identical(dirname(path), ".") && !startsWith(path, "./")
  if (bare && folder != ".") {
    path <- file.path(folder, path)
  }
  dir <- dirname(path)
  if (nzchar(dir) && dir != "." && !dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
  path
}

#' Quick-save a plot to PNG, SVG or PDF
#'
#' A thin, pipe-friendly wrapper around [ggplot2::ggsave()] that picks the device
#' from the file extension and uses presentation-friendly defaults (transparent
#' background, generous size). Returns the plot invisibly, so it drops into a
#' pipeline without breaking it.
#'
#' @param plot A ggplot object.
#' @param path Output path; the extension sets the format (`.png`, `.svg`,
#'   `.pdf`, `.jpg`/`.jpeg`, `.tiff`). `NULL` (default) writes `plot.png`.
#'   A bare file name lands in `ezrsurvey-outputs/` (created on demand); a path
#'   naming a directory (`"./x.png"`, `"charts/x.png"`, anything absolute) is used
#'   exactly as given. See the `output_dir` option.
#' @param width,height Size in inches. Default `8 x 4.5`.
#' @param dpi Raster resolution for PNG/JPG/TIFF. Default `300`.
#' @param bg Background fill. Default `"transparent"` (matches the ezrsurvey
#'   themes); use `"white"` for a solid background.
#' @param ... Passed to [ggplot2::ggsave()].
#'
#' @return The `plot`, invisibly.
#'
#' @details
#' The device is chosen from the file extension, and the plot is returned
#' invisibly so the call slots into a pipeline without breaking it
#' (`p %>% save_plot("p.png") %>% print()`). Defaults suit slides: a transparent
#' background (matching the ezrsurvey themes) and a generous size; pass
#' `bg = "white"` for a solid background. SVG output needs the suggested
#' `svglite` package.
#'
#' @family save
#' @seealso [save_data()], [save_output()].
#' @examples
#' p <- plot_bars(calc_percentage(podracing_survey, demo_gender))
#' tmp <- tempfile(fileext = ".png")
#' save_plot(p, tmp)
#' file.exists(tmp)
#' @export
save_plot <- function(plot, path = NULL, width = 8, height = 4.5, dpi = 300,
                      bg = "transparent", ...) {
  if (!inherits(plot, "ggplot")) {
    stop("`plot` must be a ggplot object.", call. = FALSE)
  }
  path <- resolve_output_path(path %||% default_output_path("plot", "png"))
  ext <- file_ext(path)
  if (ext == "svg" && !requireNamespace("svglite", quietly = TRUE)) {
    stop("Saving SVG needs the 'svglite' package. ",
         "Install it with install.packages('svglite').", call. = FALSE)
  }
  ggplot2::ggsave(filename = path, plot = plot, width = width,
                  height = height, dpi = dpi, bg = bg, ...)
  invisible(plot)
}

#' Quick-save a table to CSV, TSV or XLSX
#'
#' A pipe-friendly one-liner for dropping a summary table to disk. The format is
#' taken from the file extension. For `.xlsx`, pass a single data frame for one
#' sheet, or a *named* list of data frames to write one sheet per element.
#' Returns its input invisibly so it can sit mid-pipeline.
#'
#' @param data A data frame / tibble, or (for `.xlsx`) a named list of them.
#' @param path Output path; the extension sets the format (`.csv`, `.tsv`,
#'   `.xlsx`). `NULL` (default) writes `data.csv`.
#'   A bare file name lands in `ezrsurvey-outputs/` (created on demand); a path
#'   naming a directory (`"./x.csv"`, `"charts/x.csv"`, anything absolute) is used
#'   exactly as given. See the `output_dir` option.
#' @param na String to write for missing values. Default `""`.
#' @param ... Passed to the underlying writer ([readr::write_csv()] /
#'   [readr::write_tsv()] / [writexl::write_xlsx()]).
#'
#' @return `data`, invisibly.
#'
#' @details
#' The format follows the file extension: `.csv`/`.tsv` via \pkg{readr}, `.xlsx`
#' via the suggested `writexl` package. For an Excel workbook, pass one data
#' frame for a single sheet, or a *named* list of data frames for one sheet each.
#' Returns its input invisibly so it can sit mid-pipeline. To send several
#' separate calls to their own tabs in one line, see [export_xlsx()].
#'
#' @family save
#' @seealso [save_plot()], [save_output()], [export_xlsx()].
#' @examples
#' tab <- calc_percentage(podracing_survey, demo_gender)
#' tmp <- tempfile(fileext = ".csv")
#' save_data(tab, tmp)
#' file.exists(tmp)
#' @export
save_data <- function(data, path = NULL, na = "", ...) {
  path <- resolve_output_path(path %||% default_output_path("data", "csv"))
  ext <- file_ext(path)
  switch(
    ext,
    csv = readr::write_csv(data, path, na = na, ...),
    tsv = readr::write_tsv(data, path, na = na, ...),
    xlsx = {
      if (!requireNamespace("writexl", quietly = TRUE)) {
        stop("Saving XLSX needs the 'writexl' package. ",
             "Install it with install.packages('writexl').", call. = FALSE)
      }
      writexl::write_xlsx(data, path = path, ...)
    },
    stop("Unsupported data extension '", ext,
         "'. Use .csv, .tsv or .xlsx.", call. = FALSE)
  )
  invisible(data)
}

#' Quick-save any ezrsurvey output (plot or table)
#'
#' Convenience dispatcher: routes ggplots to [save_plot()] and data frames /
#' lists to [save_data()], choosing by the object type. Handy at the end of a
#' pipe when you do not want to think about which saver to call.
#'
#' @param x A ggplot, a data frame, or a (named) list of data frames.
#' @param path Output path; the extension picks the format. `NULL` (default)
#'   writes `plot.png` or `data.csv`.
#'   A bare file name lands in `ezrsurvey-outputs/` (created on demand); a path
#'   naming a directory (`"./x.png"`, `"charts/x.png"`, anything absolute) is used
#'   exactly as given. See the `output_dir` option.
#' @param ... Passed to [save_plot()] or [save_data()].
#'
#' @return `x`, invisibly.
#' @family save
#' @seealso [save_plot()], [save_data()].
#' @examples
#' tmp_csv <- tempfile(fileext = ".csv")
#' calc_percentage(podracing_survey, demo_gender) %>% save_output(tmp_csv)
#'
#' \donttest{
#' tmp_png <- tempfile(fileext = ".png")
#' plot_bars(calc_percentage(podracing_survey, demo_gender)) %>% save_output(tmp_png)
#' }
#' @export
save_output <- function(x, path = NULL, ...) {
  if (inherits(x, "ggplot")) {
    save_plot(x, path, ...)
  } else if (is.data.frame(x) || is.list(x)) {
    save_data(x, path, ...)
  } else {
    stop("Don't know how to save an object of class '",
         paste(class(x), collapse = "/"), "'.", call. = FALSE)
  }
  invisible(x)
}

# Internal: clean a vector of names into valid, unique Excel sheet names
# (<= 31 chars, no [ ] : * ? / \).
sanitize_sheet_names <- function(x) {
  x <- as.character(x)
  for (ch in c("\\", "/", "?", "*", ":", "[", "]")) {
    x <- gsub(ch, "_", x, fixed = TRUE)
  }
  x[is.na(x) | !nzchar(x)] <- "Sheet"
  x <- substr(x, 1, 28)              # leave room for a uniqueness suffix
  make.unique(x, sep = "_")
}

# Internal: a default tab name for a single data frame.
derive_sheet_name <- function(df, i) {
  nm <- NULL
  if ("variable" %in% names(df) && length(unique(df$variable)) == 1L) {
    nm <- as.character(df$variable[[1]])
  } else if (length(names(df)) > 0) {
    nm <- names(df)[[1]]
  }
  if (is.null(nm) || is.na(nm) || !nzchar(nm)) nm <- paste0("Sheet", i)
  nm
}

#' Export several tables to one Excel workbook, a tab each
#'
#' A quick way to drop a handful of summaries into a single `.xlsx`, one per
#' worksheet -- e.g. `export_xlsx(calc_percentage(d, a), calc_percentage(d, b),
#' path = "out.xlsx")`. Tabs are named from the argument names you give, else
#' from each table's question/first column, else `Sheet1`, `Sheet2`, ...
#'
#' @param ... Data frames to write, one per tab. Name them to set tab names
#'   (e.g. `gender = calc_percentage(d, demo_gender)`).
#' @param path Output `.xlsx` path. `NULL` (default) writes `tables.xlsx`.
#'   A bare file name lands in `ezrsurvey-outputs/` (created on demand); a path
#'   naming a directory (`"./x.xlsx"`, `"charts/x.xlsx"`, anything absolute) is used
#'   exactly as given. See the `output_dir` option.
#' @param sheet_names Optional character vector of tab names (overrides argument
#'   names).
#'
#' @return Invisibly `path`.
#'
#' @details
#' Each argument becomes one worksheet. Tab names are taken from the argument
#' names you give (`gender = ...`), otherwise from each table's `variable` column
#' or first column, otherwise `Sheet1`, `Sheet2`, ...; they are then cleaned to
#' valid, unique Excel names (<= 31 characters, with `[ ] : * ? / \\` stripped).
#' This is the quick way to drop a set of summaries into one workbook for a
#' colleague. Requires the suggested `writexl` package.
#'
#' @family save
#' @seealso [save_data()] for a single table or a pre-named list.
#' @examples
#' tmp <- tempfile(fileext = ".xlsx")
#' export_xlsx(
#'   gender = calc_percentage(podracing_survey, demo_gender),
#'   calc_percentage(podracing_survey, demo_job),
#'   path = tmp
#' )
#' file.exists(tmp)
#' @export
export_xlsx <- function(..., path = NULL, sheet_names = NULL) {
  if (!requireNamespace("writexl", quietly = TRUE)) {
    stop("Exporting XLSX needs the 'writexl' package. ",
         "Install it with install.packages('writexl').", call. = FALSE)
  }
  path <- resolve_output_path(path %||% default_output_path("tables", "xlsx"))
  items <- list(...)
  if (length(items) == 0L) {
    stop("Provide at least one data frame to export.", call. = FALSE)
  }
  if (!all(vapply(items, is.data.frame, logical(1)))) {
    stop("All `...` arguments must be data frames.", call. = FALSE)
  }

  given <- names(items)
  if (is.null(given)) given <- rep("", length(items))
  nms <- vapply(seq_along(items), function(i) {
    if (!is.null(sheet_names) && length(sheet_names) >= i &&
        nzchar(sheet_names[[i]])) {
      sheet_names[[i]]
    } else if (nzchar(given[[i]])) {
      given[[i]]
    } else {
      derive_sheet_name(items[[i]], i)
    }
  }, character(1))

  writexl::write_xlsx(stats::setNames(items, sanitize_sheet_names(nms)),
                      path = path)
  invisible(path)
}
