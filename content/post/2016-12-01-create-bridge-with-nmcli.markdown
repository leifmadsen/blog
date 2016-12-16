+++
title = "Create network bridge with nmcli for libvirt"
description = ""
keywords = []
categories = ["nfvpe", "linux", "networking", "console"]
date = "2016-12-01T14:51:52-05:00"

+++

In order to get libvirt working properly with bridged networking, we first need
to configure our local network to have network bridge slaved to our wired
ethernet adapter. I don't have to set this up too often (as once I do, it just
sits there running happily). Here are some basic steps I did to get this going
locally.

# Add a bridge interface via Network Manager

Before we get to adding a new network interface to libvirt, we'll add our
bridge interface to our host system via Network Manager.

## Review starting network configuration

First let's look at our current network configuration with `nmcli`, the Network
Manager command line interface (CLI). You can do this via the Network Manager
applet as well (nm-applet) but in recent versions of Fedora, the CLI works
quite well, and I find a little simpler since we'll only need to execute a few
commands.

We can see the current state of our network interfaces via `nmcli con show
--active`

```bash
$ nmcli con show --active
NAME          UUID                                  TYPE            DEVICE
docker0       770d6801-47dc-44a3-9d11-17249f11ef26  bridge          docker0
wired-direct  73157bec-12fb-42d0-98c4-f4576742e095  802-3-ethernet  enp0s25
```

Here you can see that I have a connection called `wired-direct` which uses the
`enp0s25` interface. I also have a `docker0` bridge interface which was created
when Docker was installed on my system.

We're going to convert the libvirt host system (e.g. my laptop) to use a bridge
interface which will get a slave port attached to `enp0s25`.

## Create bridge interface

