# A full management read-out of the bundled podracing_survey, the way an agency
# would present it back to a client: a cover, chaptered sections, and every
# question block in the questionnaire worked through in turn.
#
#   Rscript podracing-deck.R      # writes ezrsurvey-outputs/podracing-deck.pptx
#
# The point of this example is two things at once:
#
#   1. The SHAPE of a deck script -- one line per slide. Each report_slide()
#      call does the whole job (calculate, plot, place), so reordering the
#      read-out is reordering the lines, and every content title is the survey
#      question the slide answers. report_section() drops a single-word divider
#      between chapters.
#
#   2. A REAL read-out, not an illustration. It covers recommendation, the six
#      experience ratings and their drivers, motivations, the three sponsor
#      brands, the full respondent profile, favourite drivers, open-text
#      comments and a methods appendix -- the whole questionnaire, not a
#      token chart or two.
#
# Swap in an organisation template with use_brand("org-template.pptx") before
# building; otherwise the deck uses the bundled styled 16:9 template. For plain
# white slides, pass style = "plain" to report_new().

library(ezrsurvey)

# One brand call so single-series bars carry the deck's navy identity. In real
# use this points at your PowerPoint template -- use_brand("brand/org.pptx") --
# and reads the palette straight out of it.
use_brand(colors = c("#12314E", "#3E6E8E", "#C9A227"))

# Derive the one profile column that is not in the raw export: age bands. Real
# workflows prepare a handful of columns like this up front, then read them as
# plain columns on the slides.
use_dataset(podracing_survey %>% mutate(age_band = recode_age(demo_age)))

# The importance/performance model is referenced by the summary gauge and the
# driver matrix, so it is built once; everything else is calculated inline, on
# the slide that shows it.
ipm <- ipm_model(nps_value, "ratings_")
quality <- mean(ipm$performance, na.rm = TRUE)

# Three charts want a long, per-level percentage table -- the only preparation
# that does not fit on a single slide line. Each is a small named step.
rating_mix <- function() {
  podracing_survey %>%
    select(starts_with("ratings_")) %>%
    pivot_longer(everything(), names_to = "feature", values_to = "level") %>%
    filter(level != "") %>%
    mutate(feature = sub("^ratings_", "", feature),
           level = paste0(recode_likert(level), " - ", level)) %>%
    count(feature, level) %>%
    group_by(feature) %>%
    mutate(pct = n / sum(n) * 100) %>%
    ungroup()
}

like_levels <- c("Very unlikeable", "Unlikeable", "Likeable", "Very likeable")
sponsor_likeability <- function() {
  podracing_survey %>%
    select(starts_with("partner_likeability_")) %>%
    pivot_longer(everything(), names_to = "brand", values_to = "level") %>%
    filter(level != "") %>%
    mutate(brand = sub("^partner_likeability_", "", brand),
           level = paste0(recode_likert(level, levels = like_levels),
                          " - ", level)) %>%
    count(brand, level) %>%
    group_by(brand) %>%
    mutate(pct = n / sum(n) * 100) %>%
    ungroup()
}

sponsor_recall <- function() {
  podracing_survey %>%
    select(starts_with("partner_recall_")) %>%
    pivot_longer(everything(), names_to = "brand", values_to = "answer") %>%
    filter(answer != "") %>%
    mutate(brand = sub("^partner_recall_", "", brand)) %>%
    group_by(brand) %>%
    summarise(pct = round(mean(answer == "Sponsor") * 100), .groups = "drop")
}

# ---- the deck: one line per slide ------------------------------------------

