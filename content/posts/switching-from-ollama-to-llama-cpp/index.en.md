+++
title = 'Switching From Ollama to llama.cpp: More Control With llama-swap'
description = 'Why I switched from Ollama to llama.cpp: more control, 128k context with Qwen3.6 27B, and VRAM management with llama-swap on an RTX 4090.'
summary = 'Ollama was my standard for local LLMs for a long time. llama.cpp with llama-swap offers more control and brings back automatic VRAM management.'
date = 2026-08-04T17:30:00-03:00
lastmod = 2026-08-04T17:30:00-03:00

tags = ['llm', 'ai', 'open-source', 'linux', 'terminal']
categories = ['TechLab']

[params]
showComments = true
chatId = 'ollama-to-llama-cpp'

[translation]
  tool = 'Pi Agent - Qwen3.6-27B'
  version = '0.83.0'
  from = 'de'
  to = 'en'
  date = 2026-08-04T17:30:00-03:00
+++

For a long time, Ollama was my standard for local Large Language Models. Installation was child's play, usage was intuitive, and models loaded with a single command. But the more I worked with local LLMs, the more apparent the limitations became.

I said goodbye to Ollama and switched to [llama.cpp][1] with the [llama-swap][2] proxy in front. The result: **complete control over VRAM, context, and model behavior**, and GPU memory is automatically freed when I need it for ComfyUI.

## Why Ollama Was No Longer Enough

Ollama is a great tool for getting started. It automatically handles model size, context window, and hardware usage, which is perfect for simple chats. My setup looked like this for a long time, as I described in my earlier article on [Ollama Context Window Optimization][3]: Ollama as a systemd service with a fixed `OLLAMA_CONTEXT_LENGTH` and modelfiles for different `num_ctx` values.

At the time I was still using OpenCode as an agent, and I have since switched to Pi — more on that in another article. Development in the AI space is simply fast-paced; hardly has a setup been documented before something new is already on the horizon.

Three reasons ultimately moved me to switch.

### Control Over Chat Templates and Model Metadata

Ollama can now load arbitrary GGUF models directly from Hugging Face, not just from its own library — so you are not fundamentally locked in. The problem runs deeper: Ollama internally translates chat templates into its own Go template syntax, instead of using the Jinja templates embedded in the GGUF file. For new or unusual models, this repeatedly leads to incompatibilities that you have to debug before the model even responds correctly.

The llama.cpp server works directly with GGUF files and reads their Jinja templates natively. You download the desired model from Hugging Face or another source, drop it in the folder, and you are done. No translation step, no guessing whether the template was recognized correctly. This is a huge difference when working with new or exotic models.

### Performance and Day-1 Model Support

Beyond the compatibility issues, there is raw performance. Ollama has overhead. [Community benchmarks][4] show that llama.cpp runs 1.5 to 1.8 times faster on the same hardware. This became especially clear with the introduction of gpt-oss-20b: Because Ollama forked the ggml inference kernel for quick day-1 support without coordinating with the llama.cpp upstream, [20 to 30 percent slower inference][5] was measured at that time. For a system working with large context windows and complex queries, such a difference becomes noticeable quickly.

Additionally, there is the general topic of model support: New GGUFs often appear on Hugging Face within hours of a model release. With Ollama, you have to wait for someone to package the model for the registry. If you want to stay on the bleeding edge, you can start immediately with llama.cpp.

### Full Control Over Quantization and the Inference Engine

Ollama is a layer on top of llama.cpp — convenient, but every setting goes through a filter. You notice this first with quantization: Ollama offers only a handful of levels, while Hugging Face has the full range from IQ2 to BF16. Depending on the model and hardware, this choice can make a huge difference, both in quality and VRAM usage.

The filter shows up in other settings too. The llama.cpp server gives you direct access to things like KV cache type (e.g., `--cache-type-k q4_0` for large context windows), precise GPU layer offloading, or split-mode inference. Ollama deliberately hides this complexity. This is practical for beginners, but for advanced setups it eventually becomes a problem because you cannot reach the exact setting you need.

## llama.cpp: Driving the Engine Directly

The [llama.cpp][1] server is the inference engine under the hood. Written in C/C++, it reads GGUF models and offers full control over every aspect of inference. I install it via the `llama.cpp-cuda` AUR package, which brings CUDA support for the RTX 4090:

```bash
cd ~/builds
git clone https://aur.archlinux.org/llama.cpp-cuda.git
cd llama.cpp-cuda
makepkg
sudo pacman -U llama.cpp-cuda-*.pkg.tar.zst
```

