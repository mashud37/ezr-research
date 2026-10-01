# ezrsurvey <img src="man/figures/logo.png" align="right" height="120" alt="" />

> ezrsurvey: tidyverse helpers for everyday consumer-survey work, designed so
> common tasks require minimal R experience.

`ezrsurvey` packages the patterns a research manager reaches for again and again:
loading and stacking survey exports, turning questions into percentages without
the `count() %>% mutate() %>% pivot_wider()` ritual, recoding Likert and NPS scales,
importance–performance modelling, survey precision diagnostics, and a generalised
plotting toolkit (clean themes, semantic palettes, dynamic axes and automatic
"BAD / OK / GOOD" decision bands). It ships with two simulated survey datasets --
`podracing_survey` (a Star Wars pod-racing fan survey) and `shopping_survey` (an
Edwardian shopping survey) -- so every example runs out of the box.

## Installation

```r
# install.packages("pak")
pak::pak("mashud37/ezr-research/ezr-survey")
```

The analysis core depends only on dplyr, ggplot2, tidyr, tibble, readr, stringr
and purrr, which it attaches for you. A few extras unlock
optional features: `rwa` (importance analysis), `treemapify` (quote treemaps) and
`ggrepel` (non-overlapping IPM labels).

To draft the narrative that goes around these tables with a language model,
add the companion
[`ezrintelligence`](https://github.com/mashud37/ezr-research/tree/main/ezr-intelligence)
package; it takes
any summary table `ezrsurvey` produces.

## The 60-second tour

```r
library(ezrsurvey)   # attaches dplyr, ggplot2 and the rest with it

# 1. Percentages, no count/mutate/pivot_wider
calc_percentage(podracing_survey, demo_gender, sort = "desc")
#> # A tibble: 3 x 3
#>   demo_gender     n   pct
#>   <fct>       <int> <dbl>
#> 1 Male          525    55
#> 2 Female        399    42
#> 3 Non-binary     27     3

# Drop catch-all answers; the kept ones re-base to ~100%
calc_percentage(podracing_survey, demo_job, drop = "Unemployed")

# Check-all-that-apply questions, by prefix
calc_percentage_multi(podracing_survey, "motivations_", id = respondent_id, sort = "desc")

# ...or packed into one cell per respondent, the way spreadsheets export them.
# The delimiter (";", "|" or ",") is found for you
packed <- data.frame(respondent = 1:3,
                     motivations = c("Speed; Drivers", "Speed", "Betting"))
calc_percentage_multi(packed, "motivations", id = respondent)

# split_multi() widens that column into one column per answer instead, so
# crosstabs, plots and everything else can use it too
split_multi(packed, motivations)

# Grouped + pivoted to a wide cross-tab
calc_percentage(podracing_survey, satis_return, by = region, wide = TRUE)

# A master banner table: questions down the side, groups across the top, an
# Overall column, and column percentages (numeric questions turn into a
# mean/median/sd/quartile block automatically)
crosstab_banner(podracing_survey, rows = c(satis_return, nps_value),
                cols = c(demo_gender, region))

# Pass only the data frame to cross every variable against every variable
# (identifier and free-text columns are skipped automatically)
crosstab_banner(podracing_survey)

# 2. A labelled bar chart in one pipe -- orientation, wrapping and order
#    are chosen automatically (here: many long driver names -> horizontal bars)
calc_percentage(podracing_survey, fav_driver) %>%
  plot_bars()

# A whole block of rating questions as one stacked chart, features ordered
# by their average and coloured worst-to-best
plot_rating_grid(podracing_survey, "ratings_")

# 3. NPS and the gauge
nps <- calc_nps(podracing_survey, nps_value)$nps
plot_nps_gauge(nps)

# 4. Importance / performance modelling
ipm_model(podracing_survey, nps_value, "ratings_") %>%
  plot_ipm()

# 5. Survey precision diagnostics (the appendix "data info" block, as one call)
diagnose(podracing_survey, demo_gender, dplyr::starts_with("ratings_"))

# 6. Quick saves, pipe-friendly, format inferred from the extension
# (a bare name lands in ezrsurvey-outputs/; give a path to choose the folder)
calc_percentage(podracing_survey, demo_gender) %>% save_data("gender.xlsx")
plot_bars(calc_percentage(podracing_survey, demo_gender)) %>% save_plot("gender.svg")

# A tabbed Excel workbook: one sheet per question, each with its table and chart
export_summary_xlsx(podracing_survey, demo_gender, satis_return, nps_value)
```

## What's in the box

| Area | Functions |
| --- | --- |
| **Import** | `read_folder()`, `select_prefix()`, `select_suffix()`, `parse_filename()` |
| **Recode** | `na_blank()`, `drop_items()`, `ensure_numeric()`, `bin_numeric()`, `recode_age()`, `recode_generation()`, `recode_likert()`, `nps_group()`, `split_multi()`, `clean_label()` |
| **Country → region** | `add_region()`, `recode_region()`, `recode_subregion()`, `country_region` |
| **Config / profile** | `ezrsurvey_options()`, `reset_ezrsurvey_options()`, `use_ezrsurvey_profile()`, `load_ezrsurvey_profile()` |
| **Comments** | `sample_comments()`, `sample_comments_diverse()` |
| **Summaries** | `calc_percentage()`, `calc_percentage_multi()`, `calc_percentage_batch()`, `calc_summary()`, `crosstab()`, `crosstab_banner()` |
| **Modelling** | `calc_nps()`, `calc_importance()`, `ipm_model()` |
| **Diagnostics** | `se_mean()`, `se_prop()`, `rse()`, `margin_of_error()`, `diagnose()` |
| **Scales** | `nice_max()`, `scale_y_pct()`, `label_pct()` |
| **Decisions** | `annotate_bands()`, `mark_value()`, `bands_rating_3()`, `bands_rating_5()`, `bands_nps()`, `bands_nps_score()` |
| **Themes & palettes** | `theme_ezrsurvey()` (+ `_x`/`_y`/`_xy`, `transparent`), `pal_rating`, `pal_nps`, `scale_fill_rating()`, `scale_fill_nps()` |
| **Branding** | `use_brand()`, `brand_info()`, `clear_brand()`, `pal_brand()`, `scale_fill_brand()`/`scale_colour_brand()` |
| **Plots** | `plot_bars()`, `plot_stacked_rating()`, `plot_rating_grid()`, `plot_nps()`, `plot_nps_gauge()`, `plot_gauges()`, `plot_ipm()`, `plot_quotes_tree()` |
| **Reporting** | `report_new()`, `report_layouts()`, `report_slide()`/`report_section()`/`report_title_slide()`, `report_add_slide()`/`_plot()`/`_table()`, `report_deck()`, `scaffold_report()` (Quarto pptx/html/pdf/docx), `example_report()` |
| **Quick save** | `save_plot()` (png/svg/pdf), `save_data()` (csv/tsv/xlsx), `save_output()` (auto-dispatch), `export_xlsx()` (multi-tab), `export_summary_xlsx()` (table + chart per question) |
| **Data** | `podracing_survey` (1,000 simulated pod-racing fans), `shopping_survey` (800 Edwardian shoppers) |

## Two things that are not obvious

- **Name the dataset once.** `use_dataset(podracing_survey)` at the top of a
  script lets every helper drop the data argument entirely --
  `calc_percentage(demo_gender)`, `calc_nps(nps_value)`,
  `diagnose(starts_with("ratings_"))`. An explicit data frame or a pipe always
  wins over the default, and `clear_dataset()` ends it.
- **Column completion needs the pipe.** `podracing_survey %>%
  calc_percentage(<Tab>` offers `demo_gender` and the rest; the un-piped
  `calc_percentage(df, <Tab>` cannot. That is the mechanism RStudio and
  Positron use, not a limitation of this package: they only offer a data
  frame's columns inside a pipe chain, for any package including the tidyverse.

## Where output goes

Every save writes into an `ezrsurvey-outputs/` folder in the working directory,
created on demand, so a script's results collect in one place:

```r
save_plot(p, "nps.png")               # ezrsurvey-outputs/nps.png
report_deck(items, path = "q2.pptx")  # ezrsurvey-outputs/q2.pptx
scaffold_report("html")               # ezrsurvey-outputs/survey-report-html.qmd
```

The first save of a session says where the file went, so nobody hunts for it in
the working directory.

A path that names a directory is used exactly as written, which is how you
override that: `"./nps.png"` for the working directory, `"charts/nps.png"` for a
folder of your own, or any absolute path. `ezrsurvey_options(output_dir = )`
renames the folder for a project, or set it to `"."` to put bare names back in
the working directory.

## Articles

The front page is the tour. The details live in their own articles:

| Article | What it covers |
| --- | --- |
| [Getting started](https://mashud37.github.io/ezr-research/ezr-survey/articles/ezrsurvey.html) | A whole analysis end to end on the bundled data |
| [Banner tables](https://mashud37.github.io/ezr-research/ezr-survey/articles/banner-tables.html) | The client's working table: cell types, weighting, automatic variable choice, checkpointed runs |
| [Countries, regions and currency](https://mashud37.github.io/ezr-research/ezr-survey/articles/countries-and-currency.html) | Free-text country columns, ISO 3166-1 in and out, converting money people answered in their own currency |
| [PowerPoint decks](https://mashud37.github.io/ezr-research/ezr-survey/articles/powerpoint-decks.html) | One-call decks, slide-at-a-time decks, your org template, Google Slides |
| [Quarto reports](https://mashud37.github.io/ezr-research/ezr-survey/articles/quarto-reports.html) | A report you edit and re-render each wave, in html, pdf, docx or pptx |

## License

MIT © Andreas Schellewald
