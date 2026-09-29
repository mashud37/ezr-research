# List the slide layouts of a PowerPoint template

Shows what a template offers the report builders: every layout, its
master, and the placeholders it carries. Useful to decide which `layout`
to name in
[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md),
or to sanity-check an organisation template before building a deck
against it.

## Usage

``` r
report_layouts(template = NULL, style = c("elevated", "plain"))
```

## Arguments

- template:

  Path to a `.pptx`, an existing document from
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
  or `NULL` (default) for the brand template registered by
  [`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)
  (falling back to a built-in template, see `style`).

- style:

  Built-in template to inspect when no `template` and no brand template
  are set: `"elevated"` (default) or `"plain"`. See
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md).

## Value

A [tibble](https://tibble.tidyverse.org/reference/tibble.html) with one
row per layout: `layout`, `master`, `has_title`, `n_body`, `body_width`,
`body_height` (inches of the first body placeholder, `NA` when the
layout has none).

## Details

The report builders pick layouts automatically by inspecting
placeholders, so most decks never need this – but when a corporate
template offers several content layouts, `report_layouts()` plus an
explicit `report_add_slide(layout = ...)` gives you full control.
Requires the suggested `officer` package.

## See also

[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md),
[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md).

Other reporting:
[`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md),
[`list_report_templates()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_report_templates.md),
[`report_add_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_plot.md),
[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md),
[`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md),
[`report_add_text()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_text.md),
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md),
[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
[`report_save()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_save.md),
[`report_section()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_section.md),
[`report_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_slide.md),
[`report_title_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_title_slide.md),
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)

## Examples

``` r
report_layouts()
#> # A tibble: 11 × 6
#>    layout                  master       has_title n_body body_width body_height
#>    <chr>                   <chr>        <lgl>      <int>      <dbl>       <dbl>
#>  1 Blank                   Office Theme FALSE          0      NA          NA   
#>  2 Comparison              Office Theme TRUE           4       5.64        0.9 
#>  3 Content with Caption    Office Theme TRUE           2       6.75        5.33
#>  4 Picture with Caption    Office Theme TRUE           1       4.3         4.17
#>  5 Section Header          Office Theme TRUE           1      11.5         1.64
#>  6 Title Only              Office Theme TRUE           0      NA          NA   
#>  7 Title Slide             Office Theme TRUE           0      NA          NA   
#>  8 Title and Content       Office Theme TRUE           1      11.5         4.76
#>  9 Title and Vertical Text Office Theme TRUE           1      11.5         4.76
#> 10 Two Content             Office Theme TRUE           2       5.67        4.76
#> 11 Vertical Title and Text Office Theme TRUE           1       8.46        6.36
```
