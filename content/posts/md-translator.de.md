---
title: Die Herausforderung mehrsprachiger Blogs
summary: Mehrsprachige Blogs bringen Übersetzungsaufwand mit sich. Manuelle Übersetzungen sind teuer, automatische Tools beschädigen oft die Markdown-Struktur. Wie bleibt man trotzdem effizient und behält das Format?
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
  alt: Blogger verwaltet mehrsprachigen Blog mit Deutsch, Englisch, Spanisch und Französisch am Laptop
  hidden: false 
  relative: false
  responsiveImages: false
---

Als Blogger mit einem mehrsprachigen Blog steht man vor einer ständigen Herausforderung: Jeder neue Artikel muss in mehrere Sprachen übersetzt werden. Manuelle Übersetzungen sind zeitaufwändig und teuer, automatische Tools zerstören oft die sorgfältig formatierte Markdown-Struktur. Was tun?

Genau vor diesem Problem stand ich, als ich begann, meinen Blog in Deutsch, Englisch und Spanisch zu veröffentlichen. Die Lösung: Ein intelligenter Markdown-Übersetzer, der die Struktur bewahrt und hochwertige Übersetzungen liefert.

## Die Entstehung von md-translator

md-translator ist ein Python-basiertes Tool, das Markdown-Dateien mit Hilfe von KI übersetzt, ohne die Formatierung zu zerstören. Das Besondere: Es nutzt Tencent's Hunyuan-MT-7B Modell, ein spezialisiertes Übersetzungsmodell mit 7 Milliarden Parametern, das aktuell 38 Sprachen unterstützt.

Die Lösung wurde schrittweise aufgebaut und fortlaufend angepasst. Anfangs war das Ziel einfach: Eine Markdown-Datei übersetzen. Doch schnell zeigten sich die Tücken:

- Code-Blöcke wurden übersetzt (katastrophal!)
- Links zerbrachen in ihre Bestandteile
- Tabellen verloren ihre Struktur
- Front Matter wurde komplett durcheinandergebracht
- URL-Pfade passten nicht zur mehrsprachigen Blog-Struktur

Jedes dieser Probleme führte zu einer neuen Funktion, einem neuen Bugfix, einer Verbesserung. Das Ergebnis ist ein robustes Tool, das inzwischen in Version 1.2.3 vorliegt.

## Entwicklung mit Claude Code

md-translator wurde nicht im Alleingang entwickelt - ich nutzte Claude Code, Anthropics KI-Coding-Assistent im Terminal. Diese Zusammenarbeit zwischen Mensch und KI war der Schlüssel zum Erfolg.

### Der Entwicklungsprozess

Die Entwicklung verlief iterativ über mehrere Tage:

1. **Initiales Konzept**: Ich definierte die Anforderungen - ein Markdown-Übersetzer, der die Struktur bewahrt
2. **Prototyping**: Claude Code schrieb die erste Version mit grundlegender Markdown-Parsing-Logik
3. **Testing & Iteration**: Ich testete mit echten Blog-Artikeln, fand Probleme, und Claude Code implementierte Fixes
4. **Feature-Erweiterung**: Jedes neue Problem führte zu einem Gespräch über die beste Lösung

Was mich beeindruckt hat: Claude Code verstand nicht nur den Code, sondern auch den Kontext. Wenn ich sagte "die Tabellen-Formatierung geht kaputt", analysierte es das Problem, schlug eine Lösung vor und implementierte sie - inklusive Edge Cases.

### Die Herausforderungen

Nicht alles klappte beim ersten Versuch. Die Bold/Italic-Formatierung war ein perfektes Beispiel für die Grenzen:

- Wir versuchten mehrere Ansätze: Marker-Systeme, Normalisierung, XML-Tags
- Jeder Ansatz funktionierte teilweise, aber nicht konsistent
- Am Ende entschieden wir gemeinsam: Übersetzungsqualität geht vor perfekter Formatierung

Diese pragmatische Entscheidungsfindung - ein Mix aus KI-Vorschlägen und menschlicher Urteilskraft - war wertvoll.

### Was gut funktionierte

Die Zusammenarbeit mit Claude Code hatte klare Vorteile:

- **Geschwindigkeit**: Features, die Stunden gekostet hätten, waren in Minuten implementiert
- **Code-Qualität**: Sauberer, gut strukturierter Python-Code mit Docstrings
- **Problemlösung**: Alternative Lösungsansätze wurden sofort vorgeschlagen
- **Iteratives Debugging**: Fehler wurden schnell identifiziert und behoben

### Der menschliche Faktor

Trotz KI-Unterstützung war meine Rolle entscheidend:

- **Zielsetzung**: Was soll das Tool können?
- **Testing**: Funktioniert es in der Praxis?
- **Priorisierung**: Welche Features sind wichtig, welche nicht?
- **Entscheidungen**: Bold/Italic weglassen oder komplexe Lösung?

Claude Code ist ein mächtiges Werkzeug, aber kein Autopilot. Die besten Ergebnisse entstehen durch die Zusammenarbeit zwischen menschlicher Expertise und KI-Fähigkeiten.

