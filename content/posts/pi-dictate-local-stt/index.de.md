+++
title = 'Pi Dictate: Lokales Sprachdiktat mit Sherpa-ONNX im Terminal'
description = 'Pi Dictate im Fork: Lokales Sprachdiktat für den Pi Agent mit Sherpa-ONNX, ohne Cloud und ohne API-Key. Setup, Hotkeys und Stolpersteine aus dem Praxisbetrieb.'
summary = 'pi-dictate im Fork: lokal sprechen, und der Text steht fast sofort im Eingabefeld des Pi Agent. Sherpa-ONNX als STT-Backend, komplett ohne Cloud.'
date = 2026-08-24T17:00:00-03:00
lastmod = 2026-08-24T17:00:00-03:00

tags = ['ai', 'stt', 'llm', 'qwen', 'terminal', 'open-source']
categories = ['TechLab']

[params]
showComments = true
chatId = 'pi-dictate'
+++

Ich drücke `ctrl+shift+m`, spreche in das Mikrofon, drücke `ctrl+shift+m` erneut, und der Satz steht
im Eingabefeld des Pi Agent. Kein Umweg über die Cloud, kein API-Key nötig, keine spürbare Verzögerung.
Das klingt nach einem Feature aus dem Werbevideo, ist bei mir aber seit dieser Woche der normale Workflow.

Möglich macht das [pi-dictate][1], eine minimale Pi-Erweiterung für Sprachdiktat im Terminal, die ich geforkt und auf
komplett lokales STT umgestellt habe. Als Backend läuft ein [Sherpa-ONNX][2]-Server auf meinem Mac Studio; das Audio
wandert per WebSocket über das LAN, der transkribierte Text kurz darauf zurück ins Chatfenster.

{{< github repo="sebastianzehner/pi-dictate" showThumbnail=true >}}

## Warum ich pi-dictate geforkt habe

Das [Original von amosblomqvist][3] ist ein durchdachtes Minimalismus-Projekt: Kein schwebendes Diktat-Fenster, keine
Menüleisten-App, keine Benachrichtigungen. `alt+m` drücken, sprechen, erneut `alt+m` drücken, und der Text landet im
fokussierten Eingabefeld. Ob Chat-Editor, Popup oder Dialog: Die Taste wird auf der TUI-Ebene abgefangen, bevor die
fokussierte Komponente sie sieht.

Zwei Dinge passten bei mir nicht. Erstens das Backend: Das Original streamt das Audio an Deepgram Nova-3, ein
Cloud-Service mit API-Key und rund 0,50 USD pro Stunde Sprechzeit. Zweitens die Plattform: Das Original ist auf macOS
zugeschnitten (`pbcopy` für den Clipboard-Fallback, `sox` für die Aufnahme), ich arbeite unter Arch Linux mit dwm.

Der Fork ersetzt das Backend daher vollständig durch einen lokalen Sherpa-ONNX-Server. Kein dualer Aufbau, kein zweiter
Code-Pfad: Es ist einfach ein anderes WebSocket auf der anderen Seite. Alles, was das Original ausmacht, bleibt dabei
erhalten: Pegelmeter, Fokus-Erkennung, Delivery an das richtige Eingabefeld. Nur die Seite, mit der das Audio redet, hat
sich geändert.

## So funktioniert das Diktat

Zuerst fokussiere ich ein Eingabefeld, egal ob das Haupt-Chatfenster, ein Quiz-Notizfeld oder ein
`ask_user_question`-Antwortfeld ist. `ctrl+shift+m` startet die Aufnahme; die Statuszeile zeigt einen roten Punkt plus
einen Pegelmeter, der mit meiner Stimme mitschwingt: `● ▁▂▃▅ listening…`. Wenn nichts fokussiert ist, startet die
Diktation gar nicht, eine Benachrichtigung erklärt warum.

