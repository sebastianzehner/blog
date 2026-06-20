+++
title = 'Coral Edge TPU: Hardwarebeschleunigung für KI-Objekterkennung'
summary = 'Für meinen Frigate Docker Container wollte ich die AI-Objekterkennung mit Hardwarebeschleunigung betreiben. Deshalb habe ich mir einen Coral Edge TPU Chip gekauft und in meinen Server eingebaut.'
date = 2025-08-13T09:15:00-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-13T09:15:00-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'Frigate', 'AI', 'Coral', 'TPU', 'NVR', 'Docker', 'Videoüberwachung']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/coral-edge-tpu-hardware-acceleration-for-ai-object-detection.webp'
    alt = 'Beitragsbild von Coral Edge TPU: Hardwarebeschleunigung für KI-Objekterkennung'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

Für meinen **Frigate Docker Container** wollte ich die AI-Objekterkennung mit Hardwarebeschleunigung betreiben. Deshalb habe ich mir einen M.2 Accelerator Coral Edge TPU Chip mit A+E Key gekauft und in meinen Homeserver eingebaut.

## Mein erstes Setup: Lenovo ThinkCentre

Der **Coral Edge TPU** wurde in meinem **Lenovo ThinkCentre** `sumpfgeist.lan` im freien Mini PCIe Steckplatz, der normalerweise für ein WLAN-Modul genutzt wird, problemlos erkannt und funktioniert einwandfrei. Das war ein wichtiger Erfolg, denn beim **Beelink EQ14** funktioniert das gleiche Modul im WLAN-Steckplatz nicht, da dort nur ein CNVi-Interface für WLAN unterstützt wird.

## Test mit M.2 Accelerator B+M Key für den EQ14

Um den EQ14 ebenfalls mit Hardwarebeschleunigung auszustatten, habe ich mir ein M.2 Accelerator Coral Edge TPU Modul mit B+M Key bestellt.

Auf dem EQ14 läuft Alpine Linux, für das es keine offiziellen Treiber gibt. Die Treiber musste ich selbst kompilieren – was ich bereits erfolgreich getan habe.

Die Installation und der Test des M.2 Accelerator B+M Key auf dem EQ14 verliefen erfolgreich. Die Treiber wurden unter **Alpine Linux 3.22** mit dem aktuellen Kernel kompiliert und funktionieren einwandfrei. Während des Kompilierprozesses traten einige Fehler auf, die ich beheben konnte.

Um meine Anpassungen und Lösungswege zu dokumentieren, habe ich bereits einen Fork des Treiber-Repositories erstellt, auf den ich im letzten Abschnitt dieses Artikels genauer eingehe.

## Einbau des Coral Edge TPU

Der Einbau des Coral Edge TPU war unkompliziert. Im Lenovo ThinkCentre war der PCIe-Steckplatz frei, sodass ich das Modul einfach einstecken und den Server neu starten konnte. Auch im EQ14 war der entsprechende M.2-Steckplatz frei, die Karte konnte problemlos eingelegt und sicher befestigt werden.

## Treiberinstallation unter Ubuntu

