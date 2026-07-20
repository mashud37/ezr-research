# A finished management deck from the bundled podracing_survey data.
#
#   Rscript podracing-deck.R      # writes outputs/podracing-deck.pptx
#
# The point of this example is the shape of a deck that survives a real
# readout: a story that runs headline -> cause -> segment -> evidence, slide
# titles that state the finding rather than name the chart, and every number
# in the prose computed from the data rather than typed in. Change the survey
# and the narrative re-writes itself.
#
# Swap in an organisation template with use_brand("org-template.pptx") before
# building; otherwise the deck uses the bundled 16:9 template. For plain white
# slides, pass style = "plain" to report_new().

library(ezrsurvey)

use_dataset(podracing_survey)

# ---- figures the narrative is written from ---------------------------------
# Computed once, then quoted in titles and commentary, so the words can never
# drift away from the chart beside them.

n_total <- nrow(podracing_survey)
nps <- calc_nps(nps_value)$nps

grp <- nps_group(podracing_survey$nps_value)
share_promoter <- mean(grp == 1, na.rm = TRUE) * 100
share_detractor <- mean(grp == -1, na.rm = TRUE) * 100

ipm <- ipm_model(nps_value, "ratings_")
strongest <- ipm[order(-ipm$performance), ][1, ]
top_driver <- ipm[order(-ipm$importance), ][1, ]

# "Fix first" is the upper-left quadrant: features below the OK threshold that
# also carry weight in the model. Ranking by performance alone would nominate
# whatever scores worst even if nobody decides on it.
bad_band <- bands_rating_3()$to[1]                    # 3 on a 1-5 scale
underperforming <- ipm[ipm$performance < bad_band, ]
priority <- underperforming[order(-underperforming$importance), ]

demo <- calc_percentage(demo_gender, sort = "desc")
mean_age <- calc_summary(demo_age)$mean

by_region <- calc_nps(nps_value, by = region)
by_region <- by_region[order(-by_region$nps), ]
best_region <- by_region[1, ]
worst_region <- by_region[nrow(by_region), ]

motiv <- calc_percentage_multi("motivations_", id = respondent_id,
                               sort = "desc")
top_motive <- motiv[1, ]

pct <- function(x) sprintf("%.0f%%", x)

# ---- charts ----------------------------------------------------------------

chart_gender <- calc_percentage(demo_gender, sort = "desc") %>% plot_bars()

chart_motivations <- motiv %>% plot_bars(label = option)

chart_gauge <- plot_nps_gauge(nps)

chart_nps <- plot_nps(nps_value)

chart_ratings <- podracing_survey %>%
  select(starts_with("ratings_")) %>%
  pivot_longer(everything(), names_to = "feature", values_to = "level") %>%
  filter(level != "") %>%
  mutate(feature = sub("^ratings_", "", feature),
         level = paste0(recode_likert(level), " - ", level)) %>%
  count(feature, level) %>%
  group_by(feature) %>%
  mutate(pct = n / sum(n) * 100) %>%
  ungroup() %>%
  plot_stacked_rating(feature, level)

chart_ipm <- plot_ipm(ipm)

chart_quotes <- sample_comments_diverse(nps_com, show_com, n = 8, seed = 42) %>%
  plot_quotes_tree()

# ---- the deck --------------------------------------------------------------

doc <- report_new("pptx")

