# Survey weighting (post-stratification / raking).
#
# A weighting *scheme* is a set of target shares for one or more categorical
# variables, e.g. "the population is 51% women, 48% men, 1% non-binary". From the
# sample's own composition we derive a per-respondent weight so the weighted
# margins match those targets. With one variable this is exact post-stratification;
# with several it is raking (iterative proportional fitting).
#
# The scheme is stored in the session (alongside the default dataset) and honoured
# automatically by the summary helpers when it is set. Each helper also takes a
# `weights` argument to override per call (`FALSE` to force unweighted, a spec to
# use an ad-hoc scheme).

# ---- spec parsing --------------------------------------------------------

# Internal: coerce a named vector of targets to normalised numeric shares.
normalize_targets <- function(vec, var) {
  vec <- vec[names(vec) != "variable"]
  nm <- names(vec)
  if (is.null(nm) || any(!nzchar(nm))) {
    stop("Weight targets for '", var, "' must be named by category.",
         call. = FALSE)
  }
  shares <- suppressWarnings(as.numeric(vec))
  if (any(is.na(shares))) {
    stop("Weight targets for '", var, "' must be numeric.", call. = FALSE)
  }
  if (any(shares < 0)) {
    stop("Weight targets for '", var, "' must be non-negative.", call. = FALSE)
  }
  if (sum(shares) == 0) {
    stop("Weight targets for '", var, "' sum to zero.", call. = FALSE)
  }
  stats::setNames(shares / sum(shares), nm)
}

# Internal: parse one vector spec of the form
# c("variable" = "demo_gender", "Male" = .8, "Female" = .19, ...).
parse_one_spec <- function(v) {
  nm <- names(v)
  if (is.null(nm) || !"variable" %in% nm) {
    stop("Each weight spec needs a 'variable' entry naming the column, e.g. ",
         "c(variable = \"demo_gender\", Male = 0.5, Female = 0.5).",
         call. = FALSE)
  }
  var <- as.character(v[["variable"]])
  list(variable = var, targets = normalize_targets(v, var))
}

# Internal: normalise any accepted input into a canonical named list
# list(<variable> = c(<category> = <share>, ...), ...).
parse_weight_spec <- function(...) {
  args <- list(...)
  if (length(args) == 0L) {
    stop("Provide at least one weighting variable.", call. = FALSE)
  }
  # A single list argument: either the canonical form, a list of vector specs,
  # or a named list of target vectors.
  if (length(args) == 1L && is.list(args[[1]]) && is.null(names(args))) {
    args <- args[[1]]
  }
  nm <- names(args)
  out <- list()
  if (!is.null(nm) && all(nzchar(nm))) {
    # Named-list form: names are the variables, values are target vectors.
    for (v in nm) out[[v]] <- normalize_targets(args[[v]], v)
  } else {
    # Vector-spec form: each element carries its own `variable` entry.
    for (el in args) {
      one <- parse_one_spec(el)
      out[[one$variable]] <- one$targets
    }
  }
  out
}

# ---- weight computation --------------------------------------------------

# Internal: Kish design effect and effective sample size for a weight vector.
weight_diagnostics <- function(w) {
  deff <- mean(w^2) / mean(w)^2
  list(deff = deff, n_eff = length(w) / deff)
}

# Internal: compute per-row weights for `data` under a (canonical) spec by raking.
compute_weights <- function(data, spec, max_iter = 50L, tol = 1e-6) {
  if (length(spec) == 0L) return(rep(1, nrow(data)))
  N <- nrow(data)

  # Pre-clean the weighting columns and validate coverage up front.
  cols <- list()
  for (var in names(spec)) {
    if (!var %in% names(data)) {
      stop("Weighting variable '", var, "' is not a column in the data.",
           call. = FALSE)
    }
    col <- as.character(na_blank(data[[var]]))
    obs <- unique(col[!is.na(col)])
    missing <- setdiff(obs, names(spec[[var]]))
    if (length(missing)) {
      stop("These categories of '", var, "' have no weight target: ",
           paste(missing, collapse = ", "),
           ". Add them to the scheme (or recode them first).", call. = FALSE)
    }
    cols[[var]] <- col
  }

  w <- rep(1, N)
  for (iter in seq_len(max_iter)) {
    max_change <- 0
    for (var in names(spec)) {
      col <- cols[[var]]
      known <- !is.na(col)
      total_known <- sum(w[known])
      if (total_known <= 0) next
      for (cat in names(spec[[var]])) {
        idx <- which(col == cat)
        cur <- sum(w[idx])
        if (cur > 0) {
          ratio <- (spec[[var]][[cat]] * total_known) / cur
          w[idx] <- w[idx] * ratio
          max_change <- max(max_change, abs(log(ratio)))
        }
      }
    }
    if (max_change < tol) break
  }
  w / mean(w)            # normalise to mean 1 (so sum(w) == N)
}

