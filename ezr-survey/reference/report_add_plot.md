# Add a plot to a report

Renders a ggplot to an image and places it in the current slide's
content placeholder (pptx) or as a new figure (docx).

## Usage

``` r
report_add_plot(doc, plot, width = NULL, height = NULL, dpi = 150)
```

## Arguments

- doc:

  A document from
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md).

- plot:

  A ggplot object (any grid grob also works, e.g. an aligned plot from
  [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)'s
  alignment step).

- width, height:

  Image size in inches. `NULL` (default) sizes the image to the slide's
  content placeholder (pptx) or `6 x 3.5` (docx), so charts fill
  whatever template the deck is built on.

- dpi:

  Raster resolution. Defaults to `150`.

## Value

The updated document.

## Details

On slides the image is rendered at exactly the content placeholder's
size, so nothing is stretched or letterboxed; when the template does not
define placeholder geometry the slide size (minus margins) is used
instead.

## See also

[`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md).

Other reporting:
[`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md),
[`list_report_templates()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_report_templates.md),
[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md),
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
# \donttest{
p <- calc_percentage(podracing_survey, demo_gender) %>% plot_bars()
doc <- report_new("pptx") %>%
  report_add_slide("Gender") %>%
  report_add_plot(p)
class(doc)
#> [1] "rpptx"
# }
```
