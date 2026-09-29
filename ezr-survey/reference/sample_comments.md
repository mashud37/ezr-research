# Pick a random sample of open-text comments

Pulls a tidy, presentation-ready sample of comments out of one or more
free-text columns, applying the usual clean-ups: drop blanks and very
short answers, optionally exclude comments matching unwanted terms, and
truncate to a maximum length. The result feeds straight into
[`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md).

## Usage

``` r
sample_comments(
  data = NULL,
  ...,
  n = 8,
  min_chars = 30,
  max_chars = 400,
  exclude = NULL,
  by_column = TRUE,
  by = NULL,
  seed = NULL
)
```

## Arguments

- data:

  A data frame.

- ...:

  One or more comment columns, using tidyselect (e.g. `nps_com`,
  `show_com`, or `ends_with("_com")`).

- n:

  Number of comments to sample. With `by_column = TRUE`, this is per
  column.

- min_chars:

  Drop comments with this many characters or fewer. Default `30`.

- max_chars:

  Truncate longer comments to this length. Default `400`.

- exclude:

  Optional character vector of (case-insensitive) regex terms; comments
  matching any are dropped (e.g. `c("friend", "recommend")`).

- by_column:

  If `TRUE` (default), sample `n` from each column; if `FALSE`, sample
  `n` from the pooled comments.

- by:

  Optional grouping column (unquoted), e.g. an NPS group. Sampling then
  takes `n` from each group, and the group is kept as a column of the
  result so a slide can filter on it.

- seed:

  Optional integer for reproducible sampling (the RNG state is restored
  afterwards).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
`source`, `comment` and `length`, plus the `by` column when one is
given.

## Details

Verbatims need clean-up before they go on a slide: this drops blanks and
very short answers, optionally removes comments matching unwanted terms
(`exclude`), and truncates the long ones. With `by_column = TRUE` you
get `n` from each source column (e.g. an even split across `nps_com` and
`show_com`); with `FALSE`, `n` from the pooled set. The result feeds
[`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md).
For a set that is varied rather than uniformly random, use
[`sample_comments_diverse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments_diverse.md).

## See also

[`sample_comments_diverse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments_diverse.md)
for a diversity-aware sample,
[`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md).

Other comments:
[`sample_comments_diverse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments_diverse.md)

## Examples

``` r
sample_comments(podracing_survey, nps_com, show_com, n = 3)
#> # A tibble: 6 × 3
#>   source   comment                                                        length
#>   <chr>    <chr>                                                           <int>
#> 1 nps_com  Boonta Eve Classic has lost all its charm and prestige.            55
#> 2 nps_com  Ticket window staff were incredibly rude to everyone.              53
#> 3 nps_com  Snacks taste like they were made weeks ago, not fresh.             54
#> 4 show_com Pet policies were not communicated or enforced consistently.       60
#> 5 show_com Truguts for beverages were absolutely marked up beyond reason.     62
#> 6 show_com Mos Espa Circuit needs major investment to be viable.              53

# three quotes per NPS group, with the group kept as a column
podracing_survey %>%
  mutate(group = nps_group(nps_value, labels = TRUE)) %>%
  filter(!is.na(group)) %>%
  sample_comments(nps_com, n = 3, by = group)
#> # A tibble: 6 × 4
#>   group     source  comment                                               length
#>   <chr>     <chr>   <chr>                                                  <int>
#> 1 Detractor nps_com They ran out of seats even though we reserved ahead.      52
#> 2 Detractor nps_com Safety protocols are inadequate for crowd size here.      52
#> 3 Detractor nps_com Fode kept calling drivers by the wrong names, it was…     66
#> 4 Promoter  nps_com Dud Bolt drove like his career depended on it, inspi…     63
#> 5 Promoter  nps_com Would definitely recommend this to anyone who loves …     70
#> 6 Promoter  nps_com Dud Bolt won the crowd's hearts regardless of the fi…     63
```
