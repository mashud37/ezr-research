# Add a slide (PowerPoint) or heading (Word) to a report

For a `pptx` document this starts a new slide and sets its title; for a
`docx` document it adds a heading paragraph.

## Usage

``` r
report_add_slide(
  doc,
  title = NULL,
  layout = NULL,
  master = NULL,
  heading_level = 1
)
```

## Arguments

- doc:

  A document from
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md).

- title:

  Optional slide title / heading text.

- layout, master:

  PowerPoint layout and master names. `NULL` (default) picks the
  template's best content layout automatically (by inspecting
  placeholders, so corporate templates with renamed layouts work). Name
  a layout from
  [`report_layouts()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_layouts.md)
  to override.

- heading_level:

  Word heading level (1-3). Defaults to `1`.

## Value

The updated document.

## Details

Automatic selection scores every layout of the template: a title
placeholder plus a single content placeholder is the ideal, and the
layout's *placeholders* decide – not its (language-dependent) name. If
the chosen layout has no title placeholder, the title is skipped with a
warning rather than failing the build.

## See also

[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
[`report_layouts()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_layouts.md).

Other reporting:
[`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md),
[`list_report_templates()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_report_templates.md),
[`report_add_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_plot.md),
[`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md),
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
doc <- report_new("pptx") %>% report_add_slide("Audience")
class(doc)
#> [1] "rpptx"
```
