# Builds the two bundled 16:9 PowerPoint templates from officer's 4:3 base:
#
#   inst/templates/ezrsurvey-16x9.pptx        styled ("elevated") default
#   inst/templates/ezrsurvey-16x9-plain.pptx  undecorated white
#
# Both convert the base template to widescreen the way PowerPoint itself does
# (uniform horizontal scale), add the "Content with Caption" layout Pandoc
# expects, replace the dated Office colour scheme with a navy/gold identity, and
# bring the title/body sizes down to deck-appropriate values with shrink-to-fit
# on every text placeholder so descriptive question headlines never overflow.
# Layout names stay the PowerPoint standards ("Title Slide", "Title and
# Content", ...) so either file also works as a Quarto reference-doc.
#
# The styled one is a proper report design, not white slides with rules on top:
#   - a full-bleed navy cover with a large left-aligned white title, a gold
#     accent rule and a white subtitle;
#   - full-bleed navy section dividers with a large white section word;
#   - content slides with a navy title over one slim navy rule (nothing else),
#     and the template's slide number in the corner.
# Every added shape is a plain drawing, never a placeholder, so
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

# ---- brand identity ------------------------------------------------------

NAVY <- "12314E"               # primary: chrome, cover, dividers, bars
GOLD <- "C9A227"               # accent: cover / divider rules
STEEL <- "3E6E8E"
SLATE <- "6E7C8C"
LSLATE <- "A9B4C0"
BGOLD <- "D8B04A"

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

# Append a shape (drawn in front of everything already on the slide/layout).
add_shape <- function(doc, fragment) {
  tree <- xml_find_first(doc, "//p:cSld/p:spTree", ns)
  xml_add_child(tree, read_xml(fragment))
  invisible(doc)
}

