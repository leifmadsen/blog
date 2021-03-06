+++
categories = ["nfvpe", "yakLab", "virtualization", "howto"]
keywords = ["lab", "build", "documentation", "howto", "docs", "virtualization",
"baremetal", "node", "cobbler", "gluster", "glusterFS", "filesystem", "k8s",
"kubernetes", "persistent storage"]
description = ""
title = "yakLab build out"
date = "2017-07-12T15:00:00-04:00"

+++

_Edit 2017-08-09: Updated diagram 1-1 to a graphic showing the entire lab
physical topology_

The yakLab is a place where yaks are electronically instantiated for the
purpose of learning and documenting. The lab consists of a virtualization host
(virthost) which has 64GB of memory and hosts all the virtual machines,
primarily for infrastructure.
<!--more-->

We then have 3 mini-ITX based baremetal nodes with 16GB of memory, 110GB hard
drive (single disk, SSD), with a quad-core CPU. The processing power of these
machines is quite low compared to modern day machines, but they consume a
relatively small amount of electricity, and don't make a lot of noise (the CPU
is fanless).

Here is a physical overview of the lab.

{{% figure src="/media/yakLab-phys-topology.png" title="Image 1-1: yakLab Physical Topology" %}}```
```
## Infrastructure build out episodes

In the yakLab build out, we'll talk about several of the infrastructure build
out scenes, including:

(**NOTE** I'll update the list below with links to articles as they become
available.)

* Scene 1a: [Building the virtual Cobbler deployment]({{< ref "post/2017-07-10-building-cobbler-vm.md" >}})
* Scene 1b: [Kickstart file build out]({{< ref "post/2017-07-19-kickstart-file-buildout.md" >}})
* Scene 1c: [Bootstrapping Bifrost with Ansible]({{< ref "post/2017-08-04-deploying-bifrost.md" >}})
* **[Not Complete]** Scene 2: GlusterFS distributed volumes
* **[Not Complete]** Scene 3: Kubernetes deployment with `kubeadm`
* Scene 4: [Kubernetes persistent volumes with GlusterFS]({{< ref "post/2017-09-19-glusterfs-persistent-volumes.md" >}})
