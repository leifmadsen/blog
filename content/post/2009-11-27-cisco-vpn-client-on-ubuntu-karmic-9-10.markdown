---
author: leifmadsen
comments: true
date: 2009-11-27 13:19:44+00:00
layout: post
slug: cisco-vpn-client-on-ubuntu-karmic-9-10
title: Cisco VPN Client on Ubuntu Karmic 9.10
wordpress_id: 152
categories:
- Technology
tags:
- cisco
- linux
- patch
- reference
- ubuntu
- vpn
---

I have a client who I need to connect to via a Cisco VPN, and since I use Ubuntu as my primary OS on my MacBook Pro, I've often needed to find some information about how to get the client working.

I had previously found some information about patching on Ubuntu 9.04 and it worked great, but since updating to 9.10 I had the same compile time issues I had before, which makes sense since the kernel is different now.

I found this site: [http://joepcremers.nl/wordpress/?p=1699](http://joepcremers.nl/wordpress/?p=1699) which had some good instructions for getting it going, but there almost appeared to be a patch missing, at least for my platform. The patch I needed was found on this site here: [http://www.painfullscratch.nl/code/vpn/](http://www.painfullscratch.nl/code/vpn/)

All the patches for the VPN client appear to have come from the tuxx-home.at forums: [http://forum.tuxx-home.at/viewforum.php?f=15](http://forum.tuxx-home.at/viewforum.php?f=15)

Hopefully that gets you all the information you need to get your Cisco VPN client working on Ubuntu Karmic 9.10!


_Update: June 15, 2010_




So I've been having some problems trying to get the Cisco VPN client working past a certain kernel version update (I think it's something like 2.6.19-something). I'm currently running 2.6.31-22-generic x86_64. I spent a bit of time trying to figure out why I couldn't get past that older kernel (and to avoid rebooting). On some kernels it would lock up the system entirely, on other kernels the CPN client just wouldn't connect.




After some web searching, I came across this blog post dated September 2009: [http://ilapstech.blogspot.com/2009/09/cisco-vpn-client-on-karmic-koala.html](http://ilapstech.blogspot.com/2009/09/cisco-vpn-client-on-karmic-koala.html). It seems to have the patch I needed to get around a compile time option that is described on that blog post. The error I was getting when compiling was:




    
    CC [M]  /usr/src/vpnclient/interceptor.o
    /usr/src/vpnclient/interceptor.c: In function ‘add_netdev’:
    /usr/src/vpnclient/interceptor.c:284: error: assignment of read-only location ‘*dev->netdev_ops’
    /usr/src/vpnclient/interceptor.c: In function ‘remove_netdev’:
    /usr/src/vpnclient/interceptor.c:311: error: assignment of read-only location ‘*dev->netdev_ops’
    make[2]: *** [/usr/src/vpnclient/interceptor.o] Error 1
    make[1]: *** [_module_/usr/src/vpnclient] Error 2
    make[1]: Leaving directory `/usr/src/linux-headers-2.6.31-22-generic'
    make: *** [default] Error 2




After the patch provided on that blog post I was still getting an error like so:




    
    Making module
    make -C /lib/modules/2.6.31-22-generic/build SUBDIRS=/usr/src/vpnclient-4.8.02.0030 modules
    make[1]: Entering directory `/usr/src/linux-headers-2.6.31-22-generic'
    scripts/Makefile.build:49: *** CFLAGS was changed in "/usr/src/vpnclient-4.8.02.0030/Makefile". Fix it to use EXTRA_CFLAGS.  Stop.
    make[1]: *** [_module_/usr/src/vpnclient-4.8.02.0030] Error 2
    make[1]: Leaving directory `/usr/src/linux-headers-2.6.31-22-generic'
    make: *** [default] Error 2
    Failed to make module "cisco_ipsec.ko".




Oh I've seen that error before. I used a patch from a site I mentioned earlier: [http://www.painfullscratch.nl/code/vpn/](http://www.painfullscratch.nl/code/vpn/).




Note that I've not actually checked to see if I only needed the latter patch, but with a combination of patch with the first site I mentioned in this update followed by the above mentioned sites patch, I was able to get onto my VPN connection for the client I require this for. Hope it helps!
