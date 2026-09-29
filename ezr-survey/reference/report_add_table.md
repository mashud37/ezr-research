# Add a table to a report

Adds a data frame as a flextable – in the current slide's content
placeholder (pptx) or as a new table (docx).

## Usage

``` r
report_add_table(doc, data, font_size = 12, autofit = TRUE)
```

## Arguments

- doc:

  A document from
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md).

- data:

  A data frame / tibble.

- font_size:

  Cell font size in points. Defaults to `12`.

- autofit:

  Word only: auto-size columns to content. Defaults to `TRUE`. On slides
  the table is always sized to fill the content placeholder.

## Value

The updated document.

## Details

On a slide the table is styled (a clean banded header, centred cells, a
readable font) and its columns are widened to span the content
placeholder – roughly in proportion to each column's contents – so it
fills the slide meaningfully instead of sitting tiny in a corner. In
Word it is added as a plain auto-fitted flextable.

## See also

[`report_add_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_plot.md).

Other reporting:
[`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md),
[`list_report_templates()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_report_templates.md),
[`report_add_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_plot.md),
[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md),
[`report_add_text()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_text.md),
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md),
[`report_layouts()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_layouts.md),
[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
[`report_save()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_save.md),
[`report_section()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_section.md),
[`report_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_slide.md),
[`report_title_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_title_slide.md),
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)

## Examples

``` r
tbl <- calc_percentage(podracing_survey, demo_gender)
doc <- report_new("docx") %>% report_add_table(tbl)
class(doc)
#> [1] "rdocx"
```
