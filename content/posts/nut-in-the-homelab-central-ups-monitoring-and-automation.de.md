+++
title = 'NUT im Homelab: Zentrale Steuerung und Überwachung von USV-Systemen'
#description = 'So automatisiere ich mein Homelab bei Stromausfall'
summary = 'In meinem Homelab kommen mehrere unterbrechungsfreie Stromversorgungen (USV) zum Einsatz – darunter Modelle von **Eaton** und **CyberPower**. Sie schützen meine Server, NAS-Systeme und Netzwerkgeräte zuverlässig.'
date = 2025-08-06T20:35:10-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-06T20:35:10-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'USV', 'NUT', 'Docker', 'Notstrom']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/nut-in-the-homelab-central-ups-monitoring-and-automation.webp'
    alt = 'Beitragsbild von NUT im Homelab: Zentrale Steuerung und Überwachung von USV-Systemen'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

## Wie automatisiere ich mein Homelab bei Stromausfall?

In meinem Homelab kommen mehrere unterbrechungsfreie Stromversorgungen (USV) zum Einsatz – darunter Modelle von **Eaton** und **CyberPower**. Sie schützen meine Server, NAS-Systeme und Netzwerkgeräte zuverlässig bei Stromausfällen. Bisher lief jede USV mehr oder weniger isoliert, ohne zentrale Überwachung oder automatisiertes Herunterfahren der Geräte.

