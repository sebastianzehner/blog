+++
title = 'Frigate: Open Source NVR with Real-Time AI Object Detection'
summary = 'Frigate is an open-source Network Video Recorder (NVR) that combines traditional video surveillance with AI-powered real-time detection of people, vehicles, animals, and other objects.'
date = 2025-08-12T18:35:10-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-12T18:35:10-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'Frigate', 'AI', 'Coral', 'TPU', 'NVR', 'Docker', 'CCTV']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/frigate-open-source-nvr-real-time-ai-object-detection.webp'
    alt = 'Featured image from Frigate: Open Source NVR with Real-Time AI Object Detection'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

**Frigate** is an open-source Network Video Recorder (NVR) specifically designed for real-time AI-based object detection. It not only offers traditional video recording and playback but also automatically detects people, vehicles, animals, and other objects using machine learning.

## Why Frigate Became the Solution for My Video Surveillance

Before moving to Paraguay in 2019, I worked in Germany planning and installing video surveillance systems. I applied that knowledge here as well: from the start, our house was equipped with a traditional surveillance setup consisting of several network cameras and an NVR recorder with a hard drive.

However, some time ago I began looking for a more flexible solution. I wanted a central platform that would allow me to easily access my IP cameras. That’s when I discovered **Frigate**, and it quickly became clear: it can do much more than just store videos. Combined with a **Coral TPU** for AI object detection, it could even replace my conventional NVR entirely.

## Initial Tests on My Home Server

My first installation of **Frigate** was on my `sumpfgeist.lan` server to evaluate how well the system would perform in daily use. The original plan was to use an **M.2 Dual Coral**, provided it would work in the M.2 Wi-Fi slot of my Lenovo ThinkCentre. I don’t need Wi-Fi anyway, and the slot was available.

In practice, however, it turned out that dual-chip Corals are not supported in most M.2 Wi-Fi slots. These slots are often designed exclusively for Wi-Fi modules and do not provide a usable PCIe lane. If you’re lucky, a PCIe lane is available, allowing a Coral TPU to be installed instead of the Wi-Fi module.

This was the case with the ThinkCentre, where I could easily run a single-chip Coral in the M.2 Wi-Fi slot. On the **EQ14** (`eq14.lan`), however, the slot supports Wi-Fi only, so the Coral TPU was not detected.

The **EQ14** does have two full-size M.2 slots for NVMe drives. Since only one NVMe SSD was installed, the second slot was free — allowing me to install and use a single Coral TPU chip there via an adapter board.

## Camera Configuration and Migration to the EQ14

At the moment, I have five IP cameras distributed across our property, all of which can be easily integrated into **Frigate**. More will likely be added in the future.

After the initial tests went well, I migrated the Frigate installation from `sumpfgeist.lan` to `eq14.lan`. Thanks to **Docker Compose**, the move was almost seamless — only a small adjustment in the `.env` file was needed: switching from AMD GPU support to Intel, which simply meant removing one environment variable.

To get the Coral chip working on **Alpine Linux** with the **EQ14**, I have already implemented and documented all the necessary steps. I will cover these details in my next blog post.

Since the existing Traefik proxy runs on a different Docker host and cannot automatically handle domain configuration from external hosts, I set up a second Traefik proxy on the **EQ14**. Through this, **Frigate** is now accessible within the internal network. For the subdomain, I only had to update the IP address in the Pi-hole DNS server.

With the core hardware and network setup now complete, the next step will be installing **Frigate** using **Docker Compose** - from initial preparation to the first working configuration.

## Frigate Installation