# Insert a shape at the back (behind the placeholders), for full-bleed
# backgrounds that must not cover the title text.
add_background <- function(doc, fragment) {
  tree <- xml_find_first(doc, "//p:cSld/p:spTree", ns)
  first <- xml_find_first(tree, "./p:sp | ./p:pic | ./p:graphicFrame | ./p:grpSp", ns)
  if (inherits(first, "xml_missing")) {
    xml_add_child(tree, read_xml(fragment))
  } else {
    xml_add_sibling(first, read_xml(fragment), .where = "before")
  }
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

master_title_box <- function(master_path) {
  master <- read_xml(master_path)
  xfrm <- xml_find_first(master, "//p:sp[.//p:ph[@type='title']]//a:xfrm", ns)
  off <- xml_find_first(xfrm, "./a:off", ns)
  ext <- xml_find_first(xfrm, "./a:ext", ns)
  box <- list(x = as.numeric(xml_attr(off, "x")),
              y = as.numeric(xml_attr(off, "y")),
              cx = as.numeric(xml_attr(ext, "cx")),
              cy = as.numeric(xml_attr(ext, "cy")))
  stopifnot(all(vapply(box, is.finite, logical(1))))
  box
}

# ---- colour scheme -------------------------------------------------------

# Replace the dated Office palette with the navy/gold identity. accent1 is the
# primary (what use_brand() reads as brand_color_primary and single-series bars
# pick up); dk2 doubles the navy so schemeClr references cohere.
set_clrscheme <- function(theme_path) {
  doc <- read_xml(theme_path)
  set_one <- function(tag, hex) {
    node <- xml_find_first(doc, sprintf("//a:clrScheme/a:%s/a:srgbClr", tag), ns)
    if (!inherits(node, "xml_missing")) xml_set_attr(node, "val", hex)
  }
  set_one("dk2", NAVY)
  set_one("lt2", "EEF1F5")
  set_one("accent1", NAVY)
  set_one("accent2", GOLD)
  set_one("accent3", STEEL)
  set_one("accent4", SLATE)
  set_one("accent5", LSLATE)
  set_one("accent6", BGOLD)
  write_xml(doc, theme_path)
  invisible(theme_path)
}

# ---- typography ----------------------------------------------------------

# Officer's base master sets a 44pt title in theme-text colour, which turns a
# descriptive survey-question headline into overflowing lines. Bring the master
# defaults down and colour titles navy, so every content slide reads as branded.
set_master_style <- function(master_path) {
  doc <- read_xml(master_path)
  title_ppr <- xml_find_first(doc, "//p:txStyles/p:titleStyle/a:lvl1pPr", ns)
  if (!inherits(title_ppr, "xml_missing")) {
    xml_set_attr(title_ppr, "algn", "l")   # left-align content titles
  }
  title <- xml_find_first(
    doc, "//p:txStyles/p:titleStyle/a:lvl1pPr/a:defRPr", ns
  )
  if (!inherits(title, "xml_missing")) {
    xml_set_attr(title, "sz", "2400")
    fill <- xml_find_first(title, "./a:solidFill", ns)
    if (!inherits(fill, "xml_missing")) xml_remove(fill)
    xml_add_child(title, read_xml(sprintf(
      '<a:solidFill xmlns:a="%s"><a:srgbClr val="%s"/></a:solidFill>',
      ns[["a"]], NAVY)), .where = 0)
  }
  body <- xml_find_first(doc, "//p:txStyles/p:bodyStyle/a:lvl1pPr/a:defRPr", ns)
  if (!inherits(body, "xml_missing")) xml_set_attr(body, "sz", "1400")
  write_xml(doc, master_path)
  invisible(master_path)
}

# Style a layout's placeholder text (size / colour / alignment / weight) by
# editing its txBody list style, so cover and divider titles differ from the
# content default without touching the master.
style_ph <- function(path, ph_type, sz = NULL, colour = NULL,
                     algn = NULL, bold = NULL) {
  doc <- read_xml(path)
  sp <- xml_find_first(doc, sprintf("//p:sp[.//p:ph[@type='%s']]", ph_type), ns)
  if (inherits(sp, "xml_missing")) return(invisible(path))
  txbody <- xml_find_first(sp, ".//p:txBody", ns)
  lst <- xml_find_first(txbody, "./a:lstStyle", ns)
  if (inherits(lst, "xml_missing")) {
    bodypr <- xml_find_first(txbody, "./a:bodyPr", ns)
    xml_add_sibling(bodypr, read_xml(sprintf('<a:lstStyle xmlns:a="%s"/>',
                                             ns[["a"]])), .where = "after")
    lst <- xml_find_first(txbody, "./a:lstStyle", ns)
  }
  lvl <- xml_find_first(lst, "./a:lvl1pPr", ns)
  if (inherits(lvl, "xml_missing")) {
    xml_add_child(lst, read_xml(sprintf('<a:lvl1pPr xmlns:a="%s"/>', ns[["a"]])))
    lvl <- xml_find_first(lst, "./a:lvl1pPr", ns)
  }
  if (!is.null(algn)) xml_set_attr(lvl, "algn", algn)
  defrpr <- xml_find_first(lvl, "./a:defRPr", ns)
  if (inherits(defrpr, "xml_missing")) {
    xml_add_child(lvl, read_xml(sprintf('<a:defRPr xmlns:a="%s"/>', ns[["a"]])))
    defrpr <- xml_find_first(lvl, "./a:defRPr", ns)
  }
  if (!is.null(sz)) xml_set_attr(defrpr, "sz", as.character(sz))
  if (!is.null(bold)) xml_set_attr(defrpr, "b", if (bold) "1" else "0")
  if (!is.null(colour)) {
    old <- xml_find_first(defrpr, "./a:solidFill", ns)
    if (!inherits(old, "xml_missing")) xml_remove(old)
    xml_add_child(defrpr, read_xml(sprintf(
      '<a:solidFill xmlns:a="%s"><a:srgbClr val="%s"/></a:solidFill>',
      ns[["a"]], colour)), .where = 0)
  }
  write_xml(doc, path)
  invisible(path)
}

# Move a layout placeholder's left edge and width (keeps its vertical box), so
# the cover subtitle lines up under the title instead of sitting inset.
set_ph_x <- function(path, ph_type, x, cx) {
  doc <- read_xml(path)
  xfrm <- xml_find_first(
    doc, sprintf("//p:sp[.//p:ph[@type='%s']]//a:xfrm", ph_type), ns
  )
  if (inherits(xfrm, "xml_missing")) return(invisible(path))
  off <- xml_find_first(xfrm, "./a:off", ns)
  ext <- xml_find_first(xfrm, "./a:ext", ns)
  if (!inherits(off, "xml_missing")) xml_set_attr(off, "x", emu(x))
  if (!inherits(ext, "xml_missing")) xml_set_attr(ext, "cx", emu(cx))
  write_xml(doc, path)
  invisible(path)
}

# Give every text placeholder shrink-to-fit, so text that still runs long is
# scaled down by the viewer rather than spilling out of its box.
ensure_autofit <- function(path) {
  doc <- read_xml(path)
  for (bodypr in xml_find_all(doc, "//p:sp[.//p:ph]//p:txBody/a:bodyPr", ns)) {
    for (af in xml_find_all(
      bodypr, "./a:normAutofit | ./a:spAutoFit | ./a:noAutofit", ns
    )) {
      xml_remove(af)
    }
    xml_add_child(bodypr, read_xml(sprintf('<a:normAutofit xmlns:a="%s"/>',
                                           ns[["a"]])))
  }
  write_xml(doc, path)
  invisible(path)
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

  # 3. brand palette (both templates), so charts, chrome and any use_brand()
  # extraction share the same navy/gold identity.
  set_clrscheme(file.path(work, "ppt", "theme", "theme1.xml"))

  # 4. typography: navy 24pt titles, 14pt body, shrink-to-fit everywhere, and
  # larger cover / section wording. Applies to both templates.
  set_master_style(master_path)
  # cover title + subtitle
  style_ph(file.path(lay_dir, "slideLayout1.xml"), "ctrTitle",
           sz = 4000, algn = "l", bold = TRUE)
  style_ph(file.path(lay_dir, "slideLayout1.xml"), "subTitle",
           sz = 1800, algn = "l")
  # section-divider word
  style_ph(file.path(lay_dir, "slideLayout3.xml"), "title",
           sz = 4000, algn = "l", bold = TRUE)
  for (f in c(master_path,
              list.files(lay_dir, pattern = "^slideLayout[0-9]+[.]xml$",
                         full.names = TRUE))) {
    ensure_autofit(f)
  }

  # 5. styling: full-bleed navy cover and dividers with white text, one slim
  # navy rule under every content title.
  if (decorate) {
    master_box <- master_title_box(master_path)
    rule_h <- 25400               # 2pt
    gap <- round(0.06 * EMU_IN)
    accent_cx <- round(2.0 * EMU_IN)

    # Content-bearing layouts: a single navy rule under the title, nothing else.
    content <- c("slideLayout2.xml", "slideLayout4.xml", "slideLayout5.xml",
                 "slideLayout6.xml", "slideLayout8.xml")
    for (f in content) {
      path <- file.path(lay_dir, f)
      doc <- read_xml(path)
      box <- title_box(doc, master_box)
      add_shape(doc, rect_sp(box$x, box$y + box$cy + gap, box$cx, rule_h,
                             NAVY, 900, "Title Rule"))
      write_xml(doc, path)
    }

    # Cover: full-bleed navy with white title (styled above), gold accent rule
    # under the title and a white subtitle.
    style_ph(file.path(lay_dir, "slideLayout1.xml"), "ctrTitle", colour = "FFFFFF")
    style_ph(file.path(lay_dir, "slideLayout1.xml"), "subTitle", colour = "DCE4EE")
    path <- file.path(lay_dir, "slideLayout1.xml")
    box <- title_box(read_xml(path), master_box)
    set_ph_x(path, "subTitle", box$x, box$cx)   # subtitle left edge under title
    doc <- read_xml(path)
    add_background(doc, rect_sp(0, 0, WIDE_CX, SLIDE_CY, NAVY, 890, "Cover"))
    add_shape(doc, rect_sp(box$x, box$y + box$cy + gap, accent_cx, 38100,
                           GOLD, 891, "Cover Accent"))
    write_xml(doc, path)

    # Section dividers: full-bleed navy with a large white section word and a
    # gold accent rule above it.
    style_ph(file.path(lay_dir, "slideLayout3.xml"), "title", colour = "FFFFFF")
    path <- file.path(lay_dir, "slideLayout3.xml")
    doc <- read_xml(path)
    add_background(doc, rect_sp(0, 0, WIDE_CX, SLIDE_CY, NAVY, 892, "Divider"))
    box <- title_box(doc, master_box)
    add_shape(doc, rect_sp(box$x, box$y - gap - 38100, accent_cx, 38100,
                           GOLD, 893, "Divider Accent"))
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
