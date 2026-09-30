# Changelog

## ezrsurvey 0.7.0

### A country column people typed themselves

Free-text country questions do not come back tidy. In one real open
salary survey of 26,232 people, nine thousand wrote “United States” and
eight thousand wrote “USA”; the bundled table matched the first and
missed the second, so
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md)
resolved 49% of the column.

- **[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
  [`recode_subregion()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md)
  and
  [`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md)**
  now fold the answer down before looking it up (case, punctuation,
  accents and a leading “the” are dropped) and then try a table of the
  spellings people actually use. It carries endonyms (`"Deutschland"`,
  `"Brasil"`, `"Espana"`), the constituent countries of the United
  Kingdom, and ISO 3166-1 alpha-2 and alpha-3 codes, so a column already
  coded to the standard needs no preparation. On that same survey the
  three functions now resolve 99.3%, and what remains are real typos
  worth seeing.
- A two-letter code that is also an ordinary English word is read as a
  country only when it was typed in capitals, so `"NO"` is Norway and
  `"no"` stays unmatched. Unambiguous codes match either way.
- **`country_region`** gains `iso2` and `iso3` columns, so a region
  breakdown can be reported against ISO 3166-1 rather than against
  country names. Every country carries both except Kosovo, which has no
  code of its own. Namibia’s alpha-2 code is the two letters `"NA"`,
  which is worth knowing before filtering on the column.
- Three countries in that table were misspelled and so could never match
  an answer: `"Ise of Man"`, `"America Samoa"` and `"Kazakstan"`.
  Bermuda was missing altogether. All four are fixed, and the duplicate
  rows the corrections exposed are gone, which takes the table from 182
  rows to 180.

### Decision bands on a scale that is not 1 to 5

Satisfaction is often collected on 0 to 100, and seven-point agreement
scales are common. The band presets are written on 1-5, 0-10 and
-100..100, so until now a chart on any other scale meant dividing the
data to meet the thresholds, which left the axis showing a scale nobody
had been asked about.

- **[`rescale_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rescale_bands.md)**
  stretches any band specification onto the scale the chart actually
  uses: `bands_rating_3() %>% rescale_bands(to = c(0, 100))`. The
  mapping is proportional, and labels and colours are untouched. It
  works on a hand-built band data frame as well as on the presets.

### A registered answer order now reaches the table

[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md)
set the levels of the answer column and stopped there. The levels are
what a chart reads, so charts were right; a table printed to the console
or written to CSV carries no levels with it, so every number anybody
actually read came back in alphabetical order. On a recency scale that
puts “In the past month” above “In the past week”.

- **[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)**
  sorts its rows into the registered order. A `by =` breakdown keeps its
  groups together and orders within each one.
- **[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)**
  does the same on both margins. Column order was affected too, because
  tidyr names new columns in order of first appearance rather than by
  factor level.
- A margin with no registered order keeps the order it already had, so
  putting the rows right does not scramble the columns.

### Charts that were drawn on the wrong axis

- **[`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md)**
  pinned its performance axis to 1-5 whatever bands it was given. A
  study rated on 0-100 or on a seven-point scale came back as an empty
  panel with the bands still drawn across it, and ggplot2’s only
  complaint was that some rows had been removed. The axis now runs over
  whatever scale the bands describe, and a feature that really does fall
  outside them is named in a message rather than dropped in silence.

### Countries the lookup could never reach

Three separate faults kept
[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md)
from matching countries that were spelled perfectly. On the Stack
Overflow Developer Survey, whose country column is coded to ISO 3166-1,
3,126 of 87,973 answers came back `NA`. They now resolve to 99.93%, and
the only thing left unmatched is the answer “Nomadic”.

- **The two sides of the lookup were folded differently.** The answer
  had its punctuation stripped and its accents transliterated; the table
  was only lower-cased. Every country whose name carries a hyphen, an
  apostrophe, a comma or brackets was therefore unreachable however it
  was typed: `"Timor-Leste"`, `"Guinea-Bissau"`, `"Cote d'Ivoire"`,
  `"Korea, North"`, `"Gambia, The"` and some thirty more.
- **`country_region` held 180 of the 249 entries in ISO 3166-1.** What
  was missing was not obscure: Ghana, Ethiopia, Senegal, Rwanda, Yemen,
  Benin, Botswana, Haiti, Mali, Sierra Leone and South Sudan all
  returned `NA`. The table is now complete at 255 rows, grouped the way
  the package groups countries rather than the way the UN does, so no
  answer already built on it changes.
- **The official ISO names did not match.** `"Viet Nam"`,
  `"Syrian Arab Republic"`, `"Lao People's Democratic Republic"`,
  `"Brunei Darussalam"`, `"Cabo Verde"`, `"Eswatini"`,
  `"North Macedonia"` and the rest are what a questionnaire built on the
  standard shows a respondent. They match now, in ISO’s inverted order
  (`"Moldova, Republic of"`) and in the order the name is actually said
  (`"Republic of Moldova"`).

### A country column folded the same way on every machine

- **[`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md),
  [`recode_subregion()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md)
  and
  [`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md)**
  spelled a German sharp s, a Nordic slashed o and five other letters
  out by hand before transliterating. Windows renders those as a
  question mark where Linux writes the two-letter form, so a German
  respondent’s spelling of Great Britain matched on a CI runner and
  missed on the analyst’s laptop.
- The endonyms of the two most answered countries were missing while
  smaller countries had theirs: `"Estados Unidos"`, `"Etats-Unis"`,
  `"Vereinigte Staaten"`, `"Stati Uniti"`, `"Reino Unido"` and
  `"Royaume-Uni"` now match.

### Brand fonts and the device that has to draw them

- **[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)**
  says so when it sets a typeface in a session whose default device is
  `pdf`, which is what a plain `Rscript` run gets. That device carries
  its own short list of font families and fails at drawing time with
  “invalid font type” rather than substituting. Charts written with
  [`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md)
  were never affected.

### Errors that name what went wrong

- A **mistyped column name** now says which name failed and offers the
  nearest one the data has. `calc_percentage(d, gendr)` reported
  `replacement has 0 rows, data has 3`, which describes an assignment
  the caller never made; it now says
  `` Column `gendr` not found in the data. Did you mean `gender`? ``.
  The same applies to
  [`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md),
  [`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md),
  [`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md),
  [`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md)
  and
  [`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md).
- **[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md)**
  works on a frame filtered down to no rows instead of failing with
  `replacement has 1 row, data has 0`. Filtering to a segment nobody
  fell into is ordinary, and the answer is a zero count, not an error.
- **[`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)**
  refuses a frame with no rows in a sentence that says a filter is the
  usual cause, rather than reporting the same internal mismatch.
- **[`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md)**
  names the argument the caller actually omitted. Leaving out `level`
  reported a missing `level_sym`, which is not an argument it has.
- **[`plot_rating_grid()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_rating_grid.md)**
  reports two answers that land on the same rank.
  [`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md)
  falls back to matching on a substring, and “Neither agree nor
  disagree” contains “disagree”, so a five-point scale handed only four
  levels drew two segments both numbered 2. The chart looked plausible
  and was wrong; now it says which level is missing.
- **[`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md)**
  says which column it cannot find. Its defaults are the `comment` and
  `length` columns
  [`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md)
  produces, and handed anything else it failed at drawing time with a
  ggplot error about an object of type `<function>`, because `length`
  had resolved to the base function.

### Reading an export that has a second header row

- **[`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md)**
  notices when the first row of a file is question wording rather than
  an answer, which is how survey platforms export the question text, and
  says so. Read as data it becomes respondent number one and shifts
  every count by one. The new `question_row` argument drops that row
  from every file (`TRUE`), keeps it silently (`FALSE`), or keeps it and
  warns (`NULL`, the default).

### Smaller fixes

- **[`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md)**
  reports answers that held no number at all. `"young"` and
  `"prefer not to say"` became `NA` in silence, which made a column that
  was never numeric look like a column of missing ages. New `quiet`
  argument.
- The package has a **logo**. `README.md` had pointed at
  `man/figures/logo.png` since the first release without that file ever
  existing, so the front page of the README and of the documentation
  site both opened with a broken image.
- The bundled PowerPoint templates are **built from a blank presentation
  of the project’s own**, not from another package’s file.
- The documentation no longer describes the package in terms of the work
  it was extracted from. Nineteen references to “the original reports”,
  “the original survey charts” and similar reached sixteen shipped help
  pages, and one named a theme function that was never part of this
  package.

### Multi-select questions packed into one cell

Google Forms and most spreadsheet exports put every answer a respondent
ticked into a single cell, joined by a delimiter. That shape could not
be counted before, because a respondent who ticked three options is one
row, not three.

- **[`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)**
  now detects a packed column and unpacks it. When the prefix matches
  exactly one column and a `";"`, `"|"` or `","` is found inside it, the
  answers are separated and the answer text becomes the option label.
  `split = ","` forces a delimiter and `split = FALSE` turns the
  detection off. A block of one-column-per-option behaves exactly as
  before.
- **[`split_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/split_multi.md)**
  is the new recode helper for the same shape, widening a packed column
  into one column per answer so that
  [`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md),
  the plots and everything else can use it too.

### `calc_nps()` shows how the score was reached

- The result gains `pct_detractors`, `pct_passives` and `pct_promoters`,
  with the counts behind them in `detractors`, `passives` and
  `promoters`. A single NPS hides its own composition: +20 from 40%
  promoters and 20% detractors is a different picture from +20 with 25%
  and 5%. Counts are unweighted; the shares follow `nps` and so are
  weighted when a scheme is active.

### `calc_importance()` offers a second and third opinion

- New **`method`** argument. `"rwa"` (relative weights analysis) remains
  the default and is unchanged. `"forest"` adds random-forest
  permutation importance, which sees non-linear effects and interactions
  that relative weights cannot, so a feature ranking high there and low
  under `"rwa"` is a signal worth chasing. `"correlation"` needs no
  suggested package at all.
- All three are rescaled to sum to 100 and returned strongest driver
  first, so they are directly comparable and any of them can be fed to
  [`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md).
  `ipm_model(method = )` passes the choice through.

### `plot_gauges()` says what its bars are measuring

- Each bar now prints its own band boundaries underneath, so a Net
  Promoter bar reads `-100 0 30 70 100` and a quality bar reads
  `1 3 4 5`. The bars share one panel but not one scale, so no axis
  could serve them both and they carried no scale at all: a marker two
  thirds along the bar said nothing about the score it marked.
- A band name too wide for its band is now left out instead of being
  drawn over its neighbours or cut off at the edge of the panel.
  `"EXCELLENT"` in the 30-point band at the top of the NPS scale was
  printed as `"EXCELLEN"`.

### Smaller changes

- **`se_prop(pctp = TRUE)`** returns the standard error in percentage
  points, the form report footnotes use, instead of leaving you to
  multiply by 100.
- The promoter callout in
  [`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md)
  is centred over the promoter bars, like the detractor and passive
  callouts beside it. It had been pinned to the right edge of the panel,
  which left `"Very likely"` hanging off to one side of the
  `"% PROMOTER"` line above it.
- Help pages no longer print every example’s output twice. The examples
  carried a hand-written copy of their own results, which the website
  then rendered alongside the real thing.
- Every plot function’s examples now draw their chart on the reference
  page, rather than most of them assigning the plot to a variable and
  showing nothing.
- The relative-standard-error bands in
  [`rse_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse_rating.md)
  now say exactly what the Australian Bureau of Statistics does and
  where ezrsurvey departs from it.

## ezrsurvey 0.6.0

### Attaching the package attaches seven packages, not the whole tidyverse

- [`library(ezrsurvey)`](https://mashud37.github.io/ezr-research/ezr-survey)
  still puts dplyr, ggplot2, tidyr, tibble, readr, stringr and purrr on
  your search path, so nothing changes in a script. The package now
  names those seven in `Depends` rather than depending on the
  `tidyverse` meta-package, which had tied it to every package in that
  tree.

### Checkpoints clean up after themselves

- `crosstab_banner(checkpoint = TRUE)` now **deletes its checkpoint once
  the table is built**. A finished run has nothing left to resume from,
  so the file it kept under
  [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html) is
  removed instead of accumulating.
- **[`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md)**
  empties that folder, for runs that were interrupted and never
  repeated.
- A checkpoint path you chose yourself (`checkpoint = "my-run.rds"`) is
  your file: it is left exactly where it is, and
  [`clear_checkpoints()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_checkpoints.md)
  never touches it.

### The outputs folder now says where it put things

- The first save of a session that redirects a bare file name prints the
  folder it used, once, so nothing goes missing in a working directory
  that does not contain it.
- **[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)**
  now follows the same rule as every other writer: a bare name lands in
  `ezrsurvey-outputs/`, so the `.qmd` sits where its rendered output
  will. Pass a path naming a directory to put it somewhere else.

### Rating scales: a fix that can move existing numbers

- **[`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md)**
  now tries the longest answer wording first. A scale whose levels nest
  inside one another (“Good” inside “Very good”, “Likeable” inside “Very
  likeable”) previously resolved any answer the exact pass missed to the
  **shorter** level, so an answer carrying an emoji or a stray character
  was quietly downgraded. If your data has such a scale and any untidy
  answers, ratings, feature averages and
  [`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)
  performance scores will change, and the new numbers are the correct
  ones. Supplied `synonyms` follow the same longest-first rule.
- **[`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md)**
  reports values that fell outside `breaks` instead of turning them into
  `NA` in silence, and takes `quiet = TRUE` to suppress that. A closed
  top band under an open-ended label (`35` to `40.5` labelled “35 to
  40+”) silently drops everyone above it; `Inf` is what that label
  means.
- A registered order that does not list an answer now names the answers
  that became `NA` rather than letting them appear as an unlabelled bar.

### Progress on the slow helpers

- The helpers that can run for minutes –
  [`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md),
  [`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md),
  [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md),
  [`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md),
  [`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md)
  – now report the question, file or slide they are on, with a measured
  estimate of the time remaining. A full every-variable banner is one
  cross-tab per question per grouping variable, so it takes minutes on a
  wide survey and used to give no sign of life at all.
- New **`progress`** option (`ezrsurvey_options(progress = )`): `"auto"`
  (default) reports in an interactive session and stays silent in
  scripts, vignettes and `R CMD check`; `TRUE` / `FALSE` force it either
  way.

### Every output lands in one folder

- A **bare output file name now goes into `ezrsurvey-outputs/`**,
  created on demand: `save_plot(p, "nps.png")` writes
  `ezrsurvey-outputs/nps.png`, and the same holds for
  [`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md),
  [`save_output()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_output.md),
  [`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md),
  [`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md),
  [`report_save()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_save.md)
  and
  [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md).
  Previously only the `path = NULL` default used that folder, so any
  script that named its files scattered them through the working
  directory.
- A path that **names a directory** is written exactly as given, which
  is how you override it: `"./nps.png"` for the working directory,
  `"charts/nps.png"` for a folder of your own, or any absolute path (so
  [`tempfile()`](https://rdrr.io/r/base/tempfile.html) is unaffected).
- New **`output_dir`** option (default `"ezrsurvey-outputs"`) renames
  that folder for a project, or set it to `"."` to put bare names back
  in the working directory.

### Confirming an automatic variable selection

- [`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)
  and
  [`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md)
  choose their own variables when none are named, and that choice
  decides everything they produce. Both now print the questions kept,
  the grouping variables and the columns skipped, and wait for a yes
  before a run that takes minutes. Naming `rows` / `cols` (or the
  variables to summarise) is your own choice and is never questioned.
- New **`confirm`** option and argument: `"auto"` (default) asks in an
  interactive session and never asks in a script, so an unattended run
  cannot stall on a prompt; `TRUE` / `FALSE` force it either way.
  Answering no computes nothing and returns `NULL`.

### Resuming an interrupted table

- **`crosstab_banner(checkpoint = )`** saves each question as it
  finishes, so re-running the identical call after a crash or an
  interrupt continues instead of starting over. A checkpoint written
  from different data or different arguments is reported and discarded,
  never blended into the new run. Use `TRUE` to have the file managed
  under [`tools::R_user_dir()`](https://rdrr.io/r/tools/userdir.html),
  or name a path to choose the location. Nothing is written unless you
  ask.
- Weights are computed **once per dataset and scheme** and reused,
  instead of re-running the raking loop inside every cell of a banner
  table.
  [`clear_weights_cache()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_weights_cache.md)
  empties the cache;
  [`clear_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md)
  does it too.
- **`sample_comments_diverse(max_candidates = )`** narrows a large
  corpus to a random shortlist (default 500) before comparing every
  comment with every other, which is what made it slow and memory-hungry
  on a big survey.

### New

- **[`plot_rating_grid()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_rating_grid.md)**
  builds a stacked rating chart for a whole block of prefix-sharing
  columns in one call: tabulate, tidy the question names, number the
  answers by their place on the scale, stack. It replaces an eight-line
  block per question block, and it *reports* answers that are not on the
  scale instead of leaving them as an unranked segment.
- **[`clean_label()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clean_label.md)**
  is now exported. It is the tidying
  [`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)
  and
  [`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md)
  already applied to their own output, so a hand-built table can be made
  to match them: labels that disagree will not join, which is what
  silently empties a comparison chart.
- **`calc_percentage_batch(clean_names = , prefix = )`** applies that
  same tidying to its `variable` column.
- **[`bands_nps_score()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md)**
  exposes the Net Promoter Score band set (needs work / good / great /
  excellent over -100..100) that was previously locked inside
  [`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md).
  Note
  [`bands_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md)
  is the 0-10 *answer* scale and is a different thing.
- The band presets take **`from` / `to`** to trim themselves to the part
  of the scale a chart actually shows, e.g. `bands_rating_3(from = 2)`
  on a 2-5 panel.
- **`report_new(keep_slides = FALSE)`** starts from an empty deck,
  dropping any boilerplate slides the template carries.
- **`sample_comments(by = )`** samples `n` comments per group and keeps
  the group as a column, replacing a hand-rolled loop over the groups.

## ezrsurvey 0.5.0

### AI summaries move to ezrintelligence

- The language-model helpers are **removed** from ezrsurvey and now live
  in the companion `ezrintelligence` package: `ai_chat()`,
  `ai_summarise()`, `ai_report_sections()`, `ai_context()`, the
  prompt-template registry (`list_prompts()`, `get_prompt()`,
  `register_prompt()`) and key management (`set_llm_key()`,
  `get_llm_key()`, `has_llm_key()`, `delete_llm_key()`,
  `list_llm_keys()`). Install it alongside ezrsurvey and pass it any
  summary table ezrsurvey produces. `ellmer` and `keyring` are no longer
  suggested dependencies.
- **[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)**
  loses its `ai`, `ai_titles`, `chat`, `provider`, `model` and `context`
  arguments. For AI slide text, call `ezrintelligence::ai_slide_text()`
  on the table behind a slide and place the title and bullets it returns
  yourself.
- The Quarto scaffolds and the worked example lose their `ai` parameter
  and the eval-gated AI chunks; they render with placeholder narrative
  and their `data` parameter as before.

### Fixes

- **[`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md)**
  no longer fails with “Failed to save workbook” when `R_ZIPCMD` names a
  zip tool that is not installed. openxlsx2 reaches for an external zip
  whenever that variable is set, and R sets it to a bare `zip` on
  Windows under `R CMD` whether or not a `zip.exe` exists; the workbook
  is now written with openxlsx2’s own zipping code whenever the named
  tool cannot be found.
- The
  [`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)
  example that crosses every variable against every other moves to
  `\donttest`, where its runtime belongs. \# ezrsurvey 0.4.0

### Cross-tabs and summary workbooks

- **[`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md)**
  builds the market-research banner table: a stack of question variables
  down the side (`rows`) and one or more grouping variables across the
  top (`cols`), plus a whole-sample **Overall** column. Categorical
  questions become column-percentage blocks (each column sums to ~100
  within a block); numeric questions turn into a mean/median/sd/quartile
  block automatically. `cell = "diff"` shows each cell’s distance from
  the Overall column, `long = TRUE` returns the tidy form, and
  `flextable = TRUE` renders the two-row spanning header for a slide or
  Word report. It generalises
  [`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)
  from a single pair to a whole table. **Pass only the data frame** to
  cross every variable against every variable; identifier and free-text
  columns are skipped, and check-all-that-apply blocks
  (e.g. `motivations_*`) are folded into a single multi-select stub
  question with the correct question-level base.
- **[`export_summary_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_summary_xlsx.md)**
  writes a tabbed Excel workbook with one worksheet per question, each
  holding that question’s summary table and its chart (percentages and a
  bar chart for categorical questions, a
  [`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md)
  table and a histogram for numeric ones, a
  [`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)
  table for a check-all-that-apply block). **Called with just the data
  frame** it writes every question at once, one multi-select block to a
  single sheet, skipping identifier and free-text columns. The Excel
  counterpart of the slide/Word
  [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md).
  Needs the suggested `openxlsx2` package.

### Output location

- The auto-output folder is now **`ezrsurvey-outputs/`** (was
  `outputs/`).
  [`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md),
  [`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md),
  [`save_output()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_output.md),
  [`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md),
  [`report_save()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_save.md)
  and
  [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
  write straight into it with no per-type subfolders when no `path` is
  given; explicit paths behave as before.

### Working without repeating the data

- **The tidyverse metapackage is now attached with ezrsurvey.**
  [`library(ezrsurvey)`](https://mashud37.github.io/ezr-research/ezr-survey)
  brings `dplyr`, `ggplot2`, `tidyr`, `stringr` and the rest with it, so
  scripts and reports never need to load the packages ezrsurvey wraps.
- **[`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md)
  finally saves the typing it promised.** With a default set, columns
  can be passed positionally with no `data` and no `column =`:
  `calc_percentage(demo_gender)`, `calc_nps(nps_value)`,
  `crosstab(demo_gender, region)`, `diagnose(starts_with("ratings_"))`.
  The helpers tell a data frame from a column by looking at the first
  argument, so an explicit data frame or a pipe still wins. Previously
  only the much longer `calc_percentage(column = demo_gender)` worked,
  which saved nothing over just passing the data.

### Charts

- **[`plot_gauges()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_gauges.md)**
  draws several scores as thin banded gauge bars stacked one above
  another – the summary-slide staple of the Net Promoter Score over the
  average feature quality rating, each on its own scale with a marker,
  instead of one fat single bar.
  [`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md)
  remains for a single score.

### Colour correctness

- **Rating colours now agree with the decision bands.** A feature
  averaging 2.4 is inside the red BAD band (1-3) but was drawn amber,
  because the point colour came from a rounded 1-5 code while the band
  behind it came from
  [`bands_rating_3()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/band_presets.md).
  \[plot_ipm()\] now colours every point by the band it actually falls
  in, and `pal_rating` uses the same thresholds (1-2 bad, 3 ok, 4-5
  good).
  [`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md)
  gains a `bands` argument.

### Organisation branding

- **[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)**
  adopts an organisation brand from a `.pptx` / `.docx` template: theme
  accent colours and typefaces are extracted from the file’s OOXML theme
  and become the session defaults
  ([`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md)
  fill,
  [`theme_ezrsurvey()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md)
  font when installed locally), and the template is registered as the
  default reference document for
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
  [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
  and
  [`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md).
  Colours/fonts can also be set directly
  (`use_brand(colors =, fonts =)`) or persisted in the YAML profile
  (`brand_*` options).
  [`brand_info()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/brand_info.md)
  shows and
  [`clear_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_brand.md)
  resets the active brand.
- **[`pal_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/pal_brand.md)**
  and
  **[`scale_fill_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md)**
  /
  [`scale_colour_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md)
  expose the brand accents to any plot; semantic palettes (`pal_rating`,
  `pal_nps`) deliberately keep their red-amber-green meaning.

### Reporting

- **One line per slide.** New wrappers collapse `calc -> plot -> add`
  onto a single pipe step so a deck script reads as one line per slide:
  `report_slide(title, content)` starts a titled slide and places its
  content (a ggplot becomes a chart, a data frame a table, a character
  vector a bullet list); `report_section("DEMOGRAPHICS")` drops a
  single-word divider; and `report_title_slide(title, subtitle)` opens
  the deck. The rewritten
  [`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md)
  deck is built this way as a full agency read-out – cover, chaptered
  sections and every question block in the questionnaire
  (recommendation, the six experience ratings and their drivers,
  motivations, the three sponsor brands, the whole respondent profile,
  favourite drivers, open-text comments and a methods appendix) – with
  each slide title the survey question it answers.

- **Slide tables fill the slide.**
  [`report_add_table()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_add_table.md)
  now styles the table (banded header, centred cells, a readable 12pt
  font) and widens its columns to span the content placeholder, so a
  summary table fills the slide instead of sitting tiny in a corner.

- **Headlines and bullets no longer overflow.** The bundled templates
  bring the master title/body font sizes down to deck-appropriate values
  and give every text placeholder shrink-to-fit, so a descriptive
  question headline or a long bullet list is scaled to its box rather
  than spilling out of it.

- **Decks are 16:9 by default, and properly designed.** Without a brand
  template,
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
  [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
  and the Quarto pptx scaffold use a built-in widescreen template with a
  coherent navy/gold identity in place of the dated default Office
  colours: a full-bleed navy cover with a large left-aligned title, gold
  accent rule and a subtitle strapline; full-bleed navy section dividers
  carrying a single large section word; and content slides with a navy
  24pt title over one slim rule (no stray hairlines) and a live slide
  number in the corner.
  [`report_title_slide()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_title_slide.md)
  gains a `subtitle` argument for the cover strapline. Pass
  `style = "plain"` for the same palette with no decoration, or
  `slide_numbers = FALSE` to drop the numbering. Both templates keep the
  standard PowerPoint layout names (plus “Content with Caption”), so
  Quarto renders against either without falling back to Pandoc’s own
  template.

- **Bars are a constant thickness across charts.**
  [`geom_col()`](https://ggplot2.tidyverse.org/reference/geom_bar.html)
  widths are a fraction of a category slot, so a three-answer chart used
  to draw bars over twice as thick as a ten-answer one and a deck looked
  incoherent as you flicked through it. \[plot_bars()\] now scales the
  fraction with the bar count so the drawn thickness is the same
  everywhere (`bar_width` / `bar_ref_items`, see
  [`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)).

- **[`example_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/example_report.md)**
  copies a complete worked report into your project: a full narrative
  report over the bundled `podracing_survey` and the matching deck
  script. Both are written the way a real readout is – a story that runs
  headline, then cause, then segment, then evidence; slide titles that
  state the finding rather than name the chart; and every figure in the
  prose computed from the data rather than typed in, so the narrative
  cannot drift.

- The officer builders now work with **any corporate template**: slide
  layouts are chosen by inspecting placeholder types (not
  locale-dependent layout names), slide titles are skipped with a
  warning when a layout has none, and plots/tables are rendered at the
  exact size of the content placeholder with sensible fallbacks.
  **[`report_layouts()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_layouts.md)**
  lists what a template offers.

- **`report_deck(ai = TRUE)`** drafts 3-4 takeaway bullets per slide
  (and, with `ai_titles = TRUE`, headline titles) from the data behind
  each item, reusing one chat across the deck; bullets land in a
  two-content layout when the template has one, else in the speaker
  notes. AI failures degrade to plain slides.

- **Quarto scaffolds rewritten** as four distinct report skeletons (pptx
  / html / docx / pdf) with `data` and `ai` parameters, placeholder
  narrative, executive summary and a precision appendix;
  [`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md)
  gains `author` and `reference_doc` (defaulting to the brand template).

- README documents the **Google Slides workflow**: build the branded
  `.pptx` and import it (File \> Import slides); what survives and what
  to watch.

### AI summaries

- All prompt templates rewritten to an analyst standard (quote only
  present figures, respect margins of error, name base sizes) and five
  added: `slide_bullets`, `thematic_analysis`, `segment_comparison`,
  `methodology` and `full_report`.
- **`ai_context()`** bundles sample size, question wording, base,
  fieldwork and precision notes (auto-derived from the raw survey) into
  every prompt via the new `context` argument of `ai_summarise()` /
  `ai_report_sections()` /
  [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md).
- Tables are now sent to the model as markdown pipe tables;
  `register_prompt()` gains an `output_contract` field pinning the
  answer’s format; `ai_report_sections()` gains `chat` for connection
  reuse.

## ezrsurvey 0.3.1

### Output location

- All savers now default to a project-local **`outputs/`** folder in the
  working directory instead of requiring a path:
  [`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md)
  (`outputs/plot.png`),
  [`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md)
  (`outputs/data.csv`),
  [`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md)
  (`outputs/tables.xlsx`),
  [`report_save()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_save.md)
  /
  [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
  (`outputs/report.pptx` / `.docx`). Missing directories are created;
  explicit paths behave as before.

### Annotation layer

- **[`annotate_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/annotate_bands.md)**
  band labels no longer sit on top of the marker line: `label_offset`
  defaults to 4% of the opposite-axis range and labels are justified
  into the panel, so nothing clips at the panel edge. `text_size` now
  defaults to the theme’s base font size (11 pt) instead of a fixed geom
  size, and multi-line band labels get a tighter line height.
- **[`mark_value()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/mark_value.md)**
  labels are justified inside the panel next to the marker line instead
  of being half-clipped at the `Inf` edge.
- **[`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md)**
  detractor/passive/promoter callouts no longer clip at the panel top or
  overlap each other; the promoter callout right-aligns to the panel
  edge.
- **[`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md)**
  gains a `label_size` argument; band labels default to the theme’s base
  font size.

### Reproducibility

- **[`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md)**
  gains a `seed` argument (matching
  [`sample_comments_diverse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments_diverse.md)),
  so quote selections can be reproduced; the RNG state is restored
  afterwards.
- `calc_percentage(long = TRUE)` no longer triggers the deprecated
  tidyselect external-vector warning.

## ezrsurvey 0.3.0

### Smarter charts and cleaner questions

- **[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md)
  now lays itself out.** `orientation = "auto"` (the default) draws
  vertical columns for a few short labels and horizontal bars for many
  or long ones, wraps long labels with
  [`str_wrap()`](https://stringr.tidyverse.org/reference/str_wrap.html),
  steps the data-label size down as bars multiply, and orders bars so
  the longest sits at the top (bars) or on the left (cols). An
  intentional ordinal scale (an ordered factor from a registered order)
  keeps its order. `orientation` / `sort` / `wrap` / `label_size` and
  the new `bar_*` options (see
  [`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md))
  override the automatics; the old `flip` argument still works.
- **[`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md)**
  plus a **`drop =`** argument on
  [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
  [`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
  [`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md)
  and
  [`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)
  remove unwanted answers (e.g. `"Other"`, `"Don't know"`) before
  counting, so the kept answers re-base to ~100%. Set a session default
  with `ezrsurvey_options(drop_answers = ...)`.

### Data

- The bundled example survey is now **`podracing_survey`** (renamed from
  `consumer_survey`): a Star Wars pod-racing fan survey with
  international-standard demographics (ISO/IEC 5218 sex, ISCED
  education, ILO labour-force status, ISIC sectors, ISO 3166 countries)
  and diverse, entity-rich open-text comments for the text / NER
  helpers.
- New **`shopping_survey`**: a turn-of-the-century (Edwardian)
  shopping-behaviour survey – a second, very different theme for
  examples.
- [`register_order_presets()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order_presets.md)
  now ships an `education_isced` order (was `education_us`).

## ezrsurvey 0.2.0

### Survey weighting

- **[`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)**
  defines a post-stratification / raking scheme from target shares,
  e.g. `set_weights(c(variable = "demo_gender", Male = 0.49, Female = 0.50, "Non-binary" = 0.01))`,
  and multiple variables at once. With one variable it is exact
  post-stratification; with several it rakes (iterative proportional
  fitting) so every margin matches.
- Once set, the summary helpers weight automatically:
  **[`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)**
  (and
  [`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md))
  gain a `wpct` column beside `n`/`pct`, while
  **[`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md)**,
  **[`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md)**
  and
  **[`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md)**
  default to weighted values. Pass `weights = FALSE` to any of them to
  opt out, or `weights = <spec>` to weight a single call ad hoc.
- [`clear_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md),
  [`get_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md),
  [`has_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weights_scheme.md)
  manage the scheme;
  [`weight_vector()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/weight_vector.md)
  returns the per-respondent weights (and
  [`set_weights()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/set_weights.md)
  reports the Kish design effect and effective sample size).

## ezrsurvey 0.1.0

First release. A single-line-helper toolkit for everyday consumer-survey
analysis, aimed at research and insights professionals.

### Highlights

- **Import**:
  [`read_folder()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/read_folder.md),
  [`select_prefix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_prefix.md),
  [`select_suffix()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/select_suffix.md),
  [`parse_filename()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/parse_filename.md).
- **Recode / clean**:
  [`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md),
  [`ensure_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ensure_numeric.md),
  [`bin_numeric()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/bin_numeric.md),
  [`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md),
  [`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md),
  [`recode_likert()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_likert.md),
  [`nps_group()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nps_group.md),
  [`recode_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_region.md)
  /
  [`add_region()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_region.md).
- **Summarise**:
  [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md),
  [`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md),
  [`calc_percentage_batch()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_batch.md),
  [`calc_summary()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_summary.md),
  [`crosstab()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab.md).
- **Model**:
  [`calc_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_nps.md),
  [`calc_importance()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_importance.md),
  [`ipm_model()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ipm_model.md).
- **Compare**:
  [`compare_values()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/compare_values.md),
  [`plot_diff()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_diff.md).
- **Diagnostics**:
  [`se_mean()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_mean.md),
  [`se_prop()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/se_prop.md),
  [`rse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/rse.md),
  [`margin_of_error()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/margin_of_error.md),
  [`diagnose()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/diagnose.md).
- **Comments**:
  [`sample_comments()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments.md),
  [`sample_comments_diverse()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/sample_comments_diverse.md).
- **Currency**:
  [`convert_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/convert_currency.md),
  [`add_currency()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/add_currency.md),
  [`list_currencies()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_currencies.md).
- **Plot**:
  [`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md),
  [`plot_stacked_rating()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_stacked_rating.md),
  [`plot_nps()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps.md),
  [`plot_nps_gauge()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_nps_gauge.md),
  [`plot_ipm()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_ipm.md),
  [`plot_quotes_tree()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_quotes_tree.md),
  with the `theme_ezrsurvey*()` family, semantic palettes and
  [`annotate_bands()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/annotate_bands.md).
- **Save / report**:
  [`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md),
  [`save_data()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_data.md),
  [`save_output()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_output.md),
  [`export_xlsx()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/export_xlsx.md),
  the `report_*()` officer builders and
  [`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md).
- **AI summaries**: `ai_chat()`, `ai_summarise()`,
  `ai_report_sections()` with keyring-backed key management and a
  prompt-template registry.
- **Configuration**:
  [`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md),
  reusable level orders
  ([`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md)),
  YAML profiles
  ([`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md)).
- Bundled data: `podracing_survey`, `country_region`, `currency_rates`.
