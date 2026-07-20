# ezrsurvey <img src="man/figures/logo.png" align="right" height="120" alt="" />

> ezrsurvey — tidyverse helpers for everyday consumer-survey work, designed so
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
pak::pak("aschellewald/ezrsurvey")
```

The analysis core depends only on the tidyverse packages. A few extras unlock
optional features: `rwa` (importance analysis), `treemapify` (quote treemaps) and
`ggrepel` (non-overlapping IPM labels).

## The 60-second tour

```r
library(ezrsurvey)   # brings the tidyverse with it

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

# Grouped + pivoted to a wide cross-tab
calc_percentage(podracing_survey, satis_return, by = region, wide = TRUE)

# 2. A labelled bar chart in one pipe -- orientation, wrapping and order
#    are chosen automatically (here: many long driver names -> horizontal bars)
calc_percentage(podracing_survey, fav_driver) %>%
  plot_bars()

# 3. NPS and the gauge
nps <- calc_nps(podracing_survey, nps_value)$nps
plot_nps_gauge(nps)

# 4. Importance / performance modelling
ipm_model(podracing_survey, nps_value, "ratings_") %>%
  plot_ipm()

# 5. Survey precision diagnostics (the appendix "data info" block, as one call)
diagnose(podracing_survey, demo_gender, dplyr::starts_with("ratings_"))

