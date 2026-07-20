# Builds the two bundled 16:9 PowerPoint templates from officer's 4:3 base:
#
#   inst/templates/ezrsurvey-16x9.pptx        styled ("elevated") default
#   inst/templates/ezrsurvey-16x9-plain.pptx  undecorated white
#
# Both convert the base template to widescreen the way PowerPoint itself does
# (uniform horizontal scale) and add the "Content with Caption" layout Pandoc
# expects. Layout names stay the PowerPoint standards ("Title Slide", "Title
# and Content", ...) so either file also works as a Quarto reference-doc.
#
# The styled one adds the furniture a corporate deck is expected to have: an
# accent lead-in over a full-width hairline under each title, a hairline above
# the footer strip, and a full-bleed accent band across the foot of the title
# slide. Every added shape is a plain drawing, never a placeholder, so
# report_layouts() and the content-slot picker ignore them.
#
# Run from the package root: Rscript data-raw/make_default_template.R

library(xml2)

ns <- c(
  a = "http://schemas.openxmlformats.org/drawingml/2006/main",
  p = "http://schemas.openxmlformats.org/presentationml/2006/main"
)

EMU_IN <- 914400
WIDE_CX <- 12192000            # 13.333in
SLIDE_CY <- 6858000            # 7.5in
BASE_CX <- 9144000             # officer's 4:3 width
HAIRLINE <- "D6D6D6"

emu <- function(x) format(round(x), scientific = FALSE)

# ---- shape fragments -----------------------------------------------------

# A plain filled rectangle. `fill` is either a theme colour name ("accent1") or
# a literal RRGGBB hex.
rect_sp <- function(x, y, cx, cy, fill, id, name) {
  colour <- if (grepl("^[0-9A-Fa-f]{6}$", fill)) {
    sprintf('<a:srgbClr val="%s"/>', fill)
  } else {
    sprintf('<a:schemeClr val="%s"/>', fill)
  }
  sprintf(paste0(
    '<p:sp xmlns:p="%s" xmlns:a="%s">',
    '<p:nvSpPr><p:cNvPr id="%d" name="%s"/><p:cNvSpPr/>',
    '<p:nvPr/></p:nvSpPr>',
    '<p:spPr><a:xfrm><a:off x="%s" y="%s"/><a:ext cx="%s" cy="%s"/>',
    '</a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom>',
    '<a:solidFill>%s</a:solidFill>',
    '<a:ln><a:noFill/></a:ln></p:spPr>',
    '<p:txBody><a:bodyPr/><a:lstStyle/><a:p><a:endParaRPr/></a:p></p:txBody>',
    "</p:sp>"
  ), ns[["p"]], ns[["a"]], id, name,
  emu(x), emu(y), emu(cx), emu(cy), colour)
}

add_shape <- function(doc, fragment) {
  tree <- xml_find_first(doc, "//p:cSld/p:spTree", ns)
  xml_add_child(tree, read_xml(fragment))
  invisible(doc)
}

# ---- geometry ------------------------------------------------------------

scale_x <- function(path, factor) {
  doc <- read_xml(path)
  for (node in xml_find_all(doc, "//a:off", ns)) {
    xml_set_attr(node, "x", emu(as.numeric(xml_attr(node, "x")) * factor))
  }
  for (node in xml_find_all(doc, "//a:ext", ns)) {
    xml_set_attr(node, "cx", emu(as.numeric(xml_attr(node, "cx")) * factor))
  }
  write_xml(doc, path)
}

# The title box a layout actually draws in. Layout placeholders usually inherit
# their geometry from the master (no own a:xfrm), so fall back to the master's
# title box rather than writing NA coordinates.
title_box <- function(doc, master_box) {
  xfrm <- xml_find_first(
    doc, "//p:sp[.//p:ph[@type='title' or @type='ctrTitle']]//a:xfrm", ns
  )
  if (inherits(xfrm, "xml_missing")) return(master_box)
  off <- xml_find_first(xfrm, "./a:off", ns)
  ext <- xml_find_first(xfrm, "./a:ext", ns)
  box <- list(x = as.numeric(xml_attr(off, "x")),
              y = as.numeric(xml_attr(off, "y")),
              cx = as.numeric(xml_attr(ext, "cx")),
              cy = as.numeric(xml_attr(ext, "cy")))
  if (!all(vapply(box, is.finite, logical(1)))) return(master_box)
  box
}

# ---- build ---------------------------------------------------------------

