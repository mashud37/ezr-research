# ezr family — conventions & policy

This document is the contract every package in this monorepo follows, so the
`ezr*` family feels like one toolkit. `ezrsurvey` is the reference implementation;
the other packages (`ezrmodel`, `ezrlearning`, ...) copy these conventions.

## 1. Philosophy — the "ezr mentality"

- **Single-line helpers.** Each common task is one verb-named function that does
  the whole job and returns a finished result, not a kit of parts.
- **A family dataset.** Set the working dataset once with `use_dataset(d)`, then
  call helpers without repeating `data` (or pipe it in). See the dataset rule
  below.
- **Patterns against a target.** Supervised helpers take a `target` and surface
  what relates to it. Unsupervised helpers find structure and report it with
  diagnostics.
- **Complete results.** A helper returns the answer *and* its diagnostics in one
  object you can `print()`, `plot()`, and tidy — never make the user assemble
  the evaluation by hand.
- **Tidyverse pipe, always.** These are tidyverse wrapper packages: use `%>%`
  everywhere (source, tests, `@examples`, vignettes, READMEs) — never the base
  R `|>`. `%>%` is re-exported from the tidyverse family the package already
  depends on.

## 2. Packaging & naming

- Package `ezr<name>` (no hyphen) lives in folder `ezr-<name>/`.
- Function names are verbs or `calc_`/noun phrases (`drivers()`, `cluster()`,
  `calc_percentage()`); snake_case; no dots.
- Every exported function gets an `@family` tag; families drive the help
  cross-links and the pkgdown reference.
- Rich results are S3 objects classed `ezr<pkg>_<type>` (e.g. `ezrmodel_clusters`,
  `ezrsurvey_precision`).
- Packages are **independent**: no `ezr*` package depends on another (see §7).
  The one deliberate exception is `ezrlearning`, which *teaches* the others and so
  `Imports` them on purpose (see §7).

## 3. The shared "ezr core"

Every package re-implements the same small set of domain-agnostic primitives,
**copied verbatim from `ezrsurvey` and re-branded only where the name carries the
package** (options prefix, theme name, keyring service, profile filename). Source
files to copy:

| Primitive | Source in `ezr-survey/R/` | Re-brand? |
| --- | --- | --- |
| Default dataset: `use_dataset()`, `get_dataset()`, `has_dataset()`, `clear_dataset()`, internal `resolve_data()` | `dataset.R` | no |
| Coercion/cleaning: `ensure_numeric()`, `na_blank()` | `utils-coerce.R`, `recode.R` | no |
| Options + YAML profiles: `ezr<pkg>_options()`, `reset/use/edit/save/load_*_profile()` | `config.R` | **yes** (option prefix `ezr<pkg>.`, profile `~/.ezr<pkg>.yml`) |
| Themes + palettes: `theme_ezr<pkg>*()`, `scale_*` | `theme.R`, `palettes.R` | **yes** (theme names) |
| Save/export: `save_plot()`, `save_data()`, `save_output()`, `export_xlsx()` | `export.R` | no |
| Progress: internal `progress_plan()`, `progress_start()`, `progress_item()`, `progress_note()`, `progress_done()` | `progress.R` | no |
| Confirmation: internal `confirm_on()`, `confirm_lines()`, `confirm_selection()` | `confirm.R` | no |

**AI is not an ezr core primitive.** Language-model summaries, API-key storage
and the prompt registry live in **`ezrintelligence`** alone; no other package
duplicates them, suggests `ellmer`/`keyring`, or takes an `ai =` argument. An
analysis package must be installable and fully useful with no model dependency
at all, which is also what keeps its CRAN submission simple. `ezrintelligence`
takes any summary table the analysis packages produce, so the split costs the
user one extra `library()` call and nothing else.

**Masking caveat (document it):** when a user attaches two `ezr*` packages, R
masks the identically-named primitive from the earlier one — harmless, since the
implementations match. The default-dataset state lives in each package's own
namespace, so `use_dataset()` is per-package. A shared `ezbase` package can be
extracted **later**, once every package is stable on CRAN; until then,
duplication is the deliberate price of independent releases.

## 4. Result-object convention

A wrapper returns `structure(list(...), class = "ezr<pkg>_<type>")` carrying the
full result plus diagnostics, and provides:

- `print()` — a concise, human summary (the headline numbers / verdict).
- `plot()` — the natural chart (cluster plot, scree, coefficient/importance bars).
- `tidy()` / `augment()` — a tidy table of the result, and the input data with
  the result appended (`.cluster`, `.fitted`, component scores), where useful.

`ezrsurvey_precision` in `ezr-survey/R/diagnostics.R` is the template.

### 4.1 Where a written file goes

Any function that writes a file routes its `path` through one resolver
(`resolve_output_path()` in `ezr-survey/R/export.R`), never through a bare
`ggsave()` / `write_csv()` call:

- **A bare file name lands in the package's output folder**, created on demand,
  so a session's results collect in one place instead of scattering through the
  working directory. The folder is an option (`output_dir`, default
  `"ezrsurvey-outputs"`), not a constant.
- **A path that names a directory is used exactly as written.** `"./x.png"`,
  `"charts/x.png"` and any absolute path are the user's override, which is what
  keeps `tempfile()` in examples and tests unaffected (and so keeps §7 satisfied:
  nothing is written outside `tempdir()` during `R CMD check`).
- **The rule is in every `@param path`**, in the same words, because a reader
  meets it one function at a time.