# 6. Quick saves — pipe-friendly, format inferred from the extension
calc_percentage(podracing_survey, demo_gender) %>% save_data("gender.xlsx")
plot_bars(calc_percentage(podracing_survey, demo_gender)) %>% save_plot("gender.svg")
```

## What's in the box

| Area | Functions |
| --- | --- |
| **Import** | `read_folder()`, `select_prefix()`, `select_suffix()`, `parse_filename()` |
| **Recode** | `na_blank()`, `drop_items()`, `ensure_numeric()`, `bin_numeric()`, `recode_age()`, `recode_generation()`, `recode_likert()`, `nps_group()` |
| **Country → region** | `add_region()`, `recode_region()`, `recode_subregion()`, `country_region` |
| **Config / profile** | `ezrsurvey_options()`, `reset_ezrsurvey_options()`, `use_ezrsurvey_profile()`, `load_ezrsurvey_profile()` |
| **Comments** | `sample_comments()`, `sample_comments_diverse()` |
| **Summaries** | `calc_percentage()`, `calc_percentage_multi()`, `calc_summary()` |
| **Modelling** | `calc_nps()`, `calc_importance()`, `ipm_model()` |
| **Diagnostics** | `se_mean()`, `se_prop()`, `rse()`, `margin_of_error()`, `diagnose()` |
| **Scales** | `nice_max()`, `scale_y_pct()`, `label_pct()` |
| **Decisions** | `annotate_bands()`, `mark_value()`, `bands_rating_3()`, `bands_rating_5()`, `bands_nps()` |
| **Themes & palettes** | `theme_ezrsurvey()` (+ `_x`/`_y`/`_xy`, `transparent`), `pal_rating`, `pal_nps`, `scale_fill_rating()`, `scale_fill_nps()` |
| **Branding** | `use_brand()`, `brand_info()`, `clear_brand()`, `pal_brand()`, `scale_fill_brand()`/`scale_colour_brand()` |
| **Plots** | `plot_bars()`, `plot_stacked_rating()`, `plot_nps()`, `plot_nps_gauge()`, `plot_ipm()`, `plot_quotes_tree()` |
| **AI summaries** | `set_llm_key()`/`get_llm_key()`, `ai_chat()`, `ai_summarise()`, `ai_report_sections()`, `ai_context()`, `list_prompts()`/`register_prompt()` |
| **Reporting** | `report_new()`, `report_layouts()`, `report_add_slide()`/`_plot()`/`_table()`, `report_deck()` (incl. `ai = TRUE`), `scaffold_report()` (Quarto pptx/html/pdf/docx), `example_report()` |
| **Quick save** | `save_plot()` (png/svg/pdf), `save_data()` (csv/tsv/xlsx), `save_output()` (auto-dispatch) |
| **Data** | `podracing_survey` (1,000 simulated pod-racing fans), `shopping_survey` (800 Edwardian shoppers) |

## Two small tricks worth knowing

- **Name the dataset once.** `use_dataset(podracing_survey)` at the top of a
  script lets every helper drop the data argument entirely --
  `calc_percentage(demo_gender)`, `calc_nps(nps_value)`,
  `diagnose(starts_with("ratings_"))`. An explicit data frame or a pipe always
  wins over the default, and `clear_dataset()` ends it.
- **Column completion.** Pipe the data in and the IDE completes column names:
  `podracing_survey %>% calc_percentage(<Tab>` offers `demo_gender` etc.
  This is the same mechanism dplyr relies on -- RStudio and Positron only
  offer a data frame's columns inside a pipe chain, so the un-piped
  `calc_percentage(df, <Tab>` form cannot complete columns for *any* package
  (tidyverse included).
- **Dynamic axes.** `nice_max(x, unit = 25)` rounds a chart's ceiling up to the
  next tidy multiple, so data labels never collide with the panel top. It powers
  `scale_y_pct()` and the plot wrappers.
- **Decision bands.** `annotate_bands()` adds consistent "where's good, where's
  bad" guidance to any chart from a small band spec — the presets
  `bands_rating_3()` / `bands_nps()` cover the common cases.

## Branding

Point ezrsurvey at your organisation's PowerPoint (or Word) template once, and
everything downstream matches it:

```r
use_brand("brand/org-template.pptx")
```

This extracts the template's theme colours and fonts, so `plot_bars()` fills
with your primary accent, `pal_brand()` / `scale_fill_brand()` expose the full
accent palette, `theme_ezrsurvey()` uses your body font (only when it is
installed on the machine), and the template file becomes the default reference
document for `report_new()`, `report_deck()` and `scaffold_report()`. No
template handy? `use_brand(colors = c("#0B5394", "#E69138"), fonts = "Georgia")`
sets the same options directly, and they can live in your `.ezrsurvey.yml`
profile. `clear_brand()` returns to the neutral look. The semantic palettes
(`pal_rating`, `pal_nps`) keep their red-amber-green meaning regardless of
brand.

## AI summaries

```r
# one-time: store a key in the OS keyring
set_llm_key("openai")

# survey context makes summaries analyst-grade: base sizes and margins of
# error are quoted and respected
ctx <- ai_context(podracing_survey,
                  question = "How likely are you to recommend pod racing?")

calc_percentage(podracing_survey, demo_gender, sort = "desc") %>%
  ai_summarise(template = "exec_summary", provider = "openai", context = ctx)

# draft several report sections at once
ai_report_sections(
  list(
    gender = calc_percentage(podracing_survey, demo_gender),
    nps    = list(data = calc_nps(podracing_survey, nps_value),
                  template = "exec_summary")
  ),
  provider = "openai", context = ctx
)
```

Prompts are named templates (`list_prompts()`): headline findings, executive
summaries, drivers vs barriers, slide titles and bullets, verbatim thematic
analysis, segment comparison, methodology passages and a full-report
narrative. Add your own with `register_prompt()` (including an
`output_contract` that pins the answer's format). Only the summary table you
pass is sent to the provider -- never raw respondent rows.

## Reporting

```r
# Build a PowerPoint deck directly from R -- on your org template, with
# AI-drafted takeaway bullets beside every chart
use_brand("brand/org-template.pptx")
report_deck(
  list(
    "Gender" = plot_bars(calc_percentage(podracing_survey, demo_gender)),
    "NPS"    = calc_nps(podracing_survey, nps_value)
  ),
  path = "overview.pptx",
  ai = TRUE, provider = "openai", context = ai_context(podracing_survey)
)

# ...or scaffold a Quarto report you can render to pptx / html / pdf / docx
scaffold_report("html", path = "report.qmd", title = "Q2 Viewer Survey")
scaffold_report("pptx", title = "Q2 Viewer Survey",
                reference_doc = "brand/org-template.pptx")
```

Without a brand template, decks default to the package's own **styled 16:9
template**: an accent lead-in over a hairline under every title, a hairline
above the footer strip, a full-bleed accent band across the foot of the title
slide, and live slide numbers on every content slide. Pass `style = "plain"`
for the same widescreen deck with no decoration, or `slide_numbers = FALSE`
to drop the numbering. The same files back the Quarto pptx scaffold, so both
routes look consistent out of the box.

```r
report_deck(items, path = "deck.pptx")                   # styled (default)
report_deck(items, path = "deck.pptx", style = "plain")  # plain white
```

Charts are drawn to a **constant bar thickness** whatever the answer count, so
a three-answer chart and a ten-answer chart sit together in a deck instead of
the first one's bars turning into slabs (`bar_width` / `bar_ref_items` in
`ezrsurvey_options()`).

The officer path (`report_new()` / `report_deck()`) works with **any**
corporate template: layouts are chosen by inspecting their placeholders (not
their names), charts are rendered at the exact size of the content
placeholder, and `report_layouts()` shows what a template offers. The Quarto
scaffolds ship with parameters (`-P data:my-survey.csv`, `-P ai:true`),
placeholder narrative and a precision appendix.

For a finished, fully worked report on the bundled data -- every chart type,
real narrative, plus the matching deck script -- copy the example into your
project and adapt it:

```r
example_report()   # writes ezrsurvey-example/podracing-report.qmd + -deck.R
```

> Quarto's `reference-doc` requires the *standard* layout names ("Title
> Slide", "Title and Content", ...). If your organisation's template renamed
> its layouts, build the deck with `report_deck()` instead.

## Google Slides

Google Slides imports PowerPoint natively, so the branded-pptx route above is
also the Google Slides route: build the deck with `report_deck()` (or render
the Quarto pptx scaffold), then in Slides use **File > Import slides** (into
an existing deck) or open the `.pptx` directly from Drive. What survives the
import: chart images, text boxes, bullets, speaker notes (where
`report_deck(ai = TRUE)` places its takeaways on template-less decks) and
theme colours. What to watch: fonts that are not available in Google's
catalogue get substituted -- if Slides is the destination, brand with a
Google-available font (`use_brand(..., fonts = "Roboto")`) -- and intricate
table borders may simplify. Chart images are transparent-background PNGs, so
they sit cleanly on any Slides background.

## License

MIT © Andreas Schellewald
