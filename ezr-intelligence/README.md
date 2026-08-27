# ezrintelligence

> ezrintelligence: the language-model helpers of the `ezr*` family, split out
> so the analysis packages stay free of a model dependency.

`ezrintelligence` writes the findings that go next to a table. You do the
analysis wherever you already do it (`ezrsurvey`, `ezrmodel`, plain dplyr),
then hand the finished summary table to a model together with a named prompt
template and the study's context, and get back the paragraph, the bullets or
the slide title. Nothing here re-analyses your data: the table you pass is the
table the model sees, and raw respondent rows never leave your machine.

## Installation

```r
# install.packages("pak")
pak::pak("mashud37/ezrintelligence")
```

The model calls go through [`ellmer`](https://ellmer.tidyverse.org), and key
storage through `keyring`; both are optional and only needed when you actually
call a model.

## Setup

```r
library(ezrintelligence)

set_llm_key("openai")     # prompts, without echoing; stored in the OS keyring
has_llm_key("openai")
```

Keys never live in your scripts. The lookup order is the `"ezrintelligence"`
keyring service, then the conventional environment variable
(`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, ...). Provider `"ollama"` needs no key
at all: point it at a locally served open-weight model when the tables must
not leave the machine.

## The 60-second tour

```r
answers <- data.frame(
  answer = c("Very satisfied", "Satisfied", "Neither", "Dissatisfied"),
  pct = c(31, 42, 18, 9)
)

# 1. One table, one paragraph
ai_summarise(answers, template = "exec_summary")

# 2. Give the model the study, not just the table. A sample size and a margin
#    of error make the templates flag small differences instead of narrating
#    them.
ctx <- ai_context(
  n = 1000,
  question = "How satisfied are you overall?",
  base = "All respondents",
  fieldwork = "12-19 May 2026, online panel"
)
ai_summarise(answers, template = "key_findings", context = ctx)

# 3. A whole report's sections in one call
ai_report_sections(
  list(
    satisfaction = answers,
    nps = list(data = nps_table, template = "exec_summary")
  ),
  context = ctx
)

# 4. The two pieces of text a chart slide needs
chat <- ai_chat()
text <- ai_slide_text(answers, title = "Satisfaction", chat = chat,
                      context = ctx)
text$title     # "Satisfaction holds at three in four"
text$bullets   # c("73% satisfied or better", ...)
```

## Commands

Calling the package with no arguments is not a thing here; every task is one
function.

| Task | Function |
| --- | --- |
| Open a reusable connection | `ai_chat()` |
| Summarise one table | `ai_summarise()` |
| Summarise a named list of report sections | `ai_report_sections()` |
| Draft a slide title and takeaway bullets | `ai_slide_text()` |
| Describe the study behind the tables | `ai_context()` |
| See / read / add prompt templates | `list_prompts()`, `get_prompt()`, `register_prompt()` |
| Manage API keys | `set_llm_key()`, `get_llm_key()`, `has_llm_key()`, `delete_llm_key()`, `list_llm_keys()` |
| Session defaults | `ezrintelligence_options()`, `reset_ezrintelligence_options()` |
| Persist defaults | `use_ezrintelligence_profile()`, `edit_ezrintelligence_profile()`, `save_ezrintelligence_profile()`, `load_ezrintelligence_profile()` |

## Prompt templates

The `template` argument decides how the answer is written, not what it says.
Nine ship built in:

| Template | Writes |
| --- | --- |
| `key_findings` | 3-5 bullets, headline number first |
| `exec_summary` | One executive-summary paragraph |
| `drivers_barriers` | Findings split into what to protect and what to fix |
| `slide_title` | One headline title, max 12 words |
| `slide_bullets` | 3-4 takeaway bullets for a slide body |
| `thematic_analysis` | Named themes with illustrative quotes |
| `segment_comparison` | The few segment gaps worth acting on |
| `methodology` | A plain-language precision and limitations passage |
| `full_report` | A connected multi-section narrative |

Every built-in template inherits the same ground rules: quote only figures
present in the data, treat differences smaller than the margin of error as
noise and say so, name the base, write for a reader who will act on the
findings. Each also carries an `output_contract` pinning the answer's shape,
so a bullet list comes back as a bullet list.

Add your own:

```r
register_prompt(
  "risks",
  system = "You are a cautious risk analyst.",
  instruction = "List the top risks implied by this table.",
  description = "Top risks implied by the data.",
  output_contract = "Markdown bullets, most severe first."
)
```

## Study context

`ai_context()` is the difference between a generic summary and an analyst's
one. Pass raw respondent-level data and it derives the sample size, and from
that a worst-case margin-of-error note:

```r
ai_context(my_survey_data, question = "How satisfied are you overall?")
```

The derived note is the textbook figure for a simple random sample at
`p = 0.5`: it ignores weighting, clustering and finite populations. When you
have a real design-effect calculation, pass it as `precision` yourself.

## Defaults

```r
ezrintelligence_options(provider = "anthropic", template = "exec_summary")
```

`provider`, `model`, `template`, `max_rows` (table rows sent in a prompt) and
`confidence_z` (the z behind the derived margin of error) are ordinary R
options under the `ezrintelligence.` prefix. Persist them with
`use_ezrintelligence_profile()`, which writes a commented YAML file to the
per-user config directory. API keys are never written to a profile.

## Cost and caveats

> Model calls are billed by the provider, per token. Costs depend on the
> provider, the model and how much table you send, so no figure here would
> survive contact with your account: measure a representative call before
> extrapolating. `max_rows` (default 50) caps the table rows in a prompt,
> which is the part of the bill you control.

Model output is a draft. The templates make it hard for a model to invent a
number, but nothing makes it impossible: read what comes back against the
table before it reaches a reader.

## License

MIT © Andreas Schellewald
