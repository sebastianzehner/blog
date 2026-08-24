---
name: blowfish-shortcodes
description: >
  Use this skill whenever writing, revising, or formatting blog posts or other
  content pages for a Hugo website using the Blowfish theme. Apply it ALWAYS
  when Blowfish blog content is being created (even without an explicit request
  to use "shortcodes") to pick the right Blowfish shortcodes (alert, admonition,
  tabs, gallery, figure, video, youtubeLite, github/gitlab/gitea/
  codeberg/forgejo/huggingface/ansible cards, mermaid, chart, katex, timeline,
  accordion, lead, badge, keyword, button, cta, stats, steps, feature-grid,
  carousel, typeit, swatches, icon, gist, etc.) instead of plain text/Markdown where it genuinely helps. Trigger
  signals: "write a blog post", "Blowfish", "Hugo shortcode", requests for
  callout/warning boxes, image galleries, tabs, multi-language code examples, or
  embedded repos/videos/diagrams within an article.
---
# Blowfish Shortcodes for Blog Posts

This skill defines WHEN to use a particular Blowfish shortcode instead of plain Markdown, and HOW to use it correctly.
The full parameter reference with all examples lives in the theme's own docs:

- Location: `themes/blowfish/exampleSite/content/docs/shortcodes/index.md`
- Relative to the blog root, shipped in the submodule, always in sync with the installed theme version
  Read the relevant section as soon as a specific shortcode is needed (don't guess parameters from memory).

## Ground rules

1. **Use sparingly.** Shortcodes are a stylistic tool, not a checklist to fill. An article built from fifteen `alert` boxes reads worse than one with two well-placed ones. Rule of thumb: only use a shortcode when it adds real value for the reader (visual structure, interactivity, clarity) — not as decoration.
2. **Syntax:** `{{< shortcodeName param="value" >}}content{{< /shortcodeName >}}`. For shortcodes whose content is meant to be parsed purely as Markdown and nothing else (e.g. `rtl`/`ltr`), use `{{% %}}` delimiters instead — see the LTR/RTL section in the theme's shortcode docs.
3. When writing `.md` content files for Hugo/Blowfish, place shortcodes directly inline in the body text, not as a separate element.
4. After inserting a shortcode, double-check that parameter names and required fields are correct (see that shortcode's section in the theme's shortcode docs).
5. If it's unclear whether a given shortcode is active/wanted in the project (especially ones that make external API calls at build time, like `github`, `huggingface`, `ansible`), ask or offer a plain-Markdown alternative instead.

## Decision guide: content need → shortcode

| If the article needs...                                                                               | Shortcode                                                                                        |
| ----------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Warning/callout box                                                                                   | `alert` or `admonition` (admonition = more portable Markdown blockquote syntax, e.g. `> [!TIP]`) |
| Call-to-action button                                                                                 | `cta` (self-contained: `url`, `label`, `style`); use `button` when you need `pageRef`, `target`, or `rel` |
| Collapsible detail sections / FAQ                                                                     | `accordion` + `accordionItem`                                                                    |
| Multiple images as a slider                                                                           | `carousel`                                                                                       |
| Image grid / gallery                                                                                  | `gallery` (+ `figure` for captions)                                                              |
| Single image with a caption                                                                           | `figure` (or plain Markdown image syntax)                                                        |
| Video (local or external)                                                                             | `video`                                                                                          |
| YouTube video                                                                                         | `youtubeLite`                                                                                    |
| Platform- or language-dependent instructions (e.g. Windows/macOS/Linux, or code in several languages) | `tabs` + `tab`                                                                                   |
| Numbered process steps, tutorials, roadmaps                                                           | `steps` + `step`                                                                                   |
| Key metrics/figures (e.g. performance numbers, comparisons in cards)                                  | `stats` + `stat`                                                                                   |
| Feature overview with icons (project features, what-you-get sections)                                 | `feature-grid` + `feature` (3 or 4 columns)                                                        |
| Career history, milestones, changelog-style chronology                                                | `timeline` + `timelineItem`                                                                      |
| Diagram/flowchart generated from text                                                                 | `mermaid`                                                                                        |
| Data visualization (bars, lines, ...)                                                                 | `chart`                                                                                          |
| Mathematical formulas                                                                                 | `katex`                                                                                          |
| Emphasized intro sentence/teaser                                                                      | `lead`                                                                                           |
| Single highlighted label/tag                                                                          | `badge`                                                                                          |
| Highlighted list of skills/keywords                                                                   | `keyword` + `keywordList`                                                                        |
| Live card for a GitHub/GitLab/Gitea/Codeberg/Forgejo repo                                             | `github` / `gitlab` / `gitea` / `codeberg` / `forgejo`                                           |
| Live card for a Hugging Face model/dataset                                                            | `huggingface`                                                                                    |
| Card for an Ansible Galaxy role/collection                                                            | `ansible`                                                                                        |
| Embed a GitHub Gist                                                                                   | `gist`                                                                                           |
| Import code from an external source instead of copy-paste                                             | `codeimporter`                                                                                   |
| Embed an external Markdown file                                                                       | `mdimporter`                                                                                     |
| Embed another article from the same site                                                              | `article`                                                                                        |
| List of related/recent articles                                                                       | `list`                                                                                           |
| Show a color palette                                                                                  | `swatches`                                                                                       |
| Inline icon within body text                                                                          | `icon`                                                                                           |
| Obfuscated mailto link                                                                                | `email`                                                                                          |
| Typewriter animation effect                                                                           | `typeit`                                                                                         |
| Mixed text direction (RTL text inside an LTR article)                                                 | `rtl` / `ltr`                                                                                    |

## Workflow

1. Draft or revise the article content/structure as requested.
2. Use the table above to check which sections would benefit from a shortcode.
3. For each chosen shortcode, consult the theme's shortcode docs (path in the intro) to get the exact parameters/required fields/syntax right.
4. Insert the shortcode into the Markdown, fill in required parameters, and only set optional parameters when they serve a purpose.
5. Briefly summarize the result: which shortcodes were used where and why.

## Reference

Full parameter tables and code examples for every shortcode: `themes/blowfish/exampleSite/content/docs/shortcodes/index.md` (bundled in the theme submodule, always in sync with the installed theme version — no separate maintenance needed).
