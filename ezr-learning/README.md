# ezrlearning

> Learn the **ezr** family with a book and hands-on practice.

`ezrlearning` is the teaching companion to [`ezrsurvey`](../ezr-survey/) and
[`ezrmodel`](../ezr-model/). It pairs a **book** (a `bookdown` re-telling of the
"Intro to R" workshop, taught entirely with the ezr packages) with a **practice
engine** that generates revision exercises — reproducibly random, auto-graded by
running real ezr code, and linked back to the book chapters.

Unlike the other family packages, `ezrlearning` **depends on** `ezrsurvey` and
`ezrmodel` on purpose (it teaches them), so it is installed from this repository
rather than released on its own.

## Install

```r
# the family packages first, then this one (from the repo root)
R CMD INSTALL ezr-survey ezr-model ezr-learning
# or, during development
pkgload::load_all("ezr-learning")
```

## Practice in 30 seconds

```r
library(ezrlearning)

# draw a reproducible exercise (same seed -> same question)
x <- draw_exercise(topic = "nps", seed = 1)
x
#> <exercise nps_mcq>  Multiple choice  [ch. 2: nps]
#> For the sample below (n = 287), what is the overall NPS ...

check_answer(x, "B")     # grade an answer (A/B/C/D, a number, or option text)
hint(x)                  # nudge
reveal(x)                # worked solution

# a "write the ezr code" task is graded by running your code
y <- draw_exercise(topic = "nps", type = "code", seed = 2)
check_answer(y, "calc_nps(theme_park, nps, by = region)")
```

## Quizzes and worksheets

```r
q <- quiz(5, chapter = 4, seed = 7)        # five questions from chapter 4
grade(q, list("B", "A", "C", "A", "B"))    # score them at once

# a self-contained worksheet that rebuilds the same quiz from its seed
export_worksheet(q, "worksheet.html", answer_key = TRUE)
```

## Fresh exercises from an LLM

```r
set_llm_key("openai")                          # stored in your OS keyring
ex <- generate_exercise("NPS by region", type = "mcq")
generate_quiz(5, topic = "clustering")
```

The model is pinned to the real ezr function inventory and the `theme_park`
teaching dataset. Generated MCQs are auto-graded; generated code tasks are
self-graded (use `reveal()`).

## The book

The book lives in [`book/`](book/) and is built with `bookdown`:

```r
bookdown::render_book("book")
```

`book_chapters()` maps each chapter to the topics you can practise for it, and
`open_book(chapter)` opens the hosted build.

## License

MIT © Andreas Schellewald
