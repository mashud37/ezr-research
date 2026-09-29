# Simulated pod-racing fan survey

A fictional consumer-feedback survey from a Boonta Eve-style pod-racing
meeting – an affectionate Star Wars parody used throughout the ezrsurvey
examples and tests (the package's literal answer to `starwars`, but
survey-shaped). A latent enjoyment drives correlated attribute ratings
and the recommend score, the demographics use international-standard
categories (ISO/IEC 5218 sex, ISCED education, ILO labour-force status,
ISIC sectors, ISO 3166 countries), and the multi-select, sponsor and
open-text columns mirror the shapes the helpers consume. The open-text
comments deliberately name many drivers, places and races, so they
exercise the text / NER helpers. Blanks and "Prefer not to answer"
responses are sprinkled in so cleaning helpers have something to do.

## Usage

``` r
podracing_survey
```

## Format

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with
1,000 rows and 32 columns:

- respondent_id:

  Unique respondent id (character).

- collector:

  Survey source: email, panel, socials or in_app.

- demo_age:

  Age in years (integer, 16-70).

- demo_gender:

  Sex/gender: Male, Female, Non-binary (ISO/IEC 5218, extended), some
  blank / "Prefer not to answer".

- demo_edu:

  Highest education level (ISCED 2011 broad categories).

- demo_country:

  Country of residence (ISO 3166 names).

- region:

  World region derived from `demo_country`.

- demo_job:

  Labour-force status (ILO categories).

- demo_sector:

  Industry sector (ISIC Rev.4 sections).

- race_attended:

  Which meeting they attended (e.g. "Boonta Eve Classic"); long labels
  that exercise the auto bar layout.

- fav_driver:

  Favourite pod-racer (e.g. "Anakin Skywalker", "Sebulba").

- nps_value:

  0-10 "how likely to recommend attending" rating (integer).

- satis_return:

  Likelihood of returning next season (Very unlikely .. Very likely).

- ratings_atmosphere, ratings_commentary, ratings_safety, ratings_speed,
  ratings_value, ratings_venue:

  Worded 1-5 attribute ratings (Very bad .. Very good).

- motivations_speed, motivations_drivers, motivations_betting,
  motivations_social, motivations_tradition:

  Multi-select reasons for attending; each holds its option text when
  chosen, otherwise `""`.

- partner_recall_PodTech, partner_recall_BanthaBrew,
  partner_recall_JawaJuice:

  Sponsor recall per brand (Sponsor / Not a sponsor / Don't know this
  brand).

- partner_likeability_PodTech, partner_likeability_BanthaBrew,
  partner_likeability_JawaJuice:

  Sponsor likeability (Very likeable .. Very unlikeable).

- nps_com, show_com:

  Open-text comments (mostly blank).

## Source

Simulated. See `data-raw/make_podracing_survey.R` for the generator.

## See also

Other data:
[`country_region`](https://mashud37.github.io/ezr-research/ezr-survey/reference/country_region.md),
[`currency_rates`](https://mashud37.github.io/ezr-research/ezr-survey/reference/currency_rates.md),
[`shopping_survey`](https://mashud37.github.io/ezr-research/ezr-survey/reference/shopping_survey.md)

## Examples

``` r
calc_percentage(podracing_survey, demo_gender, sort = "desc")
#> # A tibble: 3 × 3
#>   demo_gender     n   pct
#>   <fct>       <int> <dbl>
#> 1 Male          525    55
#> 2 Female        399    42
#> 3 Non-binary     27     3
calc_nps(podracing_survey, nps_value)
#> # A tibble: 1 × 8
#>       n   nps pct_detractors pct_passives pct_promoters detractors passives
#>   <int> <dbl>          <dbl>        <dbl>         <dbl>      <int>    <int>
#> 1  1000     7             25           43            32        252      426
#> # ℹ 1 more variable: promoters <int>
```
