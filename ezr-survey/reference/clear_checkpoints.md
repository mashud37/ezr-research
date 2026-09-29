# Delete saved cross-tab checkpoints

Removes the checkpoint files that `crosstab_banner(checkpoint = TRUE)`
keeps under
[`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html). A
finished run clears its own checkpoint, so anything left is from a run
that was interrupted and never repeated; this empties the folder in one
call.

## Usage

``` r
clear_checkpoints()
```

## Value

Invisibly the number of files removed.

## Details

Only checkpoints the package named for itself are stored there. A
checkpoint you pointed somewhere yourself (`checkpoint = "my-run.rds"`)
is your file and is never touched, by this function or by a completed
run.

## See also

[`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md),
[`clear_weights_cache()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_weights_cache.md).

Other summaries:
[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
[`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md),
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md),
[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md),
[`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)

## Examples

``` r
# in your own session this is the whole call:
# clear_checkpoints()

# here it runs against a throwaway cache, so the example leaves yours alone
withr::with_envvar(c(R_USER_CACHE_DIR = tempdir()), clear_checkpoints())
#> Removed 0 checkpoint file(s).
```
