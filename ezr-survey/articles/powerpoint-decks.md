# PowerPoint decks

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

The deck is where a survey project ends, and rebuilding it by hand every
wave is where the time goes. Two routes are provided: one call for a
deck with no particular shape, and a slide-at-a-time builder for a deck
that has one. Both write a real `.pptx` through `officer`, so the result
opens in PowerPoint, Keynote and Google Slides.

Everything below writes into a temporary folder. In your own work a bare
file name lands in `ezrsurvey-outputs/`.

``` r

deck_dir <- tempdir()
```

## One call

Give
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
a named list. The names become slide titles, and each item becomes the
slide’s content.

``` r

report_deck(
  list(
    "Who follows pod racing?" = plot_bars(
      calc_percentage(podracing_survey, demo_gender)),
    "How likely are they to recommend it?" = calc_nps(
      podracing_survey, nps_value)
  ),
  path = file.path(deck_dir, "overview.pptx"),
  title = "Pod-Racing Fan Survey"
)
```

The content dispatches on what it is. A ggplot becomes a chart sized to
the layout’s content placeholder, a data frame becomes a table sized to
fill the slide, and a character vector becomes a bullet list.

## A slide at a time

A deck with chapters, dividers and commentary is assembled step by step.
Each call returns the document, so the whole deck is one pipe.

``` r

drivers <- ipm_model(podracing_survey, nps_value, "ratings_")
#> Parsing `nps_value` as a non-binary variable.
#> Applying multiple regression to calculate relative weights...

report_new("pptx") %>%
  report_title_slide(
    "Pod-Racing Fan Survey",
    subtitle = "1,000 fans | Fieldwork 2026"
  ) %>%
  report_section("RECOMMENDATION") %>%
  report_slide("How likely are you to recommend pod racing?",
               plot_nps(podracing_survey, nps_value)) %>%
  report_section("RATINGS") %>%
  report_slide("Which aspects matter most, and which fall short?",
               plot_ipm(drivers)) %>%
  report_add_slide("What we should fix first") %>%
  report_add_text(c(
    "Value and commentary sit lowest and matter most.",
    "Atmosphere is already strong; further gains there move nothing."
  )) %>%
  report_save(file.path(deck_dir, "deck.pptx"))
```

[`report_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_slide.md)
is title plus one thing, which is most slides.
[`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md)
opens a slide you then add to with
[`report_add_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_plot.md),
[`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md)
and
[`report_add_text()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_text.md),
for the slides that carry more than one element.

The same calls produce a Word document. Sections become headings rather
than dividers:

``` r

report_new("docx") %>%
  report_section("Pod-Racing Fan Survey") %>%
  report_add_text("Net Promoter Score and the drivers behind it.") %>%
  report_add_table(drivers) %>%
  report_save(file.path(deck_dir, "report.docx"))
```

## Your organisation’s template

Point ezrsurvey at a template once and everything downstream matches it:

``` r

use_brand("brand/org-template.pptx")
```

That reads the template’s theme: accent colours become the palette
behind
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md),
[`pal_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/pal_brand.md)
and
[`scale_fill_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md),
the body typeface becomes the default for
[`theme_ezrsurvey()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md),
and the file itself becomes the reference document for
[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
and
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md).
With no template to hand, set the values directly:

``` r

use_brand(colors = c("#0B5394", "#E69138"), fonts = "Georgia", quiet = TRUE)
pal_brand()
#> [1] "#0B5394" "#E69138"
clear_brand()
```

Both live in an `.ezrsurvey.yml` profile if you want them for every
project. The semantic palettes keep their meaning whatever the brand:
`pal_rating` and `pal_nps` stay red-amber-green, because recolouring a
detractor to match a logo would make the chart lie.

> A brand typeface only reaches the page through a graphics device that
> reads the machine’s fonts.
> [`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md)
> uses one. The `pdf` device, which is the default in a plain `Rscript`
> run, does not, and
> [`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)
> says so when it sets a font in such a session.

Layouts are chosen by inspecting a template’s placeholders rather than
their names, so a template written in any language works.
[`report_layouts()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_layouts.md)
shows what yours offers:

``` r

report_layouts()
#> # A tibble: 11 × 6
#>    layout                  master       has_title n_body body_width body_height
#>    <chr>                   <chr>        <lgl>      <int>      <dbl>       <dbl>
#>  1 Blank                   Office Theme FALSE          0      NA          NA   
#>  2 Comparison              Office Theme TRUE           4       5.64        0.9 
#>  3 Content with Caption    Office Theme TRUE           2       6.75        5.33
#>  4 Picture with Caption    Office Theme TRUE           1       4.3         4.17
#>  5 Section Header          Office Theme TRUE           1      11.5         1.64
#>  6 Title and Content       Office Theme TRUE           1      11.5         4.76
#>  7 Title and Vertical Text Office Theme TRUE           1      11.5         4.76
#>  8 Title Only              Office Theme TRUE           0      NA          NA   
#>  9 Title Slide             Office Theme TRUE           0      NA          NA   
#> 10 Two Content             Office Theme TRUE           2       5.67        4.76
#> 11 Vertical Title and Text Office Theme TRUE           1       8.46        6.36
```

## Without a template

Decks default to the package’s own 16:9 template: a full-bleed cover
with a large title and a subtitle strapline, full-bleed section
dividers, and content slides carrying a left-aligned title over a slim
rule with a live slide number in the corner.

``` r

report_deck(items, path = "deck.pptx")                   # styled, the default
report_deck(items, path = "deck.pptx", style = "plain")  # same palette, no decoration
report_new("pptx", slide_numbers = FALSE)                # drop the numbering
```

Charts are drawn at a constant bar thickness whatever the answer count,
so a three-answer chart and a ten-answer chart sit together in a deck
instead of the first one’s bars turning into slabs. `bar_width` and
`bar_ref_items` in
[`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)
control it.

## Google Slides

Google Slides imports PowerPoint natively, so the route above is also
the Google Slides route: build the deck, then use **File \> Import
slides**, or open the `.pptx` straight from Drive.

Chart images, text boxes, bullets, speaker notes and theme colours all
survive the import. Two things to watch. Fonts outside Google’s
catalogue are substituted, so if Slides is the destination, brand with
one that is in it (`use_brand(..., fonts = "Roboto")`). And intricate
table borders simplify. Charts are saved as transparent-background PNGs,
so they sit cleanly on any Slides background.
