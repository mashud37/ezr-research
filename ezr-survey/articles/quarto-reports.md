# Quarto reports

``` r

library(ezrsurvey)
#> Loading required package: dplyr
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
#> Loading required package: ggplot2
#> Loading required package: tidyr
#> Loading required package: tibble
#> Loading required package: readr
#> Loading required package: stringr
#> Loading required package: purrr
```

Building a deck from R suits a deliverable whose shape you already know.
A report you will rewrite between waves, or one that has to go out as a
web page this quarter and a PDF the next, wants a document you can edit
rather than a script that emits one.
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)
writes that document: a Quarto file already wired to your data, with the
analysis in it, ready to render.

Everything below writes into a temporary folder. In your own work a bare
file name lands in `ezrsurvey-outputs/`.

``` r

report_dir <- tempdir()
```

## The scaffold

Pick the output format and you get a `.qmd` set up for it.

``` r

path <- scaffold_report(
  "html",
  path = file.path(report_dir, "survey-report.qmd"),
  title = "Q2 Customer Survey",
  author = "Research team",
  overwrite = TRUE
)

file.exists(path)
#> [1] TRUE
```

Four formats are supported, and the difference between them is the YAML
header and the chunk settings, not the analysis:

``` r

scaffold_report("html")   # a web page
scaffold_report("pdf")    # print
scaffold_report("docx")   # a Word document to be edited further
scaffold_report("pptx")   # slides
```

What the file contains is a working report rather than an empty
skeleton: setup, the data read in, a respondent profile, the headline
measures, a driver model, a chart or two and a precision appendix, with
placeholder narrative between them saying what each section is for.

``` r

writeLines(head(readLines(path), 25))
```

    #> ---
    #> title: "Q2 Customer Survey"
    #> author: "Research team"
    #> date: today
    #> format:
    #>   html:
    #>     toc: true
    #>     toc-location: left
    #>     theme: cosmo
    #>     embed-resources: true
    #>     fig-format: svg
    #> params:
    #>   data: ""
    #> ---
    #> 
    #> ```{r setup, include=FALSE}
    #> library(ezrsurvey)
    #> knitr::opts_chunk$set(echo = FALSE, warning = FALSE, message = FALSE,
    #>                       fig.width = 9, fig.height = 5, dpi = 150)
    #> 
    #> # Render with your own data:  quarto render <file> -P data:my-survey.csv
    #> # For multi-file exports, replace this with read_folder("data/") %>% ...
    #> d <- if (nzchar(params$data)) {
    #>   readr::read_csv(params$data, show_col_types = FALSE)
    #> } else {

## Rendering it

Rendering needs Quarto itself, which is not an R package:

``` r

quarto::quarto_render("ezrsurvey-outputs/survey-report.qmd")
```

The scaffold takes the data file as a parameter, so the same report runs
against the next wave without being edited:

``` r

quarto::quarto_render("survey-report.qmd", execute_params = list(data = "wave-3.csv"))
```

From the command line that is `-P data:wave-3.csv`.

## On your own template

The pptx and docx scaffolds accept a reference document, which is how
the report inherits your organisation’s look:

``` r

scaffold_report("pptx", title = "Q2 Customer Survey",
                reference_doc = "brand/org-template.pptx")
```

With
[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)
already set, the template it carries is used by default and the argument
can be left out.

> Quarto’s `reference-doc` requires the standard layout names (“Title
> Slide”, “Title and Content” and so on). If your organisation’s
> template renamed its layouts, Quarto will not find them; build that
> deck with
> [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
> instead, which reads placeholders rather than names. See [PowerPoint
> decks](https://mashud37.github.io/ezr-research/ezr-survey/articles/powerpoint-decks.md).

## A finished example to copy

The scaffold is a starting point. For a complete worked report on the
bundled data, with every chart type, real narrative rather than
placeholders, and the matching deck script beside it:

``` r

example_dir <- file.path(report_dir, "ezrsurvey-example")
example_report(example_dir, overwrite = TRUE)
#> Example written to /tmp/Rtmpa63r3T/ezrsurvey-example/ -- start with podracing-report.qmd.

list.files(example_dir)
#> [1] "podracing-deck.R"     "podracing-report.qmd"
```

Copy that into a project and adapt it. It is the fastest way to see how
the pieces fit together in a document rather than one call at a time.

## Which route to take

| You want | Use |
|----|----|
| A deck from a list of charts, no shape to control | [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md) |
| A deck with chapters, commentary and mixed slides | [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md) and the `report_*` builders |
| A document you will edit and re-render each wave | [`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md) |
| The same analysis as html, pdf, docx and pptx | [`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md), one per format |
| A worked example to learn from | [`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md) |
