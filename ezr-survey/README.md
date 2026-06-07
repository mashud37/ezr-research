# ezrsurvey <img src="man/figures/logo.png" align="right" height="120" alt="" />

> ezrsurvey — a small, opinionated tidyverse wrapper for everyday consumer-survey
> work.

`ezrsurvey` packages the patterns a research manager reaches for again and again:
loading and stacking survey exports, turning questions into percentages without
the `count() |> mutate() |> pivot_wider()` ritual, recoding Likert and NPS scales,
importance–performance modelling, survey precision diagnostics, and a generalised
plotting toolkit (clean themes, semantic palettes, dynamic axes and automatic
"BAD / OK / GOOD" decision bands). It ships with a simulated consumer-survey
dataset, `consumer_survey`, so every example runs out of the box.

## Installation

```r
# install.packages("pak")
pak::pak("aschellewald/ezrsurvey")
```

The analysis core depends only on the tidyverse packages. A few extras unlock
optional features: `rwa` (importance analysis), `treemapify` (quote treemaps) and
`ggrepel` (non-overlapping IPM labels).

## The 60-second tour

```r
library(ezrsurvey)

# 1. Percentages, no count/mutate/pivot_wider
calc_percentage(consumer_survey, demo_gender, sort = "desc")
#> # A tibble: 3 x 3
#>   demo_gender           n   pct
#>   <fct>             <int> <dbl>
#> 1 As a man            648    70
#> 2 As a woman          228    24
#> 3 Non-binary person    56     6

# Check-all-that-apply questions, by prefix
calc_percentage_multi(consumer_survey, "motivations_", id = respondent_id, sort = "desc")

# Grouped + pivoted to a wide cross-tab
calc_percentage(consumer_survey, satis_return, by = region, wide = TRUE)

# 2. A labelled bar chart in one pipe
calc_percentage(consumer_survey, demo_edu, sort = "asc") |>
  plot_bars(flip = TRUE)

# 3. NPS and the gauge
nps <- calc_nps(consumer_survey, nps_value)$nps
plot_nps_gauge(nps)

# 4. Importance / performance modelling
ipm_model(consumer_survey, nps_value, "ratings_") |>
  plot_ipm()

# 5. Survey precision diagnostics (the appendix "data info" block, as one call)
diagnose(consumer_survey, demo_gender, dplyr::starts_with("ratings_"))

# 6. Quick saves — pipe-friendly, format inferred from the extension
calc_percentage(consumer_survey, demo_gender) |> save_data("gender.xlsx")
plot_bars(calc_percentage(consumer_survey, demo_gender)) |> save_plot("gender.svg")
```

## What's in the box

| Area | Functions |
| --- | --- |
| **Import** | `read_folder()`, `select_prefix()`, `parse_filename()` |
| **Recode** | `na_blank()`, `ensure_numeric()`, `bin_numeric()`, `recode_age()`, `recode_generation()`, `recode_likert()`, `nps_group()` |
| **Country → region** | `add_region()`, `recode_region()`, `recode_subregion()`, `country_region` |
| **Config / profile** | `ezrsurvey_options()`, `reset_ezrsurvey_options()`, `use_ezrsurvey_profile()`, `load_ezrsurvey_profile()` |
| **Comments** | `sample_comments()`, `sample_comments_diverse()` |
| **Summaries** | `calc_percentage()`, `calc_percentage_multi()`, `calc_summary()` |
| **Modelling** | `calc_nps()`, `calc_importance()`, `ipm_model()` |
| **Diagnostics** | `se_mean()`, `se_prop()`, `rse()`, `margin_of_error()`, `diagnose()` |
| **Scales** | `nice_max()`, `scale_y_pct()`, `label_pct()` |
| **Decisions** | `annotate_bands()`, `mark_value()`, `bands_rating_3()`, `bands_rating_5()`, `bands_nps()` |
| **Themes & palettes** | `theme_ezrsurvey()` (+ `_x`/`_y`/`_xy`, `transparent`), `pal_rating`, `pal_nps`, `scale_fill_rating()`, `scale_fill_nps()` |
| **Plots** | `plot_bars()`, `plot_stacked_rating()`, `plot_nps()`, `plot_nps_gauge()`, `plot_ipm()`, `plot_quotes_tree()` |
| **AI summaries** | `set_llm_key()`/`get_llm_key()`, `ai_chat()`, `ai_summarise()`, `ai_report_sections()`, `list_prompts()`/`register_prompt()` |
| **Reporting** | `report_new()`, `report_add_slide()`/`_plot()`/`_table()`, `report_deck()`, `scaffold_report()` (Quarto pptx/html/pdf/docx) |
| **Quick save** | `save_plot()` (png/svg/pdf), `save_data()` (csv/tsv/xlsx), `save_output()` (auto-dispatch) |
| **Data** | `consumer_survey` (1,000 simulated respondents) |

## Two small tricks worth knowing

- **Dynamic axes.** `nice_max(x, unit = 25)` rounds a chart's ceiling up to the
  next tidy multiple, so data labels never collide with the panel top. It powers
  `scale_y_pct()` and the plot wrappers.
- **Decision bands.** `annotate_bands()` adds consistent "where's good, where's
  bad" guidance to any chart from a small band spec — the presets
  `bands_rating_3()` / `bands_nps()` cover the common cases.

## AI summaries (Phase 2)

```r
# one-time: store a key in the OS keyring
set_llm_key("openai")

calc_percentage(consumer_survey, demo_gender, sort = "desc") |>
  ai_summarise(template = "exec_summary", provider = "openai")

# draft several report sections at once
ai_report_sections(
  list(
    gender = calc_percentage(consumer_survey, demo_gender),
    nps    = list(data = calc_nps(consumer_survey, nps_value),
                  template = "exec_summary")
  ),
  provider = "openai"
)
```

Prompts are named templates (`list_prompts()`); add your own with
`register_prompt()`. Only the summary table you pass is sent to the provider.

## Reporting (Phase 2)

```r
# Build a PowerPoint deck directly from R
report_deck(
  list(
    "Gender" = plot_bars(calc_percentage(consumer_survey, demo_gender)),
    "NPS"    = calc_nps(consumer_survey, nps_value)
  ),
  path = "overview.pptx"
)

# ...or scaffold a Quarto report you can render to pptx / html / pdf / docx
scaffold_report("html", path = "report.qmd", title = "Q2 Viewer Survey")
```

## Roadmap (Phase 3)

- Worked **examples, help and tab-completion metadata** across every function so
  `?fn` and IDE F1 give runnable, copy-paste answers; a getting-started
  vignette and a pkgdown site.

## License

MIT © Andreas Schellewald
