# ezrsurvey 0.4.0

## Working without repeating the data

* **The tidyverse metapackage is now attached with ezrsurvey.** `library(ezrsurvey)`
  brings `dplyr`, `ggplot2`, `tidyr`, `stringr` and the rest with it, so scripts
  and reports never need to load the packages ezrsurvey wraps.
* **`use_dataset()` finally saves the typing it promised.** With a default set,
  columns can be passed positionally with no `data` and no `column =`:
  `calc_percentage(demo_gender)`, `calc_nps(nps_value)`,
  `crosstab(demo_gender, region)`, `diagnose(starts_with("ratings_"))`. The
  helpers tell a data frame from a column by looking at the first argument, so
  an explicit data frame or a pipe still wins. Previously only the much longer
  `calc_percentage(column = demo_gender)` worked, which saved nothing over just
  passing the data.

## Colour correctness

* **Rating colours now agree with the decision bands.** A feature averaging 2.4
  is inside the red BAD band (1-3) but was drawn amber, because the point colour
  came from a rounded 1-5 code while the band behind it came from
  `bands_rating_3()`. [plot_ipm()] now colours every point by the band it
  actually falls in, and `pal_rating` uses the same thresholds (1-2 bad, 3 ok,
  4-5 good). `plot_ipm()` gains a `bands` argument.

## Organisation branding

* **`use_brand()`** adopts an organisation brand from a `.pptx` / `.docx`
  template: theme accent colours and typefaces are extracted from the file's
  OOXML theme and become the session defaults (`plot_bars()` fill,
  `theme_ezrsurvey()` font when installed locally), and the template is
  registered as the default reference document for `report_new()`,
  `report_deck()` and `scaffold_report()`. Colours/fonts can also be set
  directly (`use_brand(colors =, fonts =)`) or persisted in the YAML profile
  (`brand_*` options). `brand_info()` shows and `clear_brand()` resets the
  active brand.
* **`pal_brand()`** and **`scale_fill_brand()`** / `scale_colour_brand()`
  expose the brand accents to any plot; semantic palettes (`pal_rating`,
  `pal_nps`) deliberately keep their red-amber-green meaning.

## Reporting

* **Decks are 16:9 by default, and styled.** Without a brand template,
  `report_new()`, `report_deck()` and the Quarto pptx scaffold use a built-in
  widescreen template carrying the furniture a corporate deck is expected to
  have: an accent lead-in over a full-width hairline under every title, a
  hairline above the footer strip, a full-bleed accent band across the foot of
  the title slide, and live slide numbers on every content slide. Pass
  `style = "plain"` for the same deck with no decoration at all, or
  `slide_numbers = FALSE` to drop the numbering. Both templates keep the
  standard PowerPoint layout names (plus "Content with Caption"), so Quarto
  renders against either without falling back to Pandoc's own template.
* **Bars are a constant thickness across charts.** `geom_col()` widths are a
  fraction of a category slot, so a three-answer chart used to draw bars over
  twice as thick as a ten-answer one and a deck looked incoherent as you
  flicked through it. [plot_bars()] now scales the fraction with the bar count
  so the drawn thickness is the same everywhere (`bar_width` /
  `bar_ref_items`, see `ezrsurvey_options()`).
* **`example_report()`** copies a complete worked report into your project: a
  full narrative report over the bundled `podracing_survey` and the matching
  deck script. Both are written the way a real readout is -- a story that runs
  headline, then cause, then segment, then evidence; slide titles that state
  the finding rather than name the chart; and every figure in the prose
  computed from the data rather than typed in, so the narrative cannot drift.
* The officer builders now work with **any corporate template**: slide layouts
  are chosen by inspecting placeholder types (not locale-dependent layout
  names), slide titles are skipped with a warning when a layout has none, and
  plots/tables are rendered at the exact size of the content placeholder with
  sensible fallbacks. **`report_layouts()`** lists what a template offers.
* **`report_deck(ai = TRUE)`** drafts 3-4 takeaway bullets per slide (and,
  with `ai_titles = TRUE`, headline titles) from the data behind each item,
  reusing one chat across the deck; bullets land in a two-content layout when
  the template has one, else in the speaker notes. AI failures degrade to
  plain slides.
* **Quarto scaffolds rewritten** as four distinct report skeletons (pptx /
  html / docx / pdf) with `data` and `ai` parameters, placeholder narrative,
  executive summary and a precision appendix; `scaffold_report()` gains
  `author` and `reference_doc` (defaulting to the brand template).
* README documents the **Google Slides workflow**: build the branded `.pptx`
  and import it (File > Import slides); what survives and what to watch.

## AI summaries

* All prompt templates rewritten to an analyst standard (quote only present
  figures, respect margins of error, name base sizes) and five added:
  `slide_bullets`, `thematic_analysis`, `segment_comparison`, `methodology`
  and `full_report`.
* **`ai_context()`** bundles sample size, question wording, base, fieldwork
  and precision notes (auto-derived from the raw survey) into every prompt via
  the new `context` argument of `ai_summarise()` / `ai_report_sections()` /
  `report_deck()`.
* Tables are now sent to the model as markdown pipe tables;
  `register_prompt()` gains an `output_contract` field pinning the answer's
  format; `ai_report_sections()` gains `chat` for connection reuse.

# ezrsurvey 0.3.1

## Output location

* All savers now default to a project-local **`outputs/`** folder in the working
  directory instead of requiring a path: `save_plot()` (`outputs/plot.png`),
  `save_data()` (`outputs/data.csv`), `export_xlsx()` (`outputs/tables.xlsx`),
  `report_save()` / `report_deck()` (`outputs/report.pptx` / `.docx`). Missing
  directories are created; explicit paths behave as before.

