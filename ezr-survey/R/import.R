#' Read and stack every CSV in a folder
#'
#' Loads all CSV files matching `pattern` in `path`, reading each as character
#' (so survey codes never get silently coerced), tags every row with its source
#' filename, and row-binds the lot into one tibble. Generalises the
#' `list.files() %>% map(read.csv) %>% bind_rows()` opening of the original
#' scripts.
#'
#' @param path Directory to read from.
#' @param pattern Regular expression matching the files to load. Defaults to
#'   `"\\.csv$"` (all CSVs).
#' @param id Name of the column in which to record each row's source filename.
#'   Defaults to `"file"`. Set to `NULL` to omit it.
#' @param all_character If `TRUE` (default), every column is read as character.
#'   This keeps ragged survey exports stackable; recode types afterwards with
#'   the `recode_*` helpers. If `FALSE`, types are guessed per file.
#' @param locale A [readr::locale()] controlling encoding etc. Defaults to a
#'   UTF-8 locale; pass `readr::locale(encoding = "windows-1252")` for legacy
#'   exports.
#' @param ... Further arguments passed to [readr::read_csv()].
#'
#' @return A single [tibble][tibble::tibble] of all files stacked together. If
#'   columns differ across files, missing columns are filled with `NA`.
#'
#' @details
#' Every matching file is read and the results are row-bound, so a folder of
#' monthly or per-event exports becomes one dataset. By default every column is
#' read as text (`all_character = TRUE`); this is deliberate, because survey
#' exports are ragged (a column that is numeric in one file may carry "Prefer
#' not to answer" in another), and stacking text columns never fails. Recode the
#' types you need afterwards with `recode_*()` / [ensure_numeric()]. The `id`
#' column records which file each row came from -- split it into metadata with
#' [parse_filename()]. For legacy encodings pass a `locale`, e.g.
#' `readr::locale(encoding = "windows-1252")`.
#'
#' @family import
#' @seealso [select_prefix()], [parse_filename()].
#' @examples
#' # build a tiny folder of CSVs, then read them back
#' dir <- tempfile(); dir.create(dir)
#' readr::write_csv(head(podracing_survey, 3), file.path(dir, "a.csv"))
#' readr::write_csv(head(podracing_survey, 2), file.path(dir, "b.csv"))
#' read_folder(dir)[, c("file", "respondent_id")]
#' @export
read_folder <- function(path, pattern = "\\.csv$", id = "file",
                        all_character = TRUE,
                        locale = readr::locale(encoding = "UTF-8"), ...) {
  if (!dir.exists(path)) {
    stop("Directory does not exist: ", path, call. = FALSE)
  }
  files <- list.files(path, pattern = pattern, full.names = FALSE)
  if (length(files) == 0L) {
    stop("No files matching '", pattern, "' found in ", path, call. = FALSE)
  }

  col_types <- if (all_character) readr::cols(.default = readr::col_character()) else NULL

  pieces <- purrr::map(files, function(f) {
    inp <- readr::read_csv(
      file.path(path, f),
      col_types = col_types,
      locale = locale,
      show_col_types = FALSE,
      ...
    )
    if (!is.null(id)) {
      inp[[id]] <- f
    }
    inp
  })

  dplyr::bind_rows(pieces)
}

#' Select identifier and prefixed columns
#'
#' Keeps a handful of id columns plus every column sharing a prefix -- the
#' `select(id, starts_with("demo_"))` idiom -- in one tidy call.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param prefix One or more column-name prefixes to keep (e.g. `"demo_"`, or
#'   `c("demo_", "ratings_")`).
#' @param keep Optional character vector of additional column names to retain in
#'   front of the prefixed block (e.g. an id column).
#'
#' @return A data frame with `keep` columns followed by all prefix-matching
#'   columns.
#'
#' @details
#' Survey questionnaires are usually organised by prefix (`demo_`, `ratings_`,
#' `partner_`, ...), so this is a quick way to grab one block plus a couple of id
#' columns without naming every variable. Order is `keep` first, then the
#' prefix-matching columns in their original order.
#'
#' @family import
#' @seealso [read_folder()], [calc_percentage_multi()].
#' @examples
#' select_prefix(podracing_survey, "demo_", keep = "respondent_id")
#' select_prefix(podracing_survey, c("ratings_", "partner_"))
#' @export
select_prefix <- function(data = NULL, prefix, keep = NULL) {
  data <- resolve_data(data)
  dplyr::select(
    data,
    dplyr::all_of(keep %||% character(0)),
    dplyr::starts_with(prefix)
  )
}

