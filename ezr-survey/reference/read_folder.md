# Read and stack every CSV in a folder

Loads all CSV files matching `pattern` in `path`, reading each as
character (so survey codes never get silently coerced), tags every row
with its source filename, and row-binds the lot into one tibble.
Generalises the `list.files() %>% map(read.csv) %>% bind_rows()` opening
of a survey script.

## Usage

``` r
read_folder(
  path,
  pattern = "\\.csv$",
  id = "file",
  all_character = TRUE,
  question_row = NULL,
  locale = readr::locale(encoding = "UTF-8"),
  ...
)
```

## Arguments

- path:

  Directory to read from.

- pattern:

  Regular expression matching the files to load. Defaults to `"\\.csv$"`
  (all CSVs).

- id:

  Name of the column in which to record each row's source filename.
  Defaults to `"file"`. Set to `NULL` to omit it.

- all_character:

  If `TRUE` (default), every column is read as character. This keeps
  ragged survey exports stackable; recode types afterwards with the
  `recode_*` helpers. If `FALSE`, types are guessed per file.

- question_row:

  What to do with a second header row of question wording. `NULL`
  (default) keeps it and warns when a file looks like it has one; `TRUE`
  drops the first row of every file; `FALSE` keeps it silently.

- locale:

  A
  [`readr::locale()`](https://readr.tidyverse.org/reference/locale.html)
  controlling encoding etc. Defaults to a UTF-8 locale; pass
  `readr::locale(encoding = "windows-1252")` for legacy exports.

- ...:

  Further arguments passed to
  [`readr::read_csv()`](https://readr.tidyverse.org/reference/read_delim.html).

## Value

A single [tibble](https://tibble.tidyverse.org/reference/tibble.html) of
all files stacked together. If columns differ across files, missing
columns are filled with `NA`.

## Details

Every matching file is read and the results are row-bound, so a folder
of monthly or per-event exports becomes one dataset. By default every
column is read as text (`all_character = TRUE`); this is deliberate,
because survey exports are ragged (a column that is numeric in one file
may carry "Prefer not to answer" in another), and stacking text columns
never fails. Recode the types you need afterwards with `recode_*()` /
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md).
The `id` column records which file each row came from – split it into
metadata with
[`parse_filename()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/parse_filename.md).
For legacy encodings pass a `locale`, e.g.
`readr::locale(encoding = "windows-1252")`.

Survey platforms commonly write the question wording as a second header
row, which reads back as respondent number one and quietly skews every
count by one. A file whose first row is long, spaced prose in most
columns at once and numeric in none is reported as such;
`question_row = TRUE` drops that row from every file, and `FALSE` keeps
it without comment.

## See also

[`select_prefix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_prefix.md),
[`parse_filename()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/parse_filename.md).

Other import:
[`parse_filename()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/parse_filename.md),
[`select_prefix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_prefix.md),
[`select_suffix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_suffix.md)

## Examples

``` r
# build a tiny folder of CSVs, then read them back
dir <- tempfile(); dir.create(dir)
readr::write_csv(head(podracing_survey, 3), file.path(dir, "a.csv"))
readr::write_csv(head(podracing_survey, 2), file.path(dir, "b.csv"))
read_folder(dir)[, c("file", "respondent_id")]
#> # A tibble: 5 × 2
#>   file  respondent_id
#>   <chr> <chr>        
#> 1 a.csv R00001       
#> 2 a.csv R00002       
#> 3 a.csv R00003       
#> 4 b.csv R00001       
#> 5 b.csv R00002       
```
