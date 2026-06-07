# Common alternative codes/symbols mapped to their ISO 4217 code, so everyday
# inputs like "RMB" or "US$" resolve correctly.
.currency_aliases <- c(
  RMB = "CNY", YUAN = "CNY", RENMINBI = "CNY",
  DOLLAR = "USD",
  EURO = "EUR",
  STERLING = "GBP", QUID = "GBP",
  YEN = "JPY",
  NIS = "ILS"
)

# Internal: normalise a currency code (upper-case, trim, resolve aliases).
normalize_currency <- function(x) {
  x <- toupper(trimws(as.character(x)))
  hit <- x %in% names(.currency_aliases)
  x[hit] <- unname(.currency_aliases[x[hit]])
  x
}

# Internal: turn the `rates` argument into a named numeric vector of units per
# USD. Accepts NULL (use the bundled snapshot), a named numeric vector, or a
# data frame with `currency` and `per_usd` columns.
resolve_rates <- function(rates = NULL) {
  if (is.null(rates)) {
    return(stats::setNames(currency_rates$per_usd, currency_rates$currency))
  }
  if (is.numeric(rates) && !is.null(names(rates))) {
    return(stats::setNames(as.numeric(rates), toupper(names(rates))))
  }
  if (is.data.frame(rates)) {
    val <- if ("per_usd" %in% names(rates)) "per_usd" else
      if ("rate" %in% names(rates)) "rate" else NA_character_
    if (!"currency" %in% names(rates) || is.na(val)) {
      stop("A `rates` data frame needs a `currency` column and a ",
           "`per_usd` (or `rate`) column.", call. = FALSE)
    }
    return(stats::setNames(rates[[val]], toupper(rates[["currency"]])))
  }
  stop("`rates` must be NULL, a named numeric vector, or a data frame.",
       call. = FALSE)
}

#' Convert amounts between currencies
#'
#' Converts monetary amounts from one currency to another using a table of
#' exchange rates. By default it uses the bundled [currency_rates] snapshot
#' (units per US dollar); pass your own `rates` for up-to-date or custom figures.
#' Because rates share the USD base, any pair is converted as a cross-rate
#' through USD automatically (e.g. EUR to CNY goes EUR -> USD -> CNY in one call).
#' `amount`, `from` and `to` are vectorised and recycled, so you can convert a
#' whole column with per-row source currencies at once.
#'
#' @param amount Numeric amounts (text like `"$1,200"` is salvaged with
#'   [ensure_numeric()]).
#' @param from Source currency code(s), e.g. `"EUR"` (case-insensitive). Common
#'   aliases resolve to their ISO code (e.g. `"RMB"` -> `"CNY"`).
#' @param to Target currency code(s). Defaults to `"USD"`.
#' @param rates Exchange rates: `NULL` (default) for the bundled snapshot, a
#'   named numeric vector of units-per-USD (e.g. `c(EUR = 0.92, GBP = 0.79)`),
#'   or a data frame with `currency` and `per_usd` columns.
#'
#' @return A numeric vector of converted amounts; unknown currency codes yield
#'   `NA` with a warning.
#'
#' @details
#' Each rate is stored as units of the currency per 1 US dollar, so a conversion
#' is `amount / rate(from) * rate(to)` -- which means any pair is handled as a
#' cross-rate through USD without you doing anything. The bundled
#' [currency_rates] table is a dated, approximate snapshot meant for convenience,
#' not live trading; for accuracy pass your own `rates` (a named vector or a
#' `currency`/`per_usd` data frame). Amounts are coerced with [ensure_numeric()],
#' codes are upper-cased and resolved through a small alias map (`"RMB"` ->
#' `"CNY"`, `"EURO"` -> `"EUR"`, ...), and any unknown code yields `NA` with a
#' warning rather than a silent wrong number.
#'
#' @family currency
#' @seealso [add_currency()], [list_currencies()], [currency_rates].
#' @examples
#' convert_currency(100, "EUR", "USD")
#' #> [1] 108.7
#'
#' convert_currency(c(100, 50), from = c("EUR", "GBP"), to = "USD")
#'
#' convert_currency(100, "EUR", "CNY")          # cross-rate via USD
#' convert_currency(100, "EUR", "RMB")          # alias -> CNY, same result
#' @export
convert_currency <- function(amount, from, to = "USD", rates = NULL) {
  tab <- resolve_rates(rates)
  amount <- ensure_numeric(amount, quiet = TRUE)
  from <- normalize_currency(from)
  to <- normalize_currency(to)

  per_from <- unname(tab[from])
  per_to <- unname(tab[to])

  unknown <- unique(c(from[is.na(per_from)], to[is.na(per_to)]))
  unknown <- unknown[!is.na(unknown)]
  if (length(unknown) > 0) {
    warning("Unknown currency code(s): ", paste(unknown, collapse = ", "),
            ". Add them via `rates`.", call. = FALSE)
  }

  as.numeric(amount / per_from * per_to)
}

