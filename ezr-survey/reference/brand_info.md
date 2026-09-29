# Show the active brand settings

Show the active brand settings

## Usage

``` r
brand_info()
```

## Value

An `ezrsurvey_brand` list with elements `colors`, `color_primary`,
`font_major`, `font_minor`, `template_pptx`, `template_docx` (each
`NULL` when unset).

## See also

[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md),
[`clear_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_brand.md).

Other brand:
[`clear_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/clear_brand.md),
[`pal_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/pal_brand.md),
[`scale_fill_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/scale_brand.md),
[`use_brand()`](https://mashud37.github.io/ezr-research/ezr-survey/reference/use_brand.md)

## Examples

``` r
brand_info()
#> No brand set. See ?use_brand.
```
