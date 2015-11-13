---
author: leifmadsen
comments: true
date: 2011-11-02 16:08:40+00:00
layout: post
slug: controlling-outbound-bitrate-using-tc
title: Controlling outbound bitrate using tc
wordpress_id: 396
categories:
- Programming
- Useful Tools
tags:
- htb
- iptables
- mangle
- networking
- pfifo
- qdisc
- rate limiting
- tc
- traffic control
- traffic shaping
---

Today I was using the VMware vCenter Converter application to build a VM from a physical machine so that I could replace Ubuntu 10.04.3 LTS with VMware ESXi (and move the functionality that the server is performing now to a VM instead of it being the base OS).

Because my server is colocated in a friends rack, and the bandwidth is shared, I needed to limit the rate at which the data was being sent from the colocated server to the virtual machine server. I needed to do this so he didn't get pages, and so that my local connection would remain viable for VoIP communication.

After scouring Google, I found this page: [http://opalsoft.net/qos/DS.htm](http://opalsoft.net/qos/DS.htm)

I looked at the HTB queuing section, and came up with a simple rate limiter for my outbound data to a specific IP. The example he shows is more complex, but it gave me enough to make it work. Here is what I entered at the console:

```bash
tc qdisc del dev eth0 root  # clear existing rules
tc qdisc add dev eth0 root handle 1:0 htb
tc class add dev eth0 parent 1:0 classid 1:1 htb rate 2048kbit
tc class add dev eth0 parent 1:1 classid 1:2 htb rate 1228kbit ceil 2048kbit
tc class add dev eth0 parent 1:2 classid 1:21 htb rate 1228kbit ceil 2048kbit
tc qdisc add dev eth0 parent 1:21 handle 210: pfifo limit 10
tc filter add dev eth0 parent 1:0 protocol ip prio 1 u32 match ip dst 172.16.0.228/32 flowid 1:21

iptables -t mangle -A OUTPUT --dest 172.16.0.228 -p tcp -j MARK --set-mark 21
```

I'm sure I could have made that a bit more efficient on lines 4 and 5, but not knowing a ton about **tc** and the fact it worked, made me happy enough :)
