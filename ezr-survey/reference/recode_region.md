# Look up the region or subregion for a country

Vectorised lookup from country name to world `region` or finer
`subregion`, using the bundled
[country_region](https://mashud37.github.io/ezr-research/ezr-survey/reference/country_region.md)
table. Matching is case-insensitive and whitespace-tolerant, and
understands the spellings people type as well as ISO 3166-1 alpha-2 and
alpha-3 codes, so `"USA"`, `"U.S."`, `"us"` and `"United States"` all
resolve alike; blanks and non-answers (see
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md))
become `NA`, and unmatched countries become `NA` with a one-line warning
so spelling mismatches are easy to spot.

## Usage

``` r
recode_region(x, which = c("region", "subregion"), quiet = FALSE)

recode_subregion(x, quiet = FALSE)
```

## Arguments

- x:

  A character vector of country names.

- which:

  `"region"` (default) or `"subregion"`.

- quiet:

  If `FALSE` (default), warn about unmatched countries. Set `TRUE` to
  silence the warning.

## Value

A character vector of regions (or subregions), `NA` where unmatched.

## Details

A country column that people typed themselves is rarely tidy: in one
real open salary survey, nine thousand respondents wrote "United States"
and eight thousand wrote "USA". So the name is folded down before it is
looked up – case, stray punctuation, accents and a leading "the" are all
dropped – and then tried against the bundled
[country_region](https://mashud37.github.io/ezr-research/ezr-survey/reference/country_region.md)
table (182 countries), then against a table of the spellings people
actually use. That table carries endonyms (`"Deutschland"`, `"Brasil"`),
the constituent countries of the United Kingdom, and ISO 3166-1 alpha-2
and alpha-3 codes (`"US"`, `"USA"`, `"DE"`, `"DEU"`), so a column
already coded to the standard needs no preparation at all.

A two-letter code is only read as a code when it was typed in capitals,
because `"NO"` is Norway but `"no"` is an answer to a different
question. Blanks and non-answers are blanked with
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md)
first, and anything still unmatched returns `NA` with a warning listing
the offenders, so a spelling the table does not carry is easy to spot
and add. Set `quiet = TRUE` inside pipelines where you have already
checked the coverage. `region` is the coarse level (e.g. "Europe");
`subregion` is finer (e.g. "Western Europe").

## See also

[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md),
[country_region](https://mashud37.github.io/ezr-research/ezr-survey/reference/country_region.md).

Other recode:
[`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md),
[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md),
[`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md),
[`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
[`generation_scheme()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/generation_scheme.md),
[`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md),
[`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md),
[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md),
[`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md),
[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md),
[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)

## Examples

``` r
recode_region(c("Germany", "Japan", "Brazil"))
#> [1] "Europe"        "Asia"          "South America"

# the spellings a free-text country question actually collects
recode_region(c("USA", "U.S.", "England", "Deutschland", "Holland"))
#> [1] "North America" "North America" "Europe"        "Europe"       
#> [5] "Europe"       

# a column already coded to ISO 3166-1
recode_region(c("US", "GBR", "DE", "JPN"))
#> [1] "North America" "Europe"        "Europe"        "Asia"         

recode_subregion(c("Germany", "Japan"))
#> [1] "Western Europe" "East Asia"     

# unmatched -> NA (warning suppressed here)
recode_region(c("Germany", "Atlantis"), quiet = TRUE)
#> [1] "Europe" NA      
```
