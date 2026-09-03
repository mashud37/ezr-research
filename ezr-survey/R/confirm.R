# Internal confirmation prompts. A call that picks its own variables and then
# runs for minutes shows the choice first and waits for a yes, so nobody sits
# through a long run over the wrong columns.

# Internal: is a prompt on? "auto" means an interactive session only, so scripts,
# vignettes and R CMD check are never left waiting for an answer.
confirm_on <- function(setting = NULL) {
  if (is.null(setting)) {
    setting <- ezrsurvey_default("confirm")
  }
  if (identical(setting, "auto")) {
    return(interactive())
  }
  if (!is.logical(setting) || length(setting) != 1 || is.na(setting)) {
    stop("`confirm` must be TRUE, FALSE, or \"auto\", not ",
         class(setting)[1], ".", call. = FALSE)
  }
  setting
}

# Internal: one "Label (3): alpha, beta, gamma" entry, wrapped so a survey with
# forty columns still prints something a reader can scan.
confirm_lines <- function(label, names) {
  if (!length(names)) {
    return(paste0(label, ": none"))
  }
  text <- paste0(label, " (", length(names), "): ",
                 paste(names, collapse = ", "))
  strwrap(text, width = 76, exdent = 4)
}

# Internal: show what the call is about to do and ask whether to go ahead.
# Returns TRUE when the run should proceed. Enter means yes, because a reader who
# has looked over the list and agrees should not have to type anything.
confirm_selection <- function(title, lines, setting = NULL) {
  if (!confirm_on(setting)) {
    return(TRUE)
  }
  message(title)
  for (line in lines) {
    message("  ", line)
  }
  answer <- tolower(trimws(readline("Continue? [Y/n] ")))
  !answer %in% c("n", "no")
}
