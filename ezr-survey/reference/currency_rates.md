# Currency exchange-rate snapshot

A dated, approximate reference table of exchange rates used by
[`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md)
/
[`add_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_currency.md)
when no custom rates are supplied. Rates are expressed as units of the
currency per 1 US dollar (base `USD`). These are a convenience snapshot,
**not** live rates – pass your own `rates` to the conversion helpers
when accuracy matters.

## Usage

``` r
currency_rates
```

## Format

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per currency and columns:

- currency:

  ISO 4217 code (e.g. `"EUR"`).

- name:

  Currency name.

- per_usd:

  Units of the currency per 1 US dollar.

The snapshot date is stored in `attr(currency_rates, "snapshot_date")`.

## Source

Approximate reference snapshot. See `data-raw/make_currency_rates.R`.

## See also

[`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md),
[`add_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_currency.md),
[`list_currencies()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_currencies.md).

Other data:
[`country_region`](https://mashud37.github.io/ezr-research/ezr-survey/reference/country_region.md),
[`podracing_survey`](https://mashud37.github.io/ezr-research/ezr-survey/reference/podracing_survey.md),
[`shopping_survey`](https://mashud37.github.io/ezr-research/ezr-survey/reference/shopping_survey.md)

## Examples

``` r
head(currency_rates)
#> # A tibble: 6 × 3
#>   currency name          per_usd
#>   <chr>    <chr>           <dbl>
#> 1 USD      US Dollar        1   
#> 2 EUR      Euro             0.92
#> 3 GBP      British Pound    0.79
#> 4 JPY      Japanese Yen   150   
#> 5 CNY      Chinese Yuan     7.2 
#> 6 CHF      Swiss Franc      0.88
attr(currency_rates, "snapshot_date")
#> [1] "2025-01-01"
```
