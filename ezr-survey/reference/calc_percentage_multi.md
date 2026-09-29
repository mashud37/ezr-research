# Tabulate a check-all-that-apply (multi-select) question as percentages

Multi-select questions arrive as a block of columns sharing a prefix,
each holding the chosen option (or blank). This computes, per option,
the share of respondents who selected it – so the percentages can (and
usually do) sum to more than 100. The denominator is the number of
distinct respondents who selected at least one option.

## Usage

``` r
calc_percentage_multi(
  data = NULL,
  prefix,
  id = NULL,
  by = NULL,
  sort = c("none", "desc", "asc"),
  digits = 0,
  drop = NULL,
  clean_names = TRUE,
  split = "auto"
)
```

## Arguments

- data:

  A data frame.

- prefix:

  Common column-name prefix identifying the option block, e.g.
  `"motivations_"`.

- id:

  Optional respondent identifier column (unquoted) used as the
  distinct-respondent denominator. If omitted, each row is treated as
  one respondent.

- by:

  Optional grouping column(s); percentages are computed within group.

- sort, digits:

  As in
  [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md).
  Sorting acts on the `option` labels.

- drop:

  Optional character vector of option labels to remove before counting
  (matched against the cleaned labels, case-insensitive). Defaults to
  the `drop_answers` option. See
  [`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md).

- clean_names:

  If `TRUE` (default), tidy the option labels by stripping `prefix` and
  un-mangling exporter artefacts (`"A...B"` -\> `"A / B"`).

- split:

  How to handle a question that arrives packed into a single cell per
  respondent (`"Speed; Drivers"`). `"auto"` (default) detects `";"`,
  `"|"` or `","` and splits on it; pass a string to force a delimiter,
  or `FALSE` never to split. Only ever applies when `prefix` selects
  exactly one column.

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
`option`, `n` (respondents choosing it) and `pct`.

## Details

The crucial difference from
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
is the denominator: it is the number of distinct respondents who picked
*any* option in the block, not the number of ticks. So if 700 of 1,000
respondents selected at least one motivation, each option's percentage
is "out of 700", and the percentages can (and usually do) sum to more
than 100. Supply `id` to count distinct respondents exactly; without it,
each row counts as one respondent. With `clean_names = TRUE` the option
labels are stripped of `prefix` and exporter artefacts like `"A...B"`
are turned back into `"A / B"`.

Two export shapes are handled. The usual one is a block of columns, one
per option, named with a shared `prefix`; that is what `prefix` selects.
The other is a single column holding every answer a respondent ticked,
joined by a delimiter, which is what Google Forms and most spreadsheet
exports produce. If `prefix` matches exactly one column and a delimiter
is found in it, that column is unpacked automatically and the answer
text itself becomes the option label (`clean_names` is not applied,
since the answers are real wording rather than mangled column names).
Behaviour on a column block is unchanged. Use
[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)
when you want those unpacked columns kept for other work.

## See also

[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md),
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md).

Other summaries:
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md),
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md),
[`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md),
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md),
[`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)

## Examples

``` r
calc_percentage_multi(podracing_survey, "motivations_",
                      id = respondent_id, sort = "desc")
#> # A tibble: 5 × 3
#>   option        n   pct
#>   <fct>     <int> <dbl>
#> 1 speed       772    79
#> 2 drivers     533    54
#> 3 social      437    45
#> 4 tradition   349    36
#> 5 betting     295    30

# a spreadsheet export that packs every answer into one cell
packed <- data.frame(
  respondent = 1:4,
  motivations = c("Speed; Drivers", "Speed", "", "Betting; Speed")
)
calc_percentage_multi(packed, "motivations", id = respondent, sort = "desc")
#> # A tibble: 3 × 3
#>   option      n   pct
#>   <fct>   <int> <dbl>
#> 1 Speed       3   100
#> 2 Betting     1    33
#> 3 Drivers     1    33
```
