# Recode age or birth year into a generational cohort

Maps either an **age** (converted to a birth year using a reference
year) or a **birth year** directly onto a generational cohort such as
Millennial or Gen Z. Text input like `"34 years"` is salvaged with
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md).

## Usage

``` r
recode_generation(x, input = c("age", "year"), year = NULL, scheme = NULL)
```

## Arguments

- x:

  A numeric (or coercible) vector of ages or birth years.

- input:

  What `x` represents: `"age"` (default) or `"year"` (birth year).

- year:

  Reference year for the age-to-birth-year conversion. If `NULL`
  (default), uses the `current_year` option (see
  [`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md))
  or the system year.

- scheme:

  Either a scheme name passed to
  [`generation_scheme()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/generation_scheme.md)
  (default from the `generation_scheme` option) or your own data frame
  with `from` and `label` columns.

## Value

A factor of cohort labels, levels from the oldest cohort to the
youngest; values outside the scheme's range become `NA`.

## Details

When `input = "age"`, the birth year is `year - age`, where `year`
defaults to the `current_year` option or the system year – so set
`ezrsurvey_options(current_year = 2026)` to keep results stable across
runs. When `input = "year"`, `x` is treated as the birth year directly.
The birth year is then bucketed into the scheme's cohorts (see
[`generation_scheme()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/generation_scheme.md));
birth years before the earliest cohort return `NA`. Use this for
generational reporting; for simple age bands use
[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md).

## See also

[`generation_scheme()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/generation_scheme.md),
[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md),
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
[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md),
[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md),
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)

## Examples

``` r
recode_generation(c(1990, 2001, 1968), input = "year")
#> [1] Millennial Gen Z      Gen X     
#> Levels: Silent Baby Boomer Gen X Millennial Gen Z Gen Alpha

# from age, with an explicit reference year
recode_generation(c(36, 25), input = "age", year = 2026)
#> [1] Millennial Gen Z     
#> Levels: Silent Baby Boomer Gen X Millennial Gen Z Gen Alpha
```
