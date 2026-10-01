# ezrsurvey

> ezrsurvey: tidyverse helpers for everyday consumer-survey work,
> designed so common tasks require minimal R experience.

`ezrsurvey` packages the patterns a research manager reaches for again
and again: loading and stacking survey exports, turning questions into
percentages without the `count() %>% mutate() %>% pivot_wider()` ritual,
recoding Likert and NPS scales, importance–performance modelling, survey
precision diagnostics, and a generalised plotting toolkit (clean themes,
semantic palettes, dynamic axes and automatic “BAD / OK / GOOD” decision
bands). It ships with two simulated survey datasets – `podracing_survey`
(a Star Wars pod-racing fan survey) and `shopping_survey` (an Edwardian
shopping survey) – so every example runs out of the box.

## Installation

``` r

# install.packages("pak")
pak::pak("mashud37/ezr-research/ezr-survey")
```

The analysis core depends only on dplyr, ggplot2, tidyr, tibble, readr,
stringr and purrr, which it attaches for you. A few extras unlock
optional features: `rwa` (importance analysis), `treemapify` (quote
treemaps) and `ggrepel` (non-overlapping IPM labels).

To draft the narrative that goes around these tables with a language
model, add the companion
[`ezrintelligence`](https://github.com/mashud37/ezr-research/tree/main/ezr-intelligence)
package; it takes any summary table `ezrsurvey` produces.

## The 60-second tour

``` r

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

## What’s in the box

| Area | Functions |
|----|----|
| **Import** | [`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md), [`select_prefix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_prefix.md), [`select_suffix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_suffix.md), [`parse_filename()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/parse_filename.md) |
| **Recode** | [`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md), [`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md), [`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md), [`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md), [`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md), [`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md), [`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md), [`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md), [`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md), [`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md) |
| **Country → region** | [`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md), [`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md), [`recode_subregion()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md), `country_region` |
| **Config / profile** | [`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md), [`reset_ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/reset_ezrsurvey_options.md), [`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md), [`load_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/load_ezrsurvey_profile.md) |
| **Comments** | [`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md), [`sample_comments_diverse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments_diverse.md) |
| **Summaries** | [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md), [`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md), [`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md), [`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md), [`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md), [`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md) |
| **Modelling** | [`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md), [`calc_importance()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_importance.md), [`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md) |
| **Diagnostics** | [`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md), [`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md), [`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md), [`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md), [`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md) |
| **Scales** | [`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md), [`scale_y_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_y_pct.md), [`label_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/label_pct.md) |
| **Decisions** | [`annotate_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/annotate_bands.md), [`mark_value()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/mark_value.md), [`bands_rating_3()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md), [`bands_rating_5()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md), [`bands_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md), [`bands_nps_score()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md) |
| **Themes & palettes** | [`theme_ezrsurvey()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md) (+ `_x`/`_y`/`_xy`, `transparent`), `pal_rating`, `pal_nps`, [`scale_fill_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_rating.md), [`scale_fill_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_fill_nps.md) |
| **Branding** | [`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md), [`brand_info()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/brand_info.md), [`clear_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_brand.md), [`pal_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/pal_brand.md), [`scale_fill_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md)/[`scale_colour_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md) |
| **Plots** | [`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md), [`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md), [`plot_rating_grid()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_rating_grid.md), [`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md), [`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md), [`plot_gauges()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_gauges.md), [`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md), [`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md) |
| **Reporting** | [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md), [`report_layouts()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_layouts.md), [`report_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_slide.md)/[`report_section()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_section.md)/[`report_title_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_title_slide.md), [`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md)/`_plot()`/`_table()`, [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md), [`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md) (Quarto pptx/html/pdf/docx), [`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md) |
| **Quick save** | [`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md) (png/svg/pdf), [`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md) (csv/tsv/xlsx), [`save_output()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_output.md) (auto-dispatch), [`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md) (multi-tab), [`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md) (table + chart per question) |
| **Data** | `podracing_survey` (1,000 simulated pod-racing fans), `shopping_survey` (800 Edwardian shoppers) |

## Two things that are not obvious

- **Name the dataset once.** `use_dataset(podracing_survey)` at the top
  of a script lets every helper drop the data argument entirely –
  `calc_percentage(demo_gender)`, `calc_nps(nps_value)`,
  `diagnose(starts_with("ratings_"))`. An explicit data frame or a pipe
  always wins over the default, and
  [`clear_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md)
  ends it.
- **Column completion needs the pipe.**
  `podracing_survey %>% calc_percentage(<Tab>` offers `demo_gender` and
  the rest; the un-piped `calc_percentage(df, <Tab>` cannot. That is the
  mechanism RStudio and Positron use, not a limitation of this package:
  they only offer a data frame’s columns inside a pipe chain, for any
  package including the tidyverse.

## Where output goes

Every save writes into an `ezrsurvey-outputs/` folder in the working
directory, created on demand, so a script’s results collect in one
place:

``` r

save_plot(p, "nps.png")               # ezrsurvey-outputs/nps.png
report_deck(items, path = "q2.pptx")  # ezrsurvey-outputs/q2.pptx
scaffold_report("html")               # ezrsurvey-outputs/survey-report-html.qmd
```

The first save of a session says where the file went, so nobody hunts
for it in the working directory.

A path that names a directory is used exactly as written, which is how
you override that: `"./nps.png"` for the working directory,
`"charts/nps.png"` for a folder of your own, or any absolute path.
`ezrsurvey_options(output_dir = )` renames the folder for a project, or
set it to `"."` to put bare names back in the working directory.

## Articles

The front page is the tour. The details live in their own articles:

| Article | What it covers |
|----|----|
| [Getting started](https://mashud37.github.io/ezr-research/ezr-survey/articles/ezrsurvey.html) | A whole analysis end to end on the bundled data |
| [Banner tables](https://mashud37.github.io/ezr-research/ezr-survey/articles/banner-tables.html) | The client’s working table: cell types, weighting, automatic variable choice, checkpointed runs |
| [Countries, regions and currency](https://mashud37.github.io/ezr-research/ezr-survey/articles/countries-and-currency.html) | Free-text country columns, ISO 3166-1 in and out, converting money people answered in their own currency |
| [PowerPoint decks](https://mashud37.github.io/ezr-research/ezr-survey/articles/powerpoint-decks.html) | One-call decks, slide-at-a-time decks, your org template, Google Slides |
| [Quarto reports](https://mashud37.github.io/ezr-research/ezr-survey/articles/quarto-reports.html) | A report you edit and re-render each wave, in html, pdf, docx or pptx |

## License

MIT © Andreas Schellewald
