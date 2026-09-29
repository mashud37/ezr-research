# Simulated historical shopping-behaviour survey

A fictional survey of patrons of a turn-of-the-century (c. 1905) general
emporium, written in an Edwardian register for colour. It behaves like a
real survey export – a latent satisfaction drives the worded attribute
ratings and the recommend score together, demographics use standard
sex/country categories alongside period social-class and occupation
items, and the multi-select and open-text columns mirror the shapes the
helpers consume. A companion to
[podracing_survey](https://mashud37.github.io/ezr-research/ezr-survey/reference/podracing_survey.md)
for examples that want a second, very different theme.

## Usage

``` r
shopping_survey
```

## Format

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with 800
rows and 25 columns:

- patron_id:

  Unique patron id (character).

- demo_age:

  Age in years (integer, 18-80).

- demo_gender:

  Sex (Female / Male, some "Prefer not to answer").

- demo_country:

  Country of residence (ISO 3166 names).

- region:

  World region derived from `demo_country`.

- social_class:

  Edwardian social class (Upper class .. Poor).

- occupation:

  Period occupation (Clerk, Domestic servant, ...).

- household_size:

  Number in the household (integer).

- weekly_spend:

  Weekly spend at the emporium, in shillings (numeric).

- payment:

  How they pay: Cash, On account or Barter.

- transport:

  How they travel to the shop (On foot, Horse and cart, ...).

- visit_frequency:

  How often they visit (Never .. Always).

- recommend:

  0-10 "would recommend to a neighbour" rating (integer).

- ratings_goods, ratings_service, ratings_credit, ratings_delivery,
  ratings_value:

  Worded 1-5 attribute ratings (Very bad .. Very good).

- reasons_price, reasons_quality, reasons_credit, reasons_proximity,
  reasons_variety, reasons_service:

  Multi-select reasons for patronage; each holds its option text when
  chosen, otherwise `""`.

- comment:

  Open-text comment (mostly blank).

## Source

Simulated. See `data-raw/make_shopping_survey.R` for the generator.

## See also

Other data:
[`country_region`](https://mashud37.github.io/ezr-research/ezr-survey/reference/country_region.md),
[`currency_rates`](https://mashud37.github.io/ezr-research/ezr-survey/reference/currency_rates.md),
[`podracing_survey`](https://mashud37.github.io/ezr-research/ezr-survey/reference/podracing_survey.md)

## Examples

``` r
calc_percentage(shopping_survey, social_class, sort = "desc")
#> # A tibble: 6 × 3
#>   social_class              n   pct
#>   <fct>                 <int> <dbl>
#> 1 Skilled working class   232    30
#> 2 Working class           193    25
#> 3 Lower middle class      183    23
#> 4 Upper middle class       82    11
#> 5 Poor                     63     8
#> 6 Upper class              26     3
calc_summary(shopping_survey, weekly_spend, by = payment)
#> # A tibble: 3 × 5
#>   payment        n  mean median    sd
#>   <chr>      <int> <dbl>  <dbl> <dbl>
#> 1 Barter        63  17.6   17.2  8.30
#> 2 Cash         448  18.4   18    8.15
#> 3 On account   289  19.0   19    8.46
```
