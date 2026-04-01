---
title: "Installing DD-WRT on the TL-WR949N: The complete guide"
summary: "How I flashed the Brazilian TP-Link TL-WR949N router with DD-WRT: including a workaround for the SSID issue related to Error 18005, a step-by-step guide, and information on using TFTP for recovery."
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
  alt: Router firmware
  hidden: false
  relative: false
  responsiveImages: false

translation:
  tool: md-translator
  version: 1.2.3
  from: de
  to: en
  date: 2026-03-31
  time: "21:06:50"
---

I flashed the cheaper TP-Link TL-WR949N routers with the firmware from [dd-wrt.com](dd-wrt.com). The following describes the steps I had to take in order to use this firmware.

I would have preferred to use [openwrt.org](openwrt.org) as the main router, just like I did with [OpenWrt One](https://openwrt.org/toh/openwrt/one), but unfortunately this is not recommended for [this router](https://openwrt.org/toh/tp-link/tl-wr940n). And especially not because of [OpenWrt on 4/32 devices](https://openwrt.org/supported_devices/openwrt_on_432_devices).

- Model: TL-WR949N(BR) Version: 6.0

I mainly use these routers as access points in my workshop and the outdoor area (the “quincho”). They are configured with WPA2 and CCMP-128 (AES) – the highest level of encryption available for WPA2.

## Background

The TL-WR949N is a Brazilian rebranded version of the TL-WR940N, with identical hardware. It does not appear on the official TP-Link international website; therefore, it does not have dedicated DD-WRT support. It is important to take into account the specific hardware version used—in my case, it is version 6.0.

A direct attempt to use the official TL-WR940N firmware or DD-WRT through the standard web interface fails due to the use of the `Error 18005` command; this is because the WR949N has a different hardware ID. However, this issue can be circumvented using a workaround.

## Required files

| File | Purpose | Source |
| ------------------------------------- | ------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `wr940nv6_3_20_1_up_boot(250925).bin` | TP-Link EU-stock firmware for the WR940N | [TP-Link Download Page for WR940N](https://www.tp-link.com/de/support/download/tl-wr940n/#Firmware) |
| `factory-to-ddwrt-eu.bin` | First installation of DD-WRT (EU) | [DD-WRT Router – Database](https://dd-wrt.com/support/router-database/) (`wr940n`) |
| `tl-wr940ndv6-webflash.bin` | Upgrading DD-WRT to a more recent build | [DD-WRT Router – Database](https://dd-wrt.com/support/router-database/) (`wr940n`) |

> **Note:** The router database from DD-WRT contains outdated builds (as of 2020) and should **not** be used. Always refer directly to the beta folder.

**DD-WRT Beta downloads:**

[Download](https://download1.dd-wrt.com/dd-wrtv2/downloads/betas/) → Select the year/build version → `tplink-tl-wr940ndv6`

Proven Builds:

| Build | Date | Notes | Download |
| ------ | ---------- | ------------------------------- | --------------------------------------------------------------------------------------------------------- |
| r44715 | 2020-11-03 | Listed in the router database | [Link](https://download1.dd-wrt.com/dd-wrtv2/downloads/betas/2020/11-03-2020-r44715/tplink_tl-wr940ndv6/) |
| r64210 | 2026-03-31 | Just confirmed that it’s in the Beta folder. | [Link](https://download1.dd-wrt.com/dd-wrtv2/downloads/betas/2026/03-31-2026-r64210/tplink-tl-wr940ndv6/) |

## Prerequisites

- LAN cable: Always use the LAN port for flashing (never the WAN port).
- Computer with a browser

> **Note:** This guide reflects my own experience. Flashing third-party firmware is done at your own risk; I will not be responsible for any damaged routers or other consequences. If in doubt, it’s always better to read the instructions twice before proceeding.

## Step 1 – Install the TP-Link EU-stock firmware

The current firmware version on my TL-WR949N v6 router is:

```text
Versão de Firmware:	3.18.1 Build 171115 Rel.43350n
Versão de Hardware:	WR949N v6 00000000
```

The WR949N device prevents the installation of foreign firmware via the web interface using the ``Error 18005`` mechanism; however, I can bypass this restriction using [this workaround](https://openwrt.org/toh/tp-link/tl-wa801nd) in the following way.

### How to bypass the firmware lock

To use the workaround, I enter the following lines one by one as the device’s SSID. The backticks must be included when typing them. Set the SSID and save between each line.

1. Open the web interface: `http://192.168.0.1` – Login: `admin` / `admin`
2. Wireless → SSID field → Enter the following lines one by one and save each one after completion (Atualizar).

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

After the last step (`sh /tmp/s`), the `httpd` process is restarted. The router itself does not reboot, but the web interface becomes unavailable for approximately 20–30 seconds.

### Flashing the Firmware

1. Open the web interface: `http://192.168.0.1` – Login: `admin` / `admin`
2. **System Tools (Ferramentas de sistema) → Firmware Upgrade (Atualizar firmware)**
3. Select `wr940nv6_3_20_1_up_boot(250925).bin` → **Upgrade (Atualizar)**
4. Wait a few minutes for the flashing process to complete, after which the router will automatically restart.
5. Factory Reset: Hold down the reset button for **20 seconds** and wait until the router restarts.

The web interface can be accessed again via `http://192.168.0.1`. On the first attempt to log in, a new password is requested immediately; there is no longer a separate username field, only a password prompt.

The interface is now in English instead of Portuguese, which indicates that the EU-specific firmware is being used.

**The firmware after the update:**

```text
Firmware Version:	3.20.1 Build 250925 Rel.57536n (4555)
Hardware Version:	WR940N v6 00000000
```

I can now use this firmware, or I can move on to Step 2 and install DD-WRT.

## Step 2 – Initial installation of DD-WRT

After completing the first step, I can now successfully install DD-WRT via the web interface without any issues, and the `Error 18005` no longer appears.

### Flashing the Firmware

1. Open the web interface: `http://192.168.0.1` – Enter the password.
2. System Tools → Firmware Upgrade
3. Select the current `factory-to-ddwrt-eu.bin` → **Upgrade**
4. Wait a few minutes for the flashing process to complete, and then the router will automatically restart.
5. Factory Reset: Hold down the reset button for **20 seconds** and wait until the router restarts.

The web interface can be accessed via `http://192.168.1.1`. On the first visit, you will be prompted to enter a new username and password immediately. After that, the router can be configured.

## Step 3 – Upgrade to a newer DD-WRT build

The `webflash.bin` is intended for upgrades when DD-WRT is already installed on the router. It comes from the same build directory as the `factory-to-ddwrt` file.

### Flashing the Firmware

1. Open the web interface: `http://192.168.1.1` – Enter your username and password.
2. Administration → Firmware Upgrade
3. `tl-wr940ndv6-webflash.bin` Upload → **Upgrade**
4. Wait a few minutes for the flashing process to complete, after which the router will automatically restart.
5. It is recommended to perform a factory reset: Press and hold the reset button for **20 seconds** and wait until the router restarts.

## Back to TP-Link stock (TFTP recovery)

If DD-WRT is running on the router and you want to revert it back to the original firmware:

```
PC-IP:       192.168.0.66 / 255.255.255.0
TFTP-file:   wr940nv6_tp_recovery.bin
             (Content: TP-Link stock firmware, renamed)
```

> **Important:** The PC and the router must be connected through a network switch; a direct connection will not work because Windows temporarily interrupts the Ethernet connection when the router restarts, causing the TFTP request to be missed.

Procedure:

1. Connect the PC and the router via a switch.
2. Starting a TFTP server (e.g., using [tftpd64](https://pjo2.github.io/tftpd64/) or [atftp](https://sourceforge.net/projects/atftp/)).
3. Select the folder that contains the renamed file.
4. Select the interface `192.168.0.66`.
5. Turn off the router.
6. Hold down the Reset button and turn on the router.
7. Hold down the Reset button until the TFTP transfer starts (about 10 seconds).
8. Wait until the transfer is complete and the router restarts.

> **Note:** The original TP-Link firmware must contain a boot header before being renamed (the file name includes `up_boot`). Firmware whose file name does not contain `up_boot` **should not** be used for TFTP transfers.

## Conclusion

The TL-WR949N is an affordable router that can be easily configured to use with DD-WRT with a bit of patience and the right steps. The workaround involving the SSID field is somewhat unusual, but it works reliably. With the latest version of DD-WRT firmware, the router functions stably as an access point.

Documenting these steps was definitely worth it; next time I won’t have to start from scratch like I did today.

Have you flashed the TL-WR949N or a similar router? Did you notice anything unusual during the process, or did you find another way to achieve your goal? I’d be interested in hearing your comments—either right here via Cactus Comments using your Matrix account, or as a guest without an account at all. This topic could also make for another great blog post.

Best regards, Sebastian

{{< chat installing-dd-wrt-on-the-tl-wr949n >}}
