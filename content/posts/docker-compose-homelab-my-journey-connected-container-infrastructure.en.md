+++
title = 'Docker Compose in the Homelab: My Journey to a Connected Container Infrastructure'
summary = 'With clearly structured volumes, dedicated networks, and a bit of automation, my services run reliably across multiple Linux systems. They are quick to deploy, easy to update, and stable.'
date = 2025-08-15T09:04:00-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-15T09:04:00-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'Docker', 'Compose', 'Container', 'Homelab', 'IPvlan', 'Networking']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/docker-compose-homelab-my-journey-connected-container-infrastructure.webp'
    alt = 'Featured Image from Docker Compose in the Homelab: My Journey to a Connected Container Infrastructure'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

Whether you’re running a small home network or a full-fledged homelab, Docker with Docker Compose provides a flexible and clean way to run, connect, and manage services.

When I started my first **Docker container** a few years ago, I never imagined it would become a central foundation of my **homelab**. Initially, Docker was just a handy tool for quickly deploying a single service.

Today, I run dozens of services. They are spread across four Linux systems, organized and managed with **Docker Compose**, and connected via their own **Docker network**.

Docker has become so deeply integrated into my daily workflow that I wouldn’t want to run many of my services any other way. It makes deployments reproducible, updates controllable, and management much easier—whether on a mini-PC, a rack server, or a small virtual machine.

## Installing Docker on Different Linux Systems

One of the reasons I enjoy using Docker so much is the flexibility of installation. In my homelab, I run a variety of Linux distributions—and Docker works everywhere:

- **Alpine Linux:** Ideal for minimal setups, installed via `apk` in just a few seconds.
- **Arch Linux:** Thanks to `pacman` and the official Docker package, installation is quick and straightforward.
- **Debian / Ubuntu:** Using Docker’s repository, I can get the latest versions directly via `apt`.

Additionally, I install **Docker Compose** to manage all systems with the same syntax.

> **Note:** In my examples on Alpine Linux, I use the command `doas` (similar to `sudo`) because Alpine doesn’t include `sudo` by default. On all other systems, I use `sudo`.

### Alpine Linux

```bash
doas apk add docker docker-compose
```

Enable the Docker service to start automatically on boot and add your user to the `docker` group:

```bash
doas rc-update add docker default
doas /etc/init.d/docker start
doas addgroup $USER docker
```

### Arch Linux

```bash
sudo pacman -S docker docker-compose
```

### Debian / Ubuntu

```bash
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install the Docker packages
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

On Arch Linux and Ubuntu, the Docker service starts automatically, but you can manually start it with:

```bash
sudo systemctl start docker
```

You should also add your user to the `docker` group:

```bash
sudo usermod -aG docker $USER
```

After installation, you can test if everything worked with:

```bash
docker info
docker ps
```

## Data Organization and Volumes

**One of my core principles in the homelab:** separate configuration and data from the container.
I structure my volumes clearly by service, for example:

```bash
# Configuration
~/docker-compose/
   ├── traefik/
   ├── komodo/
   ├── jellyfin/
   ├── frigate/

# Data and volumes
~/docker/
   ├── traefik/
   ├── komodo/
   ├── jellyfin/
   ├── frigate/
```

This way, I can not only create backups quickly, but also move or redeploy services without losing any data.

I plan to write a separate article about backups, in which **Restic** will play the main role.

## Docker Networking - The Invisible Backbone

One of the biggest game-changers for me was Docker networking.

Instead of having each service randomly floating in the network, I created a dedicated internal network for my containers. This allows services to communicate directly with each other without exposing unnecessary ports to the outside world.

In combination with **Traefik** (more on that in the next article), I can easily reach any service via a subdomain - whether it’s `komodo.mydomain.com` or `jellyfin.mydomain.com`.

For me, this means no more remembering random port numbers and a clean, centralized routing setup.

### Setting up Macvlan or IPvlan for Docker

I ultimately chose **IPvlan** to build my Docker network. I’ll cover more details in the Traefik blog post, but here are the commands to create the proxy network:

```bash
sudo docker network create -d ipvlan --subnet 192.168.x.x/24 --gateway 192.168.x.x -o parent=enp1s0f0 proxy
```

Find the name of your server’s network interface with:

```bash
ip address show
```

The network interface of the `sumpfgeist.lan` server is called `enp1s0f0`, which I used for configuring the Docker IPvlan.

**Important note when using this setup:**

I assign IP addresses for Docker containers manually in the `docker-compose.yaml` files to avoid IP conflicts, because otherwise Docker would assign IPs automatically without considering my DHCP server.

Here’s an example of a simple Meshtastic web application with a manually assigned IP address and Traefik reverse proxy labels using the external `proxy` IPvlan network:

```bash
services:
  meshtastic-web:
    image: ghcr.io/meshtastic/web
    container_name: meshtastic
    restart: unless-stopped
    networks:
      proxy:
        ipv4_address: 192.168.x.x
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.meshtastic.entrypoints=http"
      - "traefik.http.routers.meshtastic.rule=Host(`meshtastic.techlab.icu`)"
      - "traefik.http.middlewares.meshtastic-https-redirect.redirectscheme.scheme=https"
      - "traefik.http.routers.meshtastic.middlewares=meshtastic-https-redirect"
      - "traefik.http.routers.meshtastic-secure.entrypoints=https"
      - "traefik.http.routers.meshtastic-secure.rule=Host(`meshtastic.techlab.icu`)"
      - "traefik.http.routers.meshtastic-secure.tls=true"
      - "traefik.http.routers.meshtastic-secure.service=meshtastic"
      - "traefik.http.services.meshtastic.loadbalancer.server.port=8080"
      - "traefik.docker.network=proxy"
