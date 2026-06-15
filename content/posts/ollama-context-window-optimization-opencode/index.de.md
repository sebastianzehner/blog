---
title: "Ollama Context Window optimieren: Der Schlüssel für erfolgreiche OpenCode Integration"
summary: Das Context Window ist der unsichtbare Flaschenhals vieler Ollama-Setups. Drei Lösungswege zur Optimierung, Praxistests mit verschiedenen Modellen und konkrete Empfehlungen für erfolgreiche OpenCode Integration mit lokalen LLMs.
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
---

Ollama hat sich als beliebte Lösung etabliert, um Large Language Models (LLMs) lokal auf eigener Hardware auszuführen. Doch viele Nutzer stoßen bei der Integration mit Tools wie OpenCode auf mysteriöse Probleme:

Tool Calls funktionieren nicht, Agents verlieren den Kontext, und Code-Generierung bleibt weit hinter den Erwartungen zurück. Die Ursache liegt meist nicht am Modell selbst, sondern an einer oft übersehenen Einstellung: **dem Context Window**.

## Das Context Window Problem: Warum 4096 Tokens nicht ausreichen

Ollama verwendet standardmäßig ein Context Window von nur 4096 Tokens und das unabhängig davon, wie groß das Modell theoretisch ist. Dieser Wert mag für einfache Chat-Interaktionen ausreichen, wird aber zum Flaschenhals, sobald komplexere Aufgaben anstehen.

Für anspruchsvolle Anwendungen wie:

- Code-Generierung und Refactoring
- Tool Calling mit mehreren Funktionen
- Agent-basierte Workflows
- OpenCode Integration

ist dieser Standard praktisch immer zu klein. Das Modell kann seinen theoretischen Context von 32k, 128k oder sogar 256k Tokens gar nicht nutzen, weil Ollama ihn künstlich begrenzt.

Ich habe mich gewundert, warum bei mir OpenCode auf meinem Computer mit diversen lokalen Modellen nicht funktionierte und bin der Sache auf die Spur gegangen.

Nun habe ich vertsanden, warum ich anfangs keinen Erfolg hatte und das LLM nicht so wollte, wie ich mir das gewünscht habe. Ich stand kurz davor aufzugeben aber habe nun die Lösung.

## Context Window verstehen und konfigurieren

Der Context wird über den Parameter `num_ctx` gesteuert. Mit einem einfachen Befehl lässt sich überprüfen, welcher Wert aktuell aktiv ist:

```bash
ollama ps
```

Die Ausgabe zeigt deutlich das Problem:

```bash
NAME                ID              SIZE      PROCESSOR    CONTEXT    UNTIL
qwen2.5-coder:7b    dae161e27b0e    4.9 GB    100% GPU     4096       4 minutes from now
```

Trotz leistungsstarker Hardware und einem Modell, das theoretisch viel mehr verarbeiten könnte, sind nur 4096 Tokens verfügbar.

## Lösung 1: Globaler Context über systemd

Die eleganteste Lösung für ein konsistentes Setup ist das Setzen einer Environment Variable auf Systemebene. So werden alle Modelle automatisch mit dem gewünschten Context geladen.

```bash
sudo systemctl edit ollama.service
```

Alternativ kann die Override-Datei direkt bearbeitet werden:

```bash
sudo nvim /etc/systemd/system/ollama.service.d/override.conf
```

Folgender Eintrag erhöht den Standard-Context auf 16384 Tokens:

```bash
[Service]
Environment="OLLAMA_HOST=0.0.0.0"
Environment="OLLAMA_CONTEXT_LENGTH=16384"
```

Nach dem Reload ist die Änderung aktiv:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

Die Verifizierung mit einem anderen Modell zeigt den Erfolg:

```bash
NAME               ID              SIZE     PROCESSOR    CONTEXT    UNTIL
qwen3-coder:30b    06c1097efce0    20 GB    100% GPU     16384      4 minutes from now
```

## Lösung 2: Manuelle Context-Anpassung im Chat

Für Tests oder gelegentliche Nutzung kann der Context auch direkt im Ollama Chat gesetzt werden:

```bash
ollama run qwen3:32b
```

Im Chat:
```bash
/set parameter num_ctx 12288
```

**Tipp:** Mit `/save qwen3-12k:32b` lässt sich sogar eine neue Modell-Variante mit diesem Context speichern. Beim nächsten `ollama list` ist sie verfügbar.

## Lösung 3: Modelfiles – Die professionelle Methode

Die nachhaltigste Lösung sind Modelfiles. Sie kosten nur Sekunden an Erstellungszeit, praktisch keinen Speicherplatz und dokumentieren die Konfiguration perfekt.

Beispiel-Modelfile für Ministral-3 mit 64k Context:

```Modelfile
FROM ministral-3:14b
PARAMETER num_ctx 65536
```

Erstellen:

```bash
ollama create ministral-3-64k:14b -f ministral-3-64k-14b.Modelfile
```

Das Ergebnis:

```bash
NAME                   ID              SIZE     PROCESSOR    CONTEXT    UNTIL
ministral-3-64k:14b    e1befb46cf0d    20 GB    100% GPU     65536      4 minutes from now
```

## Hardware-Limits: Was ist mit einer RTX 4090 möglich?