Die Installation der Treiber für den Coral Edge TPU gestaltete sich etwas aufwendiger, da es beim Bau des Kernelmoduls zu Fehlern kam. Ich orientierte mich an der [offiziellen Anleitung](https://coral.ai/docs/m2/get-started/#2a-on-linux) von Coral für Ubuntu, stieß dabei jedoch auf Kompatibilitätsprobleme, die ich im Folgenden beschreibe.

### Vorbereitung: Prüfung vorinstallierter Treiber

Zuerst prüfte ich, ob bereits vorgefertigte Apex-Treiber vorhanden sind:

```bash
uname -r   # Zeigt die Kernel-Version, z.B. 6.8.0-60-generic
lsmod | grep apex   # Prüft, ob Apex-Treiber geladen sind
```

Bei mir waren keine Treiber vorinstalliert.

### Standardinstallation schlägt fehl

Anschließend fügte ich das Coral-Paket-Repository hinzu und versuchte, die benötigten Pakete zu installieren:

```bash
echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install gasket-dkms libedgetpu1-std
```

Dabei kam es zu einem Fehler beim Bau des `gasket-dkms`-Moduls für meinen Kernel (6.8.0-60-generic), da der Quellcode des Treibers mit meinem Kernel nicht kompatibel war.

### Fehleranalyse und Lösung

Das Build-Log zeigte unter anderem diese Fehlermeldung:

```bash
error: passing argument 1 of ‘class_create’ from incompatible pointer type
error: too many arguments to function ‘class_create’
```

Dies ist ein bekanntes Problem mit dem originalen `gasket-dkms`-Treiber, da dieser für ältere Kernel geschrieben wurde.

### Lösung: Einen Fork nutzen und Treiber selbst bauen

Um das Problem zu beheben, entfernte ich zunächst das inkompatible Paket:

```bash
sudo apt purge gasket-dkms
```

Danach klonte ich einen gepatchten Fork, der das Problem behebt:

```bash
cd ~/downloads
git clone https://github.com/KyleGospo/gasket-dkms
```

Die Build-Abhängigkeiten müssen ebenfalls installiert sein:

```bash
sudo apt install dkms libfuse2 dh-dkms devscripts debhelper
```

Dann baute ich das Paket mit `debuild`:

```bash
cd gasket-dkms
debuild -us -uc -tc -b
```

Da bei mir `debhelper` nicht installiert war, trat ein Fehler auf, den ich durch Installation von `debhelper` behoben habe.

Nach erfolgreichem Build wurde das `.deb`-Paket installiert:

```bash
cd ..
sudo dpkg -i gasket-dkms_*.deb
```

Ich musste bei mir `sudo dpkg -i gasket-dkms_1.0-18_all.deb` eingeben.

### Rechte und Neustart

Da ich die Hardware ausschließlich in Docker-Containern nutze und mein Benutzer in der Gruppe `docker` ist, setzte ich passende Zugriffsrechte mit einer `udev`-Regel:

```bash
sudo sh -c "echo 'SUBSYSTEM==\"apex\", MODE=\"0660\", GROUP=\"docker\"' > /etc/udev/rules.d/65-apex.rules"
```

Anschließend startete ich das System neu:

```bash
sudo reboot
```

### Überprüfung

Nach dem Neustart prüfte ich, ob das Gerät erkannt wird:

```bash
ls -alh /dev/apex*
```

Ausgabe:

```bash
crw-rw----  120,0 root docker 10 Jun 11:12 /dev/apex_0
```

Damit war die Treiberinstallation erfolgreich abgeschlossen und die Hardware bereit für den Einsatz in Docker-Containern wie Frigate.

## Docker Compose: Coral Edge TPU im Frigate Container nutzen

Um die Coral Edge TPU im Frigate Docker Container zu verwenden, müssen wir die Hardware dem Container zugänglich machen und die Konfiguration anpassen. [Hier](/de/posts/frigate-open-source-nvr-real-time-ai-object-detection/) geht es zu meinem Frigate Blogartikel.

### Geräteweitergabe an den Container

In der `docker-compose.yaml` Datei von Frigate (z. B. unter `~/docker-compose/frigate/`) fügen wir den folgenden Abschnitt unter `services.frigate` hinzu:

```yaml
devices:
  - /dev/apex_0:/dev/apex_0
```

Damit wird das Gerät `/dev/apex_0` vom Hostsystem an den Container durchgereicht.

### Frigate Konfiguration anpassen

In der Frigate Konfigurationsdatei `config.yml` (zum Beispiel unter `~/docker/frigate/`) muss die Detektor-Einstellung für die TPU hinzugefügt oder angepasst werden:

```yaml
detectors:
  coral1:
    type: edgetpu
    device: pci:0
```

Diese Einstellung teilt Frigate mit, dass der Edge TPU Detektor verwendet werden soll, der über das PCIe-Gerät `pci:0` angesprochen wird.

### Container neu starten

Nach diesen Änderungen kann der Frigate Container neu gestartet werden:

```bash
cd ~/docker-compose/frigate
docker compose down
docker compose up -d
```

Frigate nutzt nun die Hardwarebeschleunigung des Coral Edge TPU für die KI-Objekterkennung. Weitere Details zur Konfiguration von Frigate findest du [hier](/de/posts/frigate-open-source-nvr-real-time-ai-object-detection/).

## Treiber unter Alpine Linux

Für Alpine Linux gibt es ein spezielles Repository mit einem Bugfix, der es ermöglicht, die Coral Edge TPU Treiber für meine verwendete Alpine Version und den aktuellen Kernel zu kompilieren.

Ich habe das Repository [hier](https://github.com/sebastianzehner/alpine-coral-tpu) geclont und für meine Kernel-Version angepasst. Die genaue Anleitung zur Installation findest du ebenfalls dort.

Um den Coral Chip im EQ14 nutzen zu können, habe ich zudem ein anderes Modell der TPU auf einer SOM-Platine (System-On-Module) gekauft, das für den M.2-2280-B-M-S3 (B/M Key) Slot geeignet ist. Mit den selbst kompilierten Treibern wurde das Gerät anschließend vom System erkannt.

### Überprüfung der Hardware

Du kannst prüfen, ob die Edge TPU erkannt wurde, indem du folgenden Befehl ausführst:

```bash
ls -alh /dev/apex*
```

Das Ergebnis sieht bei mir so aus:

```bash
crw-rw----  120,0 root 28 Jun 20:46 /dev/apex_0
```

### Umzug auf den EQ14 und Leistung

Ich habe die Frigate Installation vom **ThinkCentre** (`sumpfgeist.lan`) auf den **EQ14** (`eq14.lan`) umgezogen. Dort wird der Coral Chip erkannt und die KI-Objekterkennung läuft mit einer Latenz von durchschnittlich ca. 8 ms pro Frame. Die Temperatur des Chips liegt bei etwa 45°C und ist somit im sicheren Bereich.

![Image Frigate Webinterface Detectors Coral Edge TPU](/img/galleries/coral-edge-tpu-hardware-acceleration-for-ai-object-detection/coral-edge-tpu-frigate-detector.webp)

### Kernel-Update und erneutes Kompilieren

Zwischenzeitlich habe ich **Alpine Linux** auf dem **EQ14** mit einem neuen Kernel aktualisiert. Vor dem Neustart habe ich die Treiber neu kompiliert, um die Kompatibilität sicherzustellen.

Nach dem Systemstart wurden die aktuellen Treiberdateien kopiert und aktiviert, sodass der Coral Chip weiterhin korrekt erkannt wird und Frigate problemlos läuft.

Mein Repository wurde mittlerweile aktualisiert und berücksichtigt nun auch den neuesten Kernel von **Alpine Linux 3.22**. Du kannst jederzeit meiner Schritt-für-Schritt-Anleitung auf [GitHub](https://github.com/sebastianzehner/alpine-coral-tpu) folgen, um die Treiber erfolgreich zu installieren und zu kompilieren.

## Fazit

Die Kombination aus **Frigate**, **Coral Edge TPU** und **EQ14** bildet mittlerweile das Herzstück meiner Videoüberwachung. Dank der hohen Erkennungsgenauigkeit und der stabilen Performance habe ich jetzt eine Lösung, die zuverlässig und zukunftssicher ist.

Als Nächstes möchte ich die Erkennung noch feiner abstimmen, weitere Automatisierungen über **Home Assistant** integrieren und so mein System Schritt für Schritt noch smarter machen.

## Hardware-Empfehlungen

- EQ14 Mini-PC [auf Amazon](https://amzn.to/4oBKKcg) - kompakter und stromsparender Rechner für Frigate
- Coral Edge TPU [auf Amazon US](https://a.co/d/0aeVsKY) - KI-Beschleuniger für schnelle und präzise Objekterkennung
- Coral Dual Edge TPU [auf Amazon](https://amzn.to/3Hxq83Y) - leistungsstarker KI-Beschleuniger (passt nicht in EQ14)

_Da es sich teilweise um Affiliate-Links handelt, hier der Hinweis: Als Amazon-Partner verdiene ich an qualifizierten Verkäufen._

**Verwendete Tools:**

- [Frigate](https://frigate.video/)
- [Docker](https://www.docker.com/)
- [GitHub](https://github.com/sebastianzehner/alpine-coral-tpu)
- [Coral Edge TPU](https://coral.ai/products/)

{{< chat CoralTPU >}}