networks:
  proxy:
    external: true
```

I also set up the Docker network on other servers, such as `eq14.lan` running **Alpine Linux**:

```bash
doas docker network create -d ipvlan --subnet 192.168.x.x/24 --gateway 192.168.x.x -o parent=eth0 proxy
```

### Why I Use IPvlan Instead of Macvlan

One of the key reasons was network **compatibility**:

- **Only one MAC address per physical interface** - with Macvlan, each container gets its own MAC address. This can cause issues with some switches, routers, or especially consumer devices, which may not handle multiple MACs on a single port correctly.
- **Simpler Layer-2 handling** - IPvlan appears as a single interface to the network and distributes IP addresses internally, reducing the risk of broadcast or ARP problems.
- **Better performance in some scenarios** - IPvlan bypasses the virtual network driver layer that can slow down Macvlan, making it more efficient when running many containers.
- **More compatible with firewalls and VLANs** - some security or management systems behave more reliably when only one MAC address per port is used.

## Management: CLI Instead of Click Interfaces

Although there are tools like Komodo that give me a central overview of my four Docker hosts, almost all of my actual work happens in the terminal.

I prefer direct control, for example, with:

```bash
docker ps
docker compose up -d
docker compose down
```

Each service has its own `docker-compose.yaml` file, keeping configurations transparent and well-organized.

I also love my terminal and deliberately prefer CLI commands (`docker` & `docker compose`) for scripts, automation, backups, SSH access, and more.

### Why I Use Komodo Instead of Portainer

Many homelab users rely on Portainer to manage containers through a web interface. For my workflow, however, Komodo is perfectly sufficient - a lightweight, open-source dashboard that gives me an overview of all connected systems at a glance.

I handle the actual management through the terminal anyway, so Komodo strikes the right balance of clarity and minimalism for me.

## Advantages of Docker Compose in the Homelab

- **Quick deployment:** New service? `docker compose up` and it’s running.
- **Less chaos:** No package conflicts or host dependencies.
- **Portability:** Containers can be easily moved to other systems.
- **Consistency:** Services behave identically on Arch, Debian, or Alpine.

## Outlook

In an upcoming article, I’ll go deeper into **Traefik**. This is my central reverse proxy that connects my Docker network to the outside world.

External access is provided, among other methods, via a **Cloudflare Tunnel** or **Twingate**, both running as Docker containers in the network and certainly worthy of their own blog posts.

I also plan to write an article about backups using **Restic**, to ensure no data loss occurs in the homelab. My backups run automatically via a script scheduled with Cron.

## Container Strategy: How I Distribute Docker Services in the Homelab

To wrap up, here’s a small list of the Docker containers currently running in my homelab:

- Traefik (2x)
- Frigate
- Meshtastic
- Komodo Core
- Komodo Periphery (4x)
- Searxng
- Twingate
- Mixpost
- Cloudflare Tunnel
- Gluetun
- Linkwarden
- PeaNUT
- Baikal
- IT-Tools
- Home Assistant
- Synapse
- Gotify
- Stirling PDF
- Glance
- Uptime Kuma
- Wordpress
- n8n
- Wiki.js
- Jellyfin

All of these containers run 24/7, distributed across several systems, for example:

- **Synology NAS:** Jellyfin (media server) - optimal, as the media is already stored there.
- **EQ14 Mini-PC with two LAN ports:** Frigate (NVR), separate Traefik reverse proxy - dedicated network ports and extra computing power are ideal for AI-assisted video processing.
- **Lenovo ThinkCentre M715q:** All other production services like Mixpost, Wiki.js, Searxng, Home Assistant, etc.
- **Fourth host:** Only started as needed for temporary container tests or special projects.

Initially, Frigate also ran on the ThinkCentre, which worked but consumed more resources. Moving it to the EQ14 now significantly reduces load on the main server. You can read my Frigate blog post [here](/posts/frigate-open-source-nvr-real-time-ai-object-detection/).

I deliberately chose not to use Docker Swarm - with my manageable number of hosts, the combination of targeted container distribution and a second Traefik proxy on the EQ14 is a simpler and more robust solution. But who knows what the future might bring?

## Conclusion

For me, Docker Compose is far more than just a tool - it is the foundation of my homelab. With clear organization, clean networking, and a bit of automation, it allows me to build a robust, flexible, and easily maintainable environment that makes daily operations much easier.

Do you use **Docker** or **Docker Compose** in your homelab? Feel free to share in the comments how you organize your containers!

## Hardware Recommendations

- EQ14 Mini-PC [on Amazon](https://amzn.to/4oBKKcg) - a compact and energy-efficient machine for Docker
- Lenovo ThinkCentre M715q [at RAM-KÖNIG](https://www.ram-koenig.de/lenovo-thinkcentre-m715q-ryzen5pro2400ge-8gbddr4) - used tiny PC as a Docker server

_Some of these are affiliate links. As an Amazon Associate, I earn from qualifying purchases._

**Tools Used:**

- [Docker](https://www.docker.com/)
- [Traefik](https://traefik.io/traefik)
- [Komodo](https://komo.do/)

{{< chat Docker >}}
