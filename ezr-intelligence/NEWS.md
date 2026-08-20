# ezrintelligence 0.1.0

First release. The language-model helpers of the `ezr*` family now live in
their own package, so the analysis packages stay free of a model dependency.

## Summarise

* **`ai_summarise()`** sends one finished table to a model with a named prompt
  template and returns the text. Only the table you pass is sent.
* **`ai_report_sections()`** runs the same over a named list of sections,
  each with its own template, title and context, and returns a named list of
  summaries.
* **`ai_slide_text()`** drafts the headline title and three or four takeaway
  bullets a chart slide needs, returned as plain strings for any deck builder.
  A failed call messages and returns `NULL` in that slot.
* **`ai_chat()`** opens the connection, reusable across calls. Any provider
  `ellmer` exposes works, including a locally served model through
  `"ollama"`.

## Context

* **`ai_context()`** bundles sample size, question wording, base, fieldwork
  and precision into the prompt, so the templates flag differences inside the
  margin of error instead of narrating noise. Given raw data it derives the
  sample size, and from it a worst-case margin-of-error note; pass `precision`
  yourself when you have a real design-effect figure.

## Prompts

* Nine built-in templates: `key_findings`, `exec_summary`,
  `drivers_barriers`, `slide_title`, `slide_bullets`, `thematic_analysis`,
  `segment_comparison`, `methodology`, `full_report`. Each carries a system
  prompt, a default instruction and an output contract pinning the answer's
  shape, over shared ground rules (quote only present figures, respect the
  margin of error, name the base).
* **`list_prompts()`**, **`get_prompt()`** and **`register_prompt()`** read
  and extend the registry.

## Keys and configuration

* **`set_llm_key()`** and friends store API keys in the operating system
  credential store under the `"ezrintelligence"` service, falling back to the
  conventional environment variable.
* **`ezrintelligence_options()`** sets the default provider, model, template,
  prompt row limit and confidence level; a YAML profile persists them across
  sessions. Keys are never written to a profile.
