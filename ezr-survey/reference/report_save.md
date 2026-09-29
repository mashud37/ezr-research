# Save a report to disk

Writes a deck or document built with
[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md)
and the `report_*` verbs, and returns the path it used, so a build
pipeline can carry on from it.

## Usage

``` r
report_save(doc, path = NULL)
```

## Arguments

- doc:

  A document from
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md).

- path:

  Output file path (`.pptx` or `.docx`). `NULL` (default) writes
  `report.pptx` / `report.docx`. A bare file name lands in
  `ezrsurvey-outputs/` (created on demand); a path naming a directory
  (`"./x.pptx"`, `"charts/x.pptx"`, anything absolute) is used exactly
  as given. See the `output_dir` option.

## Value

Invisibly `path`.

## Details

The format follows the document, not the file name: a deck writes
`.pptx` and a Word document writes `.docx`, which is why `path` may be
left out entirely. Where the file lands follows the same rule as every
other ezrsurvey save, so a bare name collects in the outputs folder with
the rest of a session's results and a path naming a directory goes
exactly there.

## See also

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
[`report_section()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_section.md),
[`report_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_slide.md),
[`report_title_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_title_slide.md),
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)

## Examples

``` r
tmp <- tempfile(fileext = ".pptx")
report_new("pptx") %>% report_add_slide("Hi") %>% report_save(tmp)
file.exists(tmp)
#> [1] TRUE

# a bare name instead lands in ezrsurvey-outputs/:
# report_new("pptx") %>% report_add_slide("Hi") %>% report_save("deck.pptx")
```