Sprechen, und beim zweiten `ctrl+shift+m` stoppt alles. Kurz ein `finalizing…`-Spinner, der auf dem lokalen Server meist
zu schnell zum Sehen ist, dann ist der Text da. Das Transkribieren läuft dabei live mit: Der Server liefert während des
Sprechens fortlaufend Text, eingefügt wird er aber erst in einem einzigen Schritt beim Stopp. `ctrl+shift+n` bricht eine
laufende Diktation ab und wirft das Transkript weg, jederzeit sicher.

Wichtig ist das Ziel des Textes: Er wird immer **angehängt, nie ersetzt**, und zwar an das Feld, das **zum Zeitpunkt des
Stopps** fokussiert ist.

Das erlaubt zum Beispiel folgenden Ablauf: Man startet ein Diktat, fügt danach per Copy & Paste noch eine Fehlermeldung
aus dem Terminal ein, startet anschließend ein weiteres Diktat, und der neue Text wird einfach angehängt, statt etwas zu
überschreiben. Am Ende lässt sich alles zusammen im Chat absenden.

Konkret läuft das Anhängen je nach Kontext so ab:

- Editor oder Popup-Eingabefeld: direkter Append
- Geschlossene Dialoge (Quiz, `ask_user_question`): als synthetische Tastenanschläge, dafür vorab mit Tab in das
  Notizfeld wechseln
- Kein Eingabefeld fokussiert: Clipboard via `xclip`, plus Benachrichtigung

Optional lässt sich die Live-Vorschau aktivieren (`LIVE_PREVIEW = true` in `index.ts`). Dann zeigt die Statuszeile neben
dem Pegelmeter auch den laufenden Rolling-Text, das beste Feedback, wenn man sehen will, was der Server gerade versteht.

## Der STT-Server: Sherpa-ONNX mit dem Kroko-Modell

Das Herzstück ist ein schlanker Docker-Container mit dem Sherpa-ONNX WebSocket-Server auf Port 6006. Als Modell nutze
ich das deutsche Streaming-Zipformer [de-kroko-2025-08-06][4]. In meinem Setup liegt die Latenz bei unter 300ms,
der Text erscheint praktisch gleichzeitig mit dem Aussprechen, und die CPU-Last auf dem Mac Studio bleibt niedrig.

Das Modell hat noch einen zweiten Vorteil: Es punktiert und kapitalisiert nativ. Kommata, Punkte, Frage- und
Ausrufezeichen kommen direkt aus dem Modell, ein Post-Processing-Schritt à la `smart_format` ist nicht nötig. Auch
englische Wörter und Fachbegriffe werden dabei meist zuverlässig erkannt und korrekt geschrieben, ohne dass man die
Sprache manuell umschalten muss. Wer andere Sprachen diktieren will, tauscht serverseitig einfach ein anderes
sherpa-onnx-Modell ein.

Das Protokoll ist schlicht: 16 kHz Mono-PCM wird als binäre WebSocket-Frames hochgeschickt, zurück kommt JSON mit einem
Rolling-Text, der sich bei jedem Update selbst ersetzt. Nach dem String `DONE` kommt genau ein Final. Ein Detail, das
man kennen sollte, wenn man eigene Clients baut: Der Server schließt die Verbindung nach dem Final nicht selbst, der
Client muss das übernehmen. Wer das vergisst, lässt die Session auf dem Server offen. Das gilt für jeden Client, der
sich an diesen Server anbindet: Mein Voice-Assistent Konrad hängt mit seinem Wyoming-Proxy an genau derselben Instanz.

## Installation

Auf der Pi-Seite ist das Setup kurz:

```bash
pi install git:github.com/sebastianzehner/pi-dictate
pacman -S pulseaudio-utils xclip
```

`pulseaudio-utils` liefert `parec` für die native 48-kHz-Aufnahme, `xclip` den Clipboard-Fallback. Die Erweiterung
sampelt intern per FIR-Filter auf 16 kHz Mono herunter, das Format, das der Server erwartet. Der STT-Server startet
separat per Docker Compose:

```bash
docker compose -f <pfad-zum-sherpa-compose>/compose.yaml up -d
```

