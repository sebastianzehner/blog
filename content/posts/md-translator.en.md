---
title: The challenges of multilingual blogs
summary: Multilingual blogs incur translation costs. Manual translations are expensive, while automated tools often damage the Markdown format. How can one still remain efficient and preserve the original format?
date: 2025-12-17T17:00:00-03:00
lastmod: 2025-12-17T17:00:00-03:00
draft: false
tags:
  - hugo
  - markdown
  - blogging
  - ai
  - llm
  - claude
categories:
  - tech

ShowToc: true
TocOpen: true

params:
  author: Sebastian Zehner
  ShowPageViews: true

cover:
  image: /img/md-translator.webp
  alt: The blogger manages a multilingual blog on a laptop, featuring content in German, English, Spanish, and French
  hidden: false
  relative: false
  responsiveImages: false

translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: en
  date: 2025-12-17
  time: "18:07:15"
---

As a blogger with a multilingual blog, you face a constant challenge: every new article needs to be translated into several languages. Manual translations are time-consuming and expensive, while automated tools often ruin the carefully formatted Markdown structure. What to do?

That’s exactly the problem I faced when I started publishing my blog in German, English, and Spanish. The solution? An intelligent Markdown translator that preserves the structure of the text and provides high-quality translations.

## The creation of md-translator

md-translator is a Python-based tool that translates Markdown files using artificial intelligence (AI), without altering their formatting in the process. What makes it special is its use of Tencent’s Hunyuan-MT-7B model—a specialized translation model with 7 billion parameters that currently supports 38 languages.

The solution was built step by step and continuously refined. At first, the goal was simple: to translate a Markdown file. However, the challenges soon became apparent.

- The code blocks have been translated (horribly!).
- The links broke down into their individual components.
- The tables lost their structure.
- The “Front Matter” section has been completely messed up.
- The URL paths did not match the structure of the multilingual blog.

Each of these issues led to the development of a new feature, the fixing of a bug, or some other improvement. The result is a robust tool that is now available in version 1.2.3.

## Development using Claude Code

The md-translator wasn’t developed on its own; I used Claude Code, an AI-based coding assistant from Anthropics, in the terminal. This collaboration between human and AI was the key to its success.

### The development process

The development process was iterative and took several days to complete.

1. **Initial Concept:** I defined the requirements: a Markdown translator that preserves the structure of the text.
2. **Prototyping:** Claude Code wrote the first version of the tool, which included the basic logic for parsing Markdown content.
3. **Testing & Iteration:** I tested using actual blog articles, identified issues, and Claude Code implemented the necessary fixes.
4. **Feature Expansion:** Every new problem led to discussions about the best way to solve it.

What impressed me was that Claude Code not only understood the code itself but also the context in which it was used. When I said “the table formatting is broken,” he would analyze the problem, suggest a solution, and implement it—taking into account all possible edge cases as well.

### The challenges

Not everything worked on the first try. The bold/italic formatting was a perfect example of the limitations involved.

- We tried several approaches: marker systems, normalization, and XML tags.
- Every approach worked to some extent, but not consistently.
- In the end, we all agreed together that the quality of the translation is more important than having the formatting perfect.

This pragmatic decision-making process—combining AI suggestions with human judgment—was truly valuable.

### What worked well

Working with Claude Code had clear advantages:

- **Speed:** Features that would have taken hours to develop were implemented in just minutes.
- **Code Quality:** Clean, well-structured Python code with docstrings.
- **Problem-solving:** Alternative solutions were immediately proposed.
- **Iterative debugging:** Errors were quickly identified and fixed.

### The human factor

Despite the AI assistance, my role was still crucial:

- **Goal:** What capabilities should this tool have?
- **Testing**: Does it actually work in practice?
- **Prioritization:** Which features are important, and which are not?
- **Decisions:** Should the bold/italic formatting be removed, or should a more complex solution be adopted?

