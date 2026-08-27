# Internal progress reporting. The slow helpers say which item they are on, so a
# long run never looks like a hung session. Everything here goes to message()
# (stderr), so it never lands in a returned value or a piped chain.

# Internal: is progress reporting on? "auto" means interactive sessions only,
# which keeps scripts, vignettes and R CMD check silent.
progress_on <- function() {
  setting <- ezrsurvey_default("progress")
  if (identical(setting, "auto")) {
    return(interactive())
  }
  isTRUE(setting)
}

# Internal: turn a number of seconds into something a reader can act on.
format_duration <- function(seconds) {
  if (!is.finite(seconds)) {
    return("?")
  }
  if (seconds < 90) {
    return(paste0(round(seconds), "s"))
  }
  minutes <- seconds / 60
  if (minutes < 90) {
    return(paste0(round(minutes), "m"))
  }
  paste0(round(minutes / 60, 1), "h")
}

# Internal: list every phase before the first one starts, so no phase arrives as
# a surprise part-way through a run.
progress_plan <- function(title, steps) {
  if (!progress_on()) {
    return(invisible(FALSE))
  }
  message(title)
  total <- length(steps)
  for (i in seq_len(total)) {
    message("  ", i, "/", total, "  ", steps[[i]])
  }
  invisible(TRUE)
}

# Internal: open a run over `total` items. Whether progress is on is settled
# once, here, so a run cannot start reporting and then stop half way.
progress_start <- function(total, label = NULL) {
  on <- progress_on()
  if (on && !is.null(label)) {
    message(label)
  }
  list(total = total, started = Sys.time(), on = on)
}

# Internal: seconds left, from the throughput measured so far. Empty until a few
# seconds have passed, because an estimate off one fast item is noise.
progress_eta <- function(run, i) {
  done <- i - 1L
  if (done < 1L || run$total <= i) {
    return("")
  }
  elapsed <- as.numeric(difftime(Sys.time(), run$started, units = "secs"))
  if (elapsed < 5) {
    return("")
  }
  remaining <- (elapsed / done) * (run$total - done)
  paste0("  (about ", format_duration(remaining), " left)")
}

# Internal: one "[i/N] name" line. Called BEFORE the item is processed, so a run
# that stops tells you which item it stopped on.
progress_item <- function(run, i, name) {
  if (!run$on) {
    return(invisible(FALSE))
  }
  message("[", i, "/", run$total, "] ", name, progress_eta(run, i))
  invisible(TRUE)
}

# Internal: a single line outside the per-item loop (a scan, a skip, a resume).
progress_note <- function(...) {
  if (!progress_on()) {
    return(invisible(FALSE))
  }
  message(...)
  invisible(TRUE)
}

# Internal: close a run with what it produced and how long it took.
progress_done <- function(run, note = NULL) {
  if (!run$on) {
    return(invisible(FALSE))
  }
  elapsed <- as.numeric(difftime(Sys.time(), run$started, units = "secs"))
  message("Done: ", run$total, " item(s) in ", format_duration(elapsed),
          if (is.null(note)) "" else paste0(", ", note))
  invisible(TRUE)
}