There is also `llama.cpp-cuda-git`, which always builds against the latest state of the repo. I deliberately use the more stable `llama.cpp-cuda` variant and only update manually when I want to try a new model and it does not run with my current version. For Qwen3.6 27B, such an update was recently necessary. So far I have had no problems with this approach.

The package installs `llama-server` and all associated tools to `/usr/bin/`. This gives me direct access to parameters like:

- `-ngl 99` — load all layers into VRAM
- `--ctx-size 131072` — explicit 128k context window
- `--cache-type-k q4_0` — KV cache quantization for large contexts
- `--mmproj` — multimodal projector for image inputs
- `--spec-type draft-mtp` — speculative decoding with multi-token prediction

This is control that Ollama does not offer me in this form.

## llama-swap: Bringing Back Ollama's Comfort

Unfortunately, llama.cpp alone has one drawback: it does not support automatic unloading. A loaded model stays loaded until you manually stop the server. This is where [llama-swap][2] comes in.

llama-swap is a proxy that sits in front of the llama-server and automatically loads the configured model on the first request. After a configurable inactivity period — I use 300 seconds — `llama-server` is stopped and VRAM is completely freed. This is exactly the behavior I missed in llama.cpp and was used to from Ollama.

Installation also via AUR:

```bash
cd ~/builds
git clone https://aur.archlinux.org/llama-swap.git
cd llama-swap
makepkg
sudo pacman -U llama-swap-*.pkg.tar.zst
```

The service runs as a systemd unit. To start it automatically at boot, I enable it:

```bash
sudo systemctl enable --now llama-swap
```

The service listens on `127.0.0.1:12434`, the configuration lives under `/etc/llama-swap/config.yaml` and supports multiple models simultaneously.

One stumbling block: the package sets `DynamicUser=yes` by default. This means the service runs with its own isolated user that has no access to my internal NVMe drive mounted at `/mnt/sumpf/` — which is exactly where my models live. A systemd override fixes this without modifying the package file itself:

```bash
sudo systemctl edit llama-swap
```

```ini
[Service]
DynamicUser=no
User=<username>
```

### The Configuration

```yaml
healthCheckTimeout: 120
logLevel: info
logToStdout: proxy
globalTTL: 300

macros:
  models_dir: "/mnt/sumpf/ai/ComfyUI/models/LLM"

models:
  gemma-4-26B-A4B-it:
    cmd: >
      llama-server --port ${PORT}
      -m ${models_dir}/gemma-4-26B-A4B-it-UD-Q4_K_XL.gguf
      --mmproj ${models_dir}/mmproj-gemma4-BF16.gguf
      -ngl 99 --ctx-size 131072
    name: "Gemma 4 26B (llama.cpp)"
    ttl: 300
  qwen3.6-27B:
    cmd: >
      llama-server --port ${PORT}
      -m ${models_dir}/Qwen3.6-27B-UD-Q4_K_XL.gguf
      --mmproj ${models_dir}/mmproj-qwen36-BF16.gguf
      --spec-type draft-mtp --spec-draft-n-max 2 -np 1
      -ngl 99 --ctx-size 131072
      --cache-type-k q4_0 --cache-type-v q4_0
    name: "Qwen 3.6 27B (llama.cpp)"
    ttl: 300
```

Important details:

- **`DynamicUser=no`** — Since I need to access `/mnt/sumpf/`, the service runs under my user (set via `sudo systemctl edit llama-swap`)
- **`-ngl 99`** — All layers into VRAM, no CPU/GPU split
- **`--ctx-size 131072`** — Set explicitly, instead of accepting the automatically calculated value
- **`--cache-type-k q4_0`** — KV cache quantization, necessary for 128k context without out-of-memory errors

A quick background on the `--ctx-size` value: Without this explicit setting, `llama-server` has been automatically reducing context since the built-in [auto-fitting feature][6] to maintain a 1 GB VRAM buffer (default value of `--fit-target`). On my system that landed at 196608 instead of the full 262144 tokens that Qwen3.6-27B natively supports. Even that was still too tight on my VRAM, so I manually went down to 131072 — the more stable compromise between context size and VRAM buffer for my hardware.

## The Model: Qwen3.6 27B

After extensive testing with various models (most recently Gemma 4 26B), I decided on Qwen3.6 27B. Downloaded from Unsloth in GGUF format, quantization `UD-Q4_K_XL`. With 24 GB of VRAM, there is no reason to sacrifice quantization quality.

The model brings three features that run simultaneously on the RTX 4090:

1. **128k context window** — enough for complex agentic workflows and large codebases
2. **Multimodal / Vision** — images can be processed as input via the `mmproj` projector (`mmproj-qwen36-BF16.gguf`)
3. **Multi-Token Prediction (MTP)** — speculative decoding that speeds up inference by about 1.5 to 2×

Measured performance with this configuration:

| Metric | Value |
|---|---|
| Tokens per second (generation) | ~82 t/s |
| Tokens per second (prompt eval) | ~116 t/s |
| Draft acceptance rate (MTP) | ~75% |
| VRAM usage | ~21 GB of 24 GB |

For structured responses — such as tool calls or code generation — the MTP acceptance rate rises above 80%. That means: more tokens per step, faster response times.

## Integration With Pi

My Pi agent connects via the llama-swap endpoint. The configuration in `~/.pi/agent/models.json` shows how the OpenAI-compatible API is integrated:

```json
{
  "providers": {
    "llama-cpp": {
      "baseUrl": "http://127.0.0.1:12434/v1",
      "api": "openai-completions",
      "apiKey": "none",
      "compat": {
        "supportsDeveloperRole": false,
        "supportsReasoningEffort": false
      },
      "models": [
        {
          "id": "gemma-4-26B-A4B-it",
          "name": "Gemma 4 26B (llama.cpp)",
          "input": ["text", "image"],
          "contextWindow": 131072
        },
        {
          "id": "qwen3.6-27B",
          "name": "Qwen 3.6 27B (llama.cpp)",
          "input": ["text", "image"],
          "contextWindow": 131072
        }
      ]
    }
  }
}
```

Since llama-swap provides an OpenAI-compatible API, any application that speaks OpenAI interfaces works — without changes on the client side.

## VRAM On Demand: llama.cpp Makes Way for ComfyUI

This is the feature that makes the switch worthwhile for me. llama.cpp alone does not free up VRAM, but with llama-swap in front it works automatically again. The model is loaded on demand, and 300 seconds after the last request, VRAM is completely free for ComfyUI.

If I need to free it up immediately — for example before a larger ComfyUI session — a single command suffices:

```bash
curl -X POST http://127.0.0.1:12434/api/models/unload
```

llama-swap stays active and automatically reloads the model on the next request, entirely without a manual `systemctl restart`.

## Monitoring and Debugging

The status of llama-swap can be conveniently tracked via `journalctl`:

```bash
journalctl -fu llama-swap
```

The most important log entries:

- **`Health check passed`** — llama-server started successfully, first request takes ~6 seconds
- **`200`** — successful request, follow-up requests significantly faster (~400ms–2s)
- **`Unloading model, TTL of 300s reached`** — VRAM is being freed
- **`Configuration Changed / Reloaded`** — changes in `config.yaml` are automatically detected thanks to `-watch-config` (enabled by default in the AUR package)

Additionally, there is a web interface at `http://127.0.0.1:12434` that automatically redirects to `http://127.0.0.1:12434/ui/`. There you find a playground, a list of configured models with upstream logs, activity statistics, and logs for both proxy and upstream.

## Lessons Learned: Ollama Was the Right Starting Point

And honestly, I do not miss anything essential about it. I still recommend Ollama for anyone who wants to quickly get a local LLM running without dealing with parameters.

But once you go deeper — managing multiple models, optimizing VRAM, or needing specific inference parameters — the abstraction layer becomes a bottleneck. llama.cpp with llama-swap in front gives me everything Ollama offered (automatic load/unload, OpenAI API), plus the control I actually need.

The switch costs about an hour of setup. The AUR package takes care of most of the work, and the `config.yaml` is self-explanatory.

## Conclusion

The move from Ollama to llama.cpp with llama-swap was the right step. I have more control over context, quantization, and VRAM management. My system can now seamlessly switch between text LLM and ComfyUI without me having to intervene manually.

Qwen3.6 27B with 128k context, vision support, and MTP speedup runs stable on the RTX 4090. At ~82 tokens per second generation and ~75% draft acceptance rate, the performance is impressive for local hardware.

If you too are switching from Ollama to llama.cpp: start with the AUR package, configure llama-swap with a model of your choice, and adjust the `config.yaml` as needed. The effort is worth it.

Best regards,  
Sebastian

[1]: https://github.com/ggml-org/llama.cpp
[2]: https://github.com/mostlygeek/llama-swap
[3]: ollama-context-window-optimization-opencode/
[4]: https://willschenk.com/howto/2026/migrating_to_llama_cpp/
[5]: https://www.nijho.lt/post/llama-nixos/
[6]: https://github.com/ggml-org/llama.cpp/discussions/18049

{{< translation-note >}}