Claude Code is a powerful tool, but it’s not an autopilot. The best results are achieved through the collaboration between human expertise and AI capabilities.

## How does md-translator work?

### Intelligent segmentation

The translator doesn’t simply convert Markdown files into plain text; it understands their structure as well.

- **Front Matter:** The YAML metadata is translated selectively (only the title, description, etc.).
- **Headers:** The headings are translated, and their hierarchy is preserved.
- **Code blocks:** They are completely protected and not translated.
- **Tables:** Translated cell by cell, while maintaining the overall structure intact.
- **Links:** The text will be translated, while the URL remains protected.
- **Images:** The alt-text is translated, while the image path remains unchanged.

### Element Protection

Certain elements must never be translated.

- Inline code such as `variable_name`
- HTML tags such as `<div>` or `<span>`
- URLs in links and images
- Footnote references such as `[^1]`

These elements are replaced with placeholders before the translation and then restored afterward. The Large Language Model (LLM) never sees them.

### Intelligent CLI

The command-line interface is intentionally kept simple.

```bash
python md-translator.py artikel.de.md -l en es
```

The tool automatically recognizes:

- The source language, as indicated in the file name (`artikel.de.md` → German):
- Automatically generates output files (`artikel.en.md`, `artikel.es.md`).
- Loads the model only once for all translations

## Special Features

### URL rewriting for multilingual blogs

A typical problem with multilingual blogs: German articles are stored under `/de/posts/my-article`, English articles directly under `/posts/my-article`, and Spanish articles under `/es/posts/my-article`. The internal links need to be adjusted accordingly.

The md-translator handles this elegantly with an optional configuration file:

```yaml
url_rewriting:
  enabled: true
  patterns:
    de: /de
    en: ""
    es: /es
```

A link such as `/de/posts/my-article` will be automatically converted to `/posts/my-article` (in English) or `/es/posts/my-article` (in Spanish).

### Translation Metadata

Each translated file automatically receives metadata in the Front Matter section.

```yaml
translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: en
  date: 2024-12-16
  time: "14:23:45"
```

This makes it understandable when and how a file was translated. Very useful for large blogs with hundreds of articles.

### Automatic display in Hugo

The translation metadata is not just documentation; it’s also practically useful. My Hugo blog automatically analyzes this data and displays it at the bottom of each post (in the “footer” section).

**Hugo template customization:**

The Hugo template checks whether the `translation` field is present in the front matter. If it is, a notice is generated automatically.

```html
# singles.html {{ if .Params.translation }}
<div class="translation-note-wrapper">
  {{ partial "translation-note.html" . }}
</div>
{{- end }}
```

```html
# translation-note.html {{ with .Params.translation }} {{ $from := i18n (printf
"lang_%s" .from) }} {{ $to := i18n (printf "lang_%s" .to) }} {{ $toolPage :=
site.GetPage "posts/md-translator" }} {{ $toolName := .tool }} {{ if $toolPage
}} {{ $toolName = printf `<a href="%s">%s</a>` $toolPage.RelPermalink .tool |
safeHTML }} {{ end }} {{ i18n "translation_note" (dict "From" $from "To" $to
"Tool" $toolName "Version" .version ) | safeHTML }} {{ end }}
```

**For the reader, this looks like this:**

> This article was translated from German to English using md-translator v1.2.3.

In this way, the reader immediately and clearly understands the information.

- ✅ That he is reading a translation.
- ✅ Which tool was used?
- ✅ From which language into which language was translated
- ✅ When the translation was created

This is especially useful for articles that are updated regularly. When the original content is updated, you can translate it again later on, and the date will indicate which version of the translation is currently in use.

### Punctuation normalization

A common issue is that the LLM sometimes adds punctuation marks where they shouldn’t be. For example, `Über mich` becomes `About me.` – with an unwanted period at the end.

The md-translator checks the original text: if no punctuation mark is present at the end, none are added to the translation either. Simple logic, but with a big impact.

## Technical Details

### GPU Optimization

