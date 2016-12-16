+++
categories = ["libvirt", "linux", "virtualization", "console"]
date = "2016-12-16T14:36:23-05:00"
title = "Creating virtual machines in libvirt with virt-install"
description = ""
keywords = [
]

+++

I've been wanting to automate my virtual machine instantiation for a while now,
but I've always hated the idea of having to spin up multiple bits of
infrastruction to deal with PXE booting, web server to host a kickstart file,
etc. Luckily, I ran into some stuff today, and figured out how to automate
virtual machine instantitation without having to resort to anything outside of
localhost.
<!--more-->
# Using `virt-install`
