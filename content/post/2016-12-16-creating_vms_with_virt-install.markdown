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

# Preface

I have an LVM logical volume that hosts my virtual machines my M.2 disk drive,
and everything else on the host running from the SSD. This means that I have
`/var/lib/libvirt/images/` mounted to my M.2 drive, and everything else on the
SSD (except for swap as well).

Originally I was trying to get all this working with the user session, but the
user doesn't have permission to make networking changes and to attach to the
bridged network. A few things on the internet seemed to indicate running as a
user wasn't possible because of this. I suspect there are some permissions
things and SElinux tweaks I could do to make it work, but path of least
resistence for now is how it'll be.

That just means the following commands are going to be run with `sudo`. Of
course if you are just going to use the `default` network then you might be
able to get away with doing some of this in a user session.

# Using `virt-install`

Using the `virt-install` application we can instantitate a virtual machine from
the console. I got this all working by running the following command:

    sudo virt-install --name testing --memory 1024 \
        --disk /var/lib/libvirt/images/testing.qcow2,size=20,bus=virtio \
        --cdrom /var/lib/libvirt/isos/centos7.iso \
        --boot cdrom \
        --network bridge=br0 \
        --noautoconsole --vnc

If we look at this command, it defines the following things:

* virtual machine is named `testing`
* we define 1024 MB of memory (RAM) to this VM
* the VM will use a qcow2 backing disk with a size of 20GB, over the virtio bus
* we'll mount the `centos7.iso` into the CDROM (boot media)
* tell the system to boot from the CDROM
* assign the network to bridge to interface `br0`
* don't start a console, and enable VNC

I originally did this so that 1) I could validate that everything was going to
work :) and 2) so that I could perform a minimal install to generate my initial
anaconda-ks.cfg file (kickstart file).

After installation, I `scp`'d the file down to my host and moved onto the next
step. Automation ftw!

# Automating our virtual machine instantiation

Next up we just need to make a couple changes to our `virt-install` command so
that we use the new kickstart file for our deployment. First though, we need to
add a `reboot` value to the default `anaconda-ks.cfg` file. 

## Kickstart file
The following is the default generated kickstart file from a CentOS 7 minimal
install.

You'll see that I've added `reboot` right after the `clearpart` command, and
just before the `%packages` command.

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
    network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate
    network  --hostname=localhost.localdomain

    # Root password
    rootpw --iscrypted <ENCRYPTED_PASSWORD>
    # System services
    services --enabled="chronyd"
    # System timezone
    timezone America/New_York --isUtc
    user --groups=wheel --name=stack --password=<ENCRYPTED_PASSWORD> --iscrypted --gecos="stack"
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

# Kickstart-based virtual machine instantiation

And here is our modified `virt-install` line which will get you a CentOS 7
virtual machine created. Once the installation completes, the VM will shut
down, and you can start it back up with `sudo virsh start <machine_name>`.

Here is the command that will install your VM for you using the local kickstart
file.

    sudo virt-install --name testing --memory 1024 \
        --disk /var/lib/libvirt/images/testing.qcow2,size=20,bus=virtio \
        --location /var/lib/libvirt/isos/centos7.iso \
        --boot cdrom \
        --network bridge=br0 \
        --noautoconsole --vnc \
        --initrd-inject anaconda-ks.cfg \
        --extra-args "inst.ks=file:/anaconda-ks.cfg"