The Hunyuan-MT-7B model has 7 billion parameters. To process all of them with full precision (FP32), it would require approximately 28 GB of VRAM – which is more than most graphics cards can handle.

The solution: FP16 (half-precision). This reduces memory usage to approximately 14 GB while doubling the performance. On an RTX 4090, the conversion process runs smoothly and effortlessly.

### Post-processing

After the translation, a few more things need to be done:

1. **Correction of Markdown syntax:** The spaces between `]` and `(` in the links are being removed.
2. **Image syntax restoration:** Missing `!` sections in front of images are being added.
3. **Placeholder restoration:** Protected elements are restored to their original state.
4. **Link-Translation:** Texts from links are translated separately.

The result: perfectly formatted Markdown files that look as if they were written by hand.

## Lessons Learned

The development of md-translator was quite informative. Here are some of the key insights:

**What worked:**

- Clear placeholders like `__INLINECODE0__` are compatible with large language models (LLMs).
- Segmenting based on the Markdown structure ensures that the context is properly maintained.
- FP16 optimization is a game-changer when it comes to performance.
- The YAML-based configuration makes the tool flexible.

**What didn’t work:**

- The bold/italic formatting (`*` and `**`) cannot be reliably protected.
- The LLM treats these markers in a inconsistent manner.
- Sometimes they are preserved, sometimes they are not.
- Manual post-processing is required in this case.

**Worked surprisingly well:**

- Table translation, cell by cell:
- URL rewriting for multilingual structures
- Translation of the link-text without changing the URL:

## Practical usefulness

Since using md-translator, my workflow has been significantly simplified.

**Before:**

1. Writing articles in German
2. Copy to Translation Tool
3. Have it translated
4. Manually repairing Markdown formatting issues
5. Check and correct the links and images
6. Manually translating the Front Matter section
7. Adjust the URLs to match the target language
8. Repetition for each language

**Later on:**

```bash
python md-translator.py artikel.de.md -l en es
```

Time for a 1,000-word article:

- Previously: ~60–90 minutes (for 2 languages)
- Later: ~3–5 minutes (pure translation time)

This saves more than 90 percent of the time!

## Open Source and the Future

The md-translator project is open source and available on GitHub. The current version 1.2.3, is stable and ready for use in production environments.

Planned features for the future:

- Batch processing for entire directories
- Support for additional Markdown dialects

## Conclusion

The md-translator demonstrates how modern AI can be used to solve practical problems. It’s not a perfect tool (formatting text in bold/italic remains a challenge), but it saves a tremendous amount of time and provides high-quality translations.

For bloggers who publish content in multiple languages, this is a game-changer. For me personally, it has lowered the barrier to publishing articles in different languages. And that’s exactly the goal: to make knowledge accessible, regardless of the language.

## The meta-character of this article

This article is a perfect example of modern AI-driven development and content creation:

**The creation story:**

1. The md-translator was developed using **Claude Code** (AI that assists with programming).
2. This article was written using **Claude Code** (AI assistance was involved in the writing process).
3. The article will be translated using **md-translator** (an AI tool that translates automatically).
4. You might be reading the **AI-translated version** of this article.

This is pure examples of “dogfooding”, while also demonstrating the possibilities of AI-driven work. From the code itself, to the article, to the translation process: AI serves as a tool, guided by human intentions and quality control measures.

If you read this article in English or Spanish, you will see a notice indicating that the automatic translation feature has been used at the end of the article. That’s Hugo integration in action!

---

**Technical Specifications:**

- Language: Python 3.12
- Framework: PyTorch 2.5.0 with CUDA 12.4
- Model: [Tencent Hunyuan-MT-7B](https://github.com/Tencent-Hunyuan/Hunyuan-MT) (7B parameters, FP16)
- Supported languages: currently 38 languages
- License: MIT
- Repository: [github.com/sebastianzehner/md-translator](https://github.com/sebastianzehner/md-translator)

{{< chat md-translator >}}