## Annotation layer

* **`annotate_bands()`** band labels no longer sit on top of the marker line:
  `label_offset` defaults to 4% of the opposite-axis range and labels are
  justified into the panel, so nothing clips at the panel edge. `text_size`
  now defaults to the theme's base font size (11 pt) instead of a fixed geom
  size, and multi-line band labels get a tighter line height.
* **`mark_value()`** labels are justified inside the panel next to the marker
  line instead of being half-clipped at the `Inf` edge.
* **`plot_nps()`** detractor/passive/promoter callouts no longer clip at the
  panel top or overlap each other; the promoter callout right-aligns to the
  panel edge.
* **`plot_nps_gauge()`** gains a `label_size` argument; band labels default to
  the theme's base font size.

## Reproducibility

* **`sample_comments()`** gains a `seed` argument (matching
  `sample_comments_diverse()`), so quote selections can be reproduced; the RNG
  state is restored afterwards.
* `calc_percentage(long = TRUE)` no longer triggers the deprecated tidyselect
  external-vector warning.

# ezrsurvey 0.3.0

## Smarter charts and cleaner questions

* **`plot_bars()` now lays itself out.** `orientation = "auto"` (the default)
  draws vertical columns for a few short labels and horizontal bars for many or
  long ones, wraps long labels with `str_wrap()`, steps the data-label size down
  as bars multiply, and orders bars so the longest sits at the top (bars) or on
  the left (cols). An intentional ordinal scale (an ordered factor from a
  registered order) keeps its order. `orientation` / `sort` / `wrap` /
  `label_size` and the new `bar_*` options (see `ezrsurvey_options()`) override
  the automatics; the old `flip` argument still works.
* **`drop_items()`** plus a **`drop =`** argument on `calc_percentage()`,
  `calc_percentage_multi()`, `calc_percentage_batch()` and `crosstab()` remove
  unwanted answers (e.g. `"Other"`, `"Don't know"`) before counting, so the kept
  answers re-base to ~100%. Set a session default with
  `ezrsurvey_options(drop_answers = ...)`.

## Data

* The bundled example survey is now **`podracing_survey`** (renamed from
  `consumer_survey`): a Star Wars pod-racing fan survey with
  international-standard demographics (ISO/IEC 5218 sex, ISCED education, ILO
  labour-force status, ISIC sectors, ISO 3166 countries) and diverse, entity-rich
  open-text comments for the text / NER helpers.
* New **`shopping_survey`**: a turn-of-the-century (Edwardian) shopping-behaviour
  survey -- a second, very different theme for examples.
* `register_order_presets()` now ships an `education_isced` order (was
  `education_us`).

# ezrsurvey 0.2.0

## Survey weighting

* **`set_weights()`** defines a post-stratification / raking scheme from target
  shares, e.g. `set_weights(c(variable = "demo_gender", Male = 0.49,
  Female = 0.50, "Non-binary" = 0.01))`, and multiple variables at once. With
  one variable it is exact post-stratification; with several it rakes (iterative
  proportional fitting) so every margin matches.
* Once set, the summary helpers weight automatically: **`calc_percentage()`**
  (and `calc_percentage_batch()`) gain a `wpct` column beside `n`/`pct`, while
  **`calc_nps()`**, **`calc_summary()`** and **`crosstab()`** default to weighted
  values. Pass `weights = FALSE` to any of them to opt out, or `weights = <spec>`
  to weight a single call ad hoc.
* `clear_weights()`, `get_weights()`, `has_weights()` manage the scheme;
  `weight_vector()` returns the per-respondent weights (and `set_weights()`
  reports the Kish design effect and effective sample size).

# ezrsurvey 0.1.0

First release. A single-line-helper toolkit for everyday consumer-survey
analysis, aimed at research and insights professionals.

## Highlights

* **Import**: `read_folder()`, `select_prefix()`, `select_suffix()`,
  `parse_filename()`.
* **Recode / clean**: `na_blank()`, `ensure_numeric()`, `bin_numeric()`,
  `recode_age()`, `recode_generation()`, `recode_likert()`, `nps_group()`,
  `recode_region()` / `add_region()`.
* **Summarise**: `calc_percentage()`, `calc_percentage_multi()`,
  `calc_percentage_batch()`, `calc_summary()`, `crosstab()`.
* **Model**: `calc_nps()`, `calc_importance()`, `ipm_model()`.
* **Compare**: `compare_values()`, `plot_diff()`.
* **Diagnostics**: `se_mean()`, `se_prop()`, `rse()`, `margin_of_error()`,
  `diagnose()`.
* **Comments**: `sample_comments()`, `sample_comments_diverse()`.
* **Currency**: `convert_currency()`, `add_currency()`, `list_currencies()`.
* **Plot**: `plot_bars()`, `plot_stacked_rating()`, `plot_nps()`,
  `plot_nps_gauge()`, `plot_ipm()`, `plot_quotes_tree()`, with the
  `theme_ezrsurvey*()` family, semantic palettes and `annotate_bands()`.
* **Save / report**: `save_plot()`, `save_data()`, `save_output()`,
  `export_xlsx()`, the `report_*()` officer builders and `scaffold_report()`.
* **AI summaries**: `ai_chat()`, `ai_summarise()`, `ai_report_sections()` with
  keyring-backed key management and a prompt-template registry.
* **Configuration**: `ezrsurvey_options()`, reusable level orders
  (`register_order()`), YAML profiles (`use_ezrsurvey_profile()`).
* Bundled data: `podracing_survey`, `country_region`, `currency_rates`.