## Wie md-translator funktioniert

### Intelligente Segmentierung

Der Übersetzer parst Markdown-Dateien nicht einfach als Text, sondern versteht ihre Struktur:

- **Front Matter**: YAML-Metadaten werden selektiv übersetzt (nur title, description, etc.)
- **Headers**: Überschriften werden übersetzt, ihre Hierarchie bleibt erhalten
- **Code-Blöcke**: Werden komplett geschützt und nicht übersetzt
- **Tabellen**: Zelle für Zelle übersetzt, Struktur bleibt intakt
- **Links**: Der Text wird übersetzt, die URL bleibt geschützt
- **Bilder**: Alt-Text wird übersetzt, der Bildpfad bleibt unverändert

### Element-Schutz

Bestimmte Elemente dürfen niemals übersetzt werden:

- Inline-Code wie `variable_name`
- HTML-Tags wie `<div>` oder `<span>`
- URLs in Links und Bildern
- Fußnoten-Referenzen wie `[^1]`

Diese Elemente werden vor der Übersetzung durch Platzhalter ersetzt und danach wiederhergestellt. Das LLM sieht sie nie.

### Intelligente CLI

Die Kommandozeilen-Schnittstelle ist bewusst einfach gehalten:

```bash
python md-translator.py artikel.de.md -l en es
```

Das Tool erkennt automatisch:
- Die Quellsprache aus dem Dateinamen (`artikel.de.md` → Deutsch)
- Generiert automatisch Ausgabedateien (`artikel.en.md`, `artikel.es.md`)
- Lädt das Modell nur einmal für alle Übersetzungen

## Besondere Features

### URL-Rewriting für mehrsprachige Blogs

Ein typisches Problem mehrsprachiger Blogs: Deutsche Artikel leben bei mir unter `/de/posts/my-article`, englische direkt unter `/posts/my-article`, spanische unter `/es/posts/my-article`. Interne Links müssen entsprechend angepasst werden.

md-translator löst das elegant mit einer optionalen Konfigurationsdatei:

```yaml
url_rewriting:
  enabled: true
  patterns:
    de: /de
    en: ""
    es: /es
```

Ein Link wie `/de/posts/my-article` wird automatisch zu `/posts/my-article` (Englisch) oder `/es/posts/my-article` (Spanisch) umgeschrieben.

### Translation Metadata

Jede übersetzte Datei erhält automatisch Metadaten im Front Matter:

```yaml
translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: en
  date: 2024-12-16
  time: "14:23:45"
```

So bleibt nachvollziehbar, wann und wie eine Datei übersetzt wurde. Praktisch für große Blogs mit hunderten Artikeln.

### Automatische Anzeige in Hugo

Die Translation-Metadaten sind nicht nur Dokumentation - sie sind auch praktisch nutzbar. Mein Hugo-Blog wertet diese Daten automatisch aus und zeigt sie im Post-Footer an.

**Hugo Template Anpassung:**

Das Hugo-Template prüft, ob das `translation`-Feld im Front Matter vorhanden ist. Falls ja, wird automatisch ein Hinweis generiert:

```html
# singles.html

{{ if .Params.translation }}
<div class="translation-note-wrapper">
    {{ partial "translation-note.html" . }}
</div>
{{- end }}
```

```html
# translation-note.html

{{ with .Params.translation }}

  {{ $from := i18n (printf "lang_%s" .from) }}
  {{ $to   := i18n (printf "lang_%s" .to) }}

  {{ $toolPage := site.GetPage "posts/md-translator" }}

  {{ $toolName := .tool }}

  {{ if $toolPage }}
    {{ $toolName = printf `<a href="%s">%s</a>` $toolPage.RelPermalink .tool | safeHTML }}
  {{ end }}

  {{ i18n "translation_note" (dict
    "From" $from
    "To" $to
    "Tool" $toolName
    "Version" .version
  ) | safeHTML }}

{{ end }}
```

**Für den Leser sieht das so aus:**

> _This article was translated from German to English using md-translator v1.2.3._

So weiß der Leser sofort und transparent:
- ✅ Dass er eine Übersetzung liest
- ✅ Welches Tool verwendet wurde
- ✅ Von welcher Sprache in welche übersetzt wurde
- ✅ Wann die Übersetzung erstellt wurde

Das ist besonders hilfreich bei Artikeln, die regelmäßig aktualisiert werden. Wenn das Original aktualisiert wird, kann man später neu übersetzen und das Datum zeigt, welche Version der Übersetzung aktuell ist.

### Satzzeichen-Normalisierung

Ein häufiges Problem: Das LLM fügt manchmal Satzzeichen hinzu, wo keine sein sollten. Aus `Über mich` wird `About me.` - mit unerwünschtem Punkt.

md-translator prüft das Original: Wenn kein Satzzeichen am Ende steht, werden auch in der Übersetzung keine hinzugefügt. Simple Logik, große Wirkung.

## Technische Details

### GPU-Optimierung

Das Hunyuan-MT-7B Modell hat 7 Milliarden Parameter. In voller Präzision (FP32) würde es etwa 28 GB VRAM benötigen - zu viel für die meisten Grafikkarten.

