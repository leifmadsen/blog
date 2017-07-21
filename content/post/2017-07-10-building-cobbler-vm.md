+++
categories = ["nfvpe", "howto", "infrastructure"]
keywords = ["cobbler", "lab", "pxe", "infrastructure", "deploy", "devops"]
description = ""
title = "yakLab Part 1a: Building the virtual Cobbler deployment"
date = "2017-07-12T20:45:01-04:00"

+++

In this scene I'll discuss how I've built out a local Cobbler deployment into
my virtual host in order to bootstrap the operating system onto my baremetal
nodes via kickstart files and PXE booting.
<!--more-->

## What's Cobbler?

Directly from the Cobbler website:

> Cobbler is a Linux installation server that allows for rapid setup of network
> installation environments. It glues together and automates many associated
> Linux tasks so you do not have to hop between many various commands and
> applications when deploying new systems, and, in some cases, changing
> existing ones. Cobbler can help with provisioning, managing DNS and DHCP,
> package updates, power management, configuration management orchestration,
> and much more.

# Deploying the virtual machine

To deploy the base virtual machine into my virthost, I used `virt-install` in
order to automate the deployment with a kickstart file. I've documented this
previously in [Creating virtual machines in libvirt with virt-install]({{< ref
"post/2016-12-16-creating_vms_with_virt-install.markdown" >}}).

Instead of going through the how and why, I'm just going to dump out the
commands I've been running to get a virtual host up and running on my local
network:

```sh
virt-install --name "Cobbler" \
--memory 2048 \
--disk /home/libvirt/images/cobbler.qcow2,size=20,bus=virtio \
--location /var/lib/libvirt/images/CentOS-7-x86_64-Minimal.iso \
--boot cdrom \
--network network=host-bridge \
--noautoconsole \
--vnc \
--initrd-inject kickstart/cobbler.ks \
--extra "inst.ks=file:/cobbler.ks" \
--accelerate
```

And there isn't really anything too special in the kickstart file, but here it
is for posterity and completeness:

```sh
#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512
# Use CDROM installation media
cdrom
# Use graphical install
graphical
# Run the Setup Agent on first boot
firstboot --enable
ignoredisk --only-use=vda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=eth0 --noipv6 --activate --onboot yes
network  --hostname=cobbler.yaklab

# Root password
rootpw --iscrypted $p$g...0mg1tzcry73d
# System services
services --enabled="chronyd"
# System timezone
timezone America/New_York --isUtc
user --groups=wheel --name=admin --password=$p$g...0mg1tzcryp73d --iscrypted --gecos="admin"
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=vda
autopart --type=lvm
# Partition clearing information
clearpart --none --initlabel

reboot

%packages
@^minimal
@core
chrony
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=50 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=50 --notstrict --nochanges --notempty
pwpolicy luks --minlen=6 --minquality=50 --notstrict --nochanges --notempty
%end
```
(And if you're wondering why I'm bothering with a full out `virt-install` with
a kickstart file instead of just using a qcow2 image and maybe come cloud-init,
it's mostly just because I haven't built out my local infrastructure to do that
yet. You're not wrong though.)

# Installing Cobbler

Installing Cobbler is well documented at http://cobbler.github.io/manuals/2.8.0/2/2/2_-_RHEL_and_CentOS.html
but I'll step through the installation here quickly:

First, let's install EPEL since we'll need that for some dependencies (and
Cobbler itself).

```sh
$ sudo yum install epel-release -y
```

Next, let's install Cobbler and some dependencies.

```sh
$ sudo yum install cobbler cobbler-web syslinux pykickstart xinetd tftp-server -y
```

# Configuring and Starting TFTP Services

Before we get to the Cobbler part of things, we need to start the TFTP server
and make sure things are configured correctly.

First, let's make sure we can enable the TFTP server:

```sh
$ sudo sh -c "sed -i -e 's/= yes/= no/' /etc/xinetd.d/tftp"
```

Next, we can start and enable our TFTP server and xinetd services.

```sh
$ sudo systemctl enable xinetd.service
$ sudo systemctl start xinetd.service
$ sudo systemctl enable tftp.service
$ sudo systemctl start tftp.service
```

Then we'll do some permission setup.

```sh
sudo chcon -t tftpdir_rw_t /var/lib/tftpboot
sudo useradd -s /bin/false -r tftp
```

# Firewall Rules

We can now open up some ports that we'll need in our firewall so that our
servers can access the services we're hosting.

```sh
$ sudo firewall-cmd --add-port=69/tcp --permanent
$ sudo firewall-cmd --add-port=69/udp --permanent
$ sudo firewall-cmd --add-port=4011/udp --permanent
$ sudo firewall-cmd --add-port=443/tcp --permanent
$ sudo firewall-cmd --add-port=80/tcp --permanent
$ sudo firewall-cmd --reload
```

Then we can validate that our firewall rules are in place by running
`iptables`.

```sh
sudo iptables -L -v -n
...
Chain IN_public_allow (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:22 ctstate NEW
    0     0 ACCEPT     udp  --  *      *       0.0.0.0/0            0.0.0.0/0            udp dpt:69 ctstate NEW
    0     0 ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:443 ctstate NEW
    0     0 ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80 ctstate NEW
    0     0 ACCEPT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            tcp dpt:69 ctstate NEW
    0     0 ACCEPT     udp  --  *      *       0.0.0.0/0            0.0.0.0/0            udp dpt:4011 ctstate NEW
...
```

# Setting up SELinux

Instead of disabling SELinux, let's run some `sesetbool` commands.

```sh
$ sudo setsebool -P cobbler_can_network_connect 1
$ sudo setsebool -P httpd_can_network_connect_cobbler 1
$ sudo setsebool -P httpd_serve_cobbler_files 1
$ sudo restorecon -R /var/lib/cobbler/
```

If we're still having issues, we can start to debug SELinux by running some of
the following commands.

```sh
$ sudo yum install policycoreutils-python checkpolicy -y
$ sudo sh -c "grep cobbler /var/log/audit/audit.log | audit2why"
```

Note that nothing will return until we start our Cobbler services, so we might
as well do that now.

# Starting Cobbler and Services

Now that we have our prerequisites installed, we can get the services started
that we need running. Before we get to that part, we need to do a bit of
configuration.

First, we'll want to change the default password that Cobbler sets on hosts
when the appropriate variable is used in the kickstart configurations. We can
generate a password with `openssl` like so:

```sh
openssl passwd -1
```

Copy that password and put it into the `default_password_crypted` field.

Next, we need to tell Cobbler what interface to listen on, and the server IP to
tell the PXE server to connect to for kickstart and boot loaders. These fields
are:

* `bind_master`
* `next_server`
* `server`

Change the value from `127.0.0.1` to the IP address your host is on. Mine is
currently `192.168.1.146`.

We clearly aren't going to want our machines to keep PXE booting and looping on
installation, so we'll want to change the `pxe_just_once` value from `0` to
`1`.

```json
pxe_just_once: 1
```

Below is the patch showing our changes:

```diff
$ diff -ru settings /etc/cobbler/settings
--- settings	2017-07-12 19:42:20.512969338 -0400
+++ /etc/cobbler/settings	2017-07-12 19:49:11.440585148 -0400
@@ -98,7 +98,7 @@
 # The simplest way to change the password is to run
 # openssl passwd -1
 # and put the output between the "" below.
-default_password_crypted: "$1$mF86/UHC$WvcIcX2t6crBz2onWxyac."
+default_password_crypted: "$1$QMG/8mMb$gpFBFiDc0S3P/uSDGdpP10"

 # the default template type to use in the absence of any
 # other detected template. If you do not specify the template
@@ -251,7 +251,7 @@

 # set to the ip address of the master bind DNS server for creating secondary
 # bind configuration files
-bind_master: 127.0.0.1
+bind_master: 192.168.1.146

 # set to 1 to enable Cobbler's TFTP management features.
 # the choice of TFTP mangement engine is in /etc/cobbler/modules.conf
@@ -269,7 +269,7 @@
 # if using cobbler with manage_dhcp, put the IP address
 # of the cobbler server here so that PXE booting guests can find it
 # if you do not set this correctly, this will be manifested in TFTP open timeouts.
-next_server: 127.0.0.1
+next_server: 192.168.1.146

 # settings for power management features.  optional.
 # see https://github.com/cobbler/cobbler/wiki/Power-management to learn more
@@ -289,7 +289,7 @@
 # first in it's BIOS order.  Enable this if PXE is first in your BIOS
 # boot order, otherwise leave this disabled.   See the manpage
 # for --netboot-enabled.
-pxe_just_once: 0
+pxe_just_once: 1

 # the templates used for PXE config generation are sourced
 # from what directory?
@@ -381,7 +381,7 @@
 # if you have a server that appears differently to different subnets
 # (dual homed, etc), you need to read the --server-override section
 # of the manpage for how that works.
-server: 127.0.0.1
+server: 192.168.1.146

 # If set to 1, all commands will be forced to use the localhost address
 # instead of using the above value which can force commands like
```

And now that we've made our changes, let's restart the Cobbler service:

```sh
$ sudo systemctl restart cobblerd.service
```

# Checking Our Configuration

Now that we've made several changes and restarted Cobbler, we should check that
things are ready to go. We can do this by running `sudo cobbler check`.

In our case, we're still missing a couple of things that are simple to correct.
The corresponding output is as follows.

```sh
$ sudo cobbler check
The following are potential configuration items that you may want to fix:

1 : SELinux is enabled. Please review the following wiki page for details on ensuring cobbler works correctly in your SELinux environment:
    https://github.com/cobbler/cobbler/wiki/Selinux
2 : some network boot-loaders are missing from /var/lib/cobbler/loaders, you may run 'cobbler get-loaders' to download them, or, if you only want to handle x86/x86_64 netbooting, you may ensure that you have installed a *recent* version of the syslinux package installed and can ignore this message entirely.  Files in this directory, should you want to support all architectures, should include pxelinux.0, menu.c32, elilo.efi, and yaboot. The 'cobbler get-loaders' command is the easiest way to resolve these requirements.
3 : debmirror package is not installed, it will be required to manage debian deployments and repositories
4 : fencing tools were not found, and are required to use the (optional) power management features. install cman or fence-agents to use them
```

We're missing some boot-loaders, and optionally, we're missing some fencing
agents which allows us to control some power management functionality (not
really a thing you need to worry about if you don't have IPMI interfaces).

Let's fix those now with the next couple of commands.

```sh
$ sudo cobbler get-loaders
$ sudo yum install fence-agents -y
```

Then we can restart our Cobbler service again:

```sh
$ sudo systemctl restart cobblerd.service
```

Let's see if our check looks a bit better.

```sh
$ sudo cobbler check
The following are potential configuration items that you may want to fix:

1 : SELinux is enabled. Please review the following wiki page for details on ensuring cobbler works correctly in your SELinux environment:
    https://github.com/cobbler/cobbler/wiki/Selinux
2 : debmirror package is not installed, it will be required to manage debian deployments and repositories
```

Much better! I'm not worried about the SELinux comment because we've dealt with
that, and I'm not doing anything with Debian packages, so time to move to the
next steps!

# Using an external DHCP server

The key to getting your external DHCP server working with Cobbler, is to enable
option 66 and direct the PXE booting machines to your Cobbler server to pull
down their configuration and booting information. For my EdgeRouter running
EdgeOS, I configure the following lines.

```sh
configure
edit service dhcp-server shared-network-name management subnet 192.168.1.0/24
set bootfile-name pxelinux.0
set bootfile-server 192.168.1.146
set subnet-parameters "filename &quot;pxelinux.0&quot;;"
commit
save
```

# Next Steps

I'm not going to document all the next steps since our installation is
configuration is done. You should be able to import an operating system, build
out your systems in the web interface (or via console), and start PXE booting
your machines. In my next post I'll go ahead and build out a Kickstart file for
the machines showing snippets and how I've gotten my lab up and running.

You'll probably want to start by importing an operating system, which is
documented in the manual at
http://cobbler.github.io/manuals/2.8.0/3/2/4_-_Import.html

# Conclusion

We've stepped through a critical aspect of the yakLab, which is to make it easy
to reproduce and deploy baremetal systems in our lab. In future blog posts,
we'll look at building the kickstart file, running a bootstrap playbook with
Ansible, deploying GlusterFS for a distributed file system, and layering
Kubernetes on top. Stay tuned!