# Internal: resolve a function's `weights` argument to a weight vector or NULL.
# NULL  -> use the session scheme if one is set, else no weighting.
# FALSE -> force unweighted.
# TRUE  -> use the session scheme (error if none).
# spec  -> an ad-hoc scheme for this call.
resolve_weights <- function(data, weights = NULL) {
  if (isFALSE(weights)) return(NULL)
  spec <- NULL
  if (is.null(weights)) {
    if (!has_weights()) return(NULL)
    spec <- get_weights()
  } else if (isTRUE(weights)) {
    if (!has_weights()) {
      stop("weights = TRUE but no weighting scheme is set; call set_weights().",
           call. = FALSE)
    }
    spec <- get_weights()
  } else {
    spec <- parse_weight_spec(weights)
  }
  compute_weights(data, spec)
}

# ---- session scheme ------------------------------------------------------

#' Set a survey weighting scheme for the session
#'
#' Defines target shares for one or more categorical variables (e.g. a known
#' population split by gender or region). Once set, the summary helpers
#' ([calc_percentage()], [calc_nps()], [calc_summary()], [crosstab()]) weight
#' their results automatically, so the weighted margins match your targets. Pass
#' `weights = FALSE` to any of them to opt out for a single call.
#'
#' @param ... One scheme per variable. Two forms are accepted:
#'   * **vector form** (one argument per variable) carrying a `variable` entry and
#'     a share per category:
#'     `c(variable = "demo_gender", Male = 0.49, Female = 0.50, "Non-binary" = 0.01)`;
#'   * **named form**: `demo_gender = c(Male = 0.49, Female = 0.50)`, where the
#'     argument name is the column.
#'   Shares need not sum to 1 -- they are normalised per variable (so raw
#'   percentages or counts work too).
#'
#' @return Invisibly, the parsed scheme (a named list of normalised targets).
#'
#' @details
#' With a single variable the weights are exact post-stratification:
#' `target_share / sample_share` for each category. With several variables the
#' weights are found by raking (iterative proportional fitting) so every variable's
#' weighted margin matches its targets. Weights are normalised to mean 1 (so the
#' weighted base equals the sample size), and respondents whose weighting value is
#' blank / a non-answer (see [na_blank()]) are left unadjusted. A category that
#' appears in the data but is missing from your targets is an error -- give every
#' observed category a share. If a default dataset is set, this prints the Kish
#' design effect and the effective sample size so you can see the precision cost.
#'
#' @family weighting
#' @seealso [clear_weights()], [get_weights()], [weight_vector()],
#'   [calc_percentage()].
#' @examples
#' set_weights(c(variable = "demo_gender",
#'               "As a man" = 0.49, "As a woman" = 0.50,
#'               "Non-binary person" = 0.01))
#' calc_percentage(consumer_survey, satis_return)   # gains a wpct column
#' clear_weights()
#' @export
set_weights <- function(...) {
  spec <- parse_weight_spec(...)
  assign("weight_spec", spec, envir = .ezrsurvey_active)
  if (has_dataset()) {
    w <- tryCatch(compute_weights(get_dataset(), spec), error = function(e) e)
    if (inherits(w, "error")) {
      rm("weight_spec", envir = .ezrsurvey_active)
      stop(conditionMessage(w), call. = FALSE)
    }
    d <- weight_diagnostics(w)
    message(sprintf(
      "Weighting on %d variable(s): %s. Design effect %.2f, effective n = %d of %d.",
      length(spec), paste(names(spec), collapse = ", "), d$deff,
      round(d$n_eff), length(w)))
  } else {
    message("Weighting scheme stored for: ", paste(names(spec), collapse = ", "),
            ". It applies once a dataset is in play.")
  }
  invisible(spec)
}

