---
title: "Optimizing the Ollama Context Window: The key to a successful integration of OpenCode"
summary: The Context Window is the “invisible bottleneck” in many Ollama setups. Here are three approaches to optimize its performance, practical tests using various models, and specific recommendations for successfully integrating OpenCode with LLMs.
date: 2026-01-10T19:20:00-03:00
lastmod: 2026-01-10T19:20:00-03:00
draft: false
tags:
  - ollama
  - llm
  - opencode
  - open-source
  - terminal
categories:
  - techlab

ShowToc: true
TocOpen: true

params:
  author: Sebastian Zehner
  ShowPageViews: true

cover:
  image: /img/ollama-context-cover.webp
  alt: Ollama Context Window
  hidden: false
  relative: false
  responsiveImages: false

translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: en
  date: 2026-01-10
  time: "21:17:26"
---

The Ollama hat emerged as a popular solution for running Large Language Models (LLMs) locally on one’s own hardware. However, many users encounter mysterious issues when trying to integrate it with tools like OpenCode.

“Tool Calls” don’t work properly, agents lose context, and code generation falls far short of expectations. The cause is usually not the model itself, but a frequently overlooked setting: the “Context Window”.

## The Context Window Problem: Why 4096 Tokens Aren’t Enough

Ollama typically uses a Context Window of only 4096 tokens by default, regardless of the theoretical size of the model. This value may be sufficient for simple chat interactions, but it becomes a bottleneck when more complex tasks are at hand.

For demanding applications such as:

- Code generation and refactoring
- A tool that invokes multiple functions
- Agent-based workflows
- OpenCode Integration

Is this standard practically always too small. The model simply cannot make use of its theoretical context of 32k, 128k, or even 256k tokens, because Ollama artificially limits it.

I was wondering why OpenCode wouldn’t work on my computer with various local models, so I decided to investigate the issue.

Now I understand why I didn’t succeed at first, and why the Large Language Model (LLM) didn’t behave in the way I desired. I was almost about to give up, but now I’ve found the solution.

## Understanding and configuring the Context Window

The context is controlled through the parameter `num_ctx`. With a simple command, it is possible to check which value is currently active.

```bash
ollama ps
```

The output clearly demonstrates the problem.

```bash
NAME                ID              SIZE      PROCESSOR    CONTEXT    UNTIL
qwen2.5-coder:7b    dae161e27b0e    4.9 GB    100% GPU     4096       4 minutes from now
```

Despite having high-performance hardware and a model that theoretically could handle much more data, only 4096 tokens are available.

## Solution 1: Providing a global context through systemd

The most elegant solution for ensuring a consistent setup is to set an environment variable at the system level. This way, all models will be automatically loaded with the desired context.

```bash
sudo systemctl edit ollama.service
```

Alternatively, the override file can be edited directly.

```bash
sudo nvim /etc/systemd/system/ollama.service.d/override.conf
```

The following entry increases the standard context to 16384 tokens:

```bash
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_CONTEXT_LENGTH=16384"
```

After the daemon is reloaded and the service restarted, the change takes effect.

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

Verification using another model demonstrates the success.

```bash
NAME               ID              SIZE     PROCESSOR    CONTEXT    UNTIL
qwen3-coder:30b    06c1097efce0    20 GB    100% GPU     16384      4 minutes from now
```

## Solution 2: Manually adjusting the context in the chat

For testing or occasional use, the context can also be set directly in the Ollama chat:

```bash
ollama run qwen3:32b
```

In the chat:
```bash
/set parameter num_ctx 12288
```

Tip: Using `/save qwen3-12k:32b`, you can even save a new variant of the model with this context. It will be available the next time `ollama list` is executed.

## Solution 3: Model files – the professional approach

The most sustainable solution is to use model files. They only take a few seconds to create, require almost no storage space, and perfectly document the configuration.

Sample model file for Ministral-3 with a 64k context:

```Modelfile
FROM ministral-3:14b
PARAMETER num_ctx 65536
```

Create:

```bash
ollama create ministral-3-64k:14b -f ministral-3-64k-14b.Modelfile
```

The result:

```bash
NAME                   ID              SIZE     PROCESSOR    CONTEXT    UNTIL
ministral-3-64k:14b    e1befb46cf0d    20 GB    100% GPU     65536      4 minutes from now
```

