# Coerce text to numeric, salvaging embedded numbers

A defensive helper for the common survey-export headache where a column
that should be numeric arrives as text – `"25 years"`,
`"8 - very likely"`, `"3.5/5"`. It returns `x` unchanged if it is
already numeric; otherwise it pulls the first number out of each value
(via a digit pattern) and coerces to numeric, leaving genuinely
unparseable entries as `NA`. The ezrsurvey functions that need numbers
(e.g.
[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md),
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md))
call this for you, so they "just work" on lightly messy data.

## Usage

``` r
ensure_numeric(x, name = NULL, quiet = FALSE)
```

## Arguments

- x:

  A vector. Numeric input is returned as-is.

- name:

  Optional column/argument name, used only to make the message clearer.

- quiet:

  If `FALSE` (default), emit a one-line message when coercion happens
  (and note any values that could not be parsed). Set `TRUE` to silence
  it.

## Value

A numeric vector the same length as `x`.

## Details

The first numeric token in each value is extracted with the pattern
`-?[0-9]*\.?[0-9]+`, which captures negatives and decimals but takes
only the *first* number it finds – so `"8 - very likely"` becomes `8`,
not `-8`. A value that is genuinely numeric already is returned
untouched (no copy, no message). When `quiet = FALSE` a single
informative message reports that coercion happened and how many values
could not be parsed; the internal callers
([`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md),
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md),
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md),
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
...) pass `quiet = TRUE` so they don't spam your console. Truly blank
entries (`""`/`NA`) are not counted as parse failures.

## See also

[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md),
[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md),
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md).

Other recode:
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md),
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md),
[`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md),
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
ensure_numeric(c("25 years", "31", "forty"), quiet = TRUE)
#> [1] 25 31 NA

ensure_numeric(c("8 - very likely", "10", "3.5/5"), quiet = TRUE)
#> [1]  8.0 10.0  3.5

ensure_numeric(c(1, 2, 3))    # already numeric, returned as-is
#> [1] 1 2 3
```
