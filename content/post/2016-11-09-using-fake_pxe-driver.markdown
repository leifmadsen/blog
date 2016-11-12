+++
categories = ["TripleO", "nfvpe"]
date = "2016-11-11T17:00:00-05:00"
description = ""
keywords = []
title = "TripleO: Using the fake_pxe driver with Ironic"

+++

I've been working on testing things with TripleO and normally I use [TripleO
Quickstart](https://github.com/openstack/tripleo-quickstart/) to spin things up
in a virtual environment.

Often when doing NFV work though, you need things that can't be used in a
virtual environment (such as DPDK, SR-IOV, etc) so you need some baremetal
nodes.

In my home lab environment though, I don't have the luxury of IPMI, so I need
to make use of the `fake_pxe` driver in Ironic, which allows for standard PXE
control, but requires you to deal with powering on and off the machines
manually. Let me show you how I make use of that.

# tl;dr

* power off machines
* start introspection
* power up machines
* wait for `openstack baremetal node list` to show `available`
* power off machines
* start `openstack overcloud deploy [...]`
* watch output of `openstack baremetal node list`
* when you see `wait for call-back` then power on the machines
* machines will boot via PXE, pull image from undercloud, write to disk
* machine will power down automatically via Linux `shutdown`
* watch `openstack baremetal node list` for `active`
* power machines on
* machine will report back to undercloud, and Puppet will execute to configure
  system

# Why use the `fake_pxe` driver?

The `fake_pxe` driver "provides stubs instead of real power and management
operations"<sup>[1](http://docs.openstack.org/developer/tripleo-docs/environments/baremetal.html)</sup>
so that you can utilize hardware that supports PXE, but doesn't provide the
necessary functionality to control power management functionality remotely.

This allows you to use some standard commodity hardware that doesn't have the
advanced power management systems of more expensive hardware.

# Enabling the driver in Ironic

By default the `fake_pxe` driver isn't enabled on the undercloud. You can
enable it in the `/etc/ironic/ironic.conf` by modifying the following line:

    enabled_drivers = pxe_ipmitool,pxe_ssh,pxe_drac,pxe_ilo,fake_pxe

Add `fake_pxe` to the end of the `enabled_drivers` configuration option. Then
we'll need to restart the Ironic services.

    $ sudo systemctl list-unit-files | grep ironic
    openstack-ironic-api.service                  enabled
    openstack-ironic-conductor.service            enabled
    openstack-ironic-inspector-dnsmasq.service    enabled
    openstack-ironic-inspector.service            enabled

I believe the only service you need to restart to make the driver active is
`openstack-ironic-conductor.service` but you can easily restart all the
services with the following commands:

    ironic_services=$(sudo systemctl list-unit-files | grep ironic | awk '/enabled/ {print $1}')
    sudo systemctl restart $ironic_services

# Validate driver is active

Now that we've modified the `ironic.conf` file and restarted the Ironic
services, let's double check the driver is active:

    $ openstack baremetal driver list
    Jun 2017. Please use osc_lib.utils
    +---------------------+-----------------------+
    | Supported driver(s) | Active host(s)        |
    +---------------------+-----------------------+
    | fake_pxe            | localhost.localdomain |
    | pxe_drac            | localhost.localdomain |
    | pxe_ilo             | localhost.localdomain |
    | pxe_ipmitool        | localhost.localdomain |
    | pxe_ssh             | localhost.localdomain |
    +---------------------+-----------------------+

# Workflow for TripleO deploy

Awesome, our driver is enabled. Now we can make use of it for our nodes. Using
the driver and understanding when to turn machines on and off wasn't super
obvious, so lets review the workflow.

## Import nodes for introspection

First, we need to make sure our baremetal nodes are configured on the
undercloud to make use of the `fake_pxe` driver. In our `instackenv.json` we
can set that up:

    {
        "nodes": [
            {
                "pm_type":"fake_pxe",
                "mac":[
                    "aa:bb:cc:dd:ee:ff"
                ],
                "cpu":"2",
                "memory":"4096",
                "disk":"40",
                "arch":"x86_64",
                "pm_user":"admin",
                "pm_password":"password",
                "pm_addr":"10.0.0.8",
                "capabilities": "profile:control,boot_option:local"
            }
        ]
    }

We've configured the `pm_type` to be `fake_pxe`, filled in our MAC address, and
setup some initial data about the node. I generally enable the
`inspection_extras = true` option in the `undercloud.conf` file so that the
hardware is evaluated during introspection and the database setup
appropriately. You can modify these values to match the hardware if you don't
want to execute that step (or it isn't detecting the hardware accurately).

The other `pm_???` values are just dummy data, and don't need to be populated
with anything meaningful (since we don't have any IPMI interface to connect to,
they are unnecessary). In previous versions of TripleO importing the nodes
would fail without the `pm_???` values which is why they are there at all.

## Perform introspection

With our nodes imported, can start the introspection process. Remember that we
want to start with the nodes turned off. Of course make sure you have the BIOS
setup to allow booting from PXE as the first boot device.

Start the introspection process:

    $ openstack baremetal import --initial-state=enroll instackenv.json

    $ openstack baremetal introspection bulk start

You can monitor status of the machines using `watch`:

    $ watch -n30 "openstack baremetal node list"

When the introspection process starts, you'll see the `Power State` switch to
`power on` and the `Provisioning State` field work its way through the
introspection process.

At this point, **power on** the machines.

    +--------------------------------------+------+---------------+-------------+--------------------+-------------+
    | UUID                                 | Name | Instance UUID | Power State | Provisioning State | Maintenance |
    +--------------------------------------+------+---------------+-------------+--------------------+-------------+
    | 25167102-fc8d-4907-b16c-dbdb09ea9d10 | None | None          | power on    | manageable         | False       |
    | 97c229c3-07bc-4f5e-a451-6ae3341f1f5a | None | None          | power on    | manageable         | False       |
    | a5d8a413-4458-480f-8a94-5f22902cea6c | None | None          | power on    | manageable         | False       |
    +--------------------------------------+------+---------------+-------------+--------------------+-------------+

When introspection completes, you'll see the `Provisioning State` switch to
`available` and the `Power State` should show `power off`. You'll need to
manually power down the machines at this point.

    +--------------------------------------+------+---------------+-------------+--------------------+-------------+
    | UUID                                 | Name | Instance UUID | Power State | Provisioning State | Maintenance |
    +--------------------------------------+------+---------------+-------------+--------------------+-------------+
    | 25167102-fc8d-4907-b16c-dbdb09ea9d10 | None | None          | power off   | available          | False       |
    | 97c229c3-07bc-4f5e-a451-6ae3341f1f5a | None | None          | power off   | available          | False       |
    | a5d8a413-4458-480f-8a94-5f22902cea6c | None | None          | power off   | available          | False       |
    +--------------------------------------+------+---------------+-------------+--------------------+-------------+

## Start overcloud deployment

With introspection completed and our machines **powered off**, we can start the
overcloud deployment. I won't get into how to deploy your cloud here (you might
want to refresh your memory with [TripleO: Consuming Composable
Roles](http://blog.leifmadsen.com/blog/2016/10/03/tripleo-consuming-composable-roles/)) but here is the general process:

* power off machines
* start `openstack overcloud deploy [...]`
* watch output of `openstack baremetal node list`
* when you see `wait for call-back` then power on the machines
* machines will boot via PXE, pull image from undercloud, write to disk
* machine will power down automatically via Linux `shutdown`
* watch `openstack baremetal node list` for `active`
* power machines on
* machine will report back to undercloud, and Puppet will execute to configure
  system

Once you run the `openstack overcloud deploy [...]` command, you'll `watch` the
output of your `openstack overcloud baremetal list` command, waiting for `Power
State` to switch to `power on`. At this point you'll power up the nodes.

Here is what we'll see while the overcloud starts to get provisioned:

    +--------------------------------------+------+---------------+-------------+--------------------+-------------+
    | UUID                                 | Name | Instance UUID | Power State | Provisioning State | Maintenance |
    +--------------------------------------+------+---------------+-------------+--------------------+-------------+
    | 25167102-fc8d-4907-b16c-dbdb09ea9d10 | None | None          | power off   | available          | False       |
    | 97c229c3-07bc-4f5e-a451-6ae3341f1f5a | None | None          | power off   | available          | False       |
    | a5d8a413-4458-480f-8a94-5f22902cea6c | None | None          | power off   | available          | False       |
    +--------------------------------------+------+---------------+-------------+--------------------+-------------+

Once you see the `Provisioning State` switch to `wait call-back` then you can
power the nodes back up so they can pull the disk image from the undercloud and
write it to the local disk drive.

    +--------------------------------------+------+--------------------------------------+-------------+--------------------+-------------+
    | UUID                                 | Name | Instance UUID                        | Power State | Provisioning State | Maintenance |
    +--------------------------------------+------+--------------------------------------+-------------+--------------------+-------------+
    | 25167102-fc8d-4907-b16c-dbdb09ea9d10 | None | c57f80dc-2e27-465a-b4ba-3e811313627b | power on    | wait call-back     | False       |
    | 97c229c3-07bc-4f5e-a451-6ae3341f1f5a | None | ef1d5f8e-79fd-423c-bdd2-39b850dadac8 | power on    | wait call-back     | False       |
    | a5d8a413-4458-480f-8a94-5f22902cea6c | None | 784f79b0-37de-461a-957a-8cac55fea72c | power on    | wait call-back     | False       |
    +--------------------------------------+------+--------------------------------------+-------------+--------------------+-------------+

The machines will then call back to the undercloud and you should see the
`Provisioning State` change to `deploying`.

After about 5-10 minutes (depending on image size, network speed, disk speed,
etc) your machines should power themselves off. The `Power State` value won't
change to `power off` though so you'll need to physically look at the machines
to validate the nodes have powered off.

We need to continue monitoring the nodes for the `Provisioning State` to switch
to `active`, meaning the undercloud is ready for you to power the machines back
up. After the state changes to `active` power the machines back on manually.

At this point, you're done playing power jockey, and can simply sit back and
watch your overcloud `COMPLETE` or `FAIL`.

# Conclusion

The `fake_pxe` driver is useful when you need to utilize commodity hardware
that doesn't have remote power management, when you're using hardware that
doesn't have a driver available for power management, or when your IPMI network
isn't available to the undercloud directly. Knowing when to power the nodes up
and down is really the only key to being successful with hardware that doesn't
have remote power management.
