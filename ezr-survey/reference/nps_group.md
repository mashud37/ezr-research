# Classify Net Promoter Score answers into groups

Collapses an 0-10 "how likely to recommend" question into the three
standard NPS groups: detractors (0-6), passives (7-8) and promoters
(9-10).

## Usage

``` r
nps_group(x, labels = FALSE)
```

## Arguments

- x:

  A numeric vector of 0-10 ratings (character input is coerced).

- labels:

  If `FALSE` (default) returns the signed integer coding `-1 / 0 / 1`
  used by
  [`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md).
  If `TRUE` returns the labels `"Detractor" / "Passive" / "Promoter"`.

## Value

Either an integer vector (`-1/0/1`) or a character vector, the same
length as `x`. Out-of-range or missing values become `NA`.

## Details

The signed `-1/0/1` coding is deliberate: the mean of it, times 100, is
exactly the Net Promoter Score (% promoters minus % detractors), which
is how
[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md)
computes the headline number. Inputs are run through
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md)
first, so worded answers like `"9 - very likely"` are classified
correctly. Values outside 0–10 (and `NA`) return `NA`.

## See also

[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md),
[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md).

Other recode:
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md),
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md),
[`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md),
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
[`generation_scheme()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/generation_scheme.md),
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md),
[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md),
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md),
[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md),
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)

## Examples

``` r
nps_group(c(0, 6, 7, 8, 9, 10))
#> [1] -1 -1  0  0  1  1

nps_group(c(3, 8, 10), labels = TRUE)
#> [1] "Detractor" "Passive"   "Promoter" 
```
