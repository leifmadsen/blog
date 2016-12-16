+++
keywords = []
categories = ["libvirt", "linux", "virtualization"]
title = "Initial Fedora libvirt Setup"
description = ""
date = "2016-12-16T10:30:35-05:00"

+++

There are always a few things I need to do to get libvirt working with a
non-root user on Fedora that I need to do, and typically results in some Google
researching. Here are some notes of what I recently did to get my libvirt setup
going on a new Fedora 25 installation and working with a non-root user.
<!--more-->

**NOTE** I found [this tuxfixer blog
post](http://www.tuxfixer.com/install-and-configure-kvm-qemu-on-centos-7-rhel-7-bridge-vhost-network-interface/)
while doing some other research for this blog post, which basically does
everything I'm about to say, but he does some other network setup and things
I'd have done via `nmcli` and the console. See my other blog post about
[creating a network bridge with nmcli for libvirt]({{< ref
"post/2016-12-01-create-bridge-with-nmcli.markdown" >}}).

# Installing packages

First thing to do is install the Virtualization group with `dnf`, then enable
and start with systemd.

    $ sudo dnf install @virtulization
    $ sudo systemctl enable libvirt
    $ sudo systemctl start libvirt

# Permissions setup

I want to use libvirt with my logged in user, so we need to setup some
permissions. First add to the `kvm` user group. You'll need to log back in to
validate. Then you can run `groups` at the console to confirm your groups.

    $ sudo usermod -a -G kvm leifmadsen

Then add the following contents to the bottom of your
`/etc/polkit-1/rules.d/49-polkit-pkla-compat.rules` file.

    polkit.addRule(function(action, subject) {
        if (action.id == "org.libvirt.unix.manage" &&
            subject.isInGroup("kvm")) {
                return polkit.Result.YES;
            }
    });

I'm not sure if this is entirely necessary, but I restart polkit.

    sudo systemctl restart polkit.service
    sudo sysetmctl status polkit.service

# Conclusion

That should be about it really! Try running `virt-manager` or using
`virt-install` to instantiate your first virtual machine to validate everything
is setup as it should be.
