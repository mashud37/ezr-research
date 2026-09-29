# Tidy an exported column name into a readable label

Turns the mangled column names survey tools produce back into the
wording a reader expects: `"Broadcast.quality...audio"` becomes
`"Broadcast quality / audio"`. Drop a question prefix at the same time
with `prefix`, so a block of `ratings_*` columns becomes plain feature
names.

## Usage

``` r
clean_label(x, prefix = NULL)
```

## Arguments

- x:

  A character vector of column names.

- prefix:

  Optional prefix to strip from the start of each name before tidying,
  e.g. `"ratings_"`. Names that do not start with it are left alone.

## Value

A character vector of labels, the same length as `x`.

## Details

Exporters replace every character they cannot put in a column name with
a dot, so a slash surrounded by spaces arrives as three dots and a space
arrives as one. This restores both, in that order, then squishes the
result. It is the same cleaning
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)
and
[`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)
apply to their own output, exported so a hand-built table can match
them: labels that disagree will not join, which is what silently empties
a comparison chart.

## See also

[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md),
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md).

Other recode:
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md),
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
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
clean_label("Broadcast.quality...audio")
#> [1] "Broadcast quality / audio"

clean_label(c("ratings_Camera.work", "ratings_Talent...analysis"),
            prefix = "ratings_")
#> [1] "Camera work"       "Talent / analysis"
```
