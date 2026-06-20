+++
title = 'Coral Edge TPU: Hardware Acceleration for AI Object Detection'
summary = 'For my Frigate Docker container, I wanted to enable AI object detection with hardware acceleration. Therefore, I bought an M.2 Accelerator Coral Edge TPU chip with an A+E key and installed it in my home server.'
date = 2025-08-13T09:15:00-03:00 #Ctrl+Shift+I to insert date and time or dts in nvim
lastmod = 2025-08-13T09:15:00-03:00
draft = false #Entwurf wird noch nicht veröffentlicht
tags = ['Linux', 'Frigate', 'AI', 'Coral', 'TPU', 'NVR', 'Docker', 'CCTV']
categories = ['TechLab']

ShowToc = true
TocOpen = true

[params]
    author = 'Sebastian Zehner'
    ShowPageViews = true

[cover]
    image = '/img/coral-edge-tpu-hardware-acceleration-for-ai-object-detection.webp'
    alt = 'Featured image from Coral Edge TPU: Hardware Acceleration for AI Object Detection'
    hidden = false
    #caption = 'This is the caption'
    relative = false
    responsiveImages = false
+++

For my **Frigate Docker container**, I wanted to enable AI object detection with hardware acceleration. Therefore, I bought an M.2 Accelerator Coral Edge TPU chip with an A+E key and installed it in my home server.

## My First Setup: Lenovo ThinkCentre

The **Coral Edge TPU** was recognized without issues and worked flawlessly in the free Mini PCIe slot of my **Lenovo ThinkCentre** (`sumpfgeist.lan`), which is normally used for a WiFi module. This was an important success, since the same module does not work in the WiFi slot of the **Beelink EQ14**, as it only supports a CNVi interface for WiFi.

## Testing the M.2 Accelerator B+M Key for the EQ14

To also equip the EQ14 with hardware acceleration, I ordered an M.2 Accelerator Coral Edge TPU module with a B+M key.

The EQ14 runs Alpine Linux, for which there are no official drivers available. I had to compile the drivers myself — which I have already successfully done.

The installation and testing of the M.2 Accelerator B+M key on the EQ14 went smoothly. The drivers were compiled on **Alpine Linux 3.22** with the current kernel and work perfectly. Some errors occurred during compilation, but I was able to fix them.

To document my adjustments and solutions, I have already created a fork of the driver repository, which I describe in more detail in the last section of this article.

## Installing the Coral Edge TPU

Installing the Coral Edge TPU was straightforward. The PCIe slot in the Lenovo ThinkCentre was free, so I simply plugged in the module and restarted the server. The corresponding M.2 slot in the EQ14 was also free, allowing the card to be easily inserted and securely fastened.

## Driver Installation on Ubuntu

