+++
title = 'Pi Dictate: Local Voice Dictation with Sherpa-ONNX in the Terminal'
description = 'Pi Dictate, forked: local voice dictation for the Pi Agent with Sherpa-ONNX, no cloud and no API key. Setup, hotkeys, and pitfalls from real daily use.'
summary = 'pi-dictate, forked: speak locally and the text lands in the Pi Agent input field almost instantly. Sherpa-ONNX as STT backend, no cloud at all.'
date = 2026-08-24T17:00:00-03:00
lastmod = 2026-08-24T17:00:00-03:00

tags = ['ai', 'stt', 'llm', 'qwen', 'terminal', 'open-source']
categories = ['TechLab']

[params]
showComments = true
chatId = 'pi-dictate'

[translation]
  tool = 'Pi Agent - Qwen3.8-27B'
  version = '0.84.3'
  from = 'de'
  to = 'en'
  date = 2026-08-24T18:30:00-03:00
+++

I press `ctrl+shift+m`, speak into the microphone, press `ctrl+shift+m` again, and the sentence is sitting in the
Pi Agent's input field. No detour through the cloud, no API key needed, no perceptible lag. That sounds like a feature
from a promo video, but for me it has been the normal workflow since this week.

What makes this possible is [pi-dictate][1], a minimal Pi extension for voice dictation in the terminal, which I
forked and switched to fully local STT. The backend is a [Sherpa-ONNX][2] server running on my Mac Studio; the audio
travels over the LAN via WebSocket, and the transcribed text heads back to the chat window a moment later.

{{< github repo="sebastianzehner/pi-dictate" showThumbnail=true >}}

## Why I forked pi-dictate

[The original by amosblomqvist][3] is a thoughtfully minimal project: no floating dictation window, no menu bar app,
no notifications. Press `alt+m`, speak, press `alt+m` again, and the text lands in the focused input field. Chat
editor, popup, or dialog: the key is intercepted at the TUI level, before the focused component sees it.

Two things didn't fit my setup. First, the backend: the original streams the audio to Deepgram Nova-3, a cloud service
with an API key and a cost of around 0.50 USD per hour of speech. Second, the platform: the original is tailored to
macOS (`pbcopy` for the clipboard fallback, `sox` for capture), and I work on Arch Linux with dwm.

The fork replaces the backend entirely with a local Sherpa-ONNX server. No dual setup, no second code path:
it's simply a different WebSocket on the other end. Everything that makes the original what it is stays intact: level
meter, focus detection, delivery to the right input field. Only the side the audio talks to has changed.

## How the dictation works

First I focus an input field, be it the main chat window, a quiz note field, or an `ask_user_question` answer box.
`ctrl+shift+m` starts recording; the status line shows a red dot plus a level meter that swings with my voice:
`● ▁▂▃▅ listening…`. If nothing is focused, dictation doesn't start at all, and a notification explains why.

Speak, and the second `ctrl+shift+m` stops everything. A brief `finalizing…` spinner, usually too fast to see on a
local server, then the text is there. Transcription runs live as you go: the server keeps delivering text while you
speak, but insertion happens in a single step only when you stop. `ctrl+shift+n` aborts an ongoing dictation and
throws the transcript away, safe to press at any time.

What matters is where the text goes: it is always **appended, never replaced**, to the field that is **focused at the
moment you stop**.

This makes the following flow possible: start a dictation, then paste an error message from the terminal, start another
dictation, and the new text is simply appended instead of overwriting anything. At the end, everything can be sent
together in the chat.

Depending on the context, the appending works like this:

- Editor or popup input field: direct append
- Closed dialogs (quiz, `ask_user_question`): inserted as synthetic keystrokes, so press Tab into the note field first
- No input field focused: clipboard via `xclip`, plus a notification

Optionally, you can enable the live preview (`LIVE_PREVIEW = true` in `index.ts`). The status line then shows the
rolling text next to the level meter, the best feedback if you want to see what the server is picking up.

## The STT server: Sherpa-ONNX with the Kroko model

The core is a slim Docker container running the Sherpa-ONNX WebSocket server on port 6006. As the model, I use the
German streaming Zipformer [de-kroko-2025-08-06][4]. In my setup, latency is under 300ms, the text appears practically
at the same moment as you speak, and the CPU load on the Mac Studio stays low.

