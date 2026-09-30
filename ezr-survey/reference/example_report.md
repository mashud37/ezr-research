# Copy the worked example report into a folder

Drops the package's complete worked example next to your data: a full
Quarto report over the bundled `podracing_survey` (every chart type,
real narrative) plus the matching slide-deck script on the officer path.
Render / run them as they are, then swap in your own data.

## Usage

``` r
example_report(dir = "ezrsurvey-example", overwrite = FALSE)
```

## Arguments

- dir:

  Destination folder. Defaults to `"ezrsurvey-example"` in the working
  directory; created if missing.

- overwrite:

  Overwrite existing files of the same names. Defaults to `FALSE`.

## Value

Invisibly the paths written.

## Details

Two files are copied: `podracing-report.qmd` (render with
`quarto render podracing-report.qmd`) and `podracing-deck.R` (run with
`Rscript podracing-deck.R`; writes a 16:9 deck to `ezrsurvey-outputs/`).
Unlike the blank
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)
skeletons, the example ships finished narrative over the bundled data,
so you can see every visual and slide element in a finished state before
adapting it.

## See also

[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)
for blank skeletons,
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md).

Other reporting:
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
[`report_title_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_title_slide.md),
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)

## Examples

``` r
dir <- file.path(tempdir(), "ezrsurvey-example")
example_report(dir)
#> Example written to /tmp/RtmpOerYd4/ezrsurvey-example/ -- start with podracing-report.qmd.
list.files(dir)
#> [1] "podracing-deck.R"     "podracing-report.qmd"

# then render it:
# quarto::quarto_render("ezrsurvey-example/podracing-report.qmd")
```
