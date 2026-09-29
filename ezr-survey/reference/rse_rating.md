# Rate precision from a relative standard error

Turns a relative standard error (RSE, in percent) into a plain-language
reliability rating, using a five-band scheme.

## Usage

``` r
rse_rating(rse)
```

## Arguments

- rse:

  Relative standard error(s), in percent (see
  [`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md)).

## Value

A character vector of ratings.

## Details

The bands are: under 5% "high precision", under 10% "precise", under 15%
"satisfactory", under 25% "use with caution", and 25% or more "likely
reliability issues". Rating estimates by their relative standard error
is how national statistical agencies signal whether a survey number is
solid enough to publish: the Australian Bureau of Statistics treats an
RSE of 25% or more as "not reliable for most purposes", flags 25–50%
with an asterisk as estimates to use with caution, and suppresses
anything above 50%. The 25% boundary here is that same one. The tighter
bands below it are specific to consumer-survey work, where the question
is usually which of several adequately precise numbers to lead a report
with. This drives the `precision` column of
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md)
and the overall verdict of
[`precision_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/precision_summary.md).

## See also

[`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md),
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md),
[`precision_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/precision_summary.md).

Other diagnostics:
[`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md),
[`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md),
[`precision_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/precision_summary.md),
[`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md),
[`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md),
[`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md)

## Examples

``` r
rse_rating(c(3, 8, 12, 20, 40))
#> [1] "high precision"            "precise"                  
#> [3] "satisfactory"              "use with caution"         
#> [5] "likely reliability issues"
```
