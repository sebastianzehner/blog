+++
title = 'Frigate: Open Source NVR mit Echtzeit-KI-Objekterkennung'
summary = 'Frigate ist ein Open Source Network Video Recorder (NVR), der klassische Videoüberwachung mit KI-gestützter Echtzeiterkennung von Personen, Fahrzeugen, Tieren und anderen Objekten kombiniert.'
date = 2025-08-12T18:35:10-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-12T18:35:10-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'Frigate', 'AI', 'Coral', 'TPU', 'NVR', 'Docker', 'Videoüberwachung']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/frigate-open-source-nvr-real-time-ai-object-detection.webp'
    alt = 'Beitragsbild von Frigate: Open Source NVR mit Echtzeit-KI-Objekterkennung'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

**Frigate** ist ein Open Source Network Video Recorder (NVR), der speziell für die Echtzeit-KI-Objekterkennung entwickelt wurde. Die Software ermöglicht nicht nur klassisches Aufzeichnen und Abspielen von Kamerastreams, sondern auch die automatische Erkennung von Personen, Fahrzeugen, Tieren und weiteren Objekten mithilfe von Machine Learning.

## Warum Frigate die Lösung für meine Videoüberwachung wurde?

Bevor ich 2019 nach Paraguay ausgewandert bin, habe ich in Deutschland beruflich unter anderem Videoüberwachungsanlagen geplant und installiert. Dieses Wissen habe ich auch hier angewendet: Unser Haus wurde von Anfang an mit einer klassischen Videoüberwachung ausgestattet, bestehend aus mehreren Netzwerkkameras und einem NVR Recorder mit Festplatte.

Vor einiger Zeit habe ich jedoch begonnen, mich nach einer flexibleren Lösung umzusehen. Ich wollte eine zentrale Plattform, über die ich komfortabel auf meine IP-Kameras zugreifen kann. Dabei stieß ich auf **Frigate**, und schnell wurde klar: Das kann mehr, als nur Videos speichern. In Kombination mit einem **Coral TPU** für KI-Objekterkennung könnte es sogar meinen herkömmlichen NVR vollständig ersetzen.

## Die ersten Tests auf meinem Homeserver

Die erste Installation von **Frigate** habe ich auf meinem `sumpfgeist.lan` Server durchgeführt, um zu sehen, wie gut das System im Alltag funktioniert. Geplant war eigentlich der Einsatz eines **M.2 Dual Coral**, falls dieser im M.2-WiFi-Slot meines Lenovo ThinkCentre funktioniert. WLAN benötige ich ohnehin nicht, und der Slot war frei.

In der Praxis stellte sich jedoch heraus: Ein Dual-Chip wird in den meisten M.2-WiFi-Slots nicht unterstützt. Oftmals sind diese Slots ausschließlich für WLAN-Module ausgelegt und bieten keine nutzbare PCIe-Lane. Mit etwas Glück steht jedoch eine PCIe-Lane zur Verfügung, dann kann anstelle des WLAN-Moduls auch ein Coral TPU betrieben werden.

Beim ThinkCentre war dies der Fall, sodass ich dort einen Single-Chip-Coral problemlos im M.2-WiFi-Slot nutzen konnte. Beim **EQ14** (`eq14.lan`) hingegen unterstützt der Slot ausschließlich WLAN, sodass der Coral TPU dort nicht erkannt wird.

Der **EQ14** verfügt jedoch über zwei große M.2-Slots für NVMe-Karten. Da nur eine NVMe-SSD verbaut ist, war der zweite Slot frei – so konnte ich dort mithilfe eines Adapter-Boards ebenfalls einen Single-Coral-TPU-Chip einbauen und nutzen.

## Kamerakonfiguration und Migration zum EQ14

Aktuell habe ich fünf IP-Kameras auf unserem Grundstück verteilt, die ich problemlos in **Frigate** einbinden kann. Zukünftig kommen wahrscheinlich noch weitere hinzu.

