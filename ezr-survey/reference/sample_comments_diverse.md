# Pick a diverse, information-rich sample of comments

A smarter alternative to
[`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md):
instead of sampling uniformly, it scores each comment and selects a set
that is both **informative** and **varied**, so a quote slide isn't five
ways of saying the same thing. Scoring is lexical – comments are turned
into TF-IDF vectors, an information score is computed (Shannon entropy
of the word distribution, or TF-IDF mass), and a randomised
maximal-marginal-relevance pass trades off informativeness against
similarity to already-picked comments.

## Usage

``` r
sample_comments_diverse(
  data = NULL,
  ...,
  n = 8,
  min_chars = 30,
  max_chars = 400,
  exclude = NULL,
  lambda = 0.6,
  method = c("mmr", "entropy"),
  score = c("entropy", "tfidf"),
  stopwords = NULL,
  max_candidates = 500,
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

- lambda:

  Diversity/informativeness trade-off in `[0, 1]` for `method = "mmr"`:
  higher favours informative comments, lower favours dissimilar ones.
  Default `0.6`.

- method:

  `"mmr"` (default) for the diversity-aware greedy selection, or
  `"entropy"` to weight a random sample by each comment's information
  score.

- score:

  By which to measure information: `"entropy"` (default, Shannon bits)
  or `"tfidf"` (summed TF-IDF weight).

- stopwords:

  Stop-word handling: `NULL` (default) uses the `stopwords` package when
  installed (English), otherwise a small built-in fallback; a character
  vector supplies your own list; `FALSE` disables removal. Pass e.g.
  `stopwords::stopwords("de")` for another language.

- max_candidates:

  Largest number of comments compared with one another (default `500`).
  A bigger corpus is narrowed to a random shortlist of this size first,
  because the comparison grows with the square of the number kept. Raise
  it to widen the choice, at the cost of time and memory.

- seed:

  Optional integer for reproducible sampling (the RNG state is restored
  afterwards).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
`source`, `comment`, `length` and the `info` score, ordered by
selection.

## See also

[`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md),
[`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md).

Other comments:
[`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md)

## Examples

``` r
sample_comments_diverse(podracing_survey, nps_com, show_com, n = 5, seed = 1)
#> # A tibble: 5 × 4
#>   source   comment                                                  length  info
#>   <chr>    <chr>                                                     <int> <dbl>
#> 1 show_com Sebulba held his own out there, but the whole crowd see…    109  3.17
#> 2 show_com Gasgano displayed more cunning than raw speed, which is…     72  2.81
#> 3 nps_com  Dud Bolt's grit and determination are inspiring qualiti…     58  2.58
#> 4 nps_com  Phoebos Memorial Run has professional event management.      55  2.58
#> 5 show_com The pit radio communications showed trust between drive…     66  2.81
```
