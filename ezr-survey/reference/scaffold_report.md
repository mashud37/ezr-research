# Scaffold a Quarto survey-report template

Copies a ready-to-render Quarto report skeleton into your project, wired
up with ezrsurvey helpers against the bundled `podracing_survey` data:
an executive summary, per-question sections with placeholder narrative,
and a methodology appendix built from the precision diagnostics. Swap in
your own data via the `data` parameter (or at the top of the file) and
render with Quarto. This is the document-driven counterpart to the
[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md)
/
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
officer builders.

## Usage

``` r
scaffold_report(
  format = c("pptx", "html", "pdf", "docx"),
  path = NULL,
  title = "Survey Report",
  author = NULL,
  reference_doc = NULL,
  overwrite = FALSE
)
```

## Arguments

- format:

  Output format: one of
  [`list_report_templates()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_report_templates.md)
  (`"pptx"`, `"html"`, `"pdf"`, `"docx"`). Defaults to `"pptx"`.

- path:

  Destination `.qmd` path. `NULL` (default) writes
  `survey-report-<format>.qmd`. A bare file name lands in
  `ezrsurvey-outputs/` (created on demand), so the scaffold sits where
  its rendered output will; a path naming a directory (`"./x.qmd"`,
  `"reports/x.qmd"`, anything absolute) is used exactly as given. See
  the `output_dir` option.

- title:

  Title inserted into the template's YAML header.

- author:

  Author name for the YAML header. `NULL` leaves a placeholder.

- reference_doc:

  Path to a PowerPoint / Word template used as the Quarto
  `reference-doc` (pptx and docx formats only). `NULL` (default) uses
  the brand template registered by
  [`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md),
  if any; pptx then falls back to the package's built-in 16:9 template,
  docx leaves the line commented in the scaffold.

- overwrite:

  Overwrite `path` if it already exists. Defaults to `FALSE`.

## Value

Invisibly the path written.

## Details

Each scaffold declares one Quarto parameter: `data`, the path to a CSV
of your survey; empty means the bundled example data.

**Corporate templates:** Quarto/Pandoc fills a `reference-doc` by
looking for the *standard* layout names ("Title Slide", "Title and
Content", "Two Content", ...). A corporate template whose layouts keep
those names works directly; one with renamed layouts will render broken
or blank slides here – build the deck with
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
instead, which inspects placeholders and works with any template.

## See also

[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
for building decks directly without Quarto;
[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)
to register a default reference document.

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
[`report_title_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_title_slide.md)

## Examples

``` r
tmp <- tempfile(fileext = ".qmd")
scaffold_report("html", path = tmp, title = "Q2 Customer Survey")
file.exists(tmp)
#> [1] TRUE

# a bare name instead lands in ezrsurvey-outputs/, beside its render:
# scaffold_report("html", title = "Q2 Customer Survey")
# quarto::quarto_render("ezrsurvey-outputs/survey-report-html.qmd")
```