Nachdem die ersten Tests gut verliefen, habe ich die Frigate-Installation vom `sumpfgeist.lan` auf den `eq14.lan` verschoben. Dank **Docker Compose** war der Umzug nahezu problemlos – nur eine kleine Anpassung in der `.env`-Datei war nötig: Statt AMD-GPU-Unterstützung jetzt Intel, wodurch eine Umgebungsvariable einfach entfiel.

Damit der Coral Chip unter **Alpine Linux** auf dem **EQ14** funktioniert, habe ich bereits alle notwendigen Schritte umgesetzt und dokumentiert. Die Details dazu werde ich im nächsten Blogartikel beschreiben.

Da der bestehende Traefik-Proxy auf einem anderen Docker-Host läuft und keine automatische Domain-Konfiguration von externen Hosts übernehmen kann, habe ich auf dem **EQ14** einen zweiten Traefik-Proxy eingerichtet. Über diesen ist **Frigate** nun im internen Netzwerk erreichbar. Für die Subdomain musste ich lediglich im Pi-Hole-DNS-Server die IP-Adresse entsprechend anpassen.

Nachdem die grundlegende Hardware- und Netzwerkumgebung nun steht, folgt als Nächstes die Installation von **Frigate** mittels **Docker Compose** – von der Vorbereitung bis zur ersten funktionierenden Konfiguration.

## Frigate Installation

