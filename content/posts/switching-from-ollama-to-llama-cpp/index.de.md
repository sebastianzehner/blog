+++
title = 'Von Ollama zu llama.cpp: Mehr Kontrolle mit llama-swap'
description = 'Warum ich von Ollama zu llama.cpp gewechselt bin: mehr Kontrolle, 128k Context mit Qwen3.6 27B, und VRAM-Management mit llama-swap auf einer RTX 4090.'
summary = 'Ollama war lange mein Standard für lokale LLMs. llama.cpp mit llama-swap bietet mehr Kontrolle und bringt automatisches VRAM-Management zurück.'
date = 2026-08-04T17:30:00-03:00
lastmod = 2026-08-04T17:30:00-03:00

tags = ['llm', 'ai', 'open-source', 'linux', 'terminal']
categories = ['TechLab']

[params]
showComments = true
chatId = 'ollama-to-llama-cpp'
+++

Lange Zeit war Ollama mein Standard für lokale Large Language Models. Die
Installation war kinderleicht, die Bedienung intuitiv, und Modelle waren mit
einem einzigen Befehl geladen. Doch je mehr ich mit lokalen LLMs gearbeitet
habe, desto deutlicher wurden die Einschränkungen.

Ich habe mich von Ollama verabschiedet und bin zu [llama.cpp][1] gewechselt, mit
dem Proxy [llama-swap][2] davor. Das Ergebnis: **vollständige Kontrolle über
VRAM, Context und Modell-Verhalten**, und der GPU-Speicher wird automatisch
frei, wenn ich ihn für ComfyUI brauche.

## Warum Ollama nicht mehr gereicht hat

Ollama ist ein großartiges Tool für den Einstieg. Es kümmert sich automatisch um
Modellgröße, Context-Fenster und Hardware-Nutzung, was für einfache Chats
perfekt ist. Mein Setup sah lange so aus, wie ich es in meinem früheren Artikel
zur [Ollama Context Window Optimierung][3] beschrieben habe: Ollama als
systemd-Service mit einem festen `OLLAMA_CONTEXT_LENGTH` und Modelfiles für
verschiedene `num_ctx`-Werte.

Damals nutzte ich dafür noch OpenCode als Agent, mittlerweile bin ich auf Pi
umgestiegen, dazu aber mehr in einem anderen Artikel. Die Entwicklung im
KI-Bereich bleibt eben rasant, kaum ist ein Setup dokumentiert, ist schon wieder
etwas Neues dran.

Drei Gründe haben mich aber schließlich zum Umstieg bewegt.

### Kontrolle über Chat-Templates und Modell-Metadaten

Ollama kann inzwischen auch beliebige GGUF-Modelle direkt von Hugging Face
laden, nicht nur aus der eigenen Library — man ist also nicht grundsätzlich
eingesperrt. Das Problem liegt tiefer: Ollama übersetzt Chat-Templates intern in
eine eigene Go-Template-Syntax, statt die in der GGUF-Datei eingebetteten
Jinja-Templates direkt zu verwenden. Bei neuen oder ungewöhnlichen Modellen
führt das immer wieder zu Inkompatibilitäten, die man erst debuggen muss, bevor
das Modell überhaupt korrekt antwortet.

Der llama.cpp Server arbeitet direkt mit GGUF-Dateien und liest deren
Jinja-Templates nativ. Man lädt das gewünschte Modell von Hugging Face oder
einer anderen Quelle herunter, legt es in den Ordner und ist fertig. Kein
Übersetzungsschritt, keine Ratespiele, ob das Template richtig erkannt wurde.
Das ist ein enormer Unterschied, wenn man mit neuen oder exotischen Modellen
arbeiten will.

### Performance und Tag-1-Modellsupport

Neben den Kompatibilitätsproblemen kommt noch die reine Performance dazu. Ollama
hat Overhead. [Community-Benchmarks][4] zeigen, dass llama.cpp auf derselben
Hardware 1,5- bis 1,8-mal schneller läuft. Besonders deutlich wurde das bei der
Einführung von gpt-oss-20b: Weil Ollama den ggml-Inferenzkern für einen
schnellen Day-1-Support geforkt hatte, ohne sich mit dem llama.cpp-Upstream zu
koordinieren, wurden zu diesem Zeitpunkt [20 bis 30 Prozent langsamere
Inferenz][5] gemessen. Für ein System, das mit großen Context-Fenstern und
komplexen Anfragen arbeitet, macht sich so ein Unterschied schnell bemerkbar.