## 5. Documentation standard

Every exported function has: `@description`, a `@details` section explaining the
how/why, fully documented `@param`, `@return`, **runnable `@examples` with `#>`
results**, and an `@family` tag. Suggests-gated examples use
`@examplesIf requireNamespace("pkg", quietly = TRUE)`. Ship a `test-docs.R`
meta-test that fails if any exported function loses its `@return`, `@examples`,
or `@family`. Provide a getting-started vignette and a family-grouped
`_pkgdown.yml`.

## 6. Testing

- `testthat` edition 3, one test file per `R/` module.
- Optional (`Suggests`) packages are exercised behind `skip_if_not_installed()`.
- The `test-docs.R` meta-test enforces the documentation standard.

## 7. CRAN conformance

- Source is **ASCII** — use `\u` escapes, never literal non-ASCII bytes.
- `Suggests` packages are used **conditionally** (`requireNamespace()` in code,
  `skip_if_not_installed()` in tests, `@examplesIf` in examples) and the package
  works without them, failing gracefully with an install hint.
- Never write outside `tempfile()`/`tempdir()` or `tools::R_user_dir()`; restore
  global state (RNG seed, `options()`) that you change.
- Examples run in a few seconds each; wrap slow/IO/key-dependent ones in
  `\donttest` or `@examplesIf`.
- **No inter-package dependencies** between `ezr*` packages — each is
  independently releasable, avoiding CRAN submission-ordering deadlocks (an
  `Imports` must already be on CRAN). This is why the ezr core is duplicated.
  - **Exception — `ezrlearning`.** Because it is a *teaching companion* for the
    family, `ezrlearning` deliberately `Imports` `ezrsurvey` and `ezrmodel` (its
    exercises run and grade real ezr code). It is therefore installed from this
    repository rather than released independently on CRAN; its `--as-cran` check
    is clean apart from the expected "Imports not on CRAN" note. Generators that
    lean on an optional backend (e.g. `ipm_model()` → `rwa`) declare it and are
    filtered out when it is absent, so the package still works without it. A new
    result family applies: exercises are `ezrlearning_exercise` /
    `ezrlearning_quiz` / `ezrlearning_result` objects.
- Target `R CMD check --as-cran` with no ERROR/WARNING; the only acceptable
  NOTEs are the universal "New submission" and a local-only pandoc/README note.

## 8. Dev workflow

```r
roxygen2::roxygenise("ezr-<name>")          # regenerate NAMESPACE + man/
devtools::test("ezr-<name>")
```

```sh
# vignettes need pandoc; Quarto bundles one:
#   set RSTUDIO_PANDOC=<Quarto>/bin/tools
R CMD build  ezr-<name>
R CMD check  ezr<name>_<version>.tar.gz --as-cran
```

Commit or submit a package only when its own `--as-cran` check is clean.

## 9. Progress and resumability

A helper that can run for more than a few seconds says what it is doing. The
rules, which mirror the workspace's CLI liveness policy translated for a library
called from an R console:

- **Announce before the work, not after.** The `[i/N]` line for an item is
  printed *before* that item is processed, so a run that stops names the item it
  stopped on.
- **Print from the main thread, never animate.** R blocks during a long call, so
  a spinner is a lie. Progress is tied to real completed items.
- **A multi-step run prints its plan first.** No phase appears as a surprise.
- **The ETA is measured, not guessed**: `elapsed / done * remaining`, and it
  stays hidden until there is enough elapsed time to mean anything.
- **Everything goes through `message()`** (stderr), so progress never
  contaminates a returned value or a piped chain, and never through `cat()`.
- **Silent by default outside an interactive session.** The `progress` option is
  `"auto"`, which reports in a console and stays quiet in scripts, vignettes and
  `R CMD check`. `TRUE` / `FALSE` force it. Whether a run reports is settled when
  the run opens, so it cannot start reporting half way through.
- **No new dependency.** `cli` and `progressr` are not used; `message()` plus
  `sprintf()` covers the whole contract.

Resumability applies to any loop that accumulates a list and binds it at the
end. Such a function takes an optional `checkpoint = NULL` file path:

- Writes **after each item**, never an end-of-run summary, so a crash costs one
  item at most. Write to `<path>.part` and rename, so an interruption mid-write
  cannot leave a half-written checkpoint.
- Carries a **fingerprint** of the data and every argument that shapes the
  result. A checkpoint that does not match is reported and discarded, never
  blended into the new run. A corrupt file is treated the same way.
- **Defaults to `NULL`.** CRAN forbids writing outside `tempdir()` /
  `tools::R_user_dir()` unasked (§7), so the file only exists when the user
  names one. Checkpoints are gitignored and are the user's to delete.

A third rule covers the choice a long call makes for you. When a function picks
its own variables because the user named none, and the run then costs minutes or
writes a file, it **shows the selection and waits for a yes** before starting:

- **Only when the consequential default was used.** A named selection is the
  user's own choice and is never questioned.
- **Show both sides**: what was kept, what was skipped, and the one argument that
  changes the answer. A count is not enough; the reader needs the names.
- **The `confirm` option is `"auto"`,** interactive sessions only, so an
  unattended script can never stall on a prompt. Enter means yes. Declining
  computes nothing, writes nothing and returns `NULL`.

`crosstab_banner()` in `ezr-survey/R/crosstab_banner.R` is the template for all
three, with the shared helpers in `ezr-survey/R/progress.R` and
`ezr-survey/R/confirm.R`.
