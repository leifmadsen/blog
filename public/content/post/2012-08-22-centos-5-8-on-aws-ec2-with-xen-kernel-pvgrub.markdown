---
author: leifmadsen
comments: true
date: 2012-08-22 14:10:46+00:00
layout: post
slug: centos-5-8-on-aws-ec2-with-xen-kernel-pvgrub
title: CentOS 5.8 On AWS EC2 With Xen Kernel (PVGRUB)
wordpress_id: 467
categories:
- DevOps
- Technology
tags:
- aki
- amazon
- aws
- cloud
- ec2
- GRUB
- kernel
- mkinitrd
- pvgrub
- virtualization
- xen
---

At [CoreDial](http://coredial.com) we've been using a lot of AWS EC2 lately for building sandbox infrastructure for testing. Part of the infrastructure is a voice platform utilizing Asterisk 1.4 and 1.8, and those voice platforms are using Zaptel and DAHDI respectively for use with MeetMe(). This hasn't been an issue previously as our testing has either been on bare metal, or in other virtual machine systems where installation of a base image and standard kernel are not an issue.

However, with the introduction of a lot of EC2 instances in our testing process, we ran into issues with building our own DAHDI RPMs since there aren't any EC2 kernel development packages outside of OpenSuSE (which we don't use). After spending a day of trying to hack around it, Kevin found a [PDF](http://ec2-downloads.s3.amazonaws.com/user_specified_kernels.pdf) from Amazon that states AWS now supports the ability to load your own kernels via PVGRUB. Great! If I can do that, then I can just continue using the same RPMs I'd be building anyways (albeit the xen based kernel, but that's easy to do in the spec file).

Unfortunately this was not nearly as trivial and simple as it appeared at first. The first problem was that I had to figure out the correct magic kernel AKI that needed to be loaded, and the PDF wasn't incredibly clear about which one to use. (There is two different styles of the AKI, one called "hd0" and another called "hd00" which I'll get into shortly.) After searching Google and looking through several forum posts and other blogs (linked at the end), I finally found a combination that seems to work for our imported CentOS 5.8 base image. Below is a list of the steps I executed after loading up an image from our base AMI:

* `yum install grub kernel-xen kernel-xen-devel`
* `grub-install /dev/sda`
* `cd /boot/`
* `mkinitrd -f -v --allow-missing --builtin uhci-hcd --builtin ohci-hcd --builtin ehci-hcd --preload xennet --preload xenblk --preload dm-mod --preload linear --force-lvm-probe /boot/initrd-2.6.18-308.13.1.el5xen.img 2.6.18-308.13.1.el5xen`
* `touch /boot/grub/menu.lst`
* `cat /boot/grub/menu.lst`


```bash
default 0
timeout 1

title EC2
     root (hd0)
     kernel /boot/vmlinuz-2.6.18-308.11.1.el5xen root=/dev/sda1
     initrd /boot/initrd-2.6.18-308.11.1.el5xen.img
```

Once the changes were made to the image, I took a snapshot of the running instances volume. I then created an image from the snapshot. When creating the image, I selected a new kernel ID. The kernel ID's for the various zones and architectures are listed in the [PDF](http://ec2-downloads.s3.amazonaws.com/user_specified_kernels.pdf). As our base image was CentOS 5.8 i386 in the us-east-1 zone, I had to select between either aki‐4c7d9525 or aki‐407d9529. The paragraph above seems to indicate there is a difference based on what type of machine you're using, and references S3 or EBS based images. We are using EBS based images, so I tried the first one, which in the end failed miserably. After reading through the [IonCannon](http://www.ioncannon.net/system-administration/1205/installing-cent-os-5-5-on-ec2-with-the-cent-os-5-5-kernel/) blog post it became clear that the _hd0_ and _hd00_ AKIs are really differences in whether you have a single partition, or multiple partitions with a separate /boot/ partition.

With that bit of knowledge, and knowing that we only had a single partition that contained our /boot/ directory, I knew to use **aki-407d9529** (hd0). Another forum post also pointed out that I needed to enable some modules for the xen kernel or the system wouldn't boot (and I verified that by stepping through each of the steps listed above to make sure it was required). With those two major items checked off, I am now able to build an AMI that will load with a stock CentOS Xen kernel image, making it trivial to build RPMs against now.

> **Note**:
> If you do happen to use separate partitions, make sure you use the **hd00** AKI. In the **menu.lst** you need to make sure to use _root (hd0,0)_ instead of just (hd0). Additionally, your _menu.lst_ file needs to live at _/boot/boot/grub/menu.lst_ since AWS is going to look in the _/boot/grub/menu.lst_ location on the _/boot/_ partition. On a single partition the file can just live at _/boot/grub/menu.lst_.

**References**
* [https://forums.aws.amazon.com/message.jspa?messageID=202366](https://forums.aws.amazon.com/message.jspa?messageID=202366) <-- provided the mkinitfs command required to get everything to work on boot
* [https://forums.aws.amazon.com/message.jspa?messageID=253943](https://forums.aws.amazon.com/message.jspa?messageID=253943)
* [http://technotes.twosmallcoins.com/?tag=bootgrubmenulst](http://technotes.twosmallcoins.com/?tag=bootgrubmenulst)
* [http://www.ioncannon.net/system-administration/1205/installing-cent-os-5-5-on-ec2-with-the-cent-os-5-5-kernel/](http://www.ioncannon.net/system-administration/1205/installing-cent-os-5-5-on-ec2-with-the-cent-os-5-5-kernel/) <-- this was the best link, but was also the most verbose and overly complicated for what I needed, but it had a couple of tips in there that ended up helping a lot. The explanation of the difference between the hd0 and hd00 AKIs was they key to my success.
