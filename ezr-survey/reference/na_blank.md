# Convert blank and boilerplate non-answers to `NA`

Survey exports are littered with empty strings and standard "non-answer"
options such as "Prefer not to answer". This helper turns those into
real `NA` values so they drop out of counts and summaries, replacing the
repetitive `filter(x != "", x != "Prefer not to answer")` idiom.

## Usage

``` r
na_blank(x, also = ezrsurvey_default("na_answers"), trim = TRUE)
```

## Arguments

- x:

  A character (or factor) vector.

- also:

  Additional exact strings to treat as missing. Defaults to the
  `na_answers` option (`"Prefer not to answer"`; see
  [`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)).
  Set to `character(0)` to only blank out `""`.

- trim:

  Whether to trim surrounding whitespace before comparing. Defaults to
  `TRUE`.

## Value

A character vector the same length as `x`, with blanks and non-answers
replaced by `NA`.

## Details

The input is coerced to character (so factors are handled), optionally
whitespace-trimmed, and any value equal to `""` or to one of `also`
becomes `NA`. The default `also` reads the `na_answers` option, so you
can change what counts as a non-answer package-wide with
`ezrsurvey_options(na_answers = ...)`. Most of the `calc_*` helpers call
`na_blank()` internally when `na_rm = TRUE`, so you usually get this
clean-up for free; call it directly when you want to blank a column in a
pipeline.

## See also

[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
[`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md).

Other recode:
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md),
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md),
[`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md),
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
[`generation_scheme()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/generation_scheme.md),
[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md),
[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md),
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md),
[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md),
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)

## Examples

``` r
na_blank(c("Yes", "", "Prefer not to answer", "No"))
#> [1] "Yes" NA    NA    "No" 

# add your own non-answers
na_blank(c("a", "n/a", "N/A"), also = c("n/a", "N/A"))
#> [1] "a" NA  NA 
```