## Hardware limitations: What’s possible with an RTX 4090?

A higher level of performance (or “higher context”) is not an unlimited feature; rather, it is determined by the available hardware budget. The GPU determines what is actually feasible to use.

In my tests with an RTX 4090 (24 GB of VRAM), the following optimal values were obtained:

| Model | More relevant context | Maximum Context | VRAM usage |
|--------|-------------------|-------------------|--------------|
| qwen2.5-coder:7b | 32k | 32k | 8.2 GB |
| ministral-3:14b | 64k | 256k | 20 GB |
| qwen3-coder:30b | 32k | 256k | 22 GB |
| deepseek-r1:32b | 10k | 128k | 22 GB |
| gpt-oss:20b | 128k | 128k | 17 GB |

A too high value for `num_ctx` results in:

- Memory-out-of-limit errors
- Extremely slow responses
- Unstable tool calling
- Using a CPU/GPU combination instead of relying solely on the GPU

Example of an overloaded model:

```bash
NAME         ID              SIZE     PROCESSOR          CONTEXT    UNTIL
qwen3:32b    030ee887880f    29 GB    22%/78% CPU/GPU    32768      4 minutes from now
```

The percentage value related to the CPU indicates that the GPU is under heavy load; as a result, there are performance declines.

## Practical test: Which models work with OpenCode?

After extensive testing, three models emerged as particularly suitable.

### qwen3-coder:30b – The coding expert

With a context window size of 32k, this model performs optimally on the RTX 4090. The use of the relevant tools is reliable, and the speed is impressive. The resulting output closely resembles the feel of Claude Code’s experience, although Claude itself is still a unique and separate entity in its own right.

### devstral-small-2:24b – The reliable all-rounder

Based on a provided template, this model creates files and adjusts them according to the specified requirements. Occasionally, there are minor issues with context handling, but overall, it performs stably with up to 32k contexts.

### gpt-oss:20b – The champion of analysis.

The real highlight is the 128k of context available without any performance impacts. This makes it perfect for code reviews, documentation analysis, and large-scale projects. Even if some tool calls fail, the model will correct itself automatically.

The only downside is that Markdown tables were not rendered optimally in OpenCode; however, I have found a solution using [this plugin](https://github.com/franlol/opencode-md-table-formatter).

### qwen2.5-coder:7b – Not recommended

Despite having a context of 32k tokens: With only 7 billion parameters, the model is too small to be used as a reliable tool for making function calls within OpenCode.

## Practical recommendation for RTX 4090 users

Based on my own tests, my current recommendation for these models is:

| Use Case | Model | Context |
|----------|--------|--------|
| Coding / Tools | Qwen3-Coder-30B | 16–32k |
| Review/Analysis | GPT-OSS-20B | 64–128k |
| Long documents/knowledge bases… | Ministral-14B | 32–64k |

## Model file management: Organization is everything

It’s worthwhile to have a dedicated directory for model files:

```bash
/mnt/sumpf/ai/opencode/ollama/modelfiles/
├── gpt-oss-64k-20b.Modelfile
├── gpt-oss-128k-20b.Modelfile
└── ministral-3-64k-14b.Modelfile
```

So it remains understandable why a particular model was configured in a certain way—even months later.

## Maintenance and updates

When updating the system in Arch Linux, the overrides in the `override.conf` section are automatically preserved. After making manual changes, it’s sufficient to simply:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

## Conclusion: Context is not a feature, but a budget

The “Context Window” is the invisible “neck” of many Ollama setups. Anyone who wants to use OpenCode or similar tools must definitely modify the default value of 4096 tokens.

The three approaches for solving this issue – using global environment variables, chat commands, or model files – provide the appropriate level of flexibility for each scenario. It’s crucial to understand that a higher level of “context” is not an unlimited feature; rather, it must always be considered in the context of the available hardware.

With the right settings, Ollama can become a powerful local AI infrastructure capable of reliably supporting even demanding workflows.

I can now also allow one of the mentioned large language models (LLMs) to access my local wiki, so that it can be filled with relevant context data, which can then be directly used for further processing. It’s really amazing what’s possible these days. I learn something new every day, and it’s a lot of fun.

What experiences do you have with Ollama and OpenCode? Which model works best for you? Please share your recommendations and setup tips in the comments; I’m really interested in your feedback!

{{< chat ollama-context >}}