doc <- report_new("pptx") %>%
  report_title_slide(
    "Pod-Racing Fan Survey 2026",
    subtitle = "1,000 fans surveyed after the Boonta Eve meeting  |  Fieldwork 2026") %>%

  report_section("SUMMARY") %>%
  report_slide("Executive summary", c(
    "Fans are strong advocates: the Net Promoter Score sits firmly positive.",
    "Atmosphere and speed are the standout strengths and the biggest draw.",
    "Commentary and value for money lag, and are the clearest places to improve.",
    "Sponsor recognition is uneven, leaving room to strengthen partner visibility.")) %>%
  report_slide(
    "Overall, how do fans rate pod racing and how likely are they to recommend it?",
    plot_gauges(c("Net Promoter Score" = calc_nps(nps_value)$nps,
                  "Average quality rating" = quality),
                scales = c("nps", "rating"))) %>%

  report_section("RECOMMENDATION") %>%
  report_slide("How likely are you to recommend pod racing to a friend?",
               plot_nps(nps_value)) %>%
  report_slide("Does advocacy hold up across the fan base?",
               calc_nps(nps_value, by = region)) %>%
  report_slide("How likely are you to attend another meeting?",
               plot_bars(calc_percentage(satis_return, sort = "desc"))) %>%

  report_section("RATINGS") %>%
  report_slide("How would you rate each aspect of the pod-racing experience?",
               plot_stacked_rating(rating_mix(), feature, level)) %>%
  report_slide("Which aspects matter most for recommendation, and which fall short?",
               plot_ipm(ipm)) %>%

  report_section("MOTIVATIONS") %>%
  report_slide("What draws you to pod racing?",
               plot_bars(calc_percentage_multi("motivations_", id = respondent_id,
                                               sort = "desc"), label = option)) %>%

  report_section("SPONSORS") %>%
  report_slide("Which race sponsors do fans correctly recognise?",
               plot_bars(sponsor_recall(), label = brand, sort = "desc")) %>%
  report_slide("How likeable are the race sponsors?",
               plot_stacked_rating(sponsor_likeability(), brand, level)) %>%

  report_section("DEMOGRAPHICS") %>%
  report_slide("What is your gender?",
               plot_bars(calc_percentage(demo_gender, sort = "desc"))) %>%
  report_slide("How old are you?",
               plot_bars(calc_percentage(age_band), sort = "none")) %>%
  report_slide("What is your highest level of education?",
               plot_bars(calc_percentage(demo_edu, sort = "desc"))) %>%
  report_slide("What is your employment status?",
               plot_bars(calc_percentage(demo_job, sort = "desc"))) %>%
  report_slide("Which sector do you work in?",
               plot_bars(calc_percentage(demo_sector, sort = "desc"))) %>%
  report_slide("Where in the world do you follow pod racing from?",
               plot_bars(calc_percentage(region, sort = "desc"))) %>%

  report_section("FANDOM") %>%
  report_slide("Which race meeting did you attend?",
               plot_bars(calc_percentage(race_attended, sort = "desc"))) %>%
  report_slide("Who is your favourite pod-racing driver?",
               plot_bars(calc_percentage(fav_driver, sort = "desc"))) %>%

  report_section("COMMENTS") %>%
  report_slide("In your own words, what do you think of pod racing?",
               plot_quotes_tree(sample_comments_diverse(nps_com, show_com,
                                                        n = 9, seed = 42))) %>%

  report_section("APPENDIX") %>%
  report_slide("How was the survey run?",
               plot_bars(calc_percentage(collector, sort = "desc"))) %>%
  report_slide("How to read this report",
               precision_summary(demo_gender, starts_with("ratings_"))$bullets)

report_save(doc, "ezrsurvey-outputs/podracing-deck.pptx")

clear_dataset()
clear_brand()

# ---- the one-call route ----------------------------------------------------
# When the deck is just "these charts, one per slide", report_deck() does the
# whole thing in one call.
#
#   report_deck(
#     list("How likely to recommend?" = plot_nps(podracing_survey, nps_value),
#          "Which aspects fall short?" = plot_ipm(ipm)),
#     path = "ezrsurvey-outputs/quick-deck.pptx",
#     title = "Pod-Racing Fan Survey"
#   )
