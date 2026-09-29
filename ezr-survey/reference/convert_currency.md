# Convert amounts between currencies

Converts monetary amounts from one currency to another using a table of
exchange rates. By default it uses the bundled
[currency_rates](https://mashud37.github.io/ezr-research/ezr-survey/reference/currency_rates.md)
snapshot (units per US dollar); pass your own `rates` for up-to-date or
custom figures. Because rates share the USD base, any pair is converted
as a cross-rate through USD automatically (e.g. EUR to CNY goes EUR -\>
USD -\> CNY in one call). `amount`, `from` and `to` are vectorised and
recycled, so you can convert a whole column with per-row source
currencies at once.

## Usage

``` r
convert_currency(amount, from, to = "USD", rates = NULL)
```

## Arguments

- amount:

  Numeric amounts (text like `"$1,200"` is salvaged with
  [`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md)).

- from:

  Source currency code(s), e.g. `"EUR"` (case-insensitive). Common
  aliases resolve to their ISO code (e.g. `"RMB"` -\> `"CNY"`).

- to:

  Target currency code(s). Defaults to `"USD"`.

- rates:

  Exchange rates: `NULL` (default) for the bundled snapshot, a named
  numeric vector of units-per-USD (e.g. `c(EUR = 0.92, GBP = 0.79)`), or
  a data frame with `currency` and `per_usd` columns.

## Value

A numeric vector of converted amounts; unknown currency codes yield `NA`
with a warning.

## Details

Each rate is stored as units of the currency per 1 US dollar, so a
conversion is `amount / rate(from) * rate(to)` – which means any pair is
handled as a cross-rate through USD without you doing anything. The
bundled
[currency_rates](https://mashud37.github.io/ezr-research/ezr-survey/reference/currency_rates.md)
table is a dated, approximate snapshot meant for convenience, not live
trading; for accuracy pass your own `rates` (a named vector or a
`currency`/`per_usd` data frame). Amounts are coerced with
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
codes are upper-cased and resolved through a small alias map (`"RMB"`
-\> `"CNY"`, `"EURO"` -\> `"EUR"`, ...), and any unknown code yields
`NA` with a warning rather than a silent wrong number.

## See also

[`add_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_currency.md),
[`list_currencies()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_currencies.md),
[currency_rates](https://mashud37.github.io/ezr-research/ezr-survey/reference/currency_rates.md).

Other currency:
[`add_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_currency.md),
[`list_currencies()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_currencies.md)

## Examples

``` r
convert_currency(100, "EUR", "USD")
#> [1] 108.6957

convert_currency(c(100, 50), from = c("EUR", "GBP"), to = "USD")
#> [1] 108.69565  63.29114

convert_currency(100, "EUR", "CNY")          # cross-rate via USD
#> [1] 782.6087
convert_currency(100, "EUR", "RMB")          # alias -> CNY, same result
#> [1] 782.6087
```
