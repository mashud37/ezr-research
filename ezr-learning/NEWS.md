# ezrlearning 0.1.0

First release. A teaching companion for the `ezr` family, built from workshop
material.

## The book

* A `bookdown` learning resource (in `book/`) that re-tells the "Intro to R"
  workshop using the `ezr` packages: fundamentals, the ezr way, data & graphs,
  finding patterns, segments & structure, text, automation & reporting, and a
  practice chapter.

## Practice exercises

* **Built-in bank** of randomised-yet-reproducible exercises: `draw_exercise()`,
  `exercise_bank()`, `list_topics()`. The same `seed` always gives the same
  question; different seeds vary the sample, target column or options.
* **Two kinds of task**: multiple choice and "write the ezr code". Code answers
  are graded by *running* real `ezrsurvey` / `ezrmodel` code and comparing to the
  reference result (`check_answer()`); `hint()` and `reveal()` help when stuck.
* **Quizzes & worksheets**: `quiz()`, `grade()`, and `export_worksheet()` which
  writes a self-contained R Markdown worksheet that rebuilds the identical quiz
  from its seed (with an optional answer key).
* **AI generator**: `generate_exercise()` / `generate_quiz()` draft fresh
  exercises with a language model (via `ellmer`), pinned to the real ezr function
  inventory. Keys are managed with `set_llm_key()` and friends.
* **Book link**: every exercise is tagged with its `chapter`; `book_chapters()`
  and `open_book()` connect practice to the reading.
* Bundled teaching dataset: `theme_park`.

> Note: unlike the other `ezr` packages, `ezrlearning` depends on `ezrsurvey`
> and `ezrmodel` by design (it teaches them), so it is installed from the family
> repository rather than released independently.