Das möchte ich jetzt ändern: Mithilfe von **Network UPS Tools (NUT)** soll mein gesamtes Setup intelligenter und sicherer werden. [NUT](https://networkupstools.org/) ist ein Open-Source-Projekt, das verschiedenste Power-Geräte wie USV-Systeme, Power Distribution Units (PDU), Solarregler und Netzteile unterstützt. Es bietet eine zentrale Plattform zur Überwachung, Steuerung und Automatisierung – sowohl lokal als auch über das Netzwerk hinweg.

**Mein Ziel:**

- Zentrale Überwachung aller USV-Geräte
- Automatisiertes Herunterfahren von Servern bei Stromausfall
- Einbindung in **Home Assistant** zur Integration in mein Smart-Home-System
- Optionale Visualisierung mit Tools wie **Uptime Kuma**
- Webinterface mit **PeaNUT** via Docker

Im folgenden Artikel dokumentiere ich Schritt für Schritt, wie ich **NUT** in meinem Homelab installiert, konfiguriert und erweitert habe.

## NUT installieren

In meinem Homelab kommen mehrere USVs zum Einsatz – darunter eine **Eaton USV**, die über **USB** mit einem **Raspberry Pi 3B** verbunden ist. Auf diesem Pi läuft **Ubuntu Server** (ein Debian-basiertes System), und er übernimmt die Aufgabe eines lokalen **NUT-Servers – ausschließlich für diese eine USV**.

Denn: **Jede USV in meinem Setup wird ihren eigenen NUT-Server erhalten**, jeweils auf einem Gerät, das physisch mit der USV verbunden ist. Die Geräte, die von der jeweiligen USV mit Strom versorgt werden, verbinden sich später mit genau diesem Server, um den Status abzufragen oder bei Stromausfall automatisiert herunterzufahren.

**Schritt 1: Per SSH mit dem Server verbinden**

```bash
ssh user@pi-server.lan
```

**Schritt 2: System aktualisieren**

```bash
sudo apt update && sudo apt upgrade
```

**Schritt 3: NUT installieren**

Die Installation des Network UPS Tools (NUT), inklusive Server, Client und Diagnosewerkzeugen, erfolgt mit:

```bash
sudo apt install nut
```

## NUT konfigurieren

Nach der erfolgreichen Installation wollen wir die angeschlossene USV erkennen und korrekt in NUT einbinden. Dafür nutzen wir das Tool `nut-scanner`, das verfügbare Geräte automatisch auflistet – allerdings gibt es unter Ubuntu Server ein paar Stolpersteine.

**Schritt 1: `nut-scanner` aufrufen**

```bash
sudo nut-scanner -U
```

Auf meinen Systemen erscheinen dabei zunächst einige Warnungen:

```bash
Cannot load USB library (libusb-1.0.so) : file not found. USB search disabled.
Cannot load SNMP library (libnetsnmp.so) : file not found. SNMP search disabled.
Cannot load XML library (libneon.so) : file not found. XML search disabled.
Cannot load AVAHI library (libavahi-client.so) : file not found. AVAHI search disabled.
Cannot load IPMI library (libfreeipmi.so) : file not found. IPMI search disabled.
Cannot load NUT library (libupsclient.so) : file not found. NUT search disabled.
```

Diese Meldungen bedeuten, dass bestimmte Bibliotheken fehlen oder nicht korrekt geladen werden konnten. **Die gute Nachricht:** Für die USB-Erkennung der USV reicht es meist, die fehlenden Bibliotheken durch symbolische Links zu überbrücken. [Hier](https://github.com/networkupstools/nut/issues/2431) geht es zu einem Beitrag auf GitHub, welcher dieses Thema behandelt.

**Schritt 2: Fehlende Bibliotheken über Softlinks verfügbar machen**

Für `pi-server.lan` (Raspberry Pi, ARM64)

```bash
cd /usr/lib/aarch64-linux-gnu/
sudo ln -s libusb-1.0.so.0 libusb-1.0.so
sudo ln -s libavahi-client.so.3 libavahi-client.so
```

Für `sumpfgeist.lan` (x86_64-Server)

```bash
cd /usr/lib/x86_64-linux-gnu/
sudo ln -s libusb-1.0.so.0 libusb-1.0.so
sudo ln -s libavahi-client.so.3 libavahi-client.so
```

> **Hinweis:** Weitere Links wie `libnetsnmp.so`, `libfreeipmi.so` und `libneon.so` konnten nicht erstellt werden, da die entsprechenden Dateien auf meinen Systemen tatsächlich fehlten. Für den reinen USB-Betrieb sind sie jedoch nicht zwingend erforderlich.

**Schritt 3: Erkennungsergebnisse aus `nut-scanner`**

**`pi-server.lan` (Eaton Ellipse 650 PRO)**

```bash
Scanning USB bus.
[nutdev1]
        driver = "usbhid-ups"
        port = "auto"
        vendorid = "0463"
        productid = "FFFF"
        product = "Ellipse PRO"
        serial = "G355M3xxxx"
        vendor = "EATON"
        bus = "001"
        device = "004"
        busport = "005"
        ###NOTMATCHED-YET###bcdDevice = "0100"
```

**`sumpfgeist.lan` (CyberPower CP1600EPFCLCD)**

```bash
Scanning USB bus.
[nutdev1]
        driver = "usbhid-ups"
        port = "auto"
        vendorid = "0764"
        productid = "0601"
        product = "CP1600EPFCLCD"
        serial = "BHYNZ200xxxx"
        vendor = "CPS"
        bus = "003"
        device = "003"
        busport = "001"
        ###NOTMATCHED-YET###bcdDevice = "0200"
```

Beide USVs – **Eaton Ellipse 650 PRO** und **CyberPower CP1600EPFCLCD** – wurden korrekt erkannt. Damit können wir nun die eigentliche Konfiguration in der Datei `ups.conf` vornehmen.

**Schritt 4: USV in `/etc/nut/ups.conf` eintragen**

`pi-server.lan`

```bash
[server-room-rack]
    driver = "usbhid-ups"
    product = "Ellipse PRO"
    desc = "Server Room Rack UPS"
    port = "auto"
    vendorid = "0463"
    productid = "FFFF"
    bus = "001"
```

`sumpfgeist.lan`

```bash
[ups]
    driver = "usbhid-ups"
    product = "CP1600EPFCLCD"
    desc = "HomeLab UPS"
    port = "auto"
    vendorid = "0764"
    productid = "0601"
    bus = "003"
```

Bearbeitet wird die Datei mit:

```bash
sudo nano /etc/nut/ups.conf
```

## NUT-Server konfigurieren

Nach der Definition der angeschlossenen USVs in `ups.conf` geht es nun darum, den NUT-Server für den Netzwerkbetrieb bereitzumachen. Dazu bearbeiten wir mehrere Konfigurationsdateien, legen Benutzer an und aktivieren den Servermodus.

**Schritt 1. `upsd.conf`: Netzwerkzugriff aktivieren**

```bash
sudo nano /etc/nut/upsd.conf
```

Wir fügen folgende Zeile ein, um eingehende Verbindungen von allen Interfaces auf Port 3493 zu erlauben:

```bash
LISTEN 0.0.0.0 3493
```

Alternativ kannst du hier auch die IP-Adresse des Hosts angeben, wenn du den Zugriff einschränken willst.

**Schritt 2. `upsd.users`: Benutzer für NUT-Dienste anlegen**

In dieser Datei definieren wir Benutzer mit unterschiedlichen Rechten. Diese werden später z. B. von `upsmon` oder einem Webinterface verwendet.

```bash
sudo nano /etc/nut/upsd.users
```

`pi-server.lan`

```bash
[admin]
    password = secure_password
    actions = SET
    actions = FSD
    instcmds = ALL
    upsmon primary

[monuser]
    password = secure_password
    upsmon secondary
```

`sumpfgeist.lan`

```bash
[admin]
    password = secure_password
    actions = SET
    actions = FSD
    instcmds = ALL
    upsmon primary

[monuser]
    password = secret
    upsmon secondary
```

> **Hinweis:** Die Passwörter in diesen Beispielen dienen nur der Veranschaulichung. Verwende in der Praxis sichere, individuelle Passwörter und speichere sie ggf. in einem Passwortmanager.

**Schritt 3. `upsmon.conf`: UPS Monitor einrichten**

Der UPS-Monitor (`upsmon`) übernimmt das eigentliche Überwachen der Stromversorgung und löst z. B. das automatische Herunterfahren bei Stromausfall aus. Konfiguration bearbeiten mit:

```bash
sudo nano /etc/nut/upsmon.conf
```

`pi-server.lan`

```bash
MONITOR server-room-rack@localhost 1 admin secure_password primary
```

`sumpfgeist.lan`

```bash
MONITOR ups@localhost 1 admin secret primary
```

> **Die Syntax ist:** `MONITOR <USV-Name>@<Host> <Power-Value> <Benutzer> <Passwort> <primary|secondary>`

**Schritt 4. `nut.conf`: Betriebsmodus aktivieren**

Zum Schluss definieren wir in welchem Modus NUT laufen soll:

```bash
sudo nano /etc/nut/nut.conf
```

Ändere den Eintrag:

```bash
MODE=none
```

zu:

```bash
MODE=netserver
```

Damit ist der NUT-Server bereit für den Einsatz im Netzwerk und kann ab sofort Statusdaten bereitstellen und auf Anfragen von Clients reagieren.

## NUT-Dienste neu starten

Nach der Konfiguration starten wir die NUT-Dienste neu und sorgen dafür, dass sie beim Systemstart automatisch geladen werden.

**Für Debian-/Ubuntu-basierte Systeme**

```bash
sudo systemctl restart nut-server
sudo systemctl enable nut-server

sudo systemctl restart nut-monitor
sudo systemctl enable nut-monitor
```

Damit ist sichergestellt, dass sowohl der NUT-Server (`nut-server`) als auch der Überwachungsdienst (`nut-monitor`) direkt nach dem Booten automatisch gestartet werden.

**Für Alpine Linux**

Unter Alpine Linux werden die entsprechenden Dienste über **OpenRC** verwaltet. Für ein vollständiges Server-Setup müssen sowohl `nut-upsd` als auch `nut-upsmon` gestartet und aktiviert werden:

```bash
doas rc-service nut-upsd restart
doas rc-update add nut-upsd default

doas rc-service nut-upsmon restart
doas rc-update add nut-upsmon default
```

Damit ist der NUT-Server unter Alpine Linux vollständig betriebsbereit und startet auch nach einem Reboot automatisch.

## NUT-Funktion prüfen und Fehler beheben

Sobald der NUT-Server korrekt konfiguriert und gestartet wurde, lässt sich die Kommunikation mit der USV mithilfe des Befehls `upsc` testen:

**USV-Daten anzeigen**

```bash
upsc <UPS-NAME>
```

Beispiel auf `pi-server.lan`:

```bash
upsc server-room-rack
```

Beispiel auf `sumpfgeist.lan`:

```bash
upsc ups
```

**Fehler nach der Konfiguration**

Sollte beim ersten Ausführen die folgende Fehlermeldung erscheinen: `Error: Driver not connected` kann dies an einer fehlerhaften USB-Verbindung liegen. In einem Fall genügte es, das USB-Kabel kurz abzuziehen und erneut zu verbinden. Danach wurde die USV korrekt erkannt und es erschien eine umfangreiche Statusausgabe wie diese:

**Eaton Ellipse 650 PRO**

```bash
Init SSL without certificate database
battery.charge: 100
battery.charge.low: 20
battery.runtime: 1734
battery.type: PbAc
device.mfr: EATON
device.model: Ellipse PRO 650
...
```

**CyberPower CP 1600EPFCLCD**

```bash
Init SSL without certificate database
battery.charge: 100
battery.charge.low: 10
battery.charge.warning: 20
battery.mfr.date: CPS
battery.runtime: 3750
battery.runtime.low: 300
battery.type: PbAcid
battery.voltage: 27.4
battery.voltage.nominal: 24
device.mfr: CPS
device.model: CP1600EPFCLCD
...
```

**Wiederkehrender Fehler nach Reboot**

In einem anderen Fall trat der gleiche Fehler nach einem Neustart erneut auf, jedoch ließ sich dieser nicht durch das Neuverbinden des USB-Kabels beheben.

Die Analyse mit `nut-scanner` brachte hier Klarheit:

```bash
sudo nut-scanner -U
```

Die Ausgabe zeigte, dass sich der USB-Bus und das Device geändert hatten:

**Bei der Installation**

```bash
bus = "003"
device = "003"
```

**Und jetzt**

```bash
bus = "004"
device = "006"
```

Dadurch konnte der Treiber die USV nicht mehr finden. **Lösung:** Die Datei `/etc/nut/ups.conf` wurde angepasst und der neue Bus manuell eingetragen:

```bash
sudo nano /etc/nut/ups.conf
```

Hier den `bus = "003"` ändern zu `bus = "004"` und die Datei speichern. Jetzt ist die USV wieder erreichbar, was mit `upsc ups` überprüft werden kann.

Auch unter https://usv.techlab.icu/ wird sie wieder als **online** angezeigt.

Solche Fehler sollten nicht unbemerkt bleiben – besonders nicht bei einem Stromausfall. Es empfiehlt sich dringend, eine automatisierte Überwachung einzurichten, die folgende Punkte abdeckt:

- Statusprüfung der USVs
- Benachrichtigung bei Verbindungsfehlern

Der nächste Abschnitt des Artikels wird genau darauf eingehen, wie sich solche Mechanismen umsetzen lassen.

## Statusüberwachung mit Uptime Kuma

Ich überwache den Status meiner USV-Geräte mit **Uptime Kuma**, indem ich die JSON-API von **PeaNUT** abfrage. Für jede USV existieren zwei Monitore mit HTTPS-Abfragen auf die folgenden Endpunkte:

- https://usv.techlab.icu/api/v1/devices/ups
- https://usv.techlab.icu/api/v1/devices/server-room-rack

Dabei verwende ich jeweils zwei Suchbegriffe:

1. Dieses Schlüsselwort `"ups.status":"OL"` signalisiert, dass die USV online ist und derzeit Netzstrom anliegt.
2. Wird dieser Text `Device Unreachable` gefunden, bedeutet das, dass die USV nicht mehr erreichbar ist.

Dies könnte etwa durch einen Verbindungsabbruch oder durch einen ausgefallenen NUT-Dienst vorkommen. Die Stromversorgung könnte dennoch weiterhin bestehen, muss aber nicht.

Für eine bessere Übersicht habe ich die beiden Prüfungen pro USV in einer gemeinsamen Gruppe zusammengefasst:

- `UPS [server-room-rack]`
- `UPS [usv]`

So erkenne ich sofort, wenn entweder eine USV **offline** ist oder der Netzstrom **ausgefallen** ist – oder beides. Die Benachrichtigung erfolgt von **Uptime Kuma** über **Gotify**. Beide Dienste laufen bei mir in einem Docker Container und ich kann zu diesem Thema später gerne einen weiteren Blogartikel schreiben.

## PeaNUT mit Docker bereitstellen

[PeaNUT](https://github.com/Brandawg93/PeaNUT) ist ein leichtgewichtiges Web-Dashboard für Network UPS Tools (NUT) – ideal zur Visualisierung des USV-Status. Die Anwendung kann einfach per Docker bereitgestellt werden.

![Image PeaNUT Dashboard](/img/galleries/nut-in-the-homelab-central-ups-monitoring-and-automation/peanut-dashboard.webp)

Hier ist meine `docker-compose.yaml`-Datei zur Installation von PeaNUT:

```yaml
services:
  peanut:
    image: brandawg93/peanut:latest
    container_name: PeaNUT
    restart: unless-stopped
    volumes:
      - /home/sz/docker/peanut/config:/config
    networks:
      peanut:
      proxy:
        ipv4_address: 192.168.x.x
    ports:
      - 8080:8080
    environment:
      - WEB_PORT=8080
      #- WEB_USERNAME="admin"
      #- WEB_PASSWORD="admin1234"
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.peanut.entrypoints=http"
      - "traefik.http.routers.peanut.rule=Host(`usv.techlab.icu`)"
      - "traefik.http.middlewares.peanut-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.peanut.middlewares=peanut-https-redirect"
      - "traefik.http.routers.peanut-secure.entrypoints=https"
      - "traefik.http.routers.peanut-secure.rule=Host(`usv.techlab.icu`)"
      - "traefik.http.routers.peanut-secure.tls=true"
      - "traefik.http.routers.peanut-secure.service=peanut"
      - "traefik.http.services.peanut.loadbalancer.server.port=8080"
      - "traefik.docker.network=proxy"

networks:
  peanut:
  proxy:
    external: true
```

Das Webinterface ist anschließend über https://usv.techlab.icu erreichbar – gesichert via Traefik mit TLS.

In der Datei `settings.yml` im Konfigurationsverzeichnis werden die NUT-Server eingetragen. Bei mir sieht die Konfiguration so aus:

```yaml
NUT_SERVERS:
  - HOST: 192.168.x.x
    PORT: 3493
    USERNAME: admin
    PASSWORD: secure_password
  - HOST: 172.19.x.x
    PORT: 3493
    USERNAME: admin
    PASSWORD: secret

INFLUX_HOST: ""
INFLUX_TOKEN: ""
INFLUX_ORG: ""
INFLUX_BUCKET: ""
INFLUX_INTERVAL: 10
```

## Verwaltung der angeschlossenen USV

Neben der Statusüberwachung können USV-Geräte auch direkt über die Kommandozeile verwaltet werden. Dafür bietet Network UPS Tools (NUT) das Tool `upscmd`.

Zum Beispiel kann mit folgendem Befehl eine Liste aller verfügbaren Kommandos für die USV `server-room-rack` angezeigt werden:

```bash
upscmd -l server-room-rack
```

**Beispiel: Beeper steuern**

Ein typischer Anwendungsfall ist das Deaktivieren oder Reaktivieren des akustischen Alarms (Beeper). Das funktioniert mit Benutzername und Passwort:

```bash
# Beeper deaktivieren
upscmd -u admin server-room-rack beeper.disable

# Beeper wieder aktivieren
upscmd -u admin server-room-rack beeper.enable
```

Nach Eingabe des Passworts wird der Befehl mit `OK` bestätigt. Die USV akzeptiert diese Kommandos direkt über das NUT-Protokoll.

**Weitere wichtige Kommandos**

Hier eine Auswahl nützlicher Kommandos, die je nach Modell verfügbar sein können:

| Befehl           | Beschreibung                                                            |
| ---------------- | ----------------------------------------------------------------------- |
| load.off         | Last sofort ausschalten                                                 |
| load.off.delay   | Last mit Verzögerung ausschalten                                        |
| load.on          | Last sofort einschalten                                                 |
| load.on.delay    | Last mit Verzögerung einschalten                                        |
| shutdown.return  | Last ausschalten, automatisch wieder einschalten wenn Strom zurückkehrt |
| shutdown.stayoff | Last ausschalten und aus bleiben                                        |
| shutdown.stop    | Einen laufenden Shutdown-Vorgang abbrechen                              |

> **Hinweis:** Nicht alle USV-Modelle unterstützen alle Befehle. Die genaue Liste ist gerätespezifisch und kann mit `upscmd -l <ups-name>` abgefragt werden.

## Weitere NUT-Clients hinzufügen

In einem typischen Homelab sind oft mehrere Systeme an unterschiedlichen USVs angeschlossen. Mit Network UPS Tools (NUT) kann nicht nur die direkt verbundene Maschine gesteuert werden, sondern auch alle weiteren Systeme im Netzwerk, die über die gleiche USV mit Strom versorgt werden.

Hierfür richtet man sogenannte **NUT-Clients** ein. Diese verbinden sich mit dem zentralen **NUT-Server**, der per USB-Kabel mit der USV verbunden ist, und erhalten im Falle eines Stromausfalls ein Shutdown-Signal.

**Architektur im Überblick**

- Systeme an der gleichen USV → NUT-Clients, die sich mit dem NUT-Server verbinden
- Systeme mit eigener USV → eigener NUT-Server und Client

**Beispielhafte Zuordnung**

**NUT-Clients:**

- `sumpfkrieger.lan` → Client von `sumpfgeist.lan`
- `sumpfgeist.lan` → Client von `sumpfgeist.lan`
- `nas.techlab.icu` → Client von `sumpfgeist.lan`
- `eq14.lan` → Client von `sumpfgeist.lan`
- `pi-server.lan` → Client von `pi-server.lan`

**NUT-Server:**

- `sumpfgeist.lan` → Server für die CyberPower CP 1600EPFCLCD
- `pi-server.lan` → Server für die Eaton Ellipse 650 PRO

### Synology NAS als NUT-Client einrichten

Die Synology DiskStation lässt sich als Netzwerk-USV-Client konfigurieren. Die Optionen dazu befinden sich unter:

**Systemsteuerung > Hardware & Energie > USV**

**Einstellungen:**

- USV-Unterstützung aktivieren
- USV-Typ: Synology USV-Server
- Abschaltzeit: z. B. 3 Minuten
- Netzwerk-USV-Server: `192.168.x.x` (IP des NUT-Servers)

**Voraussetzungen am NUT-Server:**

Damit die DiskStation eine Verbindung aufbauen kann, muss Folgendes auf dem Server konfiguriert sein:

- Die USV muss `ups` heißen
- Benutzername: `monuser`
- Passwort: `secret`
- `monuser` muss mit der Option `secondary` eingetragen sein

Nach einem Klick auf **Übernehmen** wird die Verbindung zur USV hergestellt. Im Stromausfall-Szenario fährt die DiskStation nach Ablauf der eingestellten Zeit sicher herunter – alle Dienste werden gestoppt, Volumes ungemountet und die Stromversorgung über die Batterie der USV rechtzeitig beendet.

### Weitere Server als NUT-Clients einrichten

Installieren unter Ubuntu:

```bash
sudo apt install nut-client
```

und die Verbindung zum NUT-Server überprüfen mit

```bash
upsc server-room-rack@192.168.x.x
upsc ups@192.168.x.x
```

Unter Alpine Linux:

```bash
# Installation
doas apk add nut

# Verbindung prüfen
upsc server-room-rack@192.168.x.x
upsc ups@192.168.x.x
```

Den USV Monitor vom NUT-Client konfigurieren mit

```bash
sudo nano /etc/nut/upsmon.conf
```

oder

```bash
doas nvim /etc/nut/upsmon.conf
```

und folgenden Monitor hinzufügen:

Falls der Client den Strom von dem Eaton Ellipse 650 PRO im Server Raum bezieht:

```bash
MONITOR server-room-rack@192.168.x.x 1 monuser PASSWORD secondary
```

Oder falls der Client den Strom im Homelab von der CyberPower CP 1600EPFCLCD bezieht:

```bash
MONITOR ups@192.168.x.x 1 monuser secret secondary
```

> **Hinweis:** Das Passwort **secret** ist erforderlich, da die Synology NAS als NUT-Client auf dieses Passwort fest eingestellt ist.

In `/etc/nut/nut.conf` den Mode von `none` ändern zu `MODE=netclient`.

Jetzt den Client neu starten und aktivieren mit:

```bash
sudo systemctl restart nut-client
sudo systemctl enable nut-client
```

Unter Alpine Linux:

```bash
doas rc-service nut-upsmon start
doas rc-update add nut-upsmon default
```

Ausgabe nach dem ersten Start:

```bash
doas rc-service nut-upsmon start
 * Caching service dependencies ...                                                                                                                                                                        [ ok ]
 * Starting udev ...                                                                                                                                                                                       [ ok ]
 * Waiting for uevents to be processed ...                                                                                                                                                                 [ ok ]
 * Starting UPS Monitor ...
Network UPS Tools upsmon 2.8.2
fopen /run/upsmon.pid: No such file or directory
Could not find PID file to see if previous upsmon instance is already running!
UPS: ups@192.168.x.x (secondary) (power value 1)
Using power down flag file /etc/killpower
```

**Shutdown-Szenario**

Sobald der primäre NUT-Server (`MODE=netserver`) eine FSD-Meldung (Forced Shutdown) ausgibt – z. B. weil die Batterie zur Neige geht – wird diese Information an alle verbundenen Clients übermittelt.

Die Clients fahren daraufhin kontrolliert herunter, bevor der Strom vollständig ausfällt. Jeder Server, der den `nut-client` betreibt, sollte daher mit dem passenden USV-Namen überwacht werden.

## Testlauf: Stromausfall simulieren

Bevor man einen echten Stromausfall abwartet oder den Stecker zieht, kann man die gesamte NUT-Konfiguration testen, indem man den sogenannten **FSD-Event** (Forced Shutdown) manuell auslöst. Das geht mit folgendem Befehl auf dem **NUT-Server**:

```bash
sudo upsmon -c fsd
```

Dabei wird ein kompletter Shutdown simuliert:

Alle Clients erhalten das Kommando zum sicheren Herunterfahren, und auch die USV selbst wird sich nach dem Ablauf der konfigurierten Wartezeit abschalten. Die angeschlossenen Geräte sind danach **stromlos**.

> **Hinweis:** Dieser Befehl funktioniert nur **lokal auf dem Server**, nicht über entfernte Clients.

### Erfahrungsbericht aus der Praxis

Ich habe diesen manuellen Testbefehl bisher nicht genutzt, sondern in der Praxis bewusst auf echte Stromausfälle gewartet – und bei Bedarf die Systeme manuell heruntergefahren. Dabei konnte ich die Funktionalität der gesamten Konfiguration mehrfach erfolgreich beobachten:

- **Alle angeschlossenen Systeme** wurden bei Stromausfall nach und nach heruntergefahren, abhängig vom jeweiligen Batteriestand.
- Die USV **schaltet sich anschließend selbstständig ab**, sobald alle Systeme sicher heruntergefahren wurden.
- Damit wird verhindert, dass der Akku der USV **vollständig** entladen wird. Das passiert **sehr schnell** bei **unkontrollierter** Nutzung.
- **Sobald der Strom zurückkehrt**, starten die USVs automatisch wieder und die angeschlossenen Systeme fahren hoch, **als wäre nichts gewesen**.
- **Push-Benachrichtigungen** über Stromausfall, Shutdown und Recovery erhalte ich in Echtzeit auf mein Smartphone – dank der Integration mit **Gotify**.

Sobald unsere Solaranlage in Betrieb ist, wird es voraussichtlich deutlich seltener nötig sein, dass sich die USVs komplett abschalten müssen. Die zusätzliche Energieversorgung schafft einen weiteren Puffer, der die Ausfallsicherheit erhöht.

## Bonus: NUT in Home Assistant integrieren

Die USV-Überwachung über **NUT** lässt sich auch problemlos in **Home Assistant** einbinden. So können Stromausfälle, Batteriestand und Shutdown-Warnungen auch dort angezeigt und automatisiert werden.

**Integration hinzufügen**

1. In Home Assistant auf **„Einstellungen > Geräte & Dienste“** gehen.
2. Auf **„Integration hinzufügen“** klicken und nach **„Network UPS Tools (NUT)“** suchen.
3. Es öffnet sich ein Dialog:
   - **IP-Adresse** des NUT-Servers eintragen.
   - Port bleibt auf dem Standardwert (`3493`).
   - **Benutzername** (`monuser`) und das zugehörige **Passwort** eintragen.
4. Optional kann ein **Raum zugewiesen oder erstellt** werden.

**Hinweis zu Docker-Containern**

Falls Home Assistant in einem Docker-Container läuft (wie bei mir auf `sumpfgeist.lan`), kann es sein, dass der Container die **reguläre Host-IP (z. B. 192.168.x.x)** nicht erreichen kann. In diesem Fall muss die **interne IP-Adresse der Docker-Bridge** verwendet werden – zum Beispiel:

```bash
172.21.0.1
```

Diese IP gehört zur Docker-Bridge (`br0`) und ermöglicht die Kommunikation zwischen dem **Home Assistant Container** und dem **NUT-Dienst** auf dem Host.

Damit sind wir nun am Ende dieses Artikels angelangt und die USVs arbeiten jetzt nicht mehr isoliert, sondern sind Teil eines intelligenten Netzwerks. Mit der künftigen Einbindung der Solaranlage entsteht ein durchdachtes, zuverlässiges Energiesystem – ganz ohne manuelle Eingriffe, aber mit maximaler Übersicht und Effizienz.

**Verwendete Tools:**

- [Network UPS Tools](https://networkupstools.org/)
- [PeaNUT](https://github.com/Brandawg93/PeaNUT)
- [Uptime Kuma](https://github.com/louislam/uptime-kuma)
- [Gotify](https://gotify.net/)
- [Home Assistant](https://www.home-assistant.io/)

{{< chat NUT >}}
