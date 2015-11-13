---
author: leifmadsen
comments: true
date: 2012-11-24 22:06:03+00:00
layout: post
slug: brother-printer-doesnt-print-in-fedora-17
title: Brother printer doesn't print in Fedora 17
wordpress_id: 522
categories:
- Technology
tags:
- brother
- CUPS
- fedora
- linux
- printer
---

**Tip: If your Brother printer won't print after installing the drivers, install glibc.i686**

Today ran into an issue with my new Brother MFC-7460DN (which is a really nice laser printer with auto-feed scanner, Scan-to-FTP which creates a PDF file, and other things). I had just recently done a clean install of Fedora 17, and I could install the RPMs (which are i386 files on my x86_64 based system), add the printer to CUPS and all sorts of things that looked fine.

However when I went to print, it wouldn't error out, but the printer wouldn't actually print. I tried changing a file per [https://bbs.archlinux.org/viewtopic.php?pid=940524#p940524](https://bbs.archlinux.org/viewtopic.php?pid=940524#p940524) but it didn't help.

Then I found this post [http://forums.fedoraforum.org/showthread.php?t=280753](http://forums.fedoraforum.org/showthread.php?t=280753) which reminded me to install glibc.i686. Wish the Brother drives would just make that a dependency in the RPM.
