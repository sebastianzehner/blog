+++
title = 'Rainy 75 Pro: So sieht meine perfekte Tastatur aus'
#description = 'Eine kurze Beschreibung unter dem Titel.'
summary = 'Im April 2025 habe ich sie gefunden: meine perfekte Tastatur. Die **Rainy 75 Pro** von Wobkey ist nicht nur hochwertig - sie hat mich vom ersten Tastenanschlag an begeistert.'
date = 2025-08-05T09:35:10-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-05T09:35:10-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'Keyboard', 'Rainy75Pro', 'keyd', 'setxkbmap']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/rainy-75-pro-this-is-what-my-perfect-keyboard-looks-like.webp'
    alt = 'Beitragsbild von Rainy 75 Pro: So sieht meine perfekte Tastatur aus'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

## Meine perfekte Tastatur für macOS und Linux

Im April 2025 habe ich sie gefunden: meine perfekte Tastatur. Die **Rainy 75 Pro** von [Wobkey](https://www.wobkey.com/products/rainy75) ist nicht nur hochwertig - sie hat mich vom ersten Tastenanschlag an begeistert.

Das massive Unibody-Gehäuse aus Aluminium, der satte Klang und das ausgewogene Schreibgefühl machen sie zu einem echten Highlight. Besonders wichtig war mir aber, dass sie sich nahtlos in mein Setup mit mehreren Systemen (macOS und Linux) integriert – ohne Umstecken, ohne ständiges Konfigurieren.

Ich nutze die Tastatur über USB an einem KVM-Switch. Dabei ist wichtig, sie **nicht** an den dedizierten "Tastatur-Port" des Switches anzuschließen (der nur eine einfache Tastatur emuliert), sondern an einen **echten USB-Port** - sonst funktionieren Sonderfunktionen wie Makros und VIA-Kompatibilität nicht zuverlässig.

In diesem Artikel zeige ich, wie ich die Tastatur optimal auf meine Bedürfnisse angepasst habe: inklusive Unterstützung für Umlaute trotz US-Layout, Remapping und praktischen Makros mit **keyd** und **Via**.

## Warum das US-Layout?

Wer viel programmiert, landet früher oder später beim **US-Layout**. So ging es zumindest mir. `{}`, `[]` oder `~` - all diese Zeichen sind ohne Verrenkungen erreichbar, und das macht im Alltag einen echten Unterschied.

Außerdem ist das **US-Layout** in vielen Tools und Betriebssystemen die Referenz. Tastenkombinationen funktionieren zuverlässiger, und auch beim Remote-Zugriff (z. B. via SSH) gibt’s seltener Probleme mit vertauschten Tasten.

Klar, Umlaute fehlen - aber keine Sorge: Auch dafür gibt’s elegante Lösungen. Sowohl unter macOS als auch unter Linux.

## Umlaute unter macOS: Einfach mit der Win- bzw. rechten Alt-Taste

Auf meinem Mac Studio gebe ich Umlaute über folgende Tastenkombinationen ein:

```
Win+u dann u → ü
Win+u dann a → ä
Win+u dann o → ö
Win+s → ß
```

Das funktioniert erstaunlich gut - ganz ohne zusätzliche Tools oder externe Software. Die **rechte Alt-Taste** erfüllt hier denselben Zweck und ist sogar der **Win-Taste** vorzuziehen – unter macOS entspricht sie der **Option-Taste**.

**Wichtig:** Die Tastatur muss dafür im Mac-Modus laufen. Den aktiviert man durch **langes Drücken von** `Fn + M` (mindestens 3 Sekunden).

Nur so stimmen auch die macOS-spezifischen Belegungen wie Command (⌘) und Option (⌥).

## Umlaute unter Linux: Mit keyd und der Compose-Taste

Unter Ubuntu mit Gnome war die Einrichtung einfach: Ich habe das Tastaturlayout auf **English (Macintosh)** umgestellt und unter _Alternative Characters Key_ die **linke Alt-Taste** gewählt. Damit funktionierten die gleichen Tastenkombinationen wie unter macOS. Zu empfehlen ist dies jedoch nicht und es sollte hier auch eher die **rechte Alt-Taste** als bekannte **AltGr-Taste** genutzt werden.

Auf minimalistischen Setups wie Alpine oder Arch Linux - meinen bevorzugten Linux-Distributionen - funktioniert das nicht ohne Weiteres. Dort kommt `keyd` ins Spiel. Genau da liegt dann auch mein Schwerpunkt, denn das sind die Systeme, welche ich selbst täglich nutze.

### Dank keyd - Tastatur-Remapping, wie es sein soll

**Keyd** ist ein leichtgewichtiges, systemweites Tool zum Umbelegen von Tasten - unabhängig vom Desktop Environment. Genau richtig für schlanke Linux-Setups.

**Installation unter Alpine Linux**

```bash
doas apk add keyd setxkbmap
```

**Oder unter Arch Linux:**

```sh
sudo pacman -Sy keyd xorg-setxkbmap
```

**Basiskonfiguration: `/etc/keyd/default.conf`**

```ini
[ids]
*

[main]
leftalt = leftmeta
leftmeta = leftalt
```

Damit wird z. B. die **linke Alt-Taste** zur **Super-Taste** (Meta) und umgekehrt.

### Compose Key aktivieren mit setxkbmap

Mit folgendem Befehl wird die Compose-Funktion systemweit aktiviert:

```bash
setxkbmap -option compose:menu
```

In meiner `.xinitrc` sieht das dann so aus:

```bash
#!/bin/bash

# set compose key
setxkbmap -option compose:menu
```

Bei mir wurde die **rechte Control-Taste** zur **Compose-Taste** (normalerweise ist das die **AltGr**-Taste) - ideal für Sonderzeichen und Umlaute.

Da meine Tastatur keine eigene **AltGr**-Taste hat, hatte ich zuvor in **Via** die **rechte Control-Taste** als **rechte Alt-Taste** konfiguriert. Auch wenn **AltGr** unter vielen Linux-Desktops direkt für Sonderzeichen genutzt werden kann, ist die **Compose-Taste** oft flexibler – besonders in minimalistischen Setups.

### Erweiterte keyd Konfiguration für Umlaute

Für noch bequemere Eingaben habe ich einen eigenen `keyd`-Layer namens **dia** erstellt. Darin definiere ich Makros für Umlaute und Sonderzeichen:

```ini
[dia]

# Make o to ö
o = macro(compose o ")

# Make a to ä
a = macro(compose a ")

# Make u to ü
u = macro(compose u ")

# Make e to €
e = macro(compose e =)

# Make s to ß
s = macro(compose s s)
```

Die **rechte Alt-Taste** (AltGr) aktiviert diesen Layer:

```ini
rightalt = layer(dia)
```

So genügt z. B. **AltGr + o** für ein `ö` - deutlich schneller und intuitiver als die klassischen Compose-Sequenzen.

### Den keyd Service starten

Damit `keyd` automatisch beim Systemstart geladen wird, muss folgender Dienst aktiviert werden:

**Unter Alpine Linux**

```bash
doas rc-update add keyd
doas rc-service keyd start
```

**Fehlermeldung beim Start?**

Falls `keyd` beim Starten abstürzt, liegt das unter Umständen an einem Konflikt mit dem Paket `keyd-openrc`. In dem Fall hilft folgende Reihenfolge:

```bash
doas apk del keyd-openrc
reboot
doas rc-update add keyd
doas rc-service keyd start
```

**Unter Arch Linux**

```bash
sudo systemctl enable -now keyd
```

**Konfiguration neu laden**

Nach Änderungen an der Datei `/etc/keyd/default.conf` kann `keyd` wie folgt neu geladen werden:

```bash
keyd reload
```

## Copy & Paste im Terminal

Unter macOS klappt Copy & Paste auch im Terminal ganz bequem mit `Alt+C` und `Alt+V`. Das ist für macOS `Command+C` und `Command+V`.

Unter Linux ist das nicht ganz so einfach: In vielen Terminal-Emulatoren ist `Ctrl+C` nicht zum Kopieren da, sondern beendet das aktuell laufende Programm. Stattdessen verwendet man oft `Shift+Ctrl+C` zum Kopieren und `Shift+Ctrl+V` zum Einfügen – was schnell unpraktisch wird, besonders wenn man regelmäßig zwischen Programmen und Systemen wechselt.

In meinem Setup mit **st** - dem minimalistischen Terminal von [suckless](https://st.suckless.org/) - war Copy & Paste anfangs ungewohnt.

Wie ich das optimiert habe - inklusive **Clipboard-History** und eigenen Tastenkombinationen - zeige ich gerne in einem der nächsten Blogartikel.

## Tastatur-Firmware mit Via anpassen

**Via** ist eine [Web-App](https://www.usevia.app/), mit der sich kompatible Tastaturen wie meine **Rainy 75 Pro** komfortabel konfigurieren lassen.

Damit lassen sich Tastenbelegungen, Makros und Layer direkt in der Firmware ändern - ohne Flashen, direkt über USB.

**Wichtig:** Via funktioniert nur, wenn die Tastatur **direkt per USB angeschlossen** ist – also **nicht über einen KVM-Switch**. Außerdem werden vor allem **Chrome-basierte Browser** unterstützt; **Firefox** funktioniert derzeit nicht.

**Beispiel:** Makro für `Ctrl+S` auf `Caps Lock`

Ich habe die **Caps Lock**-Taste durch ein Makro ersetzt, das `Ctrl+S` sendet:

- Makro: `{KC_LCTL, KC_S}`
- Verwendung: In **nvim** und **tmux** nutze ich `Ctrl+S` (statt `Ctrl+B`) als Leader Key.

So kann ich den Leader bequem mit einem einzigen Tastendruck auf **Caps Lock** aktivieren - **sehr praktisch im täglichen Workflow**.

Ich habe zudem in **Via** die rechte **Ctrl**-Taste als rechte **Alt**-Taste konfiguriert.

## Fazit

Meine **Rainy 75 Pro** ist nicht nur ein optischer und haptischer Genuss - mit den richtigen Tools wie `keyd`, `setxkbmap` und **Via** lässt sich auch der Funktionsumfang auf ein ganz neues Level heben. Egal ob macOS oder Linux - ich kann nahtlos arbeiten, Umlaute schreiben und habe volle Kontrolle über meine Tastenkombinationen.

In zukünftigen Artikeln werde ich tiefer auf meine Linux Installationen mit **dwm**-, **nvim**- und **Clipboard-Konfiguration** eingehen. Wer Fragen zur Tastatur oder den Konfigurationen hat, kann mir gerne schreiben oder einen Kommentar hinterlassen.

**Hinweis:** Die Rainy 75 Pro gibt es z. B. [hier auf Amazon](https://amzn.to/3HfwkO5) - Affiliate-Link, keine Mehrkosten für dich.

**Verwendete Tools:**

- [Rainy 75 Pro - Wobkey](https://www.wobkey.com/products/rainy75)
- [Keyd GitHub Repo](https://github.com/rvaiya/keyd)
- [Setxkbmap Linux man page](https://linux.die.net/man/1/setxkbmap)
- [Via Web App](https://www.usevia.app/)

{{< chat Rainy75Pro >}}