Now we're ready to create our bridge interface, and then create a slave
interface and attach it to the ethernet interface. The following set of
commands are taken from [Fedora
Magazine](https://fedoramagazine.org/build-network-bridge-fedora/):

```bash
$ nmcli con add ifname br0 type bridge con-name br0
Connection 'br0' (892869fe-f8ac-4f17-ace9-b8aeeeee61a0) successfully added.

$ nmcli con add type bridge-slave ifname enp0s25 master br0
Connection 'bridge-slave-enp0s25' (33ee8c62-48d8-4789-97df-604c479b6860)
successfully added.
```

Let's also disable STP since we don't want to wait for this interface to come
up on our network (keep this enabled if you need [spanning
tree](https://wiki.linuxfoundation.org/networking/bridge_stp) enabled).
Additional properties that can be adjusted can be shown via `nmcli con show
br0`.

```bash
$ nmcli con modify br0 bridge.stp no
```

## Enable bridge interface

First let's review where we're at.

```bash
$ nmcli con show

NAME                   UUID                                  TYPE             DEVICE
docker0                770d6801-47dc-44a3-9d11-17249f11ef26  bridge           docker0
wired-direct           73157bec-12fb-42d0-98c4-f4576742e095  802-3-ethernet   enp0s25
br0                    892869fe-f8ac-4f17-ace9-b8aeeeee61a0  bridge           --
bridge-slave-enp0s25   33ee8c62-48d8-4789-97df-604c479b6860  802-3-ethernet   --
```

As you can see in our output, our new bridge interface isn't active yet. We'll
first down the wired-direct (enp0s25) interface and then bring the new bridge
interface up. If you look at the output of `ip a s` before running the `nmcli`
commands, you should see your IP address move from the `enp0s25` interface to
`br0` (it is assumed you're using DHCP).

```bash
$ ip a s
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp0s25: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 54:ee:75:76:50:8e brd ff:ff:ff:ff:ff:ff
    inet 192.168.3.160/24 brd 192.168.3.255 scope global dynamic enp0s25
       valid_lft 86394sec preferred_lft 86394sec
    inet6 fe80::56ee:75ff:fe76:508e/64 scope link 
       valid_lft forever preferred_lft forever
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:e7:79:09:d0 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 scope global docker0
       valid_lft forever preferred_lft forever
7: br0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default qlen 1000
    link/ether 00:00:00:00:00:00 brd ff:ff:ff:ff:ff:ff
```

OK time to down our `enp0s25` interface:

```bash
$ nmcli con down wired-direct
Connection 'wired-direct' successfully deactivated (D-Bus active path:
/org/freedesktop/NetworkManager/ActiveConnection/11)
```

And now we can bring our new bridge up:

```bash
$ nmcli con up br0
Connection successfully activated (master waiting for slaves) (D-Bus active
path: /org/freedesktop/NetworkManager/ActiveConnection/12)
```

I've found that periodically the network interfaces won't come up for whatever
reason, and you need to kick the NetworkManager service.

```bash
sudo systemctl restart NetworkManager.service
```

Run `nmcli con show` and `nmcli con down wired-direct` if you need and then
bring the bridge back online with `nmcli con up br0`. Hopefully by this point
your `nmcli con show --active` output looks similar to the following:

```bash
NAME                  UUID                                  TYPE            DEVICE
br0                   892869fe-f8ac-4f17-ace9-b8aeeeee61a0  bridge          br0
bridge-slave-enp0s25  33ee8c62-48d8-4789-97df-604c479b6860  802-3-ethernet  enp0s25
docker0               bdc99fc1-1e2b-4e28-8309-dd0ae9c80de3  bridge          docker0
```

And our `ip a s` output looks like this:

```bash
$ ip a s
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: enp0s25: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel master br0 state UP group default qlen 1000
    link/ether 54:ee:75:76:50:8e brd ff:ff:ff:ff:ff:ff
4: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default 
    link/ether 02:42:e7:79:09:d0 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 scope global docker0
       valid_lft forever preferred_lft forever
7: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 54:ee:75:76:50:8e brd ff:ff:ff:ff:ff:ff
    inet 192.168.3.160/24 brd 192.168.3.255 scope global dynamic br0
       valid_lft 86211sec preferred_lft 86211sec
    inet6 fe80::d813:5274:e201:f3/64 scope link 
       valid_lft forever preferred_lft forever
```

# Adding bridge networks to libvirt

OK time to add a new network interface to libvirt that will utilize the `br0`
interface we just created above.

## Review starting network configuration

As before, we'll review what our networking configuration starting point is.

```bash
virsh net-list --all
 Name                 State      Autostart     Persistent
 ----------------------------------------------------------
  default              active     yes           yes
```

In this case we only have the default NAT networks.

## Create network interface

In order to create a new network interface, we need to import the XML
configuration from a local file. We can do this by creating a temporary file
that we'll import the configuration in from.

```xml
cat > bridge.xml <<EOF
<network>
    <name>host-bridge</name>
    <forward mode="bridge"/>
    <bridge name="br0"/>
</network>
EOF
```

You'll notice that we've input our local bridge name of `br0` and named the
interface `host-bridge`. You can name the bridge anything you want, as long as
you don't use things like spaces and other special characters.

We can create the network with `virsh net-define`. If you use `virsh
net-create` the network shows up temporarily.

```bash
$ virsh net-define bridge.xml
Network host-bridge defined from bridge.xml
```

Now we can validate our network shows up.

```bash
$ virsh net-list --all
 Name                 State      Autostart     Persistent
----------------------------------------------------------
 host-bridge          active     no            yes
```

## Starting the network interface

And now we can start the bridge and mark it to automatically start.

```bash
$ virsh net-start host-bridge
Network host-bridge started

$ virsh net-autostart host-bridge
Network host-bridge marked as autostarted
```

# Conclusion

At this point you should be able to create virtual machines and use the bridged
interface in order to get those virtual machines directly on your LAN using
existing infrastructure instead of going via NAT.

**NOTE** If you are having issues with using `virsh` and `virt-manager` from a
non-root user, check out [this
post](http://computingforgeeks.com/use-virt-manager-as-non-root-user/).