#' Add a converted-currency column to a data frame
#'
#' Convenience wrapper around [convert_currency()] that appends a converted
#' column to `data`. The source currency can be a fixed code or a per-row column.
#'
#' @param data A data frame.
#' @param amount The amount column to convert (unquoted).
#' @param from Source currency: either a bare column name holding per-row codes
#'   (e.g. `currency`) or a quoted constant code (e.g. `"EUR"`).
#' @param to Target currency code. Defaults to `"USD"`.
#' @param into Name of the new column. Defaults to `"<amount>_<to>"`.
#' @param rates Passed to [convert_currency()].
#'
#' @return `data` with the converted column added.
#'
#' @details
#' The `from` argument is clever about whether you mean a column or a constant: a
#' bare name (`from = currency`) is read as a per-row source-currency column,
#' while a quoted string (`from = "EUR"`) is a fixed code applied to every row.
#' This is the common case where each respondent reported spend in their own
#' currency. The new column defaults to `<amount>_<to>` (e.g. `spend_usd`);
#' override with `into`. Conversion uses [convert_currency()], so the same rates,
#' aliases and warnings apply.
#'
#' @family currency
#' @seealso [convert_currency()].
#' @examples
#' df <- tibble::tibble(spend = c(100, 200, 50),
#'                      currency = c("EUR", "GBP", "JPY"))
#'
#' # per-row source currency (a column)
#' add_currency(df, spend, from = currency, to = "USD")
#'
#' # a fixed source currency (a constant), custom output name
#' add_currency(df, spend, from = "EUR", to = "USD", into = "spend_usd")
#' @export
add_currency <- function(data = NULL, amount, from, to = "USD", into = NULL,
                         rates = NULL) {
  data <- resolve_data(data)
  amount_name <- rlang::as_name(rlang::ensym(amount))
  from_q <- rlang::enquo(from)
  from_expr <- rlang::quo_get_expr(from_q)

  from_vec <- if (is.character(from_expr)) {
    from_expr                       # a quoted constant like "EUR"
  } else {
    dplyr::pull(data, !!from_q)     # a per-row column
  }

  into <- into %||% paste0(amount_name, "_", tolower(to))
  data[[into]] <- convert_currency(data[[amount_name]], from = from_vec,
                                   to = to, rates = rates)
  data
}

#' List the currencies in a rate table
#'
#' @param rates Rate table; `NULL` (default) for the bundled [currency_rates].
#' @return A character vector of currency codes.
#'
#' @details
#' A quick way to see which codes [convert_currency()] will accept from the
#' bundled snapshot (or from a `rates` table you pass). Aliases such as `"RMB"`
#' are *not* listed -- they resolve to their ISO code (here `"CNY"`).
#'
#' @family currency
#' @seealso [currency_rates], [convert_currency()].
#' @examples
#' list_currencies()
#' #> [1] "USD" "EUR" "GBP" "JPY" "CNY" "CHF" ... (39 codes)
#' @export
list_currencies <- function(rates = NULL) {
  names(resolve_rates(rates))
}