#' Inspect or clear the session weighting scheme
#'
#' Companions to [set_weights()]: read the stored scheme, test whether one is set,
#' or remove it.
#'
#' @return `get_weights()` returns the scheme (a named list of target vectors;
#'   error if none is set); `has_weights()` returns a logical; `clear_weights()`
#'   returns `TRUE` invisibly.
#'
#' @details
#' `has_weights()` is the safe check before `get_weights()`, which errors when no
#' scheme is set. `clear_weights()` turns weighting off again, so the helpers
#' return purely unweighted results.
#'
#' @family weighting
#' @seealso [set_weights()], [weight_vector()].
#' @examples
#' has_weights()
#' set_weights(c(variable = "region", Europe = 0.5, "North America" = 0.5))
#' get_weights()
#' clear_weights()
#' @rdname weights_scheme
#' @export
get_weights <- function() {
  if (!has_weights()) {
    stop("No weighting scheme set; call set_weights() first.", call. = FALSE)
  }
  get("weight_spec", envir = .ezrsurvey_active, inherits = FALSE)
}

#' @rdname weights_scheme
#' @export
has_weights <- function() {
  exists("weight_spec", envir = .ezrsurvey_active, inherits = FALSE)
}

#' @rdname weights_scheme
#' @export
clear_weights <- function() {
  if (has_weights()) rm("weight_spec", envir = .ezrsurvey_active)
  invisible(TRUE)
}

#' Compute the per-respondent survey weights
#'
#' Returns the weight vector a scheme implies for a dataset -- the same numbers the
#' summary helpers use internally -- so you can inspect them, attach them as a
#' column, or feed them to another tool.
#'
#' @param data A data frame. If omitted, the session default ([use_dataset()]) is
#'   used.
#' @param weights A weighting scheme (any form accepted by [set_weights()]). If
#'   `NULL` (default), the session scheme is used.
#'
#' @return A numeric vector of length `nrow(data)`, normalised to mean 1.
#'
#' @details
#' This is the function behind the automatic weighting: each respondent's weight is
#' `target_share / sample_share` for their category (raked across variables when
#' there are several), normalised so the weighted base equals the unweighted one.
#' Pair it with [set_weights()]'s reported design effect to judge how much
#' precision the weighting costs.
#'
#' @family weighting
#' @seealso [set_weights()], [calc_percentage()].
#' @examples
#' w <- weight_vector(consumer_survey,
#'                    c(variable = "demo_gender",
#'                      "As a man" = 0.49, "As a woman" = 0.50,
#'                      "Non-binary person" = 0.01))
#' round(range(w), 2)
#' @export
weight_vector <- function(data = NULL, weights = NULL) {
  data <- resolve_data(data)
  spec <- if (is.null(weights)) {
    if (!has_weights()) {
      stop("No `weights` given and no session scheme set; call set_weights().",
           call. = FALSE)
    }
    get_weights()
  } else {
    parse_weight_spec(weights)
  }
  compute_weights(data, spec)
}

# Internal: weighted median (lower weighted 50th percentile).
wtd_median <- function(x, w) {
  ok <- !is.na(x)
  x <- x[ok]; w <- w[ok]
  if (length(x) == 0L) return(NA_real_)
  o <- order(x); x <- x[o]; w <- w[o]
  cw <- cumsum(w) / sum(w)
  x[which(cw >= 0.5)[1]]
}

# Internal: weighted standard deviation (reliability-weight convention).
wtd_sd <- function(x, w) {
  ok <- !is.na(x)
  x <- x[ok]; w <- w[ok]
  if (length(x) < 2L) return(NA_real_)
  m <- sum(w * x) / sum(w)
  v <- sum(w * (x - m)^2) / (sum(w) - 1)
  sqrt(v)
}
