# The "Learn the ezr family" book

This folder is a [bookdown](https://bookdown.org) project — the learning resource
that ships with `ezrlearning`. It teaches everyday survey analysis and modelling
in R using the `ezr` family of packages.

## Build it

You need the family installed (the chapters run real ezr code):

```r
# from the repository root
# R CMD INSTALL ezr-survey ezr-model ezr-learning

# then, from this folder
bookdown::render_book(".")          # outputs to _book/
```

Vignette/chapter builds need pandoc; if you do not have a system pandoc, point R
at the one bundled with Quarto:

```r
Sys.setenv(RSTUDIO_PANDOC = "<path-to>/Quarto/bin/tools")
```

The rendered site lands in `_book/index.html`. Host it (e.g. GitHub Pages) and
point `options(ezrlearning.book_url = ...)` at the build so `open_book()` finds
it.

## Chapters

1. R fundamentals
2. The ezr way
3. Data and graphs
4. Finding patterns
5. Segments and structure
6. Text
7. Automation and reporting
8. Practice
