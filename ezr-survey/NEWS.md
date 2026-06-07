# ezrsurvey 0.1.0

First release. A single-line-helper toolkit for everyday consumer-survey
analysis, aimed at research and insights professionals.

## Highlights

* **Import**: `read_folder()`, `select_prefix()`, `parse_filename()`.
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
* Bundled data: `consumer_survey`, `country_region`, `currency_rates`.
