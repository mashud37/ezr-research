# ezrmodel

> Single-line advanced modelling for consumer and behavioural data.

`ezrmodel` is the modelling member of the [`ezr`](../) family. It turns the
advanced-analytics tasks research and insights teams reach for — finding what
drives an outcome, segmenting customers, reducing dimensions, fitting and
comparing models, mining open text — into single, readable lines that return a
**complete** result: the answer *and* its diagnostics, ready to `print()`,
`plot()`, `tidy()` and `augment()`.

Like the rest of the family it follows the [shared conventions](../CONVENTIONS.md)
and is a self-contained, independently releasable package.

## Install

```r
# from the repository root
R CMD INSTALL ezr-model
# or during development
pkgload::load_all("ezr-model")
```

## A 30-second tour

```r
library(ezrmodel)

# what drives the target? (a consensus of correlation, regression,
# relative-weights, random-forest and factor importance)
drivers(nps_drivers, nps)

# target-focused correlations, a readable regression, model selection
correlations(nps_drivers, nps)
model_lm(nps_drivers, nps ~ quality + value + service)
model_select(nps_drivers, nps ~ quality + value + service + ease + support +
             trust + price + innovation, method = "lasso")
compare_models(simple = model_lm(nps_drivers, nps ~ quality),
               full   = model_lm(nps_drivers, nps ~ quality + value + service))

# segment, with diagnostics and profiles baked in
cluster(ecommerce, k = 4,
        vars = c(recency_days, frequency, monetary, tenure_months))

# reduce dimensions: PCA, UMAP or t-SNE
reduce_dims(ecommerce, method = "umap",
            vars = c(recency_days, frequency, monetary))

# group tests, latent structure
test_groups(nps_drivers, nps, region, mu = 6)
reliability(nps_drivers, items = c(value, quality, service, trust))
factors(nps_drivers, vars = c(value, quality, service, trust), n = 2)

# text: tidy terms, tf-idf, topics, extractive summaries
term_freq(reviews, text, by = rating)
topics(reviews, text, review_id, k = 3)
summarise_text(reviews, text, n = 3)
```

Every helper returns a rich `ezrmodel_*` result object with `print()` / `plot()`
/ `tidy()` / `augment()` methods, honours a session **default dataset**
(`use_dataset()`), and gates its optional packages gracefully.

## What's inside

- **Drivers & regression** — `drivers()`, `correlations()`, `model_lm()` /
  `model_glm()`, `model_select()` (stepwise / lasso / ridge / elastic-net),
  `compare_models()`.
- **Segmentation & structure** — `cluster()` (kmeans / hclust / pam, auto-`k`,
  silhouette/within-SS diagnostics, profiles), `cluster_profile()`,
  `reduce_dims()` (PCA / UMAP / t-SNE), `reliability()`, `factors()`, `sem()`.
- **Group tests** — `test_groups()`.
- **Text** — `tokenize_text()`, `term_freq()` (tf-idf), `topics()`,
  `summarise_text()`.
- **Prep & plumbing** — `model_frame()`, `to_matrix()`, `presence_matrix()`,
  themes/palettes, `save_*()` / `export_xlsx()`, AI summaries (`ai_summarise()`).
- **Bundled data** — `nps_drivers`, `ecommerce`, `reviews`.

See `NEWS.md` for the changelog and each function's help (`?drivers`) for details.

## License

MIT © Andreas Schellewald