build_template <- function(out, decorate) {
  src <- system.file("template/template.pptx", package = "officer")
  stopifnot(nzchar(src))
  work <- file.path(tempdir(), paste0("ezr-tpl-", if (decorate) "styled" else "plain"))
  unlink(work, recursive = TRUE)
  dir.create(work, recursive = TRUE)
  utils::unzip(src, exdir = work)

  lay_dir <- file.path(work, "ppt", "slideLayouts")
  master_path <- file.path(work, "ppt", "slideMasters", "slideMaster1.xml")

  # 1. widescreen
  pres <- file.path(work, "ppt", "presentation.xml")
  doc <- read_xml(pres)
  sldsz <- xml_find_first(doc, "//p:sldSz", ns)
  xml_set_attr(sldsz, "cx", emu(WIDE_CX))
  xml_set_attr(sldsz, "type", NULL)
  write_xml(doc, pres)

  factor <- WIDE_CX / BASE_CX
  for (f in c(master_path,
              list.files(lay_dir, pattern = "^slideLayout[0-9]+[.]xml$",
                         full.names = TRUE))) {
    scale_x(f, factor)
  }

  # 2. the "Content with Caption" layout Pandoc looks for (clone Two Content)
  doc <- read_xml(file.path(lay_dir, "slideLayout4.xml"))
  xml_set_attr(xml_find_first(doc, "//p:cSld", ns), "name",
               "Content with Caption")
  write_xml(doc, file.path(lay_dir, "slideLayout8.xml"))
  file.copy(file.path(lay_dir, "_rels", "slideLayout4.xml.rels"),
            file.path(lay_dir, "_rels", "slideLayout8.xml.rels"))

  types_path <- file.path(work, "[Content_Types].xml")
  types <- read_xml(types_path)
  ct <- paste0("application/vnd.openxmlformats-officedocument.",
               "presentationml.slideLayout+xml")
  xml_add_child(types, read_xml(sprintf(
    paste0('<Override xmlns="http://schemas.openxmlformats.org/package/2006/',
           'content-types" PartName="/ppt/slideLayouts/slideLayout8.xml" ',
           'ContentType="%s"/>'), ct
  )))
  write_xml(types, types_path)

  master_rels <- file.path(work, "ppt", "slideMasters", "_rels",
                           "slideMaster1.xml.rels")
  rels <- read_xml(master_rels)
  rel_ids <- xml_attr(xml_find_all(rels, "//*[@Id]"), "Id")
  new_rid <- paste0("rId", max(as.integer(sub("^rId", "", rel_ids))) + 1)
  xml_add_child(rels, read_xml(sprintf(
    paste0('<Relationship xmlns="http://schemas.openxmlformats.org/package/',
           '2006/relationships" Id="%s" Type="http://schemas.openxmlformats.',
           'org/officeDocument/2006/relationships/slideLayout" ',
           'Target="../slideLayouts/slideLayout8.xml"/>'), new_rid
  )))
  write_xml(rels, master_rels)

  master <- read_xml(master_path)
  id_list <- xml_find_first(master, "//p:sldLayoutIdLst", ns)
  ids <- as.numeric(xml_attr(xml_find_all(id_list, "./p:sldLayoutId", ns), "id"))
  xml_add_child(id_list, read_xml(sprintf(
    paste0('<p:sldLayoutId xmlns:p="%s" xmlns:r="http://schemas.',
           'openxmlformats.org/officeDocument/2006/relationships" id="%s" ',
           'r:id="%s"/>'),
    ns[["p"]], emu(max(ids) + 1), new_rid
  )))
  write_xml(master, master_path)

  # 3. styling
  if (decorate) {
    master <- read_xml(master_path)
    mxfrm <- xml_find_first(master, "//p:sp[.//p:ph[@type='title']]//a:xfrm", ns)
    moff <- xml_find_first(mxfrm, "./a:off", ns)
    mext <- xml_find_first(mxfrm, "./a:ext", ns)
    master_box <- list(x = as.numeric(xml_attr(moff, "x")),
                       y = as.numeric(xml_attr(moff, "y")),
                       cx = as.numeric(xml_attr(mext, "cx")),
                       cy = as.numeric(xml_attr(mext, "cy")))
    stopifnot(all(vapply(master_box, is.finite, logical(1))))

    rule_h <- 12700               # 1pt hairline
    lead_h <- 38100               # 3pt accent lead-in
    lead_cx <- round(1.1 * EMU_IN)
    gap <- round(0.05 * EMU_IN)
    foot_y <- SLIDE_CY - round(0.60 * EMU_IN)

    # Content-bearing layouts: accent lead-in over a full-width hairline under
    # the title, plus a hairline above the footer strip.
    content <- c("slideLayout2.xml", "slideLayout3.xml", "slideLayout4.xml",
                 "slideLayout5.xml", "slideLayout6.xml", "slideLayout8.xml")
    for (f in content) {
      path <- file.path(lay_dir, f)
      doc <- read_xml(path)
      box <- title_box(doc, master_box)
      y <- box$y + box$cy + gap
      add_shape(doc, rect_sp(box$x, y, box$cx, rule_h, HAIRLINE,
                             900, "Title Hairline"))
      add_shape(doc, rect_sp(box$x, y - (lead_h - rule_h) / 2, lead_cx, lead_h,
                             "accent1", 901, "Title Accent"))
      add_shape(doc, rect_sp(box$x, foot_y, box$cx, rule_h, HAIRLINE,
                             902, "Footer Hairline"))
      write_xml(doc, path)
    }

    # Title slide: a full-bleed accent band across the foot.
    path <- file.path(lay_dir, "slideLayout1.xml")
    doc <- read_xml(path)
    band_cy <- round(0.42 * EMU_IN)
    add_shape(doc, rect_sp(0, SLIDE_CY - band_cy, WIDE_CX, band_cy,
                           "accent1", 903, "Title Band"))
    box <- title_box(doc, master_box)
    add_shape(doc, rect_sp(box$x, box$y + box$cy + gap, lead_cx, lead_h,
                           "accent1", 904, "Title Accent"))
    write_xml(doc, path)
  }

  unlink(out)
  old <- setwd(work)
  on.exit(setwd(old), add = TRUE)
  files <- list.files(".", recursive = TRUE, all.files = TRUE)
  zip::zip(file.path(old, out), files = files, mode = "mirror")
  setwd(old)
  message("Wrote ", out)
}

build_template(file.path("inst", "templates", "ezrsurvey-16x9.pptx"),
               decorate = TRUE)
build_template(file.path("inst", "templates", "ezrsurvey-16x9-plain.pptx"),
               decorate = FALSE)
