+++
categories = ["OpenStack", "Linux", "Cloud Computing", "TripleO", "nfvpe"]
date = "2016-10-03T15:34:08-04:00"
description = ""
keywords = ["composable services", "composable roles", "tripleO", "openstack",
"newton"]
title = "TripleO: Consuming Composable Roles"

+++
So last week I started to look into learning the new [composable services and
roles](http://hardysteven.blogspot.ca/2016/08/tripleo-composable-services-101.html)
that was added to Newton. I previously learned a little bit about deploying
OpenStack clouds when I did training after joining Red Hat, but that was based
on Liberty, and a lot has changed in TripleO since that time.
<!--more-->
The first thing was learning what composable services and roles are, and
generally what they are intended to solve. I don't want to get into that
here, so I'd encourage you to go read some links first and then come back here.
Additionally, it's assumed you know what a TripleO is :)

* [TripleO Composable Services Within
  Roles Blueprint](https://blueprints.launchpad.net/tripleo/+spec/composable-services-within-roles)
* [TripleO Composable Services
  Tutorial](http://tripleo.org/developer/tht_walkthrough/tht_walkthrough.html)
* [TripleO Deep Dive: TripleO Heat
  Templates](https://www.youtube.com/watch?v=gX5AKSqRCiU)

I'm not really going to be showing anything too magical here. The primary use
case is getting bootstrapped so we can start playing with TripleO Heat
Templates (THT) and deploy using the `roles_data.yml` file along with our own
template files.

## Getting a working environment

I have access to a machine with a good amount of resources (12 cores, 24 with
HT, and 64GB of memory) so I'm doing everything here in a virtual environment.
Additionally, I'm using [TripleO
Quickstart](https://github.com/openstack/tripleo-quickstart) to get my
undercloud up and running along with instantiating the overcloud VMs (but not
provisioning them).

First I created a new configuration file to define the environment I wanted to
build. I create a single controller and three compute nodes. I did this
primarily so I could test scaling up and down the compute nodes.

The configuration file is exactly what is defined
`config/general_config/minimal.yml` but I added more another 2 compute nodes to
the list. Here is the file as tested:

``` yaml
# We run tempest in this topology instead of ping test.
# We set introspection to true and use only the minimal amount of nodes
# for this job, but test all defaults otherwise.
step_introspect: true

# Define a single controller node and a single compute node.
overcloud_nodes:
  - name: control_0
    flavor: control

  - name: compute_0
    flavor: compute
  - name: compute_1
    flavor: compute
  - name: compute_2
    flavor: compute

# Tell tripleo how we want things done.
extra_args: >-
  --neutron-network-type vxlan
  --neutron-tunnel-types vxlan
  --ntp-server pool.ntp.org

network_isolation: true

# If `test_tempest` is `true`, run tempests tests, otherwise do not
# run them.
tempest_config: true
test_ping: false
run_tempest: true

# options below direct automatic doc generation by tripleo-collect-logs
artcl_gen_docs: true
artcl_create_docs_payload:
  included_deployment_scripts:
    - undercloud-install
    - undercloud-post-install
    - overcloud-deploy
    - overcloud-deploy-post
    - overcloud-validate
  included_static_docs:
    - env-setup-virt
  table_of_contents:
    - env-setup-virt
    - undercloud-install
    - undercloud-post-install
    - overcloud-deploy
    - overcloud-deploy-post
    - overcloud-validate
```

Then I deployed my environment with **oooq** using the following command:


``` bash
./quickstart.sh \
  --working-dir ~/quickstart \
  --no-clone \
  --bootstrap \
  --teardown all \
  --tags all \
  --skip-tags overcloud-validate,overcloud-deploy \
  --config ./config/general_config/1-plus-3.yml \
  --release master \
  --playbook quickstart-extras.yml \
  127.0.0.2
```

The `quickstart-extras.yml` will make sure our overcloud scripts are added to
the undercloud, and that some other nice things happen like making sure images
are pulled down and put onto the undercloud, along with a default
`network-environment.yml` file being created.

TripleO Quickstart (oooq) will then spin up our VMs and we can validate this
with the following:

``` bash
sudo su - stack
$ virsh list --all
 Id    Name                           State
----------------------------------------------------
 2     undercloud                     running
 -     control_0                      shut off
 -     compute_0                      shut off
 -     compute_1                      shut off
 -     compute_2                      shut off
```

## Logging into the undercloud

Now that our environment is up and running lets log into the undercloud so we
can start deploying our cloud.

``` bash
cd ~/quickstart
ssh -F ssh.config.ansible stack@undercloud
[stack@undercloud ~]$
```
## Initial deployment of the cloud

Next we want to do an initial deployment of our environment. We'll be
provisiong a single controller and a single compute node to start. Prior to
Newton we would normally deploy using several `--scale` and `--flavor` flags
since we had a limited set of roles available to us. With Newton we have a lot
more range as to what services make up a role, meaning the built in flags no
longer make a lot of sense.

This OpenStack change resulted in the flags being deprecated: [OpenStack Review 378667](https://review.openstack.org/#/c/378667/3/tripleoclient/utils.py)

Instead, we should be deploying using a template file instead. Before looking
at the template lets look at what our previous deployment command might have
looked like:

``` bash
source stackrc

openstack overcloud deploy \
  --control-flavor control \
  --control-scale 1 \
  --compute-flavor compute \
  - compute-scale 1 \
  --templates \
  --libvirt-type qemu \
  --timeout 90 \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/net-single-nic-with-vlans.yaml \
  -e network-environment.yaml \
  --neutron-network-type vxlan \
  --neutron-tunnel-types vxlan \
  --ntp-server pool.ntp.org
```

At the top of that command we have the `--control-flavor`, `--control-scale`,
`--compute-flavor`, and '--compute-scale' flags. Since we now have composable
roles (and that means we could really have any number of roles and flavors)
having a built in flag doesn't make a lot of sense. Instead, we move the
scale and flavor assignments into a template file.

I created a new file in the home directory called `deploy.yaml`. The contents
are pretty straight forward:

``` yaml
parameter_defaults:
    OvercloudControlFlavor: control
    OvercloudComputeFlavor: compute
    ControllerCount: 1
    ComputeCount: 1
```

With this template we'll get a single controller and a single compute. If we
need to scale in the future, we just need to modify the values in that file and
re-run our deployment.

With our new `deploy.yaml` file lets adjust our `overcloud deploy` command:

``` bash
openstack overcloud deploy \
  --templates \
  --libvirt-type qemu \
  --timeout 90 \
  -e deploy.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
  -e /usr/share/openstack-tripleo-heat-templates/environments/net-single-nic-with-vlans.yaml \
  -e network-environment.yaml \
  --neutron-network-type vxlan \
  --neutron-tunnel-types vxlan \
  --ntp-server pool.ntp.org
```

And our resulting VMs:

``` bash
$ virsh list --all
 Id    Name                           State
----------------------------------------------------
 2     undercloud                     running
 12    control_0                      running
 11    compute_0                      running
 -     compute_1                      shut off
 -     compute_2                      shut off
```

## Scaling the cloud up and down

Scaling the cloud up and down is really pretty straight forward at this point.
Just modify the `deploy.yaml` to the correct values (and for the appropriate
level of hardware you have access to) and re-run the `openstack overcloud 
deploy` command again.

## Creating your own roles

In order to create your own roles you'll need to copy the
`openstack-tripleo-heat-templates` to your home directory and modify the
`roles_data.yml` file directly (until [this bug](https://bugs.launchpad.net/tripleo/+bug/1626955)
has been resolved).

``` bash
cp -r /usr/share/openstack-tripleo-heat-templates/ ~/tht
```

When deploying your overcloud with the `openstack overcloud deploy` command you
would append `tht/` after `--templates`:

``` bash
openstack overcloud deploy --template tht/ ...
```

## Conclusion

So that's how far I've gotten in one afternoon of playing around with the new
composable services and roles in TripleO. Next up will be attempting to build
out my own set of roles and see how easy it is to construct new topologies and
to move services around to different systems.
