# ezrsurvey 0.6.0

## Rating scales: a fix that can move existing numbers

* **`recode_likert()`** now tries the longest answer wording first. A scale
  whose levels nest inside one another ("Good" inside "Very good", "Likeable"
  inside "Very likeable") previously resolved any answer the exact pass missed
  to the **shorter** level, so an answer carrying an emoji or a stray character
  was quietly downgraded. If your data has such a scale and any untidy answers,
  ratings, feature averages and `ipm_model()` performance scores will change,
  and the new numbers are the correct ones. Supplied `synonyms` follow the same
  longest-first rule.
* **`bin_numeric()`** reports values that fell outside `breaks` instead of
  turning them into `NA` in silence, and takes `quiet = TRUE` to suppress that.
  A closed top band under an open-ended label (`35` to `40.5` labelled
  "35 to 40+") silently drops everyone above it; `Inf` is what that label means.
* A registered order that does not list an answer now names the answers that
  became `NA` rather than letting them appear as an unlabelled bar.

## Progress on the slow helpers

* The helpers that can run for minutes -- `crosstab_banner()`,
  `export_summary_xlsx()`, `report_deck()`, `read_folder()`, `diagnose()` --
  now report the question, file or slide they are on, with a measured estimate
  of the time remaining. A full every-variable banner is one cross-tab per
  question per grouping variable, so it takes minutes on a wide survey and used
  to give no sign of life at all.
* New **`progress`** option (`ezrsurvey_options(progress = )`): `"auto"`
  (default) reports in an interactive session and stays silent in scripts,
  vignettes and `R CMD check`; `TRUE` / `FALSE` force it either way.

## Every output lands in one folder

* A **bare output file name now goes into `ezrsurvey-outputs/`**, created on
  demand: `save_plot(p, "nps.png")` writes `ezrsurvey-outputs/nps.png`, and the
  same holds for `save_data()`, `save_output()`, `export_xlsx()`,
  `export_summary_xlsx()`, `report_save()` and `report_deck()`. Previously only
  the `path = NULL` default used that folder, so any script that named its files
  scattered them through the working directory.
* A path that **names a directory** is written exactly as given, which is how you
  override it: `"./nps.png"` for the working directory, `"charts/nps.png"` for a
  folder of your own, or any absolute path (so `tempfile()` is unaffected).
* New **`output_dir`** option (default `"ezrsurvey-outputs"`) renames that folder
  for a project, or set it to `"."` to put bare names back in the working
  directory.

## Confirming an automatic variable selection

* `crosstab_banner()` and `export_summary_xlsx()` choose their own variables
  when none are named, and that choice decides everything they produce. Both now
  print the questions kept, the grouping variables and the columns skipped, and
  wait for a yes before a run that takes minutes. Naming `rows` / `cols` (or the
  variables to summarise) is your own choice and is never questioned.
* New **`confirm`** option and argument: `"auto"` (default) asks in an
  interactive session and never asks in a script, so an unattended run cannot
  stall on a prompt; `TRUE` / `FALSE` force it either way. Answering no computes
  nothing and returns `NULL`.

## Resuming an interrupted table

* **`crosstab_banner(checkpoint = )`** saves each question as it finishes, so
  re-running the identical call after a crash or an interrupt continues instead
  of starting over. A checkpoint written from different data or different
  arguments is reported and discarded, never blended into the new run. Use
  `TRUE` to have the file managed under `tools::R_user_dir()`, or name a path to
  choose the location. Nothing is written unless you ask.
* Weights are computed **once per dataset and scheme** and reused, instead of
  re-running the raking loop inside every cell of a banner table.
  `clear_weights_cache()` empties the cache; `clear_weights()` does it too.
* **`sample_comments_diverse(max_candidates = )`** narrows a large corpus to a
  random shortlist (default 500) before comparing every comment with every
  other, which is what made it slow and memory-hungry on a big survey.

## New

* **`plot_rating_grid()`** builds a stacked rating chart for a whole block of
  prefix-sharing columns in one call: tabulate, tidy the question names, number
  the answers by their place on the scale, stack. It replaces an eight-line
  block per question block, and it *reports* answers that are not on the scale
  instead of leaving them as an unranked segment.
* **`clean_label()`** is now exported. It is the tidying
  `calc_percentage_multi()` and `ipm_model()` already applied to their own
  output, so a hand-built table can be made to match them: labels that disagree
  will not join, which is what silently empties a comparison chart.
* **`calc_percentage_batch(clean_names = , prefix = )`** applies that same
  tidying to its `variable` column.
* **`bands_nps_score()`** exposes the Net Promoter Score band set
  (needs work / good / great / excellent over -100..100) that was previously
  locked inside `plot_nps_gauge()`. Note `bands_nps()` is the 0-10 *answer*
  scale and is a different thing.
* The band presets take **`from` / `to`** to trim themselves to the part of the
  scale a chart actually shows, e.g. `bands_rating_3(from = 2)` on a 2-5 panel.
* **`report_new(keep_slides = FALSE)`** starts from an empty deck, dropping any
  boilerplate slides the template carries.
* **`sample_comments(by = )`** samples `n` comments per group and keeps the
  group as a column, replacing a hand-rolled loop over the groups.

# ezrsurvey 0.5.0

## AI summaries move to ezrintelligence

