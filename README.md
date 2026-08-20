# ezr — a family of easier R packages for research work

This repository is the home for the **`ezr*`** family of R packages: focused
tidyverse wrappers that reduce repetitive day-to-day research-manager tasks to
single readable lines — no deep R knowledge required. Each package lives in its own subdirectory and is
built, documented and checked independently.

## Packages

| Package | Folder | Status | What it does |
| --- | --- | --- | --- |
| **ezrsurvey** | [`ezr-survey/`](ezr-survey/) | ✅ Active (v0.5.0) | Tidyverse helpers for everyday survey analysis — load & stack exports, percentages without `count`/`mutate`/`pivot_wider`, recodes (Likert, NPS, age, generations, country→region), importance/performance modelling, precision diagnostics, a themed plotting toolkit, quick CSV/XLSX/PNG/SVG saves, and Quarto/officer reporting. |
| **ezrmodel** | [`ezr-model/`](ezr-model/) | ✅ Active (v0.3.0) | Single-line advanced modelling for consumer/behavioural data — target drivers (consensus of correlation/regression/relative-weights/random-forest/factor), clustering + diagnostics, dimensionality reduction (PCA/UMAP/t-SNE), regression with stepwise/penalised selection and model comparison, group tests, text/topic modelling, and latent-variable analysis (reliability, EFA, SEM). |
| **ezrintelligence** | [`ezr-intelligence/`](ezr-intelligence/) | ✅ Active (v0.1.0) | The family's language-model helpers, split out so the analysis packages carry no model dependency — a registry of prompt templates written to an analyst standard, a context object that puts sample size and margin of error in front of the model, one-call summaries of a table or a whole report's sections, slide titles and takeaway bullets, and API keys held in the OS credential store. Takes any summary table the other packages produce. |
| **ezrlearning** | [`ezr-learning/`](ezr-learning/) | ✅ Active (v0.1.0) | A teaching companion: a `bookdown` book that re-tells the "Intro to R" workshop using the ezr family, plus a practice engine that hands out reproducible, auto-graded exercises (multiple choice and "write the ezr code"), assembles quizzes and worksheets, and can draft fresh exercises with an LLM. Unlike the others it **depends on** `ezrsurvey`/`ezrmodel` by design. |

More `ezr*` packages will be added here over time. All of them follow the shared
**[conventions & policy](CONVENTIONS.md)** (naming, the "ezr core" primitives,
result objects, documentation and CRAN rules) so the family stays consistent.

## Working with a package

Each package is a self-contained R package — `cd` into its folder to build,
test or check it:

```r
# from the package folder, e.g. ezr-survey/
devtools::document()
devtools::test()
devtools::check()
```

```sh
# or from the command line
R CMD build ezr-survey
R CMD check ezrsurvey_0.1.0.tar.gz --as-cran
```

See each package's own `README.md` for usage and a function tour
(e.g. [`ezr-survey/README.md`](ezr-survey/README.md)).

## License

MIT © Andreas Schellewald
