# Select identifier and suffixed columns

The mirror of
[`select_prefix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_prefix.md):
keeps a handful of id columns plus every column sharing a suffix – the
`select(id, ends_with("_com"))` idiom – in one tidy call.

## Usage

``` r
select_suffix(data = NULL, suffix, keep = NULL)
```

## Arguments

- data:

  A data frame. If omitted, the session default
  ([`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md))
  is used.

- suffix:

  One or more column-name suffixes to keep (e.g. `"_com"`, or
  `c("_com", "_score")`).

- keep:

  Optional character vector of additional column names to retain in
  front of the suffixed block (e.g. an id column).

## Value

A data frame with `keep` columns followed by all suffix-matching
columns.

## Details

Some questionnaire blocks are marked by a trailing tag rather than a
leading one (`_com` open-text follow-ups, `_score` derived columns), so
this grabs one such block plus a couple of id columns without naming
every variable. Order is `keep` first, then the suffix-matching columns
in their original order.

## See also

[`select_prefix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_prefix.md),
[`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md).

Other import:
[`parse_filename()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/parse_filename.md),
[`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md),
[`select_prefix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_prefix.md)

## Examples

``` r
select_suffix(podracing_survey, "_com", keep = "respondent_id")
#> # A tibble: 1,000 × 3
#>    respondent_id nps_com                                                show_com
#>    <chr>         <chr>                                                  <chr>   
#>  1 R00001        "Dud Bolt's grit and determination are inspiring qual… ""      
#>  2 R00002        ""                                                     ""      
#>  3 R00003        "Ody Mandrell's season trajectory looks very positive… "The ev…
#>  4 R00004        "Vinta Harvest Classic has serious credentials based … "Teemto…
#>  5 R00005        "Ratts Tyerell's overtakes in traffic were executed c… "Sebulb…
#>  6 R00006        "The track marshals' positioning meant nothing was mi… "Online…
#>  7 R00007        ""                                                     ""      
#>  8 R00008        "The program timing meant no awkward gaps between rac… ""      
#>  9 R00009        "Mawhonic's acceleration off the line never faltered." "The se…
#> 10 R00010        ""                                                     ""      
#> # ℹ 990 more rows
```
