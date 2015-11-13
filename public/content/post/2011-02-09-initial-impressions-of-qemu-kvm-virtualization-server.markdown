---
author: leifmadsen
comments: true
date: 2011-02-09 01:18:22+00:00
layout: post
slug: initial-impressions-of-qemu-kvm-virtualization-server
title: Initial impressions of qemu-kvm (virtualization server)
wordpress_id: 281
categories:
- Technology
- Useful Tools
tags:
- GRUB
- kvm
- qemu
- qemu-kvm
- virtual machines
- VM
- vmware
- vmware server
---

The qemu-kvm ([http://www.linux-kvm.org/page/Main_Page](http://www.linux-kvm.org/page/Main_Page)) package on Ubuntu 10.10 allows you to create virtual machines much like VMware, Xen, etc.

My initial impressions are generally pretty positive. I like that it lets you install multiple operating systems (including MS Windows, which I haven't tried yet), and doesn't use a web interface like VMware Server 2 (which I've found to be terribly crash prone, requiring a restart of the web interface at the least, and sometime the entire server needs to be restarted, often abruptly with the kill application). My favourite part is the libvirt-manager that lets you manage the system and install virtual machines remotely over SSH using VNC (or at least something similar to it).

The one problem I had initially was installing CentOS 5.5. It was terribly slow, and when I started the virtual machine, I coudn't get it past GRUB. I thought perhaps it was just a problem with running CentOS VMs on an Ubuntu host machine, but then I had the same problem with an Ubuntu installation (which took at least 3-4 times as long to install as CentOS for some reason).

I got looking around and found people with similar issues as me, but they all basically just outlined reinstalling GRUB via a rescue disk. I tried this which got me just a little bit further, but still no GRUB menu, or system booting.

Then I found a post indicating that restarting the KVM service caused things to work, which I tried doing, but nothing changed. So as a last ditch effort I tried rebooting the service, which I didn't expect to actually fix anything, but oddly enough worked. The existing VMs I installed started up fine, and the new installation I tried went significantly faster.

I haven't had much of a chance to try more than what I've described, but thus far I like KVM a lot more than VMware. Hopefully I keep enjoying it as I go forward now that I've gotten VMs to boot :)
