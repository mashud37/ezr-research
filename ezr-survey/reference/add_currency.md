# Add a converted-currency column to a data frame

Convenience wrapper around
[`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md)
that appends a converted column to `data`. The source currency can be a
fixed code or a per-row column.

## Usage

``` r
add_currency(data = NULL, amount, from, to = "USD", into = NULL, rates = NULL)
```

## Arguments

- data:

  A data frame.

- amount:

  The amount column to convert (unquoted).

- from:

  Source currency: either a bare column name holding per-row codes (e.g.
  `currency`) or a quoted constant code (e.g. `"EUR"`).

- to:

  Target currency code. Defaults to `"USD"`.

- into:

  Name of the new column. Defaults to `"<amount>_<to>"`.

- rates:

  Passed to
  [`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md).

## Value

`data` with the converted column added.

## Details

The `from` argument is clever about whether you mean a column or a
constant: a bare name (`from = currency`) is read as a per-row
source-currency column, while a quoted string (`from = "EUR"`) is a
fixed code applied to every row. This is the common case where each
respondent reported spend in their own currency. The new column defaults
to `<amount>_<to>` (e.g. `spend_usd`); override with `into`. Conversion
uses
[`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md),
so the same rates, aliases and warnings apply.

## See also

[`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md).

Other currency:
[`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md),
[`list_currencies()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_currencies.md)

## Examples

``` r
df <- tibble::tibble(spend = c(100, 200, 50),
                     currency = c("EUR", "GBP", "JPY"))

# per-row source currency (a column)
add_currency(df, spend, from = currency, to = "USD")
#> # A tibble: 3 × 3
#>   spend currency spend_usd
#>   <dbl> <chr>        <dbl>
#> 1   100 EUR        109.   
#> 2   200 GBP        253.   
#> 3    50 JPY          0.333

# a fixed source currency (a constant), custom output name
add_currency(df, spend, from = "EUR", to = "USD", into = "spend_usd")
#> # A tibble: 3 × 3
#>   spend currency spend_usd
#>   <dbl> <chr>        <dbl>
#> 1   100 EUR          109. 
#> 2   200 GBP          217. 
#> 3    50 JPY           54.3
```
