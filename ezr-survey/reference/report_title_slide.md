# Add the opening title slide

A one-line title slide, placed on the template's title layout (the one
with a centre-title placeholder).

## Usage

``` r
report_title_slide(doc, title, subtitle = NULL, layout = NULL, master = NULL)
```

## Arguments

- doc:

  A document from
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md).

- title:

  Deck title.

- subtitle:

  Optional strapline placed in the layout's subtitle placeholder – the
  respondent base and fieldwork period, say. `NULL` (default) leaves it
  empty.

- layout, master:

  Optional overrides; `NULL` auto-selects the title layout.

## Value

The updated document.

## See also

[`report_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_slide.md),
[`report_section()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_section.md).

Other reporting:
[`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md),
[`list_report_templates()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_report_templates.md),
[`report_add_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_plot.md),
[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md),
[`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md),
[`report_add_text()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_text.md),
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md),
[`report_layouts()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_layouts.md),
[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
[`report_save()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_save.md),
[`report_section()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_section.md),
[`report_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_slide.md),
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)

## Examples

``` r
doc <- report_new("pptx") %>%
  report_title_slide("Pod-Racing Fan Survey",
                     subtitle = "1,000 fans | Fieldwork 2026")
class(doc)
#> [1] "rpptx"
```