Für den Betrieb habe ich mich für **Docker Compose** entschieden – nicht zuletzt, weil ich ein großer Fan von [Docker](https://www.docker.com/) bin und in meinem Homelab mehrere Container auf unterschiedlichen Hosts betreibe. Das Thema ist so umfangreich, dass ich dazu sicher einmal einen eigenen Blogartikel schreiben werde.

Docker Compose bietet den Vorteil, dass sich Konfigurationen leicht anpassen, sichern und bei Bedarf auch auf andere Systeme übertragen lassen. Die [offizielle Frigate-Dokumentation](https://docs.frigate.video/configuration/reference) bietet zudem eine solide Basis, die ich an meine Anforderungen – insbesondere die Einbindung mehrerer IP-Kameras – angepasst habe.

Meine `docker-compose.yaml`-Datei sieht momentan wie folgt aus:

```yaml
services:
  frigate:
    container_name: frigate
    restart: unless-stopped
    image: ghcr.io/blakeblackshear/frigate:stable
    devices:
      #- /dev/bus/usb:/dev/bus/usb # USB Coral
      - /dev/apex_0:/dev/apex_0 # M.2 Coral
      #- /dev/apex_1:/dev/apex_1 # M.2 Dual Coral
      - /dev/dri/renderD128:/dev/dri/renderD128 # for intel hwaccel, needs to be updated for your hardware
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /home/sz/docker/frigate/config.yml:/config/config.yml:ro
      - /mnt/frigate/clips:/media/frigate/clips
      - /mnt/frigate/recordings:/media/frigate/recordings
      - /home/sz/docker/frigate/db-data:/media/frigate
      - type: tmpfs # Optional 1GB memory to reduce SSD/SD card wear
        target: /tmp/cache
        tmpfs:
          size: 1000000000
    networks:
      proxy:
        ipv4_address: 192.168.x.x
    ports:
      - "5000:5000" # Frigate Webinterface
      #- "1935:1935" # RTMP feeds (deprecated) ???
      - "1984:1984" # go2rtc
      - "8554:8554" # go2rtc
    env_file: .env
    security_opt:
      - no-new-privileges:true
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frigate.entrypoints=http"
      - "traefik.http.routers.frigate.rule=Host(`frigate.techlab.icu`)"
      - "traefik.http.middlewares.frigate-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.frigate.middlewares=frigate-https-redirect"
      - "traefik.http.routers.frigate-secure.entrypoints=https"
      - "traefik.http.routers.frigate-secure.rule=Host(`frigate.techlab.icu`)"
      - "traefik.http.routers.frigate-secure.tls=true"
      - "traefik.http.routers.frigate-secure.service=frigate"
      - "traefik.http.services.frigate.loadbalancer.server.port=5000"
      - "traefik.docker.network=proxy"

networks:
  proxy:
    external: true
```

Für die Videoaufnahmen und Clips habe ich ein Netzlaufwerk meiner **Synology NAS** eingebunden und verweise darauf in der Frigate-Docker-Konfiguration mit den Verzeichnissen `/mnt/frigate/clips` und `/mnt/frigate/recordings`.

Die `config.yml`-Datei sieht aktuell wie folgt aus:

```yaml
detectors:
  coral1:
    type: edgetpu
    device: pci:0
#  coral2:
#    type: edgetpu
#    device: pci:1

# Optional: Database configuration
database:
  # The path to store the SQLite DB (default: shown below)
  path: /media/frigate/frigate.db

auth:
  enabled: True

birdseye:
  # Optional: Enable birdseye view (default: shown below)
  enabled: True
  # Optional: Width of the output resolution (default: shown below)
  width: 1280
  # Optional: Height of the output resolution (default: shown below)
  height: 720
  # Optional: Encoding quality of the mpeg1 feed (default: shown below)
  # 1 is the highest quality, and 31 is the lowest. Lower quality feeds utilize less CPU resources.
  quality: 8
  # Optional: Mode of the view. Available options are: objects, motion, and continuous
  #   objects - cameras are included if they have had a tracked object within the last 30 seconds
  #   motion - cameras are included if motion was detected in the last 30 seconds
  #   continuous - all cameras are included always
  mode: continuous

ffmpeg:
  hwaccel_args: #preset-vaapi
    - -hwaccel
    - vaapi
    - -hwaccel_device
    - /dev/dri/renderD128
    - -hwaccel_output_format
    - yuv420p
  output_args:
    record: -f segment -segment_time 10 -segment_format mp4 -reset_timestamps 1 -strftime 1 -c:v copy -c:a aac

detect:
  enabled: True
  width: 640 # <---- update for your camera's resolution
  height: 480 # <---- update for your camera's resolution
  fps: 5

objects:
  track:
    - person
    - dog
    - cat
    - bird

record:
  enabled: True
  detections:
    pre_capture: 5
    post_capture: 5
    retain:
      days: 30
      mode: active_objects

snapshots:
  enabled: True
  timestamp: False
  bounding_box: True
  retain:
    default: 30

go2rtc:
  streams:
    carport:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
    carport_sub:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
    garden:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
    garden_sub:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
    office:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
    office_sub:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
    workshop:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
    workshop_sub:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1

cameras:
  carport:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
          roles:
            - record
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
          roles:
            - detect
    webui_url: "http://192.168.x.x"
    detect:
      width: 704 # <---- update for your camera's resolution
      height: 480 # <---- update for your camera's resolution
      fps: 5
  garden:
    ffmpeg:
      inputs:
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
          roles:
            - record
        - path: rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
          roles:
            - detect
    webui_url: "http://192.168.x.x"
    detect:
      width: 704 # <---- update for your camera's resolution
      height: 480 # <---- update for your camera's resolution
      fps: 5
  office:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/office
          roles:
            - audio
            - record
        - path: rtsp://127.0.0.1:8554/office_sub
          roles:
            - detect
    webui_url: "http://192.168.x.x"
    onvif:
      host: 192.168.x.x
      port: 80
      user: frigate
      password: "{FRIGATE_RTSP_PASSWORD}"
  workshop:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/workshop
          roles:
            - audio
            - record
        - path: rtsp://127.0.0.1:8554/workshop_sub
          roles:
            - detect
    webui_url: http://192.168.x.x
    onvif:
      host: 192.168.x.x
      port: 80
      user: frigate
      password: "{FRIGATE_RTSP_PASSWORD}"
```

In dieser Frigate-Konfiguration sind beispielhafte IP-Adressen eingetragen, die du unbedingt an dein eigenes Heimnetz anpassen musst.

Ein großer Vorteil meines Setups auf dem **EQ14** ist, dass dieser zwei separate Netzwerkschnittstellen besitzt. Dadurch kann ich die IP-Kameras in einem eigenen, isolierten Netzwerk betreiben, was eine zusätzliche Sicherheitsebene bietet. Nur die zweite Netzwerkschnittstelle des **EQ14** ist mit meinem Homelab verbunden. So trenne ich die Kamera-Geräte physisch vom restlichen Netzwerk und minimiere potenzielle Angriffsflächen.

## Einbinden der Kamerastreams mit go2rtc

Um die RTSP-Streams meiner IP-Kameras möglichst flexibel und performant in **Frigate** einzubinden, setze ich auf **go2rtc**.

**Warum go2rtc?**

[go2rtc](https://docs.frigate.video/guides/configuring_go2rtc/) ist ein moderner Stream-Relay-Server, der RTSP-, RTMP- und WebRTC-Streams bündeln, transkodieren und weiterleiten kann. Besonders praktisch: Er ermöglicht die Kompatibilität mit verschiedenen Clients, reduziert Latenzen und entlastet die Kameras.

Außerdem ermöglicht go2rtc, Streams mit unterschiedlichen Protokollen (RTSP, WebRTC) im Homelab und darüber hinaus nahtlos zu verwenden. Das ist gerade bei komplexeren Setups mit mehreren Kameras und Clients ein großer Vorteil. Der Dienst go2rtc läuft bereits inerhalb des Frigate Containers.

## RTSP-Stream-Links für Dahua OEM-Kameras

Um die richtigen RTSP-Links für meine OEM Dahua IP-Kameras herauszufinden, nutzte ich diese hilfreiche Webseite [hier](https://dahuawiki.com/Remote_Access/RTSP_via_VLC). Dort sind viele gängige URL-Formate dokumentiert. Diese Links lassen sich auch mit [VLC](https://www.videolan.org/) oder anderen Playern problemlos öffnen und abspielen.

Beispiel für meine Office-Kamera:

```bash
rtsp://192.168.x.x:554/live
rtsp://192.168.x.x:554/cam/realmonitor?channel=1&subtype=0&unicast=true&proto=Onvif
rtsp://192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
```

## Aktuelles Setup und Hardware

Ich habe mir kürzlich einen Coral M.2 A+E TPU auf eBay.com bestellt, den ich in meinen Server eingebaut habe. Die AI-Objekterkennung mit dem Coral Chip ist deutlich effizienter als über die CPU, die ansonsten bei voller Auslastung läuft und nicht empfohlen wird. Meinen Blogpost über den Coral TPU Chip werde ich [hier](/de/posts/coral-edge-tpu-hardware-acceleration-for-ai-object-detection/) verlinken, sobald verfügbar.

Die GPU habe ich bereits für die Hardwarebeschleunigung von [ffmpeg](https://ffmpeg.org/) eingebunden, womit das System aktuell mit vier Kameras stabil läuft. Eine fünfte Kamera wird bald dazukommen, und langfristig plane ich bis zu acht Kameras. Diese Hardware sollte das problemlos schaffen.

## Wichtige Umgebungsvariable für GPU-Unterstützung

Damit die AMD-GPU im ThinkCentre (`sumpfgeist.lan`) von Frigate erkannt wird, musste ich folgende Umgebungsvariable in meiner `.env`-Datei setzen:

```bash
FRIGATE_RTSP_USER=frigate
FRIGATE_RTSP_PASSWORD=secure_password
LIBVA_DRIVER_NAME=radeonsi
```

Nach dem Umzug auf den **EQ14** (`eq14.lan`), der eine Intel-GPU nutzt, habe ich die Variable `LIBVA_DRIVER_NAME` entfernt, da die AMD-Treiber dort nicht benötigt werden und zu Fehlern führen würden.

```bash
FRIGATE_RTSP_USER=frigate
FRIGATE_RTSP_PASSWORD=secure_password
```

## Qualität der Aufnahme und Stream-Management

Die Aufnahmen sollten möglichst in hoher Qualität erfolgen. Dafür musste ich noch einige Einstellungen anpassen und wie bereits beschrieben **go2rtc** nutzen, um die Streams besser zu verwalten. Nach der Umstellung funktioniert das mit **go2rtc** inzwischen sehr gut.

Frigate ist aktuell über meinen Traefik Proxy Server unter folgender Adresse erreichbar: https://frigate.techlab.icu

## Streaming Server go2rtc konfigurieren

Für eine optimierte Videodarstellung und Echtzeit-Wiedergabe empfiehlt es sich, den integrierten **go2rtc** Server zu verwenden.

Die Konfiguration ist relativ einfach: Man erweitert die `config.yml` um die Streams, die **go2rtc** verwalten soll.

```yaml
go2rtc:
  streams:
    office:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
    office_sub:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
```

Diese Streams können anschließend über das **go2rtc-Webinterface** unter http://192.168.x.x:1984 aufgerufen und kontrolliert werden.

Um die Streams in der Live-Ansicht und für Aufnahmen in hoher Qualität mit Frigate zu nutzen, müssen die Kameras in der `config.yml` entsprechend angepasst werden, sodass sie den Pfad zum **go2rtc-Stream** verwenden:

```yaml
cameras:
  office:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/office
          roles:
            - audio
            - record
        - path: rtsp://127.0.0.1:8554/office_sub
          roles:
            - detect
```

### Fehlerbehebung

Bei meiner Indoor-Kamera im Workshop konnte der Stream über **go2rtc** zunächst nicht gestartet werden, während die baugleiche Kamera im Office problemlos funktionierte.

Ich habe die Video- und Audio-Einstellungen der Kameras geprüft und abgeglichen. Letztendlich lag das Problem beim Audio-Codec: Ich musste von **AAC** auf **G.711A** umstellen. Danach wurde der Stream von **go2rtc** in Frigate erfolgreich gestartet – sowohl Bild als auch Ton funktionieren nun einwandfrei.

## Objekterkennung

Die Objekterkennung in Frigate basiert auf einer KI-gestützten Erkennung. Zur Hardwarebeschleunigung verwende ich einen Coral Edge TPU Chip mit 4 TOPS (Tera-Operationen pro Sekunde). Wie man diesen Chip inklusive der Treiber installiert, habe ich bereits [hier](/de/posts/coral-edge-tpu-hardware-acceleration-for-ai-object-detection/) beschrieben.

![Image Frigate Object Detection Coral Edge TPU](/img/galleries/frigate-open-source-nvr-real-time-ai-object-detection/frigate-object-detection-coral-edge-tpu.webp)

### Docker Compose anpassen

Für die Nutzung des Coral Edge TPU im Docker-Container passe ich die `docker-compose.yml` Datei bei mir unter `~/docker-compose/frigate/` wie folgt an, um das Gerät an den Container durchzureichen:

```yaml
devices:
  #- /dev/bus/usb:/dev/bus/usb # USB Coral
  - /dev/apex_0:/dev/apex_0 # M.2 Coral
  #- /dev/apex_1:/dev/apex_1   # M.2 Dual Coral (optional)
```

### Frigate Konfiguration aktivieren

In der `config.yml` Datei bei mir unter `~/docker/frigate/` aktiviere ich die Detektoren und füge diesen Abschnitt hinzu:

```yaml
detectors:
  coral1:
    type: edgetpu
    device: pci:0
```

### Objekterkennung konfigurieren

Die Objekterkennung wird dann im Abschnitt `detect` aktiviert und konfiguriert:

```yaml
detect:
  enabled: True
  width: 640 # <---- Auflösung an die Kamera anpassen
  height: 480 # <---- Auflösung an die Kamera anpassen
  fps: 5
```

**Hinweis:** Die Parameter `width`, `height` und `fps` werden meist in den jeweiligen Kameraeinstellungen unter `cameras:` nochmal überschrieben und individuell angepasst. Für die Erkennung reicht eine geringe Auflösung und Framerate aus, um Ressourcen zu sparen.

### Neustart

Nach den Änderungen kannst du den Docker-Container neu starten oder, wenn du nur die Konfiguration geändert hast, Frigate direkt über das Webinterface neu starten.

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
- [Traefik](https://traefik.io/traefik)
- [Pi-Hole](https://pi-hole.net/)
- [Coral Edge TPU](https://coral.ai/products/)

{{< chat Frigate >}}
