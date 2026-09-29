# A stacked rating chart for a whole block of questions

The one-line form of
[`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md)
for the common case: a block of columns sharing a prefix, each asking
the same rating question about a different feature or brand. Tabulates
the block, tidies the question names, numbers the answers by their
position on the scale and stacks the result.

## Usage

``` r
plot_rating_grid(data = NULL, prefix, levels = NULL, digits = 2, ...)
```

## Arguments

- data:

  A data frame. If omitted, the session default
  ([`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md)).

- prefix:

  The block's shared column prefix, e.g. `"ratings_"`. It is stripped
  from the feature labels.

- levels:

  The scale's answer wordings, worst first. `NULL` (default) looks the
  block up in the order registry
  ([`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md)),
  falling back to the
  [`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md)
  default five-point scale.

- digits:

  Decimal places kept in the underlying percentages. Default `2`.

- ...:

  Passed to
  [`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md)
  (`palette`, `label_min`, `show_average`).

## Value

A ggplot object.

## Details

Answers are numbered by their position in `levels`, which is what orders
the features by their weighted mean and colours the segments
worst-to-best. A wording that is not on the scale cannot be numbered, so
it is reported rather than being silently dropped into an unlabelled
segment: check it against the raw export, since exports often differ
from a questionnaire by a typo. Registering the block once with
`register_order("likeability", levels, prefixes = "partner_likeability_")`
removes the `levels` argument from every later call.

## See also

[`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md),
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md),
[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md).

Other plots:
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md),
[`plot_gauges()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_gauges.md),
[`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md),
[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md),
[`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md),
[`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md),
[`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md)

## Examples

``` r
plot_rating_grid(podracing_survey, "ratings_")


plot_rating_grid(podracing_survey, "partner_likeability_",
                 levels = c("Very unlikeable", "Unlikeable",
                            "Likeable", "Very likeable"))
```