* The language-model helpers are **removed** from ezrsurvey and now live in the
  companion `ezrintelligence` package: `ai_chat()`, `ai_summarise()`,
  `ai_report_sections()`, `ai_context()`, the prompt-template registry
  (`list_prompts()`, `get_prompt()`, `register_prompt()`) and key management
  (`set_llm_key()`, `get_llm_key()`, `has_llm_key()`, `delete_llm_key()`,
  `list_llm_keys()`). Install it alongside ezrsurvey and pass it any summary
  table ezrsurvey produces. `ellmer` and `keyring` are no longer suggested
  dependencies.
* **`report_deck()`** loses its `ai`, `ai_titles`, `chat`, `provider`, `model`
  and `context` arguments. For AI slide text, call
  `ezrintelligence::ai_slide_text()` on the table behind a slide and place the
  title and bullets it returns yourself.
* The Quarto scaffolds and the worked example lose their `ai` parameter and
  the eval-gated AI chunks; they render with placeholder narrative and their
  `data` parameter as before.

## Fixes

* **`export_summary_xlsx()`** no longer fails with "Failed to save workbook"
  when `R_ZIPCMD` names a zip tool that is not installed. openxlsx2 reaches for
  an external zip whenever that variable is set, and R sets it to a bare `zip`
  on Windows under `R CMD` whether or not a `zip.exe` exists; the workbook is
  now written with openxlsx2's own zipping code whenever the named tool cannot
  be found.
* The `crosstab_banner()` example that crosses every variable against every
  other moves to `\donttest`, where its runtime belongs.
# ezrsurvey 0.4.0

## Cross-tabs and summary workbooks

* **`crosstab_banner()`** builds the market-research banner table: a stack of
  question variables down the side (`rows`) and one or more grouping variables
  across the top (`cols`), plus a whole-sample **Overall** column. Categorical
  questions become column-percentage blocks (each column sums to ~100 within a
  block); numeric questions turn into a mean/median/sd/quartile block
  automatically. `cell = "diff"` shows each cell's distance from the Overall
  column, `long = TRUE` returns the tidy form, and `flextable = TRUE` renders the
  two-row spanning header for a slide or Word report. It generalises `crosstab()`
  from a single pair to a whole table. **Pass only the data frame** to cross every
  variable against every variable; identifier and free-text columns are skipped,
  and check-all-that-apply blocks (e.g. `motivations_*`) are folded into a single
  multi-select stub question with the correct question-level base.
* **`export_summary_xlsx()`** writes a tabbed Excel workbook with one worksheet
  per question, each holding that question's summary table and its chart
  (percentages and a bar chart for categorical questions, a `calc_summary()`
  table and a histogram for numeric ones, a `calc_percentage_multi()` table for a
  check-all-that-apply block). **Called with just the data frame** it writes every
  question at once, one multi-select block to a single sheet, skipping identifier
  and free-text columns. The Excel counterpart of the slide/Word `report_deck()`.
  Needs the suggested `openxlsx2` package.

## Output location

* The auto-output folder is now **`ezrsurvey-outputs/`** (was `outputs/`).
  `save_plot()`, `save_data()`, `save_output()`, `export_xlsx()`,
  `report_save()` and `report_deck()` write straight into it with no per-type
  subfolders when no `path` is given; explicit paths behave as before.

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

## Charts

* **`plot_gauges()`** draws several scores as thin banded gauge bars stacked one
  above another -- the summary-slide staple of the Net Promoter Score over the
  average feature quality rating, each on its own scale with a marker, instead
  of one fat single bar. `plot_nps_gauge()` remains for a single score.

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

* **One line per slide.** New wrappers collapse `calc -> plot -> add` onto a
  single pipe step so a deck script reads as one line per slide:
  `report_slide(title, content)` starts a titled slide and places its content
  (a ggplot becomes a chart, a data frame a table, a character vector a bullet
  list); `report_section("DEMOGRAPHICS")` drops a single-word divider; and
  `report_title_slide(title, subtitle)` opens the deck. The rewritten
  `example_report()` deck is built this way as a full agency read-out -- cover,
  chaptered sections and every question block in the questionnaire
  (recommendation, the six experience ratings and their drivers, motivations,
  the three sponsor brands, the whole respondent profile, favourite drivers,
  open-text comments and a methods appendix) -- with each slide title the survey
  question it answers.
* **Slide tables fill the slide.** `report_add_table()` now styles the table
  (banded header, centred cells, a readable 12pt font) and widens its columns
  to span the content placeholder, so a summary table fills the slide instead
  of sitting tiny in a corner.
* **Headlines and bullets no longer overflow.** The bundled templates bring the
  master title/body font sizes down to deck-appropriate values and give every
  text placeholder shrink-to-fit, so a descriptive question headline or a long
  bullet list is scaled to its box rather than spilling out of it.

* **Decks are 16:9 by default, and properly designed.** Without a brand
  template, `report_new()`, `report_deck()` and the Quarto pptx scaffold use a
  built-in widescreen template with a coherent navy/gold identity in place of
  the dated default Office colours: a full-bleed navy cover with a large
  left-aligned title, gold accent rule and a subtitle strapline; full-bleed
  navy section dividers carrying a single large section word; and content
  slides with a navy 24pt title over one slim rule (no stray hairlines) and a
  live slide number in the corner. `report_title_slide()` gains a `subtitle`
  argument for the cover strapline. Pass `style = "plain"` for the same
  palette with no decoration, or `slide_numbers = FALSE` to drop the numbering.
  Both templates keep the standard PowerPoint layout names (plus "Content with
  Caption"), so Quarto renders against either without falling back to Pandoc's
  own template.
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
