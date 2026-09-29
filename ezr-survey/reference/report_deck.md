# Build a slide deck from a list of plots and tables in one call

Turns a named list of ggplots / data frames into a titled-slide deck (or
Word document) and saves it. Names become slide titles; each item lands
on its own slide, sized to the template's content placeholder.

## Usage

``` r
report_deck(
  items,
  path = NULL,
  format = c("pptx", "docx"),
  title = NULL,
  template = NULL,
  style = c("elevated", "plain")
)
```

## Arguments

- items:

  A named list; names become slide titles. Each element is either a
  ggplot (added as a plot) or a data frame (added as a table).

- path:

  Output file path. `NULL` (default) writes `report.pptx` /
  `report.docx`. A bare file name lands in `ezrsurvey-outputs/` (created
  on demand); a path naming a directory (`"./x.pptx"`,
  `"charts/x.pptx"`, anything absolute) is used exactly as given. See
  the `output_dir` option.

- format:

  `"pptx"` (default) or `"docx"`.

- title:

  Optional title-slide / document-title text.

- template:

  Optional reference document; `NULL` (default) uses the brand template
  registered by
  [`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md),
  see
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md).

- style:

  Built-in template to fall back on: `"elevated"` (default, the styled
  deck) or `"plain"` (undecorated white). See
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md).

## Value

Invisibly `path`.

## Details

Every chart is rendered at the exact size of the template's content
placeholder and centred in it, and
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md)
draws bars to a constant thickness whatever the category count, so the
deck reads consistently as you flick through it.

For a deck built a slide at a time, with section dividers and per-slide
control over the layout, use
[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md)
and the `report_add_*()` family instead.

## See also

[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md).

Other reporting:
[`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md),
[`list_report_templates()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_report_templates.md),
[`report_add_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_plot.md),
[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md),
[`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md),
[`report_add_text()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_text.md),
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
tmp <- tempfile(fileext = ".pptx")
report_deck(
  list(
    "Gender" = plot_bars(calc_percentage(podracing_survey, demo_gender)),
    "NPS"    = calc_nps(podracing_survey, nps_value)
  ),
  path = tmp
)
file.exists(tmp)
#> [1] TRUE
# }

# a bare name instead lands in ezrsurvey-outputs/:
# report_deck(items, path = "overview.pptx")
```
