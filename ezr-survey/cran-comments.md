# Submission

This is a new submission.

## Test environments

* Windows 11, R 4.6.0 (local)
* ubuntu-latest, macos-latest, windows-latest on R release, devel and oldrel-1
  (GitHub Actions)

## R CMD check results

0 errors | 0 warnings | 1 note

* Maintainer: 'Andreas Schellewald <aschellewald@acm.org>'
  New submission

## Notes for the reviewer

The check reports that `Depends` puts seven packages on the search path. That is
deliberate and is the package's purpose. ezrsurvey exists so that research and
insights professionals with limited coding experience can do a survey analysis
in single lines; it wraps dplyr, ggplot2, tidyr, tibble, readr, stringr and
purrr, and its users are expected to work in those packages alongside it, so
`library(ezrsurvey)` attaches them rather than asking a beginner to attach each
one. The seven are the packages the code itself calls, listed individually in
preference to the `tidyverse` meta-package. `rlang`, which is used only
internally, is in `Imports`.

`crosstab_banner(checkpoint = TRUE)` is the package's only use of
`tools::R_user_dir()`. It is off by default, holds one small `.rds` per
interrupted run so a long cross-tab can resume, and deletes that file as soon
as the run completes. `clear_checkpoints()` empties the folder if a run was
interrupted and never repeated.

Functions that save a result write only where the caller asks. A bare file name
is placed in a project-local `ezrsurvey-outputs/` folder in the working
directory, which the caller overrides with any path that names a directory; no
example, test or vignette uses a bare name, so nothing is written outside
`tempdir()` during `R CMD check`.

`\dontrun{}` appears only on the four functions that write a profile into the
user's own config directory, which cannot run unattended. Every other example
runs, behind `@examplesIf` where it needs a suggested package.