Installing the drivers for the Coral Edge TPU was somewhat more complex because errors occurred during the kernel module build process. I followed the [official Coral guide](https://coral.ai/docs/m2/get-started/#2a-on-linux) for Ubuntu but encountered compatibility issues, which I describe below.

### Preparation: Checking for Pre-installed Drivers

First, I checked whether any pre-built Apex drivers were already present:

```bash
uname -r   # Shows the kernel version, e.g., 6.8.0-60-generic
lsmod | grep apex   # Checks if Apex drivers are loaded
```

In my case, no drivers were pre-installed.

### Standard Installation Fails

Next, I added the Coral package repository and attempted to install the required packages:

```bash
echo "deb https://packages.cloud.google.com/apt coral-edgetpu-stable main" | sudo tee /etc/apt/sources.list.d/coral-edgetpu.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update
sudo apt-get install gasket-dkms libedgetpu1-std
```

This resulted in a build error during the compilation of the `gasket-dkms` module for my kernel (6.8.0-60-generic), because the driver source code was not compatible with my kernel version.

### Error Analysis and Solution

The build log showed errors such as:

```bash
error: passing argument 1 of ‘class_create’ from incompatible pointer type
error: too many arguments to function ‘class_create’
```

This is a known issue with the original `gasket-dkms` driver, as it was written for older kernel versions.

### Solution: Using a Fork and Building the Driver Yourself

To fix the problem, I first removed the incompatible package:

```bash
sudo apt purge gasket-dkms
```

Then, I cloned a patched fork that resolves the issue:

```bash
cd ~/downloads
git clone https://github.com/KyleGospo/gasket-dkms
```

The build dependencies also need to be installed:

```bash
sudo apt install dkms libfuse2 dh-dkms devscripts debhelper
```

Next, I built the package using `debuild`:

```bash
cd gasket-dkms
debuild -us -uc -tc -b
```

Since `debhelper` was not installed on my system, an error occurred which I fixed by installing `debhelper`.

After a successful build, I installed the generated `.deb` package:

```bash
cd ..
sudo dpkg -i gasket-dkms_*.deb
```

On my system, I specifically ran:

```bash
sudo dpkg -i gasket-dkms_1.0-18_all.deb
```

### Permissions and Reboot

Because I only use the hardware inside Docker containers and my user is part of the `docker` group, I set appropriate access rights via a `udev` rule:

```bash
sudo sh -c "echo 'SUBSYSTEM==\"apex\", MODE=\"0660\", GROUP=\"docker\"' > /etc/udev/rules.d/65-apex.rules"
```

Then, I rebooted the system:

```bash
sudo reboot
```

### Verification

After rebooting, I checked whether the device was detected:

```bash
ls -alh /dev/apex*
```

Output:

```bash
crw-rw----  120,0 root docker 10 Jun 11:12 /dev/apex_0
```

This confirmed that the driver installation was successful and the hardware was ready for use in Docker containers like Frigate.

## Docker Compose: Using the Coral Edge TPU in the Frigate Container

To use the Coral Edge TPU inside the Frigate Docker container, we need to make the hardware accessible to the container and adjust the configuration. You can find my full Frigate blog article [here](/posts/frigate-open-source-nvr-real-time-ai-object-detection/).

### Passing the Device to the Container

In the Frigate `docker-compose.yaml` file (e.g., located at `~/docker-compose/frigate/`), add the following section under `services.frigate`:

```yaml
devices:
  - /dev/apex_0:/dev/apex_0
```

This passes the device `/dev/apex_0` from the host system into the container.

### Adjusting the Frigate Configuration

In the Frigate configuration file `config.yml` (for example, under `~/docker/frigate/`), add or modify the detector settings for the TPU:

```yaml
detectors:
  coral1:
    type: edgetpu
    device: pci:0
```

This tells Frigate to use the Edge TPU detector, which communicates via the PCIe device `pci:0`.

### Restarting the Container

After making these changes, restart the Frigate container:

```bash
cd ~/docker-compose/frigate
docker compose down
docker compose up -d
```

Frigate will now use the Coral Edge TPU hardware acceleration for AI object detection. For more details on configuring Frigate, see [here](/posts/frigate-open-source-nvr-real-time-ai-object-detection/).

## Drivers on Alpine Linux

For Alpine Linux, there is a special repository with a bug fix that enables compiling the Coral Edge TPU drivers for the Alpine version and kernel I’m using.

I cloned the repository [here](https://github.com/sebastianzehner/alpine-coral-tpu) and adapted it for my kernel version. The detailed installation instructions can also be found there.

To use the Coral chip on the EQ14, I also purchased a different TPU model on a SOM board (System-On-Module) suitable for the M.2-2280-B-M-S3 (B/M Key) slot. With the self-compiled drivers, the device was then recognized by the system.

### Verifying the Hardware

You can check if the Edge TPU is recognized by running the following command:

```bash
ls -alh /dev/apex*
```

On my system, the output looks like this:

```bash
crw-rw----  120,0 root 28 Jun 20:46 /dev/apex_0
```

### Migration to the EQ14 and Performance

I migrated my Frigate installation from the **ThinkCentre** (`sumpfgeist.lan`) to the **EQ14** (`eq14.lan`). There, the Coral chip is recognized and AI object detection runs with an average latency of about 8 ms per frame. The chip’s temperature is around 45°C, which is within a safe range.

![Image Frigate Webinterface Detectors Coral Edge TPU](/img/galleries/coral-edge-tpu-hardware-acceleration-for-ai-object-detection/coral-edge-tpu-frigate-detector.webp)

### Kernel Update and Recompilation

In the meantime, I updated **Alpine Linux** on the **EQ14** with a new kernel. Before rebooting, I recompiled the drivers to ensure compatibility.

After the system booted, I copied and activated the current driver files, so the Coral chip was recognized again and Frigate continued to run smoothly.

My repository has since been updated to support the latest kernel of **Alpine Linux 3.22**. You can always follow my step-by-step guide on [GitHub](https://github.com/sebastianzehner/alpine-coral-tpu) to successfully install and compile the drivers.

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
- [GitHub](https://github.com/sebastianzehner/alpine-coral-tpu)
- [Coral Edge TPU](https://coral.ai/products/)

{{< chat CoralTPU >}}