Zwei Umgebungsvariablen steuern die Erweiterung, gelesen beim Laden von Pi:

| Variable          | Default                    | Effekt                                                   |
| ----------------- | -------------------------- | -------------------------------------------------------- |
| `DICTATE_STT_URL` | `ws://mac-studio.lan:6006` | WebSocket-URL des Sherpa-ONNX-Servers                    |
| `DICTATE_DEBUG`   | aus                        | `1` loggt WebSocket-Events nach `/tmp/dictate-debug.log` |

Nach der Installation oder nach Änderungen an `index.ts` genügt `/reload` in Pi.

## Stolpersteine

Drei Punkte haben mir beim Aufbau Zeit gekostet, die ich dir gerne erspare:

1. **Hotkeys und Terminals.** `ctrl+shift+m` ist als Legacy-Byte nicht darstellbar, das Terminal muss CSI-u
   (Kitty-Protokoll) senden. In st habe ich `mappedkeys[]` in `config.h` entsprechend angepasst, in tmux 3.5+
   aktiviere ich `extended-keys on` und `extended-keys-format csi-u`. Die Pi-Doku zum tmux-Setup erklärt das
   ausführlich: [pi.dev/docs/latest/tmux][5].
2. **dwm-Kollision.** Das Original hat bewusst `alt+m`/`alt+n` gewählt, weil `ctrl+shift`-Binds in Terminals ohne
   CSI-u-Unterstützung von Enter nicht unterscheidbar sind. Bei mir kollidierten die alt-Binds mit meinen
   dwm-Shortcuts, daher der Wechsel auf `ctrl+shift` in Kombination mit moderner CSI-u-Ausgabe.
3. **Wayland.** Noch nicht unterstützt. `xclip` braucht X11, ein `wl-copy`- Fallback müsste nachgereicht werden, falls
   das jemanden interessiert.

## Und Pi bleibt, wie es ist

Ein Satz, der hier vielleicht überrascht: Ich liebe den Pi Agent einfach weiter. Sprachinput macht die Tastatur nicht
überflüssig, aber lange Prompts und ausführliche Beschreibungen zu sprechen, ist schneller und entspannter als zu
tippen. Das Diktat wandert direkt in das Chatfenster, in dem der Agent ohnehin auf mich wartet.

Der LLM-Stack unter Pi ist übrigens unverändert: llama.cpp mit llama-swap als Proxy, wie in meinem [Artikel zum Umstieg
von Ollama][6] beschrieben. Gewechselt hat nur das Modell. Statt Qwen3.6-27B läuft jetzt Qwen3.8-27B im Format
`UD-Q4_K_XL`, mit Vision-Projector und Multi-Token-Prediction wie gehabt. In der llama-swap-Konfiguration ist das ein
getauschter Modellpfad, und dank TTL wird der VRAM wie bisher automatisch freigegeben, sobald ich ihn für ComfyUI
brauche.

Diese Erweiterung, der Fork mit Diktat-Anbindung, ist übrigens selbst mit dem Pi Agent entstanden, lokal auf meiner
Hardware unter Qwen3.8. Man kann sich inzwischen wirklich die Tools von seinen Tools bauen lassen.

## Fazit

Lokales STT ist für Sprachdiktat definitiv praxistauglich: unter 300ms Latenz, native Interpunktion, keine laufenden
API-Kosten und keine Audio-Daten verlassen das LAN. Der Fork bleibt so schlank wie das Original, eine TypeScript-Datei,
MIT-lizenziert, und läuft seit dieser Woche im Alltag. Wer Pi nutzt und lieber diktiert als tippt: ausprobieren lohnt
sich.

Liebe Grüße  
Sebastian

[1]: https://github.com/sebastianzehner/pi-dictate
[2]: https://github.com/k2-fsa/sherpa-onnx
[3]: https://github.com/amosblomqvist/pi-dictate
[4]: https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-de-kroko-2025-08-06
[5]: https://pi.dev/docs/latest/tmux
[6]: switching-from-ollama-to-llama-cpp/
