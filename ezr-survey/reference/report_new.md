# Start a new PowerPoint or Word report

Opens an officer document you can build up with the `report_add_*()`
helpers and write out with
[`report_save()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_save.md).
This is the "build slides/Word directly from R" path; for a Quarto-based
workflow see
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md).

## Usage

``` r
report_new(
  format = c("pptx", "docx"),
  template = NULL,
  style = c("elevated", "plain"),
  slide_numbers = TRUE,
  keep_slides = TRUE
)
```

## Arguments

- format:

  `"pptx"` (default) for PowerPoint or `"docx"` for Word.

- template:

  Optional path to a `.pptx` / `.docx` to use as the style template
  (reference doc). `NULL` (default) uses the brand template registered
  by
  [`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md),
  falling back to one of the package's built-in 16:9 templates (see
  `style`).

- style:

  Which built-in template to fall back on when no `template` and no
  brand template are set. `"elevated"` (default) is the styled deck: a
  navy/gold identity with a full-bleed navy cover, full-bleed navy
  section dividers, a navy title over one slim rule on every content
  slide and slide numbers in the corner. `"plain"` is the same
  widescreen deck with the same palette but no decoration – plain white
  slides. Ignored when a template is supplied.

- slide_numbers:

  If `TRUE` (default), every content slide added with
  [`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md)
  shows the template's slide-number placeholder in its usual corner.
  Requires the suggested `xml2` package (silently skipped without it, or
  when the template has no slide-number placeholder).

- keep_slides:

  PowerPoint only. If `TRUE` (default), any slides already in the
  template stay and your first slide is added after them. Set `FALSE` to
  start from an empty deck, which is what you want when the template
  carries example or boilerplate slides you do not intend to ship.

## Value

An officer document object (`rpptx` or `rdocx`).

## Details

This is the "build it from R" path: you get an officer document and add
to it slide by slide (pptx) or section by section (docx) with the
`report_add_*()` helpers, then write it out with
[`report_save()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_save.md).
Slide layouts are chosen by inspecting the template's placeholders, so
any organisation template works – see
[`report_layouts()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_layouts.md)
for what yours contains. For a quick deck from a list of charts and
tables,
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
does the whole thing in one call; for a document-driven workflow,
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)
gives you a Quarto template instead. Requires the suggested `officer`
package.

## See also

[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md),
[`report_add_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_plot.md),
[`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md),
[`report_save()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_save.md),
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md),
[`report_layouts()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_layouts.md),
[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md).

Other reporting:
[`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md),
[`list_report_templates()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_report_templates.md),
[`report_add_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_plot.md),
[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md),
[`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md),
[`report_add_text()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_text.md),
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md),
[`report_layouts()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_layouts.md),
[`report_save()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_save.md),
[`report_section()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_section.md),
[`report_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_slide.md),
[`report_title_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_title_slide.md),
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)

## Examples

``` r
doc <- report_new("pptx")
class(doc)
#> [1] "rpptx"

# a corporate template replaces the built-in one:
# report_new("pptx", template = "brand/org-template.pptx")
```