The model has a second advantage: it punctuates and capitalizes natively. Commas, periods, and question and
exclamation marks come straight from the model, and no `smart_format`-style post-processing step is needed. English
words and technical terms are also usually recognized reliably and spelled correctly, without switching languages
manually. If you want to dictate in other languages, just swap in a different sherpa-onnx model server-side.

The protocol is simple: 16 kHz mono PCM goes up as binary WebSocket frames, and back comes JSON with a rolling text
that replaces itself with every update. After the string `DONE`, exactly one final arrives. A detail worth knowing if
you build your own clients: the server does not close the connection after the final; the client has to take care of
that. Forget that and the session stays open on the server. This holds for every client attaching to this
server: my voice assistant Konrad hangs off the very same instance with its Wyoming proxy.

## Installation

On the Pi side, the setup is short:

```bash
pi install git:github.com/sebastianzehner/pi-dictate
pacman -S pulseaudio-utils xclip
```

`pulseaudio-utils` provides `parec` for the native 48 kHz capture, `xclip` the clipboard fallback. The extension
downsamples internally via an FIR filter to 16 kHz mono, the format the server expects. The STT server starts
separately via Docker Compose:

```bash
docker compose -f <path-to-sherpa-compose>/compose.yaml up -d
```

Two environment variables control the extension, read when Pi loads:

| Variable          | Default                    | Effect                                             |
| ----------------- | -------------------------- | -------------------------------------------------- |
| `DICTATE_STT_URL` | `ws://mac-studio.lan:6006` | WebSocket URL of the Sherpa-ONNX server            |
| `DICTATE_DEBUG`   | off                        | `1` logs WebSocket events to `/tmp/dictate-debug.log` |

After installing or after changes to `index.ts`, a `/reload` in Pi is enough.

## Pitfalls

Three points cost me time during the setup, which I'd like to save you:

1. **Hotkeys and terminals.** `ctrl+shift+m` is not representable as a legacy byte, the terminal must emit CSI-u
   (Kitty protocol). In st, I adjusted `mappedkeys[]` in `config.h` accordingly, and in tmux 3.5+ I enable
   `extended-keys on` and `extended-keys-format csi-u`. The Pi docs on the tmux setup explain this in detail:
   [pi.dev/docs/latest/tmux][5].
2. **dwm collision.** The original deliberately chose `alt+m`/`alt+n`, because `ctrl+shift` binds are indistinguishable
   from Enter in terminals without CSI-u support. Mine collided with my dwm shortcuts, hence the switch to
   `ctrl+shift` combined with modern CSI-u output.
3. **Wayland.** Not supported yet. `xclip` needs X11, a `wl-copy` fallback would have to be added if anyone cares.

## And Pi stays as it is

A sentence that might come as a surprise: I simply still love the Pi Agent. Voice input doesn't make the keyboard
redundant, but speaking long prompts and detailed descriptions is faster and more relaxed than typing. The dictation
lands directly in the chat window the agent is already waiting in.

The LLM stack under Pi is, by the way, unchanged: llama.cpp with llama-swap as the proxy, as described in my
[article on switching from Ollama][6]. Only the model changed. Instead of Qwen3.6-27B, it's now Qwen3.8-27B in
`UD-Q4_K_XL` format, with vision projector and multi-token prediction as before. In the llama-swap configuration,
that's just a changed model path, and thanks to the TTL the VRAM is automatically freed as before as soon as I need it
for ComfyUI.

This extension, the fork with the dictation integration, was by the way built itself with the Pi Agent, locally on my
hardware under Qwen3.8. These days you can genuinely have your tools build your tools.

## Conclusion

Local STT is definitely practical for voice dictation: under 300ms of latency, native punctuation, no running API
costs, and no audio data leaves the LAN. The fork stays as slim as the original, a single TypeScript file,
MIT-licensed, and it has been in daily use since this week. If you use Pi and prefer dictating to typing: it's worth a
try.

Best regards,  
Sebastian

[1]: https://github.com/sebastianzehner/pi-dictate
[2]: https://github.com/k2-fsa/sherpa-onnx
[3]: https://github.com/amosblomqvist/pi-dictate
[4]: https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-de-kroko-2025-08-06
[5]: https://pi.dev/docs/latest/tmux
[6]: switching-from-ollama-to-llama-cpp/

{{< translation-note >}}
