# Bin a numeric vector into labelled groups

A thin, survey-friendly wrapper around
[`base::cut()`](https://rdrr.io/r/base/cut.html) that returns a
character vector (not a factor) and uses left-closed, right-open
intervals by default so that age bands like 18-21 behave intuitively.
Generalises the `case_when(age %in% seq(...))` age-grouping pattern.

## Usage

``` r
bin_numeric(x, breaks, labels, right = FALSE, quiet = FALSE)
```

## Arguments

- x:

  A numeric vector.

- breaks:

  Numeric vector of cut points. With `n` labels you need `n + 1` breaks.
  Use `Inf` for an open-ended top band.

- labels:

  Character vector of group labels, length `length(breaks) - 1`.

- right:

  If `TRUE`, intervals are closed on the right; if `FALSE` (default)
  closed on the left. Left-closed matches "18 to 21" style bands.

- quiet:

  If `TRUE`, do not report values that fell outside `breaks`.

## Value

A character vector of group labels (values outside the range or `NA`
become `NA`).

## Details

Bands are built with [`base::cut()`](https://rdrr.io/r/base/cut.html)
using `include.lowest = TRUE`, so the very lowest break is included.
With `right = FALSE` (the default) a band runs from its lower break up
to *but not including* the next – i.e. `[18, 25)` – which is what you
want for age groups like "18 to 24". Text input is salvaged with
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
so `"27 years"` bins correctly. The result is a plain character vector
(not a factor); apply an order later with
[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md)
or pass `levels =` to
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
if you need a specific display order.

A value below the first break or above the last becomes `NA` and drops
out of every chart built from the result, so the function says how many
did and what their range was. A closed top band such as `35` to `40.5`
under a label of "35 to 40+" is the usual cause; `Inf` is what that
label means.

## See also

[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md)
for a ready-made age-band wrapper,
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md).

Other recode:
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md),
[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md),
[`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md),
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
bin_numeric(c(15, 19, 27, 41),
            breaks = c(0, 18, 25, 35, Inf),
            labels = c("<18", "18-24", "25-34", "35+"))
#> [1] "<18"   "18-24" "25-34" "35+"  
```
