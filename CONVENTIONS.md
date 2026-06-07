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
| AI + keys + prompts: `set_llm_key()`, `ai_chat()`, `ai_summarise()`, prompt registry | `keys.R`, `ai.R`, `prompts.R` | **yes** (keyring service `"ezr<pkg>"`) |

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
