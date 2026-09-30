# Package index

## Import data

Load and shape raw survey exports.

- [`parse_filename()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/parse_filename.md)
  : Split a filename column into metadata columns
- [`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md)
  : Read and stack every CSV in a folder
- [`select_prefix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_prefix.md)
  : Select identifier and prefixed columns
- [`select_suffix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_suffix.md)
  : Select identifier and suffixed columns

## Clean & recode

Turn messy survey columns into tidy, analysis-ready variables.

- [`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md)
  : Add region (and subregion) columns from a country column

- [`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md)
  : Bin a numeric vector into labelled groups

- [`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md)
  : Tidy an exported column name into a readable label

- [`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md)
  : Drop unwanted answer categories from a question

- [`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md)
  : Coerce text to numeric, salvaging embedded numbers

- [`generation_scheme()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/generation_scheme.md)
  : Generational-cohort definitions

- [`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md)
  :

  Convert blank and boilerplate non-answers to `NA`

- [`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md)
  : Classify Net Promoter Score answers into groups

- [`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md)
  : Recode age into standard survey bands

- [`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md)
  : Recode age or birth year into a generational cohort

- [`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md)
  : Recode a worded rating scale to integers

- [`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md)
  [`recode_subregion()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md)
  : Look up the region or subregion for a country

- [`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)
  : Split a packed multi-select column into one column per answer

## Summarise

Percentages, summaries and cross-tabulations in one line.

