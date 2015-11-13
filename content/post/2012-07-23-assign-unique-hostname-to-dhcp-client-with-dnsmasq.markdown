---
author: leifmadsen
comments: true
date: 2012-07-23 19:14:45+00:00
layout: post
slug: assign-unique-hostname-to-dhcp-client-with-dnsmasq
title: Assign unique hostname to dhcp client with dnsmasq
wordpress_id: 456
categories:
- Being Productive
- DevOps
- Useful Tools
tags:
- /etc/hosts
- devops
- dhcp
- dnsmasq
- hostname
- vagrant
---

Today I've been getting our lab environment setup with vagrant to auto-provision our lab servers with chef server in order to allow the development team to quickly and easily turn up and tear down web application servers.

Because when the server gets spun up with vagrant, it registers itself as a new node to the chef server using its hostname. Since using localhost for every node pretty much makes the chef server useless for more than 1 virtual machine at a time, I needed to figure out how to get dnsmasq to assign a unique hostname based on the IP address being provided by dnsmasq to the dhcp client.

I had seen a similar thing done with Amazon EC2 instances that when they turn up, they gets a hostname that looks similar to the private IP address it has been assigned. For example, if the private IP address assigned to the server was 192.168.12.14 it would get a hostname like _ip-192-168-12-14_. I wanted to do a similar thing with our server.

After a little bit of Googling and reading the dnsmasq configuration file, it donned on me how simple this really was. You simply need to define the hostnames that the dnsmasq server could assign to a server, list those in the _/etc/hosts_ file on the dnsmasq server, and then define the hostname you wanted to provide to the server. I didn't want to use the MAC address of the servers (a la _dhcp-host_ option) since the MAC address will be dynamic each time I spin up a virtual machine.

So in my _dnsmasq.conf_ file I might have something defined like

    
    dhcp-range=90.100.1.120,90.100.1.124,24h




So in my _/etc/hosts_ file I'd just place the following to assign those unique hostnames:

    
    90.100.1.120    ip-90-100-1-120
    90.100.1.121    ip-90-100-1-121
    90.100.1.122    ip-90-100-1-122
    90.100.1.123    ip-90-100-1-123
    90.100.1.124    ip-90-100-1-124