doc <- doc %>%
  report_add_slide("Pod-Racing Fan Survey",
                   layout = "Title Slide") %>%
  report_add_slide("Executive summary") %>%
  report_add_text(c(
    sprintf("The fan base recommends pod racing, but narrowly: a Net Promoter Score of %+d across %s respondents.",
            nps, format(n_total, big.mark = ",")),
    sprintf("Enthusiasm is built on the spectacle. %s come for %s, and %s is the best-rated part of the experience at %.2f out of 5.",
            pct(top_motive$pct), top_motive$option, strongest$feature,
            strongest$performance),
    sprintf("%d of %d rated features sit below the acceptable threshold: %s.",
            nrow(priority), nrow(ipm),
            paste(priority$feature, collapse = ", ")),
    sprintf("The problem is regional, not universal: %s scores %+d against %s at %+d.",
            best_region$region, best_region$nps,
            worst_region$region, worst_region$nps),
    sprintf("%s is the highest-return fix: it is the weightiest driver in the model at %s of explained importance and still rated only %.2f.",
            priority$feature[1], pct(priority$importance[1]),
            priority$performance[1])
  ))

# --- 1. the headline
doc <- doc %>%
  report_add_slide("The headline", layout = "Section Header") %>%
  report_add_slide(sprintf("Fans recommend pod racing, but only just: NPS %+d",
                           nps)) %>%
  report_add_plot(chart_gauge) %>%
  report_add_slide(sprintf("A split audience, not a lukewarm one: %s promoters against %s detractors",
                           pct(share_promoter), pct(share_detractor))) %>%
  report_add_plot(chart_nps)

# --- 2. what moves the score
doc <- doc %>%
  report_add_slide("What moves the score", layout = "Section Header") %>%
  report_add_slide(sprintf("%s is the fix-first driver: weightiest in the model, rated only %.2f",
                           priority$feature[1], priority$performance[1])) %>%
  report_add_plot(chart_ipm) %>%
  report_add_slide(sprintf("%d of %d features rate below the acceptable threshold",
                           nrow(priority), nrow(ipm))) %>%
  report_add_plot(chart_ratings) %>%
  report_add_slide("Reading the driver matrix") %>%
  report_add_text(c(
    sprintf("%s carries the most weight in the recommendation model, at %s of explained importance.",
            top_driver$feature, pct(top_driver$importance)),
    sprintf("Below the 3.0 threshold: %s.",
            paste(sprintf("%s (%.2f)", priority$feature, priority$performance),
                  collapse = ", ")),
    sprintf("%s is the strength to protect at %.2f: it is what fans already come for.",
            strongest$feature, strongest$performance),
    "Priority is the upper-left quadrant: high importance, low performance. Features that score badly but drive nothing can wait."
  ))

# --- 3. who and where
doc <- doc %>%
  report_add_slide("Who and where", layout = "Section Header") %>%
  report_add_slide(sprintf("%s leads on advocacy, %s lags by %d points",
                           best_region$region, worst_region$region,
                           best_region$nps - worst_region$nps)) %>%
  report_add_table(by_region) %>%
  report_add_slide(sprintf("%s of fans come for the %s",
                           pct(top_motive$pct), top_motive$option)) %>%
  report_add_plot(chart_motivations) %>%
  report_add_slide(sprintf("%s of respondents are %s, average age %.0f",
                           pct(demo$pct[1]), tolower(as.character(demo[[1]][1])),
                           mean_age)) %>%
  report_add_plot(chart_gender)

# --- 4. evidence and method
doc <- doc %>%
  report_add_slide("In their own words", layout = "Section Header") %>%
  report_add_slide("Fans praise the spectacle and question the cost") %>%
  report_add_plot(chart_quotes) %>%
  report_add_slide("How to read this report") %>%
  report_add_text(precision_summary(demo_gender,
                                    starts_with("ratings_"))$bullets)

report_save(doc, "outputs/podracing-deck.pptx")

# ---- the one-call route ----------------------------------------------------
# When the deck is just "these charts, one per slide", report_deck() does the
# whole thing; with ai = TRUE it also drafts takeaway bullets per slide.
#
#   report_deck(
#     list("Recommendation" = chart_gauge,
#          "Drivers"        = chart_ipm,
#          "Motivations"    = chart_motivations),
#     path = "outputs/quick-deck.pptx",
#     title = "Pod-Racing Fan Survey"
#   )

clear_dataset()