- [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
  : Count a categorical question as percentages
- [`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md)
  : Percentages for a batch of questions at once
- [`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)
  : Tabulate a check-all-that-apply (multi-select) question as
  percentages
- [`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md)
  : Summarise a numeric question (mean / median / sd)
- [`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md)
  : Delete saved cross-tab checkpoints
- [`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)
  : Cross-tabulate two survey questions
- [`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)
  : Build a master banner (cross-tab) table

## Weighting

Post-stratification / raking applied automatically to the summaries.

- [`clear_weights_cache()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_weights_cache.md)
  : Forget cached survey weights
- [`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)
  : Set a survey weighting scheme for the session
- [`weight_vector()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weight_vector.md)
  : Compute the per-respondent survey weights
- [`get_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md)
  [`has_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md)
  [`clear_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md)
  : Inspect or clear the session weighting scheme

## Model

NPS and importance/performance modelling.

- [`calc_importance()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_importance.md)
  : Driver importance
- [`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md)
  : Net Promoter Score
- [`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)
  : Build an importance / performance model

## Compare

Differences between events, waves or segments.

- [`compare_values()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/compare_values.md)
  : Compare a metric between two datasets (e.g. two events or waves)
- [`plot_diff()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_diff.md)
  : Diverging bar chart of differences

## Diagnostics

Sampling precision and standard errors.

- [`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md)
  : Survey precision diagnostics for one or more columns
- [`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md)
  : Margin of error from a standard error
- [`precision_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/precision_summary.md)
  : Plain-language survey precision summary
- [`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md)
  : Relative standard error
- [`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md)
  : Rate precision from a relative standard error
- [`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md)
  : Standard error of a mean (point estimate)
- [`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md)
  : Standard error of a proportion

## Comments

Select illustrative open-text comments.

- [`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md)
  : Pick a random sample of open-text comments
- [`sample_comments_diverse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments_diverse.md)
  : Pick a diverse, information-rich sample of comments

## Currency

Convert monetary amounts between currencies.

- [`add_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_currency.md)
  : Add a converted-currency column to a data frame
- [`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md)
  : Convert amounts between currencies
- [`list_currencies()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_currencies.md)
  : List the currencies in a rate table

## Plots

Presentation-ready charts.

- [`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md)
  : Bar chart of a percentage table (auto-laid-out)
- [`plot_gauges()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_gauges.md)
  : Stacked score gauges (NPS over average quality, etc.)
- [`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md)
  : Importance / performance matrix
- [`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md)
  : NPS distribution slide (0-10 scale with group labels)
- [`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md)
  : Score gauge with decision bands and a value marker
- [`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md)
  : Treemap of selected quotes
- [`plot_rating_grid()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_rating_grid.md)
  : A stacked rating chart for a whole block of questions
- [`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md)
  : Stacked rating bars with weighted-average ordering

## Brand

Adopt an organisation’s colours and typefaces for every chart.

- [`brand_info()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/brand_info.md)
  : Show the active brand settings
- [`clear_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_brand.md)
  : Clear the active brand
- [`pal_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/pal_brand.md)
  : Brand colour palette
- [`scale_fill_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md)
  [`scale_colour_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md)
  [`scale_color_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md)
  : Brand fill and colour scales
- [`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)
  : Adopt an organisation brand from a PowerPoint or Word template

## Themes, palettes & decisions

Visual identity and decision-band annotations.

- [`pal_rating`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md)
  [`pal_nps`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md)
  [`pal_sequential_blue`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md)
  [`pal_neutral`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md)
  : ezrsurvey colour palettes
- [`scale_fill_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_fill_nps.md)
  : NPS group fill scale
- [`scale_fill_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_rating.md)
  [`scale_colour_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_rating.md)
  [`scale_color_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_rating.md)
  : Rating colour and fill scales
- [`theme_ezrsurvey()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md)
  [`theme_ezrsurvey_x()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md)
  [`theme_ezrsurvey_y()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md)
  [`theme_ezrsurvey_xy()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md)
  : ezrsurvey ggplot2 themes
- [`theme_transparent()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_transparent.md)
  : Transparent-background theme fragment
- [`annotate_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/annotate_bands.md)
  : Annotate a plot with labelled decision bands
- [`bands_rating_3()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md)
  [`bands_rating_5()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md)
  [`bands_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md)
  [`bands_nps_score()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md)
  : Built-in decision-band presets
- [`mark_value()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/mark_value.md)
  : Mark a single value on a plot
- [`rescale_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rescale_bands.md)
  : Move a band specification onto another scale
- [`label_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/label_pct.md)
  : Percent label formatter
- [`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md)
  : Round an axis maximum up to a "nice" value
- [`scale_y_pct()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_y_pct.md)
  : Continuous y-scale capped at a nice maximum with optional percent
  labels

## Save & report

Export tables, charts, decks and Quarto reports.

- [`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md)
  : Export a per-question summary workbook (table + chart per sheet)
- [`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md)
  : Export several tables to one Excel workbook, a tab each
- [`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md)
  : Quick-save a table to CSV, TSV or XLSX
- [`save_output()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_output.md)
  : Quick-save any ezrsurvey output (plot or table)
- [`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md)
  : Quick-save a plot to PNG, SVG or PDF
- [`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md)
  : Copy the worked example report into a folder
- [`list_report_templates()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_report_templates.md)
  : Available Quarto report templates
- [`report_add_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_plot.md)
  : Add a plot to a report
- [`report_add_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_slide.md)
  : Add a slide (PowerPoint) or heading (Word) to a report
- [`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md)
  : Add a table to a report
- [`report_add_text()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_text.md)
  : Add a paragraph of text to a report
- [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
  : Build a slide deck from a list of plots and tables in one call
- [`report_layouts()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_layouts.md)
  : List the slide layouts of a PowerPoint template
- [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md)
  : Start a new PowerPoint or Word report
- [`report_save()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_save.md)
  : Save a report to disk
- [`report_section()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_section.md)
  : Add a section-divider slide
- [`report_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_slide.md)
  : Add a whole slide in one call (title plus its content)
- [`report_title_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_title_slide.md)
  : Add the opening title slide
- [`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)
  : Scaffold a Quarto survey-report template

## Configuration

Options, reusable orders and profiles.

- [`apply_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/apply_order.md)
  : Apply a registered order to a vector
- [`get_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md)
  [`has_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md)
  [`clear_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md)
  [`dataset_vars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md)
  : Get, check or clear the default dataset
- [`edit_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/edit_ezrsurvey_profile.md)
  : Open the ezrsurvey profile for editing
- [`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)
  : Get or set ezrsurvey defaults
- [`ezrsurvey_profile_paths()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_profile_paths.md)
  : Profile file locations ezrsurvey looks in
- [`get_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/get_order.md)
  : Get the levels of a registered order
- [`list_orders()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_orders.md)
  : List registered orders
- [`load_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/load_ezrsurvey_profile.md)
  : Load ezrsurvey defaults from a YAML profile
- [`order_for()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/order_for.md)
  : Find the order that applies to a variable
- [`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md)
  : Register a reusable ordinal level order
- [`register_order_presets()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order_presets.md)
  : Register a set of common ordinal scales
- [`remove_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/remove_order.md)
  : Remove a registered order
- [`reset_ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/reset_ezrsurvey_options.md)
  : Reset all ezrsurvey options to their built-in defaults
- [`save_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_ezrsurvey_profile.md)
  : Save current options and orders to a profile
- [`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md)
  : Set a default dataset for the session
- [`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md)
  : Create a starter ezrsurvey profile

## Datasets

- [`country_region`](https://mashud37.github.io/ezr-research/ezr-survey/reference/country_region.md)
  : Country to region lookup
- [`currency_rates`](https://mashud37.github.io/ezr-research/ezr-survey/reference/currency_rates.md)
  : Currency exchange-rate snapshot
- [`podracing_survey`](https://mashud37.github.io/ezr-research/ezr-survey/reference/podracing_survey.md)
  : Simulated pod-racing fan survey
- [`shopping_survey`](https://mashud37.github.io/ezr-research/ezr-survey/reference/shopping_survey.md)
  : Simulated historical shopping-behaviour survey
