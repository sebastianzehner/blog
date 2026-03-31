---
title: "DD-WRT auf dem TL-WR949N installieren – der vollständige Leitfaden"
summary: "Wie ich den brasilianischen TP-Link TL-WR949N Router mit DD-WRT geflasht habe – inklusive SSID-Workaround für Error 18005, Schritt-für-Schritt-Anleitung und TFTP-Recovery."
date: 2026-03-31T19:57:00-03:00
lastmod: 2026-03-31T19:57:00-03:00
draft: false
tags:
  - router
  - firmware
  - dd-wrt
categories:
  - techlab

ShowToc: true
TocOpen: true

params:
  author: Sebastian Zehner
  ShowPageViews: true

cover:
  image: /img/router-firmware-cover.webp
  alt: Router Firmware
  hidden: false
  relative: false
  responsiveImages: false
---

Ich habe die günstigeren TP-Link TL-WR949N Router mit der Firmware von [dd-wrt.com](dd-wrt.com) geflasht. Hier wird nun beschrieben, welche Schritte ich durchführen musste, damit ich diese Firmware verwenden kann.

Am liebsten hätte ich wie bei meinem [OpenWrt One](https://openwrt.org/toh/openwrt/one) als Hauptrouter [openwrt.org](openwrt.org) benutzt aber leider wird das für [diesen Router](https://openwrt.org/toh/tp-link/tl-wr940n) nicht empfohlen. Vor allem deswegen nicht: [OpenWrt on 4/32 devices](https://openwrt.org/supported_devices/openwrt_on_432_devices).

- **Modell:** TL-WR949N(BR) Ver: 6.0

Ich nutze diese Router bei mir hauptsächlich als Access Point in der Werkstatt und im Quincho, mit WPA2 und CCMP-128 (AES), der bestmöglichen Verschlüsselung für WPA2.

## Hintergrund

Der TL-WR949N ist ein brasilianisches Rebranding des TL-WR940N mit identischer Hardware. Er taucht auf der internationalen TP-Link-Website nicht auf und hat daher keine eigene DD-WRT-Unterstützung. Die Hardware Version muss dabei berücksichtigt werden. In meinem Fall ist das die Version 6.0.

Ein direkter Flash-Versuch mit der offiziellen TL-WR940N Firmware oder DD-WRT scheitert über das normale Webinterface mit `Error 18005`, da der WR949N eine andere Hardware-ID trägt. Die Prüfung lässt sich jedoch mit einem Workaround umgehen.

## Benötigte Dateien

| Datei                                 | Zweck                                | Quelle                                                                                           |
| ------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `wr940nv6_3_20_1_up_boot(250925).bin` | TP-Link EU-Stock-Firmware für WR940N | [TP-Link Download-Seite WR940N](https://www.tp-link.com/de/support/download/tl-wr940n/#Firmware) |
| `factory-to-ddwrt-eu.bin`             | DD-WRT Erstinstallation (EU)         | [DD-WRT Router-Database](https://dd-wrt.com/support/router-database/) (`wr940n`)                 |
| `tl-wr940ndv6-webflash.bin`           | DD-WRT Upgrade auf neuere Build      | [DD-WRT Router-Database](https://dd-wrt.com/support/router-database/) (`wr940n`)                 |

> **Hinweis:** Die Router Database von DD-WRT zeigt veraltete Builds (Stand 2020) und sollte **nicht** verwendet werden. Immer direkt den Beta-Ordner nutzen.

**DD-WRT Beta-Downloads:**

[Download](https://download1.dd-wrt.com/dd-wrtv2/downloads/betas/) → Jahr/Build wählen → `tplink-tl-wr940ndv6`

**Bewährte Builds:**

| Build  | Datum      | Hinweise                        | Download                                                                                                  |
| ------ | ---------- | ------------------------------- | --------------------------------------------------------------------------------------------------------- |
| r44715 | 2020-11-03 | In der Router Database gelistet | [Link](https://download1.dd-wrt.com/dd-wrtv2/downloads/betas/2020/11-03-2020-r44715/tplink_tl-wr940ndv6/) |
| r64210 | 2026-03-31 | Neu im Beta-Ordner bestätigt    | [Link](https://download1.dd-wrt.com/dd-wrtv2/downloads/betas/2026/03-31-2026-r64210/tplink-tl-wr940ndv6/) |

## Voraussetzungen

- LAN-Kabel (immer über LAN-Port flashen, nie WAN)
- Computer mit Browser

> **Hinweis:** Diese Anleitung spiegelt meine eigenen Erfahrungen wider. Das Flashen von Drittanbieter-Firmware erfolgt auf eigene Gefahr – ich übernehme keine Haftung für gebrickte Router oder andere Schäden. Im Zweifel lieber zweimal lesen bevor man loslegt.

## Schritt 1 – TP-Link EU-Stock-Firmware einspielen

**Die aktuelle Firmware auf meinem TL-WR949N v6 Router:**

```text
Versão de Firmware:	3.18.1 Build 171115 Rel.43350n
Versão de Hardware:	WR949N v6 00000000
```

Der WR949N blockiert das Einspielen fremder Firmware über das Webinterface mit `Error 18005`, den ich aber mit [diesem Workaround](https://openwrt.org/toh/tp-link/tl-wa801nd) wie folgt umgehen kann.

### Firmware-Sperre umgehen

Um den Workaround zu verwenden, trage ich die folgenden Zeilen nacheinander als SSID des Geräts ein – die Backticks müssen dabei mit eingegeben werden. SSID setzen und zwischen jeder Zeile speichern.

1. Webinterface öffnen: `http://192.168.0.1` – Login: `admin` / `admin`
2. **Wireless → SSID-Feld → folgende Zeilen nacheinander eintragen und jeweils speichern (Atualizar)**

```bash
`echo "httpd -k"> /tmp/s`
`echo "sleep 10">> /tmp/s`
`echo "httpd -r&">> /tmp/s`
`echo "sleep 10">> /tmp/s`
`echo "httpd -k">> /tmp/s`
`echo "sleep 10">> /tmp/s`
`echo "httpd -f">> /tmp/s`
`sh /tmp/s`
```

Nach dem letzten Schritt (`sh /tmp/s`) wird der `httpd`-Prozess neu gestartet – der Router selbst bootet **nicht** neu, aber das Webinterface ist ca. 20–30 Sekunden nicht erreichbar.

### Firmware flashen

1. Webinterface öffnen: `http://192.168.0.1` – Login: `admin` / `admin`
2. **System Tools (Ferramentas de sistema) → Firmware Upgrade (Atualizar firmware)**
3. `wr940nv6_3_20_1_up_boot(250925).bin` auswählen → **Upgrade (Atualizar)**
4. Wenige Minuten warten bis der Flash-Vorgang abgeschlossen ist und der Router automatisch neu startet
5. Factory-Reset: Reset-Knopf **20 Sekunden** gedrückt halten und warten bis der Router neu gestartet ist

Das Webinterface ist danach wieder über `192.168.0.1` erreichbar. Beim ersten Aufruf wird direkt nach einem neuen Passwort gefragt – es gibt keinen separaten Benutzernamen mehr, nur noch die Passwortabfrage.

Das Interface ist nun auf Englisch statt Portugiesisch – das zeigt, dass die EU-Firmware aktiv ist.

**Die Firmware nach dem Update:**

```text
Firmware Version:	3.20.1 Build 250925 Rel.57536n (4555)
Hardware Version:	WR940N v6 00000000
```

Ich kann jetzt diese Firmware verwenden oder weiter zu Schritt 2 übergehen und DD-WRT einspielen.

## Schritt 2 – DD-WRT Erstinstallation

Ich kann nach dem ersten Schritt nun problemlos DD-WRT über das Webinterface einspielen und erhalte keinen `Error 18005` mehr.

### Firmware flashen

1. Webinterface öffnen: `http://192.168.0.1` – Passwort eingeben
2. **System Tools → Firmware Upgrade**
3. Aktuelle `factory-to-ddwrt-eu.bin` auswählen → **Upgrade**
4. Wenige Minuten warten bis der Flash-Vorgang abgeschlossen ist und der Router automatisch neu startet
5. Factory-Reset: Reset-Knopf **20 Sekunden** gedrückt halten und warten bis der Router neu gestartet ist

Das Webinterface ist danach über `http://192.168.1.1` erreichbar. Beim ersten Aufruf wird direkt nach einem neuen Benutzernamen und Passwort gefragt. Der Router kann nun eingerichtet werden.

## Schritt 3 – Upgrade auf neueren DD-WRT-Build

Die `webflash.bin` ist für Upgrades gedacht, wenn DD-WRT bereits auf dem Router läuft. Sie kommt aus demselben Build-Verzeichnis wie die `factory-to-ddwrt`-Datei.

### Firmware flashen

1. Webinterface öffnen: `http://192.168.1.1` – Benutzername und Passwort eingeben
2. **Administration → Firmware Upgrade**
3. `tl-wr940ndv6-webflash.bin` hochladen → **Upgrade**
4. Wenige Minuten warten bis der Flash-Vorgang abgeschlossen ist und der Router automatisch neu startet
5. Factory-Reset empfohlen: Reset-Knopf **20 Sekunden** gedrückt halten und warten bis der Router neu gestartet ist

## Zurück zu TP-Link Stock (TFTP-Recovery)

Wenn DD-WRT auf dem Router läuft und zur Original-Firmware zurückgekehrt werden soll:

```
PC-IP:       192.168.0.66 / 255.255.255.0
TFTP-Datei:  wr940nv6_tp_recovery.bin
             (Inhalt: TP-Link Stock-Firmware, umbenannt)
```

> **Wichtig:** PC und Router müssen über einen **Netzwerk-Switch** verbunden sein – eine direkte Verbindung funktioniert nicht, weil Windows die Ethernet-Verbindung beim Router-Neustart kurz unterbricht und dadurch den TFTP-Request verpasst.

**Vorgehen:**

1. PC und Router über einen Switch verbinden
2. TFTP-Server starten (z.B. [tftpd64](https://pjo2.github.io/tftpd64/) oder [atftp](https://sourceforge.net/projects/atftp/))
3. Verzeichnis mit der umbenannten Datei auswählen
4. Interface `192.168.0.66` wählen
5. Router ausschalten
6. Reset-Knopf gedrückt halten, Router einschalten
7. Reset-Knopf gehalten lassen bis der TFTP-Transfer startet (~10 Sekunden)
8. Warten bis Transfer abgeschlossen und Router neu startet

> **Hinweis:** Die originale TP-Link-Firmware muss vor dem Umbenennen den Boot-Header enthalten (Dateiname enthält `up_boot`). Firmware ohne `up_boot` im Namen **nicht** für TFTP verwenden.

## Fazit

Der TL-WR949N ist ein günstiger Router, der sich mit etwas Geduld und den richtigen Schritten problemlos mit DD-WRT betreiben lässt. Der Workaround über das SSID-Feld ist ungewöhnlich, funktioniert aber zuverlässig – und mit der aktuellen DD-WRT-Firmware läuft der Router stabil als Access Point.

Die Dokumentation dieser Schritte hat sich gelohnt: Beim nächsten Router muss ich nicht mehr wie heute von vorne anfangen.

Hast du den TL-WR949N oder einen ähnlichen Router geflasht? Ist dir dabei etwas anderes aufgefallen, oder hast du einen anderen Weg gefunden? Ich freue mich über Kommentare – direkt hier unten über Cactus Comments, mit deinem Matrix-Account oder ganz ohne Account als Gast. Das ist wohl auch ein Thema für einen weiteren Blogartikel.

Liebe Grüße Sebastian

{{< chat installing-dd-wrt-on-the-tl-wr949n >}}