Zusätzlich gibt es das Thema Modellsupport generell: Neue GGUFs erscheinen oft
innerhalb weniger Stunden nach einem Modell-Release auf Hugging Face. Bei Ollama
muss man warten, bis jemand das Modell für die Registry paketiert hat. Wer auf
dem neuesten Stand bleiben will, kann bei llama.cpp sofort loslegen.

### Volle Kontrolle über Quantisierung und Inferenz-Engine

Ollama ist eine Schicht über llama.cpp — bequem, aber jede Einstellung geht
durch einen Filter. Das merkt man zuerst bei der Quantisierung: Ollama bietet
nur eine Handvoll Level, während man auf Hugging Face die volle Bandbreite von
IQ2 bis BF16 bekommt. Je nach Modell und Hardware kann diese Wahl einen enormen
Unterschied machen, sowohl bei der Qualität als auch beim VRAM-Verbrauch.

Der Filter zeigt sich auch bei anderen Einstellungen. Der llama.cpp Server gibt
einem direkten Zugriff auf Dinge wie den KV-Cache-Typ (z. B. über
`--cache-type-k q4_0` für große Context-Fenster), präzises GPU-Layer-Offloading
oder Split-Mode-Inference. Ollama versteckt diese Komplexität dagegen bewusst.
Für den Einstieg ist das praktisch, aber bei fortgeschrittenen Setups wird es
irgendwann zum Problem, weil man genau an die Einstellung nicht herankommt, die
man gerade braucht.

## llama.cpp: Die Engine direkt bedienen

Der [llama.cpp][1] Server ist die Inference-Engine unter der Haube. Geschrieben
in C/C++, liest sie GGUF-Modelle und bietet volle Kontrolle über jeden Aspekt
der Inferenz. Ich installiere sie über das AUR-Paket `llama.cpp-cuda`, das
CUDA-Support für die RTX 4090 mitbringt:

```bash
cd ~/builds
git clone https://aur.archlinux.org/llama.cpp-cuda.git
cd llama.cpp-cuda
makepkg
sudo pacman -U llama.cpp-cuda-*.pkg.tar.zst
```

Es gibt daneben auch `llama.cpp-cuda-git`, das immer gegen den aktuellsten Stand
des Repos baut. Ich nutze bewusst die stabilere `llama.cpp-cuda`-Variante und
update nur manuell, wenn ich ein neues Modell ausprobieren will und es mit
meiner aktuellen Version nicht läuft. Bei Qwen3.6 27B war zuletzt so ein Update
nötig. Bisher hatte ich mit diesem Ansatz keine Probleme.

Das Paket installiert `llama-server` und alle zugehörigen Tools nach
`/usr/bin/`. Damit habe ich direkten Zugriff auf Parameter wie:

- `-ngl 99` — alle Layer in den VRAM laden
- `--ctx-size 131072` — explizites 128k Context Window
- `--cache-type-k q4_0` — KV-Cache-Quantisierung für große Contexts
- `--mmproj` — Multimodal-Projector für Bild-Inputs
- `--spec-type draft-mtp` — Spekulative Decoding mit Multi-Token Prediction

Das ist Kontrolle, die mir Ollama so in dieser Form nicht bietet.

## llama-swap: Ollamas Komfort zurückholen

Leider hat llama.cpp allein einen Nachteil: es kennt kein automatisches
Unloading. Ein geladenes Modell bleibt geladen, bis man den Server manuell
stoppt. Hier kommt [llama-swap][2] ins Spiel.

Der llama-swap ist ein Proxy, der vor dem llama-server steht und bei der ersten
Anfrage automatisch das konfigurierte Modell lädt. Nach einer einstellbaren
Inaktivitätszeit — ich nutze 300 Sekunden — wird `llama-server` gestoppt und der
VRAM komplett freigegeben. Genau das Verhalten, das mir bei llama.cpp fehlte und
ich von Ollama gewohnt war.

Installation ebenfalls über AUR:

