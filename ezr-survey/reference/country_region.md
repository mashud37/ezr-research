# Country to region lookup

A tidy lookup table mapping country names to a world `region` and a
finer `subregion`, used by
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md)
/
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md)
to turn a country column into regions. Each country also carries its ISO
3166-1 codes, so a result can be reported against the standard.

## Usage

``` r
country_region
```

## Format

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with 180
rows and 5 columns:

- country:

  Country name.

- iso2:

  ISO 3166-1 alpha-2 code (e.g. `"DE"`). `NA` for Kosovo, which has no
  code of its own.

- iso3:

  ISO 3166-1 alpha-3 code (e.g. `"DEU"`).

- region:

  World region (Africa, Asia, Europe, Middle East, North America,
  Oceania, South America).

- subregion:

  Finer subregion (e.g. Western Europe, East Asia).

Note that Namibia's alpha-2 code is the two letters `"NA"`, not a
missing value, which is worth knowing before filtering on the column.

## Source

Regions are the package's own grouping. Codes are ISO 3166-1. See
`data-raw/make_country_region.R`.

## See also

[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md).

Other data:
[`currency_rates`](https://mashud37.github.io/ezr-research/ezr-survey/reference/currency_rates.md),
[`podracing_survey`](https://mashud37.github.io/ezr-research/ezr-survey/reference/podracing_survey.md),
[`shopping_survey`](https://mashud37.github.io/ezr-research/ezr-survey/reference/shopping_survey.md)

## Examples

``` r
head(country_region)
#> # A tibble: 6 × 5
#>   country                           iso2  iso3  region subregion
#>   <chr>                             <chr> <chr> <chr>  <chr>    
#> 1 Angola                            AO    AGO   Africa Africa   
#> 2 Burkina Faso                      BF    BFA   Africa Africa   
#> 3 Cameroon                          CM    CMR   Africa Africa   
#> 4 Cape Verde                        CV    CPV   Africa Africa   
#> 5 Congo, Democratic Republic of the CD    COD   Africa Africa   
#> 6 Cote d'Ivoire                     CI    CIV   Africa Africa   
recode_region("Germany")
#> [1] "Europe"
```
