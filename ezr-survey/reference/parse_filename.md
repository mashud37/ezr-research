# Split a filename column into metadata columns

Survey exports often encode metadata in the filename (e.g.
`"podracing_wave1_NA_2026.csv"`). This splits a filename column on a
separator into named metadata columns, dropping the file extension
first. Replaces the brittle `str_split(file, "_")[[1]][n]` indexing this
saves you.

## Usage

``` r
parse_filename(
  data = NULL,
  col = "file",
  into,
  sep = "_",
  drop_ext = TRUE,
  remove = FALSE
)
```

## Arguments

- data:

  A data frame.

- col:

  Name of the column holding the filename (string or unquoted). Defaults
  to `"file"`.

- into:

  Character vector of new column names, one per field you expect after
  splitting.

- sep:

  Separator to split on (a fixed string, not a regex). Defaults to
  `"_"`.

- drop_ext:

  If `TRUE` (default), strip a trailing file extension before splitting.

- remove:

  If `TRUE`, drop the original filename column. Defaults to `FALSE` so
  you keep the source reference.

## Value

The data frame with the new metadata columns added.

## Details

Pairs naturally with
[`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md),
whose `file` column carries the source filename: split it once and you
have event, wave, locale, year, etc. as real columns to group by. The
file extension is stripped first (`drop_ext`), the split is on a fixed
string (not a regex), and rows with fewer fields than `into` are padded
with `NA` so a stray filename never derails the parse.

## See also

[`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md).

Other import:
[`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md),
[`select_prefix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_prefix.md),
[`select_suffix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_suffix.md)

## Examples

``` r
df <- tibble::tibble(file = c("podracing_wave1_NA_2026.csv"))
parse_filename(df, into = c("survey", "wave", "locale", "year"))
#> # A tibble: 1 × 5
#>   file                        survey    wave  locale year 
#>   <chr>                       <chr>     <chr> <chr>  <chr>
#> 1 podracing_wave1_NA_2026.csv podracing wave1 NA     2026 
```
