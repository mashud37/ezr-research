# Round an axis maximum up to a "nice" value

Picks the smallest multiple of `unit` that is greater than or equal to
`max(x)`. This reproduces the dynamic y-axis trick used throughout the
original survey reports, where bar charts are given a tidy ceiling in
units of 25 (percentages) or 5 (NPS counts) so that data labels never
collide with the top of the panel.

## Usage

``` r
nice_max(x, unit = 25, pad = 0)
```

## Arguments

- x:

  A numeric vector. `NA` values are ignored.

- unit:

  Size of the rounding step (e.g. `25` for percentages, `5` for smaller
  counts). Must be a positive number.

- pad:

  Extra headroom added to the result, in the same units as `x`. Useful
  to leave space for annotations above the tallest bar. Defaults to `0`.

## Value

A single numeric value: the padded, rounded-up ceiling. Returns `NA` if
`x` is empty or all `NA`.

## Details

The ceiling is `(floor(max(x) / unit) + 1) * unit + pad`: the *next*
multiple of `unit` strictly above `max(x)`, always leaving headroom even
when the max already sits exactly on a multiple (e.g. `nice_max(75)` is
`100`, not `75`). Use `pad` for additional headroom on top of that, e.g.
for annotations above the tallest bar. An all-`NA` logical column (a
common shape for an empty survey field) is tolerated and returns `NA`.
This is the engine behind
[`scale_y_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_y_pct.md)
and the percentage plot wrappers, which is why their bars never quite
touch the top of the panel.

## See also

[`scale_y_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_y_pct.md),
[`label_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/label_pct.md).

Other scales:
[`label_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/label_pct.md),
[`scale_y_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_y_pct.md)

## Examples

``` r
nice_max(c(12, 63, 40))
#> [1] 75

nice_max(80, unit = 25)        # already need >75, so jumps to 100
#> [1] 100

nice_max(75, unit = 25)        # exact multiple still advances, for headroom
#> [1] 100

nice_max(c(8, 17), unit = 5, pad = 10)   # next multiple of 5 (20) + 10
#> [1] 30
```