#' Select identifier and suffixed columns
#'
#' The mirror of [select_prefix()]: keeps a handful of id columns plus every
#' column sharing a suffix -- the `select(id, ends_with("_com"))` idiom -- in
#' one tidy call.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()])
#'   is used.
#' @param suffix One or more column-name suffixes to keep (e.g. `"_com"`, or
#'   `c("_com", "_score")`).
#' @param keep Optional character vector of additional column names to retain in
#'   front of the suffixed block (e.g. an id column).
#'
#' @return A data frame with `keep` columns followed by all suffix-matching
#'   columns.
#'
#' @details
#' Some questionnaire blocks are marked by a trailing tag rather than a leading
#' one (`_com` open-text follow-ups, `_score` derived columns), so this grabs
#' one such block plus a couple of id columns without naming every variable.
#' Order is `keep` first, then the suffix-matching columns in their original
#' order.
#'
#' @family import
#' @seealso [select_prefix()], [read_folder()].
#' @examples
#' select_suffix(podracing_survey, "_com", keep = "respondent_id")
#' @export
select_suffix <- function(data = NULL, suffix, keep = NULL) {
  data <- resolve_data(data)
  dplyr::select(
    data,
    dplyr::all_of(keep %||% character(0)),
    dplyr::ends_with(suffix)
  )
}

#' Split a filename column into metadata columns
#'
#' Survey exports often encode metadata in the filename (e.g.
#' `"podracing_wave1_NA_2026.csv"`). This splits a filename column on a
#' separator into named metadata columns, dropping the file extension first.
#' Replaces the brittle `str_split(file, "_")[[1]][n]` indexing in the original
#' scripts.
#'
#' @param data A data frame.
#' @param col Name of the column holding the filename (string or unquoted).
#'   Defaults to `"file"`.
#' @param into Character vector of new column names, one per field you expect
#'   after splitting.
#' @param sep Separator to split on (a fixed string, not a regex). Defaults to
#'   `"_"`.
#' @param drop_ext If `TRUE` (default), strip a trailing file extension before
#'   splitting.
#' @param remove If `TRUE`, drop the original filename column. Defaults to
#'   `FALSE` so you keep the source reference.
#'
#' @return The data frame with the new metadata columns added.
#'
#' @details
#' Pairs naturally with [read_folder()], whose `file` column carries the source
#' filename: split it once and you have event, wave, locale, year, etc. as real
#' columns to group by. The file extension is stripped first (`drop_ext`), the
#' split is on a fixed string (not a regex), and rows with fewer fields than
#' `into` are padded with `NA` so a stray filename never derails the parse.
#'
#' @family import
#' @seealso [read_folder()].
#' @examples
#' df <- tibble::tibble(file = c("podracing_wave1_NA_2026.csv"))
#' parse_filename(df, into = c("survey", "wave", "locale", "year"))
#' @export
parse_filename <- function(data = NULL, col = "file",
                           into, sep = "_", drop_ext = TRUE, remove = FALSE) {
  data <- resolve_data(data)
  col_name <- rlang::as_name(rlang::ensym(col))
  if (!col_name %in% names(data)) {
    stop("Column '", col_name, "' not found in `data`.", call. = FALSE)
  }

  work <- data
  src <- as.character(work[[col_name]])
  if (drop_ext) {
    src <- stringr::str_remove(src, "\\.[A-Za-z0-9]+$")
  }

  parts <- stringr::str_split(src, stringr::fixed(sep))
  mat <- do.call(rbind, lapply(parts, function(p) {
    length(p) <- length(into) # pad/truncate to expected width
    p
  }))
  meta <- tibble::as_tibble(stats::setNames(as.data.frame(mat,
    stringsAsFactors = FALSE), into))

  out <- dplyr::bind_cols(work, meta)
  if (remove) {
    out <- dplyr::select(out, -dplyr::all_of(col_name))
  }
  out
}

# Null-coalescing helper (kept local to avoid a hard rlang re-export).
`%||%` <- function(x, y) if (is.null(x)) y else x