Ein höherer Context ist kein unbegrenztes Feature, sondern ein Hardware-Budget. Die GPU bestimmt, was realistisch nutzbar ist.

Bei meinen Tests mit einer RTX 4090 (24 GB VRAM) zeigten sich folgende optimale Werte:

| Modell | Sinnvoller Context | Maximaler Context | VRAM-Nutzung |
|--------|-------------------|-------------------|--------------|
| qwen2.5-coder:7b | 32k | 32k | 8.2 GB |
| ministral-3:14b | 64k | 256k | 20 GB |
| qwen3-coder:30b | 32k | 256k | 22 GB |
| deepseek-r1:32b | 10k | 128k | 22 GB |
| gpt-oss:20b | 128k | 128k | 17 GB |

Ein zu hoher `num_ctx` führt zu:

- Out-of-Memory-Fehlern
- Extrem langsamen Antworten
- Instabilem Tool Calling
- CPU/GPU-Split statt reiner GPU-Nutzung

Beispiel eines überladenen Modells:

```bash
NAME         ID              SIZE     PROCESSOR          CONTEXT    UNTIL
qwen3:32b    030ee887880f    29 GB    22%/78% CPU/GPU    32768      4 minutes from now
```

Der CPU-Anteil zeigt: Die GPU ist ausgelastet, Performance-Einbußen sind die Folge.

## Praxistest: Welche Modelle funktionieren mit OpenCode?

Nach ausgiebigen Tests haben sich drei Modelle als besonders geeignet herauskristallisiert:

### qwen3-coder:30b – Der Coding-Spezialist

Mit einem 32k Context Window läuft dieses Modell optimal auf der RTX 4090. Die Tool-Nutzung ist zuverlässig, die Geschwindigkeit beeindruckend. Das Ergebnis kommt dem Feeling von Claude Code schon nahe – auch wenn Claude noch eine Klasse für sich ist.

### devstral-small-2:24b – Der solide Allrounder

Nach Vorlage erstellt dieses Modell Dateien und passt sie nach Vorgabe an. Gelegentlich gibt es kleinere Aussetzer beim Context-Handling, aber insgesamt eine stabile Performance bei 32k Context.

### gpt-oss:20b – Der Analyse-Champion

Das wahre Highlight: 128k Context ohne Performance-Einbußen. Perfekt für Code-Reviews, Dokumentationsanalysen und umfangreiche Projekte. Selbst wenn Tool Calls mal fehlschlagen, korrigiert das Modell sich selbstständig.

Der einzige Nachteil: Markdown-Tabellen wurden in OpenCode nicht optimal gerendert aber dafür habe ich inzwischen [dieses Plugin](https://github.com/franlol/opencode-md-table-formatter) gefunden.

### qwen2.5-coder:7b – Nicht empfohlen

Trotz 32k Context: Mit nur 7 Milliarden Parametern ist das Modell zu klein für zuverlässiges Tool Calling in OpenCode.

## Praktische Empfehlung für RTX 4090 Nutzer

Meine aktuelle Empfehlung nach eigenen Tests liegt bei diesen Modellen:

| Use Case | Modell | Context |
|----------|--------|---------|
| Coding / Tools | Qwen3-Coder-30B | 16–32k |
| Review / Analysis | GPT-OSS-20B | 64–128k |
| Long Docs / Knowledge | Ministral-14B | 32–64k |

## Modelfile-Management: Organisation ist alles

Ein dediziertes Verzeichnis für Modelfiles zahlt sich aus:

```bash
/mnt/sumpf/ai/opencode/ollama/modelfiles/
├── gpt-oss-64k-20b.Modelfile
├── gpt-oss-128k-20b.Modelfile
└── ministral-3-64k-14b.Modelfile
```

So bleibt nachvollziehbar, warum welches Modell wie konfiguriert wurde – auch nach Monaten noch.

## Wartung und Updates

Bei System-Updates unter Arch Linux bleiben die Overrides in der `override.conf` automatisch erhalten. Nach manuellen Änderungen genügt:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

## Fazit: Context ist kein Feature, sondern ein Budget

Das Context Window ist der unsichtbare Flaschenhals vieler Ollama-Setups. Wer OpenCode oder ähnliche Tools nutzen möchte, muss den Standard-Wert von 4096 Tokens unbedingt anpassen.

Die drei Lösungswege – globale Environment Variable, Chat-Commands oder Modelfiles – bieten für jedes Szenario die passende Flexibilität. Entscheidend ist das Verständnis, dass ein höherer Context kein unbegrenztes Feature ist, sondern immer im Kontext der verfügbaren Hardware betrachtet werden muss.

Mit den richtigen Einstellungen wird Ollama zu einer leistungsstarken lokalen KI-Infrastruktur, die auch anspruchsvolle Workflows zuverlässig unterstützt.

Ich kann eines der genannten LLMs nun auch auf mein lokales Wiki zugreifen lassen, um es mit Kontext zu füllen, welcher direkt weiterverarbeitet werden kann. Das ist schon erstaundlich, was heutzutage alles möglich ist. Ich lerne täglich dazu und es macht Spaß.

**Welche Erfahrungen hast du mit Ollama und OpenCode gemacht?** Welches Modell läuft bei dir am besten? Schreib mir deine Empfehlungen und Setup-Tipps gerne in die Kommentare – ich bin gespannt auf dein Feedback!

{{< chat ollama-context >}}