For running Frigate, I decided to use Docker Compose — not least because I’m a big fan of [Docker](https://www.docker.com/) and run multiple containers on different hosts in my homelab. The topic is broad enough that I’ll probably dedicate a separate blog post to it at some point.

Docker Compose has the advantage of making configurations easy to adjust, back up, and migrate to other systems when needed. The [official Frigate documentation](https://docs.frigate.video/configuration/reference) also provides a solid foundation, which I adapted to my requirements — particularly the integration of multiple IP cameras.

My current `docker-compose.yaml` file looks like this:

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

For storing video recordings and clips, I’ve mounted a network share from my **Synology NAS** and pointed to it in the Frigate Docker configuration using the directories `/mnt/frigate/clips` and `/mnt/frigate/recordings`.

The current `config.yml` file looks like this:

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

In this Frigate configuration, I’ve included example IP addresses — you’ll definitely need to adjust these to match your own home network.

One major advantage of my EQ14 setup is that it has two separate network interfaces. This allows me to run the IP cameras on their own isolated network, adding an extra layer of security. Only the second network interface of the EQ14 is connected to my homelab. This way, the camera devices are physically separated from the rest of the network, minimizing potential attack surfaces.

## Integrating Camera Streams with go2rtc

To integrate the RTSP streams from my IP cameras into Frigate as flexibly and efficiently as possible, I use **go2rtc**.

**Why go2rtc?**

[go2rtc](https://docs.frigate.video/guides/configuring_go2rtc/) is a modern stream relay server that can aggregate, transcode, and forward RTSP, RTMP, and WebRTC streams. It’s especially useful because it ensures compatibility with various clients, reduces latency, and offloads work from the cameras.

Additionally, go2rtc makes it possible to seamlessly use streams with different protocols (RTSP, WebRTC) within the homelab and beyond. This is particularly valuable for more complex setups with multiple cameras and clients. The go2rtc service is already running inside the Frigate container.

## RTSP Stream Links for Dahua OEM Cameras

To find the correct RTSP links for my OEM Dahua IP cameras, I used [this helpful website](https://dahuawiki.com/Remote_Access/RTSP_via_VLC), which documents many common URL formats. These links can easily be opened and played with [VLC](https://www.videolan.org/) or other media players.

Example for my office camera:

```bash
rtsp://192.168.x.x:554/live
rtsp://192.168.x.x:554/cam/realmonitor?channel=1&subtype=0&unicast=true&proto=Onvif
rtsp://192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
```

## Current Setup and Hardware

I recently ordered a Coral M.2 A+E TPU on eBay.com and installed it in my server. The AI object detection with the Coral chip is significantly more efficient than using the CPU, which otherwise runs at full load and is not recommended for this task. I will link my blog post about the Coral TPU chip [here](/posts/coral-edge-tpu-hardware-acceleration-for-ai-object-detection/) once it’s available.

I have already integrated the GPU for hardware acceleration with [ffmpeg](https://ffmpeg.org/), and the system currently runs stably with four cameras. A fifth camera will be added soon, and in the long term, I plan to run up to eight cameras. This hardware setup should handle that without any issues.

## Important Environment Variable for GPU Support

To enable detection of the AMD GPU in my ThinkCentre (`sumpfgeist.lan`) by Frigate, I had to set the following environment variable in my `.env` file:

```bash
FRIGATE_RTSP_USER=frigate
FRIGATE_RTSP_PASSWORD=secure_password
LIBVA_DRIVER_NAME=radeonsi
```

After migrating to the **EQ14** (`eq14.lan`), which uses an Intel GPU, I removed the `LIBVA_DRIVER_NAME` variable because the AMD drivers are not needed there and would cause errors.

```bash
FRIGATE_RTSP_USER=frigate
FRIGATE_RTSP_PASSWORD=secure_password
```

## Recording Quality and Stream Management

The recordings should be as high quality as possible. For this, I needed to adjust some settings and, as mentioned before, use **go2rtc** to better manage the streams. Since switching, **go2rtc** has been working very well.

Frigate is currently accessible via my Traefik proxy server at: https://frigate.techlab.icu

## Configuring the go2rtc Streaming Server

For optimized video playback and real-time streaming, it’s recommended to use the integrated **go2rtc server**.

The configuration is quite simple: you extend the `config.yml` with the streams that **go2rtc** should manage.

```yaml
go2rtc:
  streams:
    office:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=0
    office_sub:
      - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.x.x:554/cam/realmonitor?channel=1&subtype=1
```

These streams can then be accessed and monitored via the **go2rtc web interface** at `http://192.168.x.x:1984`.

To use the streams in the live view and for recordings at high quality with Frigate, the cameras must be configured accordingly in the `config.yml` to use the **go2rtc stream paths**:

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

### Troubleshooting

For my indoor camera in the workshop, the stream initially wouldn’t start through **go2rtc**, while the identical model in the office worked fine.

I checked and compared the video and audio settings of the cameras. The problem turned out to be the audio codec: I had to switch from **AAC** to **G.711A**. After that, the stream started successfully in Frigate via go2rtc - both video and audio now work flawlessly.

## Object Detection

Object detection in Frigate is based on AI-powered recognition. For hardware acceleration, I use a Coral Edge TPU chip with 4 TOPS (tera operations per second). How to install this chip including its drivers is already described [here](/posts/coral-edge-tpu-hardware-acceleration-for-ai-object-detection/).

![Image Frigate Object Detection Coral Edge TPU](/img/galleries/frigate-open-source-nvr-real-time-ai-object-detection/frigate-object-detection-coral-edge-tpu.webp)

### Adjusting Docker Compose

To use the Coral Edge TPU inside the Docker container, I modify the `docker-compose.yaml` file in my `~/docker-compose/frigate/` directory as follows, so the device is passed through to the container:

```yaml
devices:
  #- /dev/bus/usb:/dev/bus/usb # USB Coral
  - /dev/apex_0:/dev/apex_0 # M.2 Coral
  #- /dev/apex_1:/dev/apex_1   # M.2 Dual Coral (optional)
```

### Activating Frigate Configuration

In the `config.yml` file located in my `~/docker/frigate/` folder, I activate the detectors by adding this section:

```yaml
detectors:
  coral1:
    type: edgetpu
    device: pci:0
```

### Configuring Object Detection

Object detection is enabled and configured in the `detect` section:

```yaml
detect:
  enabled: True
  width: 640 # <---- update for your camera's resolution
  height: 480 # <---- update for your camera's resolution
  fps: 5
```

**Note:** The parameters `width`, `height`, and `fps` are usually overridden in the individual camera settings under `cameras:` and tailored per device. For detection, a lower resolution and frame rate are sufficient to save resources.

### Restart

After making these changes, you can restart the Docker container or, if you only changed the configuration, simply restart Frigate via the web interface.

## Conclusion

The combination of **Frigate**, **Coral Edge TPU**, and the **EQ14** has now become the core of my video surveillance system. Thanks to the high detection accuracy and stable performance, I now have a solution that is reliable and future-proof.

Next, I plan to fine-tune the detection further, integrate additional automations via **Home Assistant**, and gradually make my system even smarter.

## Hardware Recommendations

- EQ14 Mini-PC [on Amazon](https://amzn.to/4oBKKcg) - compact and energy-efficient machine for Frigate
- Coral Edge TPU [on Amazon US](https://a.co/d/0aeVsKY) - AI accelerator for fast and precise object detection
- Coral Dual Edge TPU [on Amazon](https://amzn.to/3Hxq83Y) - powerful AI accelerator (does not fit in EQ14)

_Some of the above are affiliate links. As an Amazon Associate, I earn from qualifying purchases._

**Tools used:**

- [Frigate](https://frigate.video/)
- [Docker](https://www.docker.com/)
- [Traefik](https://traefik.io/traefik)
- [Pi-Hole](https://pi-hole.net/)
- [Coral Edge TPU](https://coral.ai/products/)

{{< chat Frigate >}}
