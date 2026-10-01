# Recode age into standard survey bands

Convenience wrapper over
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md)
using the standard survey age bands. Also tolerates messy inputs such as
"25 years" by extracting the first run of digits.

## Usage

``` r
recode_age(
  x,
  breaks = ezrsurvey_default("age_breaks"),
  labels = ezrsurvey_default("age_labels"),
  quiet = FALSE
)
```

## Arguments

- x:

  A numeric or character vector of ages.

- breaks, labels:

  Override the default bands if needed; the defaults come from the
  `age_breaks` / `age_labels` options (see
  [`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)).

- quiet:

  If `FALSE` (default), report answers that held no number and answers
  that fell outside the bands. Set `TRUE` to silence both.

## Value

A factor of age-band labels, levels in band order.

## Details

Ages are first passed through
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
so messy entries like `"22 years"` or `"age: 31"` are handled, then
binned with
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md)
using left-closed bands. An answer with no number in it at all
(`"young"`, `"prefer not to say"`) becomes `NA` and is counted in a
message, so a column that was never numeric does not pass for a column
of missing ages. The default bands come from the `age_breaks` /
`age_labels` options, so you can set your study's standard cohorts once
with `ezrsurvey_options(age_breaks = ..., age_labels = ...)` (or a
profile) instead of passing them on every call. For *generational*
cohorts (Gen Z, Millennial, ...) use
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md)
instead.

## See also

[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md),
[`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md).

Other recode:
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md),
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md),
[`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md),
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
[`generation_scheme()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/generation_scheme.md),
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md),
[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md),
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md),
[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md),
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)

## Examples

``` r
recode_age(c("17", "22 years", "31", "47"))
#> [1] 17 or younger 22 to 25      30 to 34      35+          
#> Levels: 17 or younger 18 to 21 22 to 25 26 to 29 30 to 34 35+
```