Die Lösung: FP16 (Half-Precision). Das halbiert den Speicherbedarf auf ungefähr 14 GB und verdoppelt die Geschwindigkeit. Auf einer RTX 4090 läuft die Übersetzung damit butterweich.

### Post-Processing

Nach der Übersetzung passiert noch einiges:

1. **Markdown-Syntax-Korrektur**: Leerzeichen zwischen `]` und `(` in Links werden entfernt
2. **Bild-Syntax-Wiederherstellung**: Fehlende `!` vor Bildern werden ergänzt
3. **Platzhalter-Wiederherstellung**: Geschützte Elemente werden zurückgesetzt
4. **Link-Übersetzung**: Link-Texte werden separat übersetzt

Das Ergebnis: Perfekt formatierte Markdown-Dateien, die aussehen, als wären sie von Hand geschrieben.

## Lessons Learned

Die Entwicklung von md-translator war lehrreich. Einige Erkenntnisse:

**Was funktioniert:**
- Klare Platzhalter wie `__INLINECODE0__` sind LLM-freundlich
- Segmentierung nach Markdown-Struktur erhält den Kontext
- FP16-Optimierung ist ein Game-Changer für Performance
- YAML-Konfiguration macht das Tool flexibel

**Was nicht funktioniert:**
- Bold/Italic-Formatierung (`*` und `**`) lässt sich nicht zuverlässig schützen
- Das LLM behandelt diese Marker inkonsistent
- Manchmal bleiben sie erhalten, manchmal nicht
- Manuelle Nachbearbeitung ist hier nötig

**Was überraschend gut funktioniert:**
- Tabellen-Übersetzung, Zelle für Zelle
- URL-Rewriting für mehrsprachige Strukturen
- Link-Text-Übersetzung ohne URL-Veränderung

## Praktischer Nutzen

Seit dem Einsatz von md-translator hat sich mein Workflow drastisch vereinfacht:

**Vorher:**
1. Artikel auf Deutsch schreiben
2. In Übersetzungstool kopieren
3. Übersetzen lassen
4. Markdown-Formatierung manuell reparieren
5. Links und Bilder prüfen und korrigieren
6. Front Matter manuell übersetzen
7. URLs für die Zielsprache anpassen
8. Wiederholen für jede Sprache

**Nachher:**
```bash
python md-translator.py artikel.de.md -l en es
```

Zeit für einen 1000-Wörter-Artikel:
- Vorher: ~60-90 Minuten (für 2 Sprachen)
- Nachher: ~3-5 Minuten (reine Übersetzungszeit)

Das ist eine Zeitersparnis von über 90 Prozent!

## Open Source und Zukunft

md-translator ist Open Source und auf GitHub verfügbar. Die aktuelle Version 1.2.3 ist stabil und produktionsreif.

Geplante Features für die Zukunft:
- Batch-Processing für ganze Verzeichnisse
- Unterstützung für weitere Markdown-Dialekte

## Fazit

md-translator zeigt, wie moderne KI praktische Probleme lösen kann. Es ist kein perfektes Tool - Bold/Italic-Formatierung bleibt eine Herausforderung - aber es spart enorm viel Zeit und liefert qualitativ hochwertige Übersetzungen.

Für Blogger, die mehrsprachige Inhalte veröffentlichen, ist es ein Game-Changer. Für mich persönlich hat es die Schwelle gesenkt, Artikel in mehreren Sprachen zu veröffentlichen. Und das ist genau das Ziel: Wissen zugänglich machen, unabhängig von der Sprache.

## Der Meta-Charakter dieses Artikels

Dieser Artikel ist ein perfektes Beispiel für moderne KI-gestützte Entwicklung und Content-Erstellung:

**Die Entstehungsgeschichte:**
1. md-translator wurde **mit Claude Code** entwickelt (KI hilft beim Programmieren)
2. Dieser Artikel wurde **mit Claude Code** geschrieben (KI hilft beim Schreiben)
3. Der Artikel wird **mit md-translator** übersetzt (KI-Tool übersetzt sich selbst)
4. Du liest möglicherweise **die KI-übersetzte Version** dieses Artikels

Das ist Dogfooding in Reinform - und zeigt gleichzeitig die Möglichkeiten der KI-gestützten Arbeit. Vom Code über den Artikel bis zur Übersetzung: KI als Werkzeug, gesteuert von menschlicher Intention und Qualitätskontrolle.

Wenn du diesen Artikel auf Englisch oder Spanisch liest, wirst du am Ende des Artikels den automatischen Übersetzungs-Hinweis sehen - die Hugo-Integration in Aktion!

---

**Technische Spezifikationen:**
- Sprache: Python 3.12
- Framework: PyTorch 2.5.0 mit CUDA 12.4
- Modell: [Tencent Hunyuan-MT-7B](https://github.com/Tencent-Hunyuan/Hunyuan-MT) (7B Parameter, FP16)
- Unterstützte Sprachen: derzeit 38 Sprachen
- Lizenz: MIT
- Repository: [github.com/sebastianzehner/md-translator](https://github.com/sebastianzehner/md-translator)
