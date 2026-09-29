# Recode a worded rating scale to integers

Maps the worded answers of an ordinal rating question (e.g. "Very bad"
... "Very good") onto integers `1:length(levels)`. Matching is
case-insensitive and tolerant of common synonyms supplied via
`synonyms`, in place of a `case_when(str_detect("Very bad") ...)`
recoding block.

## Usage

``` r
recode_likert(
  x,
  levels = c("Very bad", "Bad", "Ok", "Good", "Very good"),
  synonyms = NULL
)
```

## Arguments

- x:

  A character (or factor) vector of worded answers.

- levels:

  Character vector of the scale's answer wordings in ascending order.
  The first element maps to `1`, the last to `length(levels)`. Defaults
  to a 5-point bad-to-good scale.

- synonyms:

  Optional named list mapping a canonical level (one of `levels`) to a
  character vector of alternative spellings that should map to the same
  integer. Matching is by case-insensitive substring.

## Value

An integer vector the same length as `x`; unmatched values become `NA`.

## Details

Matching happens in three passes, in order: (1) an exact,
case-insensitive, trimmed match against `levels`; (2) a substring
fallback, so prefixed exports like `"4 - Good"` still resolve; (3) any
`synonyms` you supply. This makes the function robust to the small
wording differences between survey tools (e.g. "Dissatisfied" vs "Bad").
Turning ratings into integers is the first step of
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)
and lets you average a scale with
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md).

The substring passes try the longest wording first, so a scale whose
levels nest inside one another ("Likeable" inside "Very likeable",
"Good" inside "Very good") resolves to the level the answer actually
names. Without that, any answer the exact pass misses, such as one
carrying an emoji or a stray character, would quietly land on the
shorter level.

## See also

[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md),
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md),
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md).

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
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)

## Examples

``` r
recode_likert(c("Very bad", "Ok", "Good", "Very good"))
#> [1] 1 3 4 5

# substring fallback copes with numbered labels
recode_likert("4 - Good")
#> [1] 4

# nested wordings resolve to the level the answer names, not the shorter one
recode_likert(c("\U0001F642 Very good", "\U0001F610 Good"))
#> [1] 5 4

# map another tool's wording onto the same scale
recode_likert(c("Dissatisfied", "Satisfied"),
              synonyms = list(Bad = "Dissatisfied", Good = "Satisfied"),
              levels = c("Very bad", "Bad", "Ok", "Good", "Very good"))
#> [1] 2 4
```
