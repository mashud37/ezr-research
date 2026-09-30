# Adopt an organisation brand from a PowerPoint or Word template

Reads the colour and font theme out of your organisation's `.pptx` /
`.docx` template and makes it the session default for everything
ezrsurvey produces: charts pick up the brand accent colours and body
font, and the template file itself becomes the default reference
document for
[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
[`report_deck()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_deck.md)
and
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md).
One call, and analysis output is on-brand.

## Usage

``` r
use_brand(template = NULL, colors = NULL, fonts = NULL, quiet = FALSE)
```

## Arguments

- template:

  Path to a `.pptx` or `.docx` file. Its OOXML theme (accent colours,
  heading/body typefaces) is extracted, and the file is registered as
  the default reference document for reports of the matching format.
  `NULL` to set colours/fonts directly without a template.

- colors:

  Optional character vector of hex colours overriding the extracted
  accents. A single colour sets only the primary; a vector sets the full
  accent palette (first entry = primary). Invalid entries are dropped
  with a warning.

- fonts:

  Optional character vector overriding the extracted typefaces: either a
  single body font, or `c(major = "...", minor = "...")`.

- quiet:

  If `TRUE`, suppress the confirmation message.

## Value

Invisibly a `ezrsurvey_brand` list (see
[`brand_info()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/brand_info.md)).

## Details

Extraction reads `theme1.xml` inside the template (requires the
suggested `xml2` package): accent colours 1-6 become `brand_colors`
(first accent = `brand_color_primary`, the default fill of
[`plot_bars()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/plot_bars.md)),
and the minor (body) typeface becomes the default `base_family` of
[`theme_ezrsurvey()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/theme_ezrsurvey.md)
– but only when that font is actually installed on this machine, so
charts never render with substituted glyph boxes. Set
`ezrsurvey_options(brand_fonts_enabled = FALSE)` to keep brand colours
but ignore brand fonts.

A brand font also needs a graphics device that reads the machine's
fonts. The `pdf` and `postscript` devices do not: they carry their own
short list of families, and a chart printed to one fails with "invalid
font type". That is the default device in a plain `Rscript` run, so
`use_brand()` says so when it sets a font there. Charts written with
[`save_plot()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/save_plot.md)
are unaffected, because it saves through a device that does read system
fonts.

Everything lands in ordinary
[`ezrsurvey_options()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_options.md)
(`brand_*` keys), so you can equally set the values by hand or persist
them in a YAML profile; a later `use_brand()` call simply overwrites
them. Semantic palettes
([pal_rating](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md),
[pal_nps](https://mashud37.github.io/ezr-research/ezr-survey/reference/ezrsurvey_palettes.md))
deliberately keep their meaning-carrying colours and are not rebranded.
Use
[`clear_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_brand.md)
to return to the neutral look.

## See also

[`brand_info()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/brand_info.md),
[`clear_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_brand.md),
[`pal_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/pal_brand.md),
[`scale_fill_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md),
[`report_new()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/report_new.md),
[`scaffold_report()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scaffold_report.md).

Other brand:
[`brand_info()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/brand_info.md),
[`clear_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_brand.md),
[`pal_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/pal_brand.md),
[`scale_fill_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md)

## Examples

``` r
tmp <- tempfile(fileext = ".pptx")
print(officer::read_pptx(), target = tmp)
use_brand(tmp, quiet = TRUE)
brand_info()
#> ezrsurvey brand
#>   colors:   #4F81BD #C0504D #9BBB59 #8064A2 #4BACC6 #F79646
#>   primary:  #4F81BD
#>   fonts:    Calibri / Calibri
#>   pptx ref: /tmp/RtmpgWzLIC/file1c5d6ddd861.pptx
clear_brand()
# Or set brand values directly, no template needed:
use_brand(colors = c("#0B5394", "#E69138"), fonts = "Georgia", quiet = TRUE)
clear_brand()
```
