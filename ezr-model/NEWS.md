# ezrmodel 0.4.0

## Data

* New **`personas`** dataset: five consumer segments generated from explicit
  mathematical functions (well-separated Gaussian blobs via `MASS::mvrnorm`), so
  every clustering method (`kmeans` / `hclust` / `pam`) recovers them cleanly, the
  silhouette finds the true `k = 5` on its own, and `reduce_dims()` (PCA / UMAP /
  t-SNE) shows textbook structure. A redundant column gives PCA an obvious
  low-rank structure, and a ground-truth `persona` label lets you validate a
  recovered solution with `cluster_profile()`.

# ezrmodel 0.3.0

More modelling: predictor selection, model comparison and non-linear
embeddings, in the usual single-line, rich-result-object style.

* `model_select()` — stepwise (AIC) or penalised (lasso / ridge / elastic-net,
  via `glmnet`) regression that chooses its own predictors and reports the kept
  terms and coefficients.
* `compare_models()` — line up `model_lm()`, `model_select()` or raw `lm`/`glm`
  fits in one table of n, df, R-squared, AIC, BIC and RMSE, best-first.
* `reduce_dims()` gains `method = "umap"` (via `uwot`) and `method = "tsne"`
  (via `Rtsne`) alongside PCA, with a 2-D scatter `plot()` for the embeddings.

# ezrmodel 0.2.0

Text mining and latent-variable modelling, in the same single-line,
rich-result-object style.

## Text mining

* `tokenize_text()` — tidy one-row-per-term table with stop-word removal.
* `term_freq()` — term counts and, per group, tf-idf to surface distinctive
  words.
* `topics()` — Structural Topic Model (via `quanteda` + `stm`) returning the
  defining terms per topic (`beta`) and each document's topic mix (`gamma`).
* `summarise_text()` — extractive (LexRank) summary using respondents' own
  sentences, no API key needed.

## Latent variables

* `reliability()` — Cronbach's alpha with a plain-language rating and
  alpha-if-dropped per item.
* `factors()` — exploratory factor analysis with automatic factor count
  (parallel analysis), loadings, variance and fit.
* `sem()` — confirmatory factor analysis / structural equation models via
  `lavaan`, with fit measures and standardised paths.

All new helpers return rich `ezrmodel_*` objects with `print()` / `plot()` /
`tidy()` / `augment()` where applicable, and gate their optional packages
gracefully.

# ezrmodel 0.1.0

First release. Single-line advanced modelling for consumer/behavioural data,
following the ez-family conventions (see the repository `CONVENTIONS.md`).

## Highlights

* **Default dataset**: `use_dataset()` / `get_dataset()` / `has_dataset()` /
  `clear_dataset()`, honoured by every analysis helper.
* **Drivers**: `drivers()` — a consensus of correlation, regression,
  relative-weights, random-forest and factor importance against a target.
* **Clustering**: `cluster()` (kmeans / hclust / pam) with auto-k, silhouette
  and within-SS diagnostics and cluster profiles; `cluster_profile()`.
* **Dimensionality reduction**: `reduce_dims()` (PCA) with scores, loadings,
  variance explained and scree.
* **Regression**: `model_lm()` / `model_glm()` with tidy coefficients and fit.
* **Correlation**: `correlations()`, target-focused when given a target.
* **Group tests**: `test_groups()` — one-sample-vs-benchmark or pairwise tests
  as a tidy significance table.
* **Data prep**: `model_frame()`, `to_matrix()`, `presence_matrix()`.
* Rich result objects with `print()` / `plot()` / `tidy()` / `augment()`.
* Bundled data: `nps_drivers`, `ecommerce`, `reviews`.