```bash
cd ~/builds
git clone https://aur.archlinux.org/llama-swap.git
cd llama-swap
makepkg
sudo pacman -U llama-swap-*.pkg.tar.zst
```

Der Service läuft als systemd-Unit. Damit er automatisch beim Boot startet, muss
ich ihn aktivieren:

```bash
sudo systemctl enable --now llama-swap
```

Der Dienst lauscht auf `127.0.0.1:12434`, die Konfiguration liegt unter
`/etc/llama-swap/config.yaml` und unterstützt mehrere Modelle gleichzeitig.

Ein Stolperstein: Das Paket setzt standardmäßig `DynamicUser=yes`. Dadurch läuft
der Service mit einem eigenen, isolierten Benutzer, der keinen Zugriff auf meine
interne NVMe-Festplatte hat, die unter `/mnt/sumpf/` gemountet ist — genau dort
liegen aber meine Modelle. Mit einem systemd-Override lässt sich das beheben,
ohne die Paket-Datei selbst zu verändern:

```bash
sudo systemctl edit llama-swap
```

```ini
[Service]
DynamicUser=no
User=<username>
```

### Die Konfiguration

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

Wichtige Details:

- **`DynamicUser=no`** — Da ich auf `/mnt/sumpf/` zugreifen muss, läuft der
  Service unter meinem Benutzer (gesetzt via `sudo systemctl edit llama-swap`)
- **`-ngl 99`** — Alle Layer in den VRAM, kein CPU/GPU-Split
- **`--ctx-size 131072`** — Explizit gesetzt, statt den automatisch
  berechneten Wert zu übernehmen
- **`--cache-type-k q4_0`** — KV-Cache-Quantisierung, notwendig für 128k
  Context ohne Out-of-Memory

Zum `--ctx-size`-Wert noch kurz der Hintergrund: Ohne diese explizite Angabe
reduziert `llama-server` seit dem eingebauten [Auto-Fitting-Feature][6] den
Kontext automatisch, um einen VRAM-Puffer von 1 GB einzuhalten (Standardwert von
`--fit-target`). Bei mir landete das bei 196608 statt der vollen 262144 Token,
die Qwen3.6-27B nativ unterstützt. Auch das war meinem VRAM aber noch zu knapp,
deshalb bin ich manuell auf 131072 gegangen — für meine Hardware der stabilere
Kompromiss zwischen Kontextgröße und VRAM-Puffer.

## Das Modell: Qwen3.6 27B

Nach ausgiebigen Tests mit verschiedenen Modellen (zuletzt Gemma 4 26B) habe ich
mich für Qwen3.6 27B entschieden. Heruntergeladen von Unsloth im GGUF-Format,
Quantisierung `UD-Q4_K_XL`. Bei 24 GB VRAM gibt es keinen Grund, auf
Quantisierungsqualität zu verzichten.

Das Modell bringt drei Features mit, die auf der RTX 4090 gleichzeitig laufen:

1. **128k Context Window** — genug für komplexe Agentic-Workflows und große Codebases
2. **Multimodal / Vision** — über den `mmproj`-Projector
   (`mmproj-qwen36-BF16.gguf`) können Bilder als Input verarbeitet werden
3. **Multi-Token Prediction (MTP)** — Spekulative Decoding, das die Inferenz
   um etwa 1,5- bis 2× beschleunigt

Die gemessene Performance mit dieser Konfiguration:

| Metrik                      | Wert             |
| --------------------------- | ---------------- |
| Token/Sekunde (Generation)  | ~82 t/s          |
| Token/Sekunde (Prompt-Eval) | ~116 t/s         |
| Draft-Acceptance-Rate (MTP) | ~75 %            |
| VRAM-Nutzung                | ~21 GB von 24 GB |

Bei strukturierten Antworten — wie Tool-Calls oder Code-Generierung — steigt die
MTP-Acceptance-Rate auf über 80 %. Das bedeutet: mehr Tokens pro Schritt,
schnellere Antwortzeiten.

## Integration mit Pi

Mein Pi Agent verbindet sich über den llama-swap-Endpunkt. Die Konfiguration in
`~/.pi/agent/models.json` zeigt, wie das OpenAI-kompatible API eingebunden wird:

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

