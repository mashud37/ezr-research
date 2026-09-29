# List the currencies in a rate table

List the currencies in a rate table

## Usage

``` r
list_currencies(rates = NULL)
```

## Arguments

- rates:

  Rate table; `NULL` (default) for the bundled
  [currency_rates](https://mashud37.github.io/ezr-research/ezr-survey/reference/currency_rates.md).

## Value

A character vector of currency codes.

## Details

A quick way to see which codes
[`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md)
will accept from the bundled snapshot (or from a `rates` table you
pass). Aliases such as `"RMB"` are *not* listed – they resolve to their
ISO code (here `"CNY"`).

## See also

[currency_rates](https://mashud37.github.io/ezr-research/ezr-survey/reference/currency_rates.md),
[`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md).

Other currency:
[`add_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_currency.md),
[`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md)

## Examples

``` r
list_currencies()
#>  [1] "USD" "EUR" "GBP" "JPY" "CNY" "CHF" "CAD" "AUD" "NZD" "SEK" "NOK" "DKK"
#> [13] "PLN" "CZK" "HUF" "RON" "BGN" "TRY" "RUB" "UAH" "BRL" "MXN" "ARS" "CLP"
#> [25] "COP" "INR" "IDR" "KRW" "SGD" "HKD" "TWD" "THB" "MYR" "PHP" "VND" "ZAR"
#> [37] "AED" "SAR" "ILS"
```
