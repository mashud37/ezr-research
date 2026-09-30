# Countries, regions and currency

``` r

library(ezrsurvey)
#> Loading required package: dplyr
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
#> Loading required package: ggplot2
#> Loading required package: tidyr
#> Loading required package: tibble
#> Loading required package: readr
#> Loading required package: stringr
#> Loading required package: purrr
```

Two columns make a multi-country study harder than a single-market one.
The country question is usually free text, so it comes back holding
every spelling a person can produce. And if respondents answered about
money in their own currency, the amounts column cannot be averaged at
all.

## The country column people typed

On one real open salary survey of 26,232 people, nine thousand wrote
“United States”, eight thousand wrote “USA”, two and a half thousand
wrote “US”, and several hundred more wrote “U.S.”, “Usa” or “usa”.
Matching on the name as typed resolved about half the column.

[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md)
folds the answer down before looking it up. Case, punctuation, accents
and a leading “the” all stop mattering, and then a table of the
spellings people actually use is tried.

``` r

recode_region(c("United States", "USA", "U.S.", "Estados Unidos"))
#> [1] "North America" "North America" "North America" "North America"
```

It carries the constituent countries of the United Kingdom, which a UK
respondent is as likely to write as the country itself:

``` r

recode_region(c("England", "Scotland", "Wales", "Northern Ireland"))
#> [1] "Europe" "Europe" "Europe" "Europe"
```

Endonyms, because a survey fielded in more than one language collects
them:

``` r

recode_region(c("Deutschland", "Brasil", "Espana", "Osterreich"))
#> [1] "Europe"        "South America" "Europe"        "Europe"
```

And the official ISO 3166-1 names, which is what a questionnaire built
on the standard puts in front of a respondent, in either word order:

``` r

recode_region(c("Viet Nam", "Syrian Arab Republic", "Republic of Moldova",
                "Cabo Verde", "Eswatini"))
#> [1] "Asia"        "Middle East" "Europe"      "Africa"      "Africa"
```

The fold is done letter by letter rather than left to the platform’s
transliteration, so a name carrying an accent matches the same way on
Windows, macOS and Linux:

``` r

recode_region(c("Côte d'Ivoire", "Réunion", "Türkiye"))
#> [1] "Africa" "Africa" "Europe"
```

## Adding the column

[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md)
does the same thing to a data frame, and `subregion = TRUE` adds the
finer grouping alongside:

``` r

survey <- add_region(podracing_survey, demo_country, subregion = TRUE)

calc_percentage(survey, region, sort = "desc")
#> # A tibble: 5 × 3
#>   region            n   pct
#>   <fct>         <int> <dbl>
#> 1 North America   503    50
#> 2 Europe          314    31
#> 3 South America    82     8
#> 4 Asia             59     6
#> 5 Oceania          42     4
```

``` r

calc_percentage(survey, subregion, sort = "desc")
#> # A tibble: 6 × 3
#>   subregion                 n   pct
#>   <fct>                 <int> <dbl>
#> 1 North America           503    50
#> 2 Western Europe          286    29
#> 3 South America            82     8
#> 4 East Asia                59     6
#> 5 Australia New Zealand    42     4
#> 6 Northern Europe          28     3
```

Anything that did not match comes back `NA` with a warning naming the
values, because at that point what is left is genuine typos worth seeing
rather than spellings worth supporting.

## Reporting against the standard

A client who consolidates research across agencies wants countries coded
to ISO 3166-1, not to whatever names this analyst happened to pick. A
column already coded that way needs no preparation:

``` r

recode_region(c("US", "GBR", "DE", "JPN", "AUS"))
#> [1] "North America" "Europe"        "Europe"        "Asia"         
#> [5] "Oceania"
```

A two-letter code that is also an ordinary English word is only read as
a country when it was typed in capitals, so `"NO"` is Norway and `"no"`
is somebody answering a different question:

``` r

recode_region(c("NO", "no"), quiet = TRUE)
#> [1] "Europe" NA
```

The bundled table carries both codes, so a country name can be replaced
by its code on the way out. That is the table to join to, because
country names differ between sources and codes do not:

``` r

head(country_region)
#> # A tibble: 6 × 5
#>   country      iso2  iso3  region subregion
#>   <chr>        <chr> <chr> <chr>  <chr>    
#> 1 Algeria      DZ    DZA   Africa Africa   
#> 2 Angola       AO    AGO   Africa Africa   
#> 3 Benin        BJ    BEN   Africa Africa   
#> 4 Botswana     BW    BWA   Africa Africa   
#> 5 Burkina Faso BF    BFA   Africa Africa   
#> 6 Burundi      BI    BDI   Africa Africa
```

``` r

survey %>%
  dplyr::left_join(dplyr::select(country_region, country, iso2, iso3),
                   by = c("demo_country" = "country")) %>%
  dplyr::count(iso3, region, sort = TRUE) %>%
  head(8)
#> # A tibble: 8 × 3
#>   iso3  region            n
#>   <chr> <chr>         <int>
#> 1 USA   North America   336
#> 2 GBR   Europe          120
#> 3 MEX   North America    93
#> 4 DEU   Europe           89
#> 5 BRA   South America    82
#> 6 FRA   Europe           77
#> 7 CAN   North America    74
#> 8 JPN   Asia             59
```

> Namibia’s alpha-2 code is the two letters `NA`, not a missing value.
> It is worth knowing before filtering that column, and before reading a
> country file with anything other than `na.strings = ""`.

The regions themselves follow the UN M49 sub-regions with two deliberate
departures, because they are how consumer research buys these markets:
the Middle East is a region of its own rather than part of Asia and
Africa, and the Americas are split north and south.

## Money in eleven currencies

A single amount converts with
[`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md):

``` r

convert_currency(50000, from = "GBP", to = "USD")
#> [1] 63291.14
convert_currency(c(50000, 60000), from = c("EUR", "CAD"), to = "USD")
#> [1] 54347.83 44117.65
```

A whole column converts with
[`add_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_currency.md),
which takes the currency from a second column, so each row is converted
at its own rate:

``` r

pay <- tibble::tibble(
  respondent = 1:5,
  salary = c(52000, 61000, 48000, 75000, 39000),
  currency = c("GBP", "EUR", "USD", "CAD", "AUD")
)

add_currency(pay, salary, from = currency, to = "EUR", into = "salary_eur")
#> # A tibble: 5 × 4
#>   respondent salary currency salary_eur
#>        <int>  <dbl> <chr>         <dbl>
#> 1          1  52000 GBP          60557.
#> 2          2  61000 EUR          61000 
#> 3          3  48000 USD          44160 
#> 4          4  75000 CAD          50735.
#> 5          5  39000 AUD          23605.
```

The rates are bundled rather than fetched, so a figure computed today is
the same figure next year. That is what a published number needs, and it
is also why they are a dated snapshot rather than live rates.

``` r

head(list_currencies())
#> [1] "USD" "EUR" "GBP" "JPY" "CNY" "CHF"
```

When accuracy matters more than reproducibility, pass your own:

``` r

own_rates <- c(USD = 1, GBP = 0.79, EUR = 0.92)
convert_currency(50000, from = "GBP", to = "EUR", rates = own_rates)
#> [1] 58227.85
```

A code the table does not hold is reported rather than guessed at. Real
currency columns contain things like `"AUD/NZD"` and `"Other"`, and
those rows come back `NA` with a warning naming the codes.
