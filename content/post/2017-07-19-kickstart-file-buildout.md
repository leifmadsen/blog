+++
date = "2017-07-19T13:54:42-04:00"
categories = ["nfvpe","howto","infrastructure"]
keywords = ["virtualization","kickstart","automation","devops","tooling","virtual machines"]
description = ""
title = "yakLab Part 1b: Kickstart File Build Out"

+++

In scene 1b, we'll continue with our work from the [Building the virtual
Cobbler deployment]({{< ref "post/2017-07-10-building-cobbler-vm.md" >}}) and
get a _kickstart_ file loaded into Cobbler. I'm going to be mostly reviewing
the kickstart file itself, and not really getting into how to manage the
Cobbler process itself (that's left as an exercise for the reader).

The main thing to note is that this is a bit of a work in progress, and I know
there are a few things that could be enhanced (for example, in the Cobbler
configuration file you can set a secret that you can reference as a variable in
the kickstart file, but I'm not doing that here, and you could also setup
partitioning, etc).

Another thing is that this kickstart file can't be used outside of Cobbler due
to the use of
[`$SNIPPET`](http://cobbler.github.io/manuals/2.8.0/3/6_-_Snippets.html) which
is a call to some external scripts provided by Cobbler (and you can build your
own!).

Primarily I'm using the `network_config` snippet to setup the initial network
interface for me, and that will automatically start on my KVM bridge interface.
(You can see a previous blog post where I document how to setup a bridge
interface with `nmcli` and expose it as a bridge network in libvirt 
[here]({{< ref "post/2016-12-01-create-bridge-with-nmcli.markdown" >}})).

Additional built in snippets are also used in the `%pre` and `%post` sections
of the kickstart file. These are used for network configuration, but also for
signalling to Cobbler when the operating system installation starts and ends.
The use of these snippets is important when you need to make sure the machine
doesn't run into a kickstart loop.

In a kickstart loop, the machine continuously keeps reinstalling after reboot,
but this can be avoided with the snippets, which signals back to Cobbler that
the machine has finished installing successfully, and marks the Netboot flag as
disabled so that Cobbler won't respond to the PXE boot next time through.

(If you need to reinstall a machine, you can enable the Netboot parameter
again, and then next time you reboot the machine, the PXE boot process will
result in Cobbler responding, and the system will be reinstalled.)

Note that I have my partitioning setup to account for my single hard disk
machines, which are sized at 120GB.

Without further ado, my current working kickstart script with Cobbler using
snippets.

| You can also provide feedback, comments, and pull requests against this file at https://github.com/leifmadsen/kickstart-files/blob/master/cobbler_compat/glusterfs-k8s-base.ks |
| ---                                                                                                                                                                            |
```
#version=DEVEL
# System authorization information
auth --enableshadow --passalgo=sha512
# Use CDROM installation media
cdrom
# Use graphical install
graphical
# Run the Setup Agent on first boot
firstboot --disable
ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Install from the network
url --url=$tree

# Root password
rootpw --iscrypted $1$S7..3hRm3gh3rd/
# System services
services --enabled="chronyd"
# System timezone
timezone America/New_York --isUtc
user --groups=wheel --name=admin --password=$1$S7..3hRm3gh3rd/ --iscrypted --gecos="admin"

# System bootloader configuration
zerombr
clearpart --drives=sda --all --initlabel
part /boot --fstype ext4 --size=500
part swap --size=16384
# create physical volumes
part pv.01 --size=20480 --ondisk=sda
part pv.02 --size=50000 --grow --ondisk=sda
# create volume groups
volgroup vg_system pv.01
volgroup vg_gluster pv.02
# create logical volumes
logvol / --vgname=vg_system  --fstype=ext4  --size=10240 --grow --maxsize=15360 --name=lv_root
logvol /var --vgname=vg_system --fstype=ext4 --size=4096 --name=lv_var
logvol /tmp --vgname=vg_system --fstype=ext4 --size=1024 --name=lv_tmp
logvol /bricks/brick1 --vgname=vg_gluster --fstype=xfs --size=50000 --grow --name=lv_brick1

bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda

# Network information
$SNIPPET('network_config')
reboot

%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

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

%post
$SNIPPET('log_ks_post')
$SNIPPET('post_install_network_config')
# Enable post-install boot notification
$SNIPPET('post_anamon')
# Start final steps
$SNIPPET('kickstart_done')
# End final steps
%end
```