Da llama-swap ein OpenAI-kompatibles API bereitstellt, funktioniert jede
Anwendung, die mit OpenAI-Schnittstellen sprechen kann — ohne Änderungen an der
Client-Seite.

## VRAM auf Abruf: llama.cpp weicht ComfyUI

Das ist das Feature, das den Umstieg für mich erst rund macht. Denn llama.cpp
allein gibt den VRAM nicht frei, und mit llama-swap davor läuft das wieder
automatisch. Das Modell wird bei Bedarf geladen, und 300 Sekunden nach der
letzten Anfrage ist der VRAM komplett frei für ComfyUI.

Wenn ich sofort freischalten muss — zum Beispiel vor einer größeren
ComfyUI-Session — genügt ein einzelner Befehl:

```bash
curl -X POST http://127.0.0.1:12434/api/models/unload
```

Dabei bleibt llama-swap aktiv und lädt das Modell bei der nächsten Anfrage
wieder automatisch, ganz ohne manuellen `systemctl restart`.

## Monitoring und Debugging

Der Status von llama-swap lässt sich bequem über `journalctl` verfolgen:

```bash
journalctl -fu llama-swap
```

Die wichtigsten Log-Einträge:

- **`Health check passed`** — llama-server erfolgreich gestartet, erste
  Anfrage dauert ~6 Sekunden
- **`200`** — erfolgreiche Anfrage, Folgeanfragen deutlich schneller (~400ms–2s)
- **`Unloading model, TTL of 300s reached`** — VRAM wird freigegeben
- **`Configuration Changed / Reloaded`** — Änderungen in der `config.yaml`
  werden dank `-watch-config` (im AUR-Paket standardmäßig aktiviert) automatisch
  erkannt

Zusätzlich gibt es ein Webinterface unter `http://127.0.0.1:12434`, das
automatisch auf `http://127.0.0.1:12434/ui/` weiterleitet. Dort gibt es einen
Playground, eine Liste der konfigurierten Modelle mit Upstream Logs, eine
Aktivitäts-Statistik und nochmal Logs für Proxy und Upstream.

## Erkenntnisse: Ollama war der richtige Anfang

Und ehrlich gesagt vermisse ich auch nichts Wesentliches daran. Ich empfehle
Ollama weiterhin für alle, die schnell ein lokales LLM zum Laufen bringen
wollen, ohne sich mit Parametern auseinanderzusetzen.

Aber sobald man tiefer geht, also mehrere Modelle verwaltet, VRAM optimieren
will oder spezifische Inferenz-Parameter braucht, wird die Abstraktionsschicht
zum Engpass. llama.cpp mit llama-swap davor gibt mir alles, was Ollama angeboten
hat (automatisches Laden/Entladen, OpenAI-API), plus die Kontrolle, die ich
tatsächlich brauche.

Der Umstieg kostet etwa eine Stunde Setup. Das AUR-Paket übernimmt die meiste
Arbeit, und die `config.yaml` ist selbsterklärend.

## Fazit

Der Wechsel von Ollama zu llama.cpp mit llama-swap war der richtige Schritt. Ich
habe mehr Kontrolle über Context, Quantisierung und VRAM-Verwaltung. Mein System
kann jetzt nahtlos zwischen Text-LLM und ComfyUI wechseln, ohne dass ich manuell
eingreifen muss.

Qwen3.6 27B mit 128k Context, Vision-Support und MTP-Speedup läuft stabil auf
der RTX 4090. Bei ~82 Tokens pro Sekunde Generation und ~75 %
Draft-Acceptance-Rate ist die Performance für lokale Hardware beeindruckend.

Wenn du ebenfalls von Ollama zu llama.cpp wechselst: Fang mit dem AUR-Paket an,
konfiguriere llama-swap mit einem Modell deiner Wahl, und passe die
`config.yaml` nach Bedarf an. Der Aufwand lohnt sich.

Liebe Grüße  
Sebastian

[1]: https://github.com/ggml-org/llama.cpp
[2]: https://github.com/mostlygeek/llama-swap
[3]: ollama-context-window-optimization-opencode/
[4]: https://willschenk.com/howto/2026/migrating_to_llama_cpp/
[5]: https://www.nijho.lt/post/llama-nixos/
[6]: https://github.com/ggml-org/llama.cpp/discussions/18049
