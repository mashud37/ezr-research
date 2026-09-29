# Drop unwanted answer categories from a question

Removes specific answer values – typically catch-all or uninformative
options such as "Other", "Don't know" or "Not applicable" – by turning
them into `NA`, so they fall out of counts, percentages and charts and
the remaining percentages re-base on the answers you keep. The companion
to
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md)
(which targets blanks and standard non-answers): use `drop_items()` for
the substantive categories you simply do not want to show.

## Usage

``` r
drop_items(x, items, trim = TRUE)
```

## Arguments

- x:

  A character (or factor) vector.

- items:

  Character vector of exact answer values to drop. Matching is
  case-insensitive.

- trim:

  Whether to trim surrounding whitespace before comparing. Defaults to
  `TRUE`.

## Value

A character vector the same length as `x`, with any value matching
`items` replaced by `NA`.

## Details

`x` is coerced to character (so factors are handled) and, by default,
whitespace-trimmed; any value equal (ignoring case) to one of `items`
becomes `NA`. The summary helpers
([`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md))
and
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)
take a `drop =` argument that applies this for you *before* counting, so
the kept answers re-base to ~100%; set a session-wide default with
`ezrsurvey_options(drop_answers = ...)`.

## See also

[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md),
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md).

Other recode:
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md),
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md),
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
[`generation_scheme()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/generation_scheme.md),
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md),
[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md),
[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md),
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md),
[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md),
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)

## Examples

``` r
drop_items(c("Yes", "No", "Other", "Don't know"),
           items = c("Other", "Don't know"))
#> [1] "Yes" "No"  NA    NA   
```
