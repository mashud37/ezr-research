# Get or set ezrsurvey defaults

ezrsurvey reads a handful of defaults from R options (prefixed
`ezrsurvey.`), so you can tune behaviour once instead of repeating
arguments. Call with no arguments to see the current effective values;
call with `name = value` pairs to set them for the session. Persist them
across sessions with a YAML profile (see
[`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md)).

## Usage

``` r
ezrsurvey_options(...)
```

## Arguments

- ...:

  Either nothing (to read all values) or named `option = value` pairs to
  set.

## Value

When reading, a named list of all current values. When setting, the
previous values, invisibly.

## Details

Recognised options:

- `pct_axis_unit`:

  Rounding step for percentage y-axes (default `25`).

- `pct_axis_max`:

  Fixed percentage y-axis maximum, e.g. `100`; `NULL` (default) means
  dynamic via
  [`nice_max()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/nice_max.md).

- `bar_cols_max_items`, `bar_cols_max_label`:

  Thresholds that switch
  [`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md)
  (`orientation = "auto"`) from vertical columns to horizontal bars:
  more than `bar_cols_max_items` bars (`6`) or any label longer than
  `bar_cols_max_label` characters (`12`).

- `bar_wrap_cols`, `bar_wrap_bars`:

  [`stringr::str_wrap()`](https://stringr.tidyverse.org/reference/str_wrap.html)
  widths used by
  [`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md)
  for column (`12`) and bar (`28`) labels.

- `bar_label_size`, `bar_size_step`, `bar_size_min`:

  Data-label text sizing in
  [`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md):
  base size (`3.5`), reduction per item past the item threshold (`0.15`)
  and the floor (`2.4`).

- `bar_width`, `bar_ref_items`:

  Bar thickness. Bars are drawn at `bar_width` (`0.66`) of a category
  slot when a chart has `bar_ref_items` (`6`) bars, and the fraction
  scales with the bar count so the *drawn* thickness stays the same on
  every chart. Raise `bar_ref_items` for thinner bars throughout, lower
  it for chunkier ones.

- `age_breaks`, `age_labels`:

  Default bands used by
  [`recode_age()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_age.md).

- `na_answers`:

  Strings treated as non-answers by
  [`na_blank()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/na_blank.md).

- `drop_answers`:

  Answer values dropped by the `drop =` argument of
  [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
  and friends when `drop` is not given; `NULL` (default) means drop
  nothing. See
  [`drop_items()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/drop_items.md).

- `generation_scheme`:

  Default scheme for
  [`recode_generation()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/recode_generation.md).

- `current_year`:

  Reference year for age-to-cohort conversion; `NULL` uses the system
  year.

- `default_by`:

  Default grouping column name(s) applied by
  [`calc_percentage()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage.md)
  /
  [`calc_percentage_multi()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/calc_percentage_multi.md)
  when `by` is omitted; `NULL` (default) means no default grouping.

- `brand_colors`, `brand_color_primary`:

  Organisation brand colours: a vector of accent hexes and the primary
  accent used as the default single-series fill. Usually set by
  [`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md),
  but can be set by hand or in a profile. `NULL` (default) keeps the
  neutral ezrsurvey look.

- `brand_font_major`, `brand_font_minor`:

  Brand heading and body typefaces. `brand_font_minor` becomes the
  default `base_family` of
  [`theme_ezrsurvey()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md)
  when the font is installed on this machine.

- `brand_fonts_enabled`:

  Set `FALSE` to keep brand colours but ignore brand fonts (default
  `TRUE`).

- `brand_template_pptx`, `brand_template_docx`:

  Paths to the brand PowerPoint / Word template used as the default
  reference document by
  [`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
  [`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
  and
  [`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md).
  These are machine-specific absolute paths – if you persist them,
  prefer the project-level `.ezrsurvey.yml` profile over the user-level
  one.

- `progress`:

  Whether the slow helpers report which item they are on. `"auto"`
  (default) reports in an interactive session and stays silent in
  scripts, vignettes and `R CMD check`; `TRUE` or `FALSE` force it
  either way. See
  [`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md).

- `confirm`:

  Whether a call that picks its own variables shows the selection and
  waits for a yes before a long run. `"auto"` (default) asks in an
  interactive session and never asks in a script; `TRUE` or `FALSE`
  force it either way. See
  [`crosstab_banner()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/crosstab_banner.md).

- `output_dir`:

  Folder that a bare output file name lands in, created on demand
  (default `"ezrsurvey-outputs"`, relative to the working directory).
  `save_plot("chart.png")` writes `ezrsurvey-outputs/chart.png`, so a
  script's results collect in one place. A path that names a directory
  (`"./chart.png"`, `"charts/chart.png"`, anything absolute) is written
  exactly where it says. Set to `"."` to put bare names back in the
  working directory.

Options are ordinary R options under the `ezrsurvey.` prefix, so
anything you can do with
[`options()`](https://rdrr.io/r/base/options.html) works here too, and a
setting lasts for the session. Reading (`ezrsurvey_options()` with no
arguments) returns every recognised option's current effective value;
setting returns the previous values invisibly, so you can restore them.
To make settings permanent, write them to a YAML profile – edit it with
[`edit_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/edit_ezrsurvey_profile.md)
or dump the current session with
[`save_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_ezrsurvey_profile.md)
– which is loaded automatically at package start-up.

## See also

[`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md),
[`load_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/load_ezrsurvey_profile.md),
[`reset_ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/reset_ezrsurvey_options.md).

Other config:
[`apply_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/apply_order.md),
[`edit_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/edit_ezrsurvey_profile.md),
[`ezrsurvey_profile_paths()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_profile_paths.md),
[`get_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/dataset_default.md),
[`get_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/get_order.md),
[`list_orders()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/list_orders.md),
[`load_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/load_ezrsurvey_profile.md),
[`order_for()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/order_for.md),
[`register_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order.md),
[`register_order_presets()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/register_order_presets.md),
[`remove_order()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/remove_order.md),
[`reset_ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/reset_ezrsurvey_options.md),
[`save_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_ezrsurvey_profile.md),
[`use_dataset()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_dataset.md),
[`use_ezrsurvey_profile()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_ezrsurvey_profile.md)

## Examples

``` r
ezrsurvey_options()                       # view all defaults
#> $pct_axis_unit
#> [1] 25
#> 
#> $pct_axis_max
#> NULL
#> 
#> $bar_cols_max_items
#> [1] 6
#> 
#> $bar_cols_max_label
#> [1] 12
#> 
#> $bar_wrap_cols
#> [1] 12
#> 
#> $bar_wrap_bars
#> [1] 28
#> 
#> $bar_label_size
#> [1] 3.5
#> 
#> $bar_size_step
#> [1] 0.15
#> 
#> $bar_size_min
#> [1] 2.4
#> 
#> $bar_width
#> [1] 0.66
#> 
#> $bar_ref_items
#> [1] 6
#> 
#> $age_breaks
#> [1]   0  18  22  26  30  35 Inf
#> 
#> $age_labels
#> [1] "17 or younger" "18 to 21"      "22 to 25"      "26 to 29"     
#> [5] "30 to 34"      "35+"          
#> 
#> $na_answers
#> [1] "Prefer not to answer"
#> 
#> $drop_answers
#> NULL
#> 
#> $generation_scheme
#> [1] "pew"
#> 
#> $current_year
#> NULL
#> 
#> $default_by
#> NULL
#> 
#> $brand_colors
#> NULL
#> 
#> $brand_color_primary
#> NULL
#> 
#> $brand_font_major
#> NULL
#> 
#> $brand_font_minor
#> NULL
#> 
#> $brand_fonts_enabled
#> [1] TRUE
#> 
#> $brand_template_pptx
#> NULL
#> 
#> $brand_template_docx
#> NULL
#> 
#> $progress
#> [1] "auto"
#> 
#> $confirm
#> [1] "auto"
#> 
#> $output_dir
#> [1] "ezrsurvey-outputs"
#> 
ezrsurvey_options(pct_axis_max = 100)
ezrsurvey_options()$pct_axis_max          # 100
#> [1] 100
reset_ezrsurvey_options()                 # back to defaults
```
