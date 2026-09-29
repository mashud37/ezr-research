# Select identifier and prefixed columns

Keeps a handful of id columns plus every column sharing a prefix – the
`select(id, starts_with("demo_"))` idiom – in one tidy call.

## Usage

``` r
select_prefix(data = NULL, prefix, keep = NULL)
```

## Arguments

- data:

  A data frame. If omitted, the session default
  ([`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md))
  is used.

- prefix:

  One or more column-name prefixes to keep (e.g. `"demo_"`, or
  `c("demo_", "ratings_")`).

- keep:

  Optional character vector of additional column names to retain in
  front of the prefixed block (e.g. an id column).

## Value

A data frame with `keep` columns followed by all prefix-matching
columns.

## Details

Survey questionnaires are usually organised by prefix (`demo_`,
`ratings_`, `partner_`, ...), so this is a quick way to grab one block
plus a couple of id columns without naming every variable. Order is
`keep` first, then the prefix-matching columns in their original order.

## See also

[`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md),
[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md).

Other import:
[`parse_filename()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/parse_filename.md),
[`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md),
[`select_suffix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_suffix.md)

## Examples

``` r
select_prefix(podracing_survey, "demo_", keep = "respondent_id")
#> # A tibble: 1,000 × 7
#>    respondent_id demo_age demo_gender demo_edu demo_country demo_job demo_sector
#>    <chr>            <int> <chr>       <chr>    <chr>        <chr>    <chr>      
#>  1 R00001              35 Male        Bachelo… Sweden       Student  Arts and e…
#>  2 R00002              29 Male        Bachelo… United King… Student  Education  
#>  3 R00003              16 Male        Upper s… Brazil       Employe… Informatio…
#>  4 R00004              16 Male        Upper s… Australia    Employe… Human heal…
#>  5 R00005              16 Male        Bachelo… France       Student  Education  
#>  6 R00006              36 Male        Short-c… Canada       Student  Other serv…
#>  7 R00007              30 Male        Master … Mexico       Employe… Human heal…
#>  8 R00008              23 Female      Short-c… France       Employe… Human heal…
#>  9 R00009              23 Female      Upper s… United Stat… Employe… Manufactur…
#> 10 R00010              39 Male        Upper s… United King… Employe… Manufactur…
#> # ℹ 990 more rows
select_prefix(podracing_survey, c("ratings_", "partner_"))
#> # A tibble: 1,000 × 12
#>    ratings_atmosphere ratings_commentary ratings_safety ratings_speed
#>    <chr>              <chr>              <chr>          <chr>        
#>  1 Very good          Ok                 Ok             Very good    
#>  2 Bad                Very bad           Bad            Bad          
#>  3 Very good          Good               Very good      Very good    
#>  4 Very good          Bad                Good           Good         
#>  5 Very good          Bad                Very bad       Good         
#>  6 Very good          Ok                 Good           Ok           
#>  7 Very good          Good               Good           Very good    
#>  8 Ok                 Bad                Good           Good         
#>  9 Very good          Very good          Very good      Very good    
#> 10 Good               Bad                Bad            Good         
#> # ℹ 990 more rows
#> # ℹ 8 more variables: ratings_value <chr>, ratings_venue <chr>,
#> #   partner_recall_PodTech <chr>, partner_likeability_PodTech <chr>,
#> #   partner_recall_BanthaBrew <chr>, partner_likeability_BanthaBrew <chr>,
#> #   partner_recall_JawaJuice <chr>, partner_likeability_JawaJuice <chr>
```
