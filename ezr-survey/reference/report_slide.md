# Add a whole slide in one call (title plus its content)

The one-line-per-slide wrapper: starts a new slide, sets its title, and
places `content` on it in a single call, so a deck script reads as one
line per slide. `content` is dispatched by type – a ggplot becomes a
chart, a data frame a table, a character vector a bulleted text box.

## Usage

``` r
report_slide(
  doc,
  title = NULL,
  content = NULL,
  layout = NULL,
  master = NULL,
  ...
)
```

## Arguments

- doc:

  A document from
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md).

- title:

  Slide title (typically the survey question the slide answers).

- content:

  A ggplot, a data frame / tibble, or a character vector. `NULL`
  (default) adds an empty titled slide.

- layout, master:

  Passed to
  [`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md);
  `NULL` auto-selects.

- ...:

  Passed on to
  [`report_add_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_plot.md),
  [`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md)
  or
  [`report_add_text()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_text.md)
  depending on `content`.

## Value

The updated document.

## Details

Equivalent to
[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md)
followed by the matching `report_add_*()` call, but as one pipe-friendly
step so `calc -> plot -> add` collapses onto a single line:
`report_slide("How likely to recommend?", plot_nps(nps_value))`.

## See also

[`report_section()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_section.md),
[`report_title_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_title_slide.md),
[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md).

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
[`report_title_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_title_slide.md),
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)

## Examples

``` r
# \donttest{
doc <- report_new("pptx") %>%
  report_slide("Who follows pod racing?",
               plot_bars(calc_percentage(podracing_survey, demo_gender)))
class(doc)
#> [1] "rpptx"
# }
```
