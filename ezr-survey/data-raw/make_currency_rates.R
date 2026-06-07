# Builds the `currency_rates` snapshot shipped with ezrsurvey. Rates are units of
# the currency per 1 US dollar (base = USD). These are an approximate, dated
# reference snapshot for convenience -- pass your own rates to convert_currency()
# / add_currency() when accuracy matters.
# Run from the package root: Rscript data-raw/make_currency_rates.R

suppressPackageStartupMessages(library(tibble))

snapshot_date <- as.Date("2025-01-01")

currency_rates <- tibble::tribble(
  ~currency, ~name,                  ~per_usd,
  "USD",     "US Dollar",              1.000,
  "EUR",     "Euro",                   0.920,
  "GBP",     "British Pound",          0.790,
  "JPY",     "Japanese Yen",         150.000,
  "CNY",     "Chinese Yuan",           7.200,
  "CHF",     "Swiss Franc",            0.880,
  "CAD",     "Canadian Dollar",        1.360,
  "AUD",     "Australian Dollar",      1.520,
  "NZD",     "New Zealand Dollar",     1.650,
  "SEK",     "Swedish Krona",         10.500,
  "NOK",     "Norwegian Krone",       10.700,
  "DKK",     "Danish Krone",           6.900,
  "PLN",     "Polish Zloty",           4.000,
  "CZK",     "Czech Koruna",          23.500,
  "HUF",     "Hungarian Forint",     370.000,
  "RON",     "Romanian Leu",           4.600,
  "BGN",     "Bulgarian Lev",          1.800,
  "TRY",     "Turkish Lira",          35.000,
  "RUB",     "Russian Ruble",         95.000,
  "UAH",     "Ukrainian Hryvnia",     41.000,
  "BRL",     "Brazilian Real",         5.000,
  "MXN",     "Mexican Peso",          17.500,
  "ARS",     "Argentine Peso",      1000.000,
  "CLP",     "Chilean Peso",         960.000,
  "COP",     "Colombian Peso",      4300.000,
  "INR",     "Indian Rupee",          83.000,
  "IDR",     "Indonesian Rupiah",  15800.000,
  "KRW",     "South Korean Won",    1350.000,
  "SGD",     "Singapore Dollar",       1.340,
  "HKD",     "Hong Kong Dollar",       7.800,
  "TWD",     "Taiwan Dollar",         32.000,
  "THB",     "Thai Baht",             34.000,
  "MYR",     "Malaysian Ringgit",      4.500,
  "PHP",     "Philippine Peso",       58.000,
  "VND",     "Vietnamese Dong",    25000.000,
  "ZAR",     "South African Rand",    18.500,
  "AED",     "UAE Dirham",             3.670,
  "SAR",     "Saudi Riyal",            3.750,
  "ILS",     "Israeli Shekel",         3.600
)

attr(currency_rates, "snapshot_date") <- snapshot_date

if (!dir.exists("data")) dir.create("data")
save(currency_rates, file = "data/currency_rates.rda", compress = "xz")
message("Wrote data/currency_rates.rda with ", nrow(currency_rates),
        " currencies (snapshot ", snapshot_date, ").")
