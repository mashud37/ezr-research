# Split a packed multi-select column into one column per answer

Turns the single cell a spreadsheet export gives a "tick all that apply"
question (`"Speed; Drivers; Betting"`) into the one-column-per-option
layout the rest of the package expects, so
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)
and the plots all work on it.

## Usage

``` r
split_multi(data = NULL, column, split = "auto", prefix = NULL)
```

## Arguments

- data:

  A data frame. If omitted, the session default
  ([`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md))
  is used.

- column:

  The packed column (unquoted).

- split:

  The delimiter between answers inside a cell. `"auto"` (default)
  detects `";"`, `"|"` or `","`, in that order. Pass a string to force
  one.

- prefix:

  Prefix for the new column names. Defaults to the column's own name
  followed by an underscore, e.g. `motivations_`.

## Value

The data frame with one new column per distinct answer, each holding the
answer text for respondents who chose it and `""` for those who did not,
ordered most-chosen first. The packed column is kept.

## Details

Google Forms, Google Sheets and most survey platforms export a
multi-select question as one cell per respondent holding every answer
they ticked, joined by a delimiter. That shape cannot be counted
directly, because a respondent who ticked three options is one row, not
three. This function unpacks it into the indicator layout the package's
own datasets use.

The new columns are named `prefix` plus the answer text verbatim, which
keeps the labels readable all the way through to a chart:
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)
strips the prefix back off and uses what remains as the option label.
Answer text is rarely a syntactic R name, so refer to the new columns
with backticks if you need them individually. Surrounding whitespace is
trimmed and empty answers are dropped, so `"Speed; ; Drivers"` yields
two options. When no cell contains the delimiter, each cell is treated
as a single answer, which is the right answer for a multi-select
question everyone happened to answer once.

If you only want the percentages, skip this step:
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)
detects a packed column and splits it for you.

## See also

[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md).

Other recode:
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md),
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md),
[`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md),
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
[`generation_scheme()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/generation_scheme.md),
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md),
[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md),
[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md),
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md),
[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md),
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md)

## Examples

``` r
packed <- data.frame(
  respondent = 1:4,
  motivations = c("Speed; Drivers", "Speed", "", "Betting; Speed")
)
split_multi(packed, motivations)
#> # A tibble: 4 × 5
#>   respondent motivations      motivations_Speed motivations_Betting
#>        <int> <chr>            <chr>             <chr>              
#> 1          1 "Speed; Drivers" "Speed"           ""                 
#> 2          2 "Speed"          "Speed"           ""                 
#> 3          3 ""               ""                ""                 
#> 4          4 "Betting; Speed" "Speed"           "Betting"          
#> # ℹ 1 more variable: motivations_Drivers <chr>

split_multi(packed, motivations) %>%
  calc_percentage_multi("motivations_", id = respondent, sort = "desc")
#> # A tibble: 3 × 3
#>   option      n   pct
#>   <fct>   <int> <dbl>
#> 1 Speed       3   100
#> 2 Betting     1    33
#> 3 Drivers     1    33
```
